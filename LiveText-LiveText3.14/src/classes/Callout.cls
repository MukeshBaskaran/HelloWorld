/**
 * @author         Amit Madhoriya(amit@comitydesigns.com)
 * @version        1.0
 * @date           08.06.2014
 * @description    This is static class and contains method to make API callouts to HeyWire server for following functionalities,
 *                1. Validate Phone No on HeyWire.
 *                2. Send SMS from configure support number in Salesforce to other numbers.
*/
public with sharing class Callout {
    private static final String ACCOUNT_ID = 'AdminAccountId';
    private static final String AUTH_TOKEN = 'AdminPassword';
    private static final String CONTENT_TYPE = 'Content-Type';
    private static final String CONTENT_LENGTH = 'Content-Length';
    private static final String HTTP_METHOD_POST = 'POST';
    private static final String HTTP_METHOD_PUT = 'PUT';
    private static final String HTTP_METHOD_DELETE = 'DELETE';
    private static final String HTTP_METHOD_GET = 'GET';
    private static final Integer HTTP_STATUS_CODE_OK = 200;
    public static final Integer HTTP_STATUS_CODE_UNAUTHORIZED = 401;
    private static final ConfigurationSettings__c confSettings = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
    
    public class applicationException extends Exception {

    }
   
   /**
     * @description: Checks if given phone number exists on the HeyWire.
     * @param: phoneNumber, user provided phone number.
     * @return true, if given phone number exists.
    */
    public static Boolean doesPhoneNoExist(String phoneNumber) {
        Boolean phoneNumberExists = false;
        if(String.isNotBlank(phoneNumber) && Util.isHeyWireConnected()) {
            HttpResponse res = doesPhoneNoExistInternal(phoneNumber);
            if(res.getStatusCode() == HTTP_STATUS_CODE_OK) {
                phoneNumberExists = true;
            } else {
                addResponseError(res, false);
            }
        }
        return phoneNumberExists;
    }
    
    public static HttpResponse doesPhoneNoExistInternal(String phoneNumber) {
        HttpResponse res =  new HttpResponse();
        Http h = new Http();
        res = h.send(buildRequest(HTTP_METHOD_GET, Constant.HEYWIRE_API_GET_PHONE_NUMBER + phoneNumber, null));
        return res;
    }
    
   /**
     * @description: Checks if given phone number can be deleted or not. If the response code is 404 then number
     *               can be deleted.
     * @param: phoneNumber, user provided phone number.
     * @return true, if response code is 404. If response code is 200 then throws error message.
    */
    public static Boolean canDeletePhoneNo(String phoneNumber) {
        Http h = new Http();
        HttpResponse res =  new HttpResponse();
        Boolean canDeletePhoneNo = false;
        if(String.isNotBlank(phoneNumber) && Util.isHeyWireConnected()) { 
            res = h.send(buildRequest(HTTP_METHOD_GET, Constant.HEYWIRE_API_GET_PHONE_NUMBER + phoneNumber, null));
            if(res.getStatusCode() == 404){
                canDeletePhoneNo = true;
            } else if(res.getStatusCode() == HTTP_STATUS_CODE_OK) {
                Util.addMessageOnError(system.label.CannotDeleteSupportNoMsg);
            } else {
                addResponseError(res);
            }
        }
        return canDeletePhoneNo;
    }
   
   /**
     * @description: Sends the message entered by the agent to the customer number using Send SMS HeyWire API.
     *               Encodes the message as per UTF-8 standard before sending.
     * @param: smsObject, SMS_Text__c object.
     * @param: smsText, message as entered by agent.
     * @return true, if message send successfuly(response code is 204).
    */
    public static Boolean sendSMS(SObject smsObject, String smsText) {
        Boolean smsSent = false;
        SMS_Text__c castedSmsText = (SMS_Text__c)smsObject;
        LiveText_Number__c supportNumber = [
                                                SELECT Id, Number__c 
                                                FROM LiveText_Number__c 
                                                WHERE Id=:castedSmsText.Support_Number__c LIMIT 1
                                            ];
        if (supportNumber !=null) {
            HttpResponse response = sendSMSInternal(castedSmsText.Originating_Number__c, supportNumber.Number__c, smsText);
            if(response.getStatusCode() == 204) {
                smsSent = true;
            } else {
                addResponseError(response);
            }
        }
        return smsSent;
    }

 	/** 
   	* @description: Issues Http callout to LiveText Servers to send the given image as an MMS or picture attachment.
   	* @param: toPhoneNumber, Phone number to send the MMS to.
    * @param: supportNumber, Phone number to send the MMS from.
    * @param: attachmentId 
    * @param: imgName, name of the image as uploaded by the user.
   	* @param: imgType, image type as reported by the file uploader.
    * @return Result of the HTTP Request with status code 204 for success.
    */
	public static HttpResponse sendMMSInternal(String toPhoneNumber, String supportNumber, String attachmentId, String imgName, String imgType){
	   String boundary = '----------------------------741e90d31eff';
        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('To', toPhoneNumber);
        headersMap.put('PhoneNumber', supportNumber);
        headersMap.put('File', supportNumber);
        // Encode headers 
        String encodedHeaders = '';
        for(String key:headersMap.keySet()){
          String header = '--'+boundary+'\r\nContent-Disposition: form-data; name="'+key+'";\r\n\r\n'+headersMap.get(key);
          if(key == 'File'){
            header = '--'+boundary+'\r\nContent-Disposition: form-data; name="file"; filename="'+imgName+'"\r\nContent-Type: application/octet-stream';
          }
          String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
          while(headerEncoded.endsWith('=')){
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
          }
          encodedHeaders += headerEncoded;
        }
        String footer = '\r\n--'+boundary+'--';
        String mainBody = EncodingUtil.base64Encode((Blob)[Select Id, Body From Attachment Where Id = :attachmentId Limit 1][0].get('Body'));
        Integer lengthMinusFour = mainBody.length()-4;
        String last4Bytes = mainBody.substring(mainBody.length()-4,mainBody.length());
        mainBody = '';  
        String footerEncoded;
        if(last4Bytes.endsWith('==')){
          // The '==' sequence indicates that the last group contained only one 8 bit byte
          // 8 digit binary representation of CR is 00001101
          // 8 digit binary representation of LF is 00001010
          // Stitch them together and then from the right split them into 6 bit chunks
          // 0000110100001010 becomes 0000 110100 001010
          // Note the first 4 bits 0000 are identical to the padding used to encode the
          // second original 6 bit chunk, this is handy it means we can hard code the response in
          // The decimal values of 110100 001010 are 52 10
          // The base64 mapping values of 52 10 are 0 K
          // See http://en.wikipedia.org/wiki/Base64 for base64 mapping table
          // Therefore, we replace == with 0K
          // Note: if using \n\n instead of \r\n replace == with 'oK'
          last4Bytes = last4Bytes.substring(0,2) + '0K';
          mainBody = EncodingUtil.base64Encode((Blob)[Select Id, Body From Attachment Where Id = :attachmentId Limit 1][0].get('Body')).substring(0,lengthMinusFour) + last4Bytes;
          // We have appended the \r\n to the Blob, so leave footer as it is.
          footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
          //bodyAsBlob = EncodingUtil.base64Decode(encodedHeaders+bodyEncoded+footerEncoded);
        }else if(last4Bytes.endsWith('=')){
          // '=' indicates that encoded data already contained two out of 3x 8 bit bytes
          // We replace final 8 bit byte with a CR e.g. \r
          // 8 digit binary representation of CR is 00001101
          // Ignore the first 2 bits of 00 001101 they have already been used up as padding
          // for the existing data.
          // The Decimal value of 001101 is 13
          // The base64 value of 13 is N
          // Therefore, we replace = with N
          // Note: if using \n instead of \r replace = with 'K'
          last4Bytes = last4Bytes.substring(0,3) + 'N';
          mainBody = EncodingUtil.base64Encode((Blob)[Select Id, Body From Attachment Where Id = :attachmentId Limit 1][0].get('Body')).substring(0,lengthMinusFour) + last4Bytes;
          footer = '\n' + footer;
          // We have appended the CR e.g. \r, still need to prepend the line feed to the footer
          footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        }else{
          footer = '\r\n' + footer;
          mainBody = EncodingUtil.base64Encode((Blob)[Select Id, Body From Attachment Where Id = :attachmentId Limit 1][0].get('Body'));
          footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        } 

        String reqEndPoint = confSettings.Endpoint_URL__c + String.format(Constant.HEYWIRE_API_SEND_SMS, new String[]{supportNumber});
        HttpRequest req = new HttpRequest();
        req.setHeader(ACCOUNT_ID, confSettings.Account_Id__c);
        req.setHeader(AUTH_TOKEN, confSettings.Auth_Token__c);
        req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
        req.setMethod('POST');
        req.setEndpoint(reqEndPoint);
        req.setBodyAsBlob(EncodingUtil.base64Decode(encodedHeaders+mainBody+footerEncoded));
        req.setTimeout(120000); 

        Http http = new Http();
        HTTPResponse res;
        if(!Test.isRunningTest()){
          res = http.send(req);
        }else{
          res = new HTTPResponse();
          res.setStatusCode(204);
        } 
        return res;
	}     

    /** 
     * Issues Http callout to LiveText Servers. created this as public in-order to be able to get test coverage.
    */
     public static HttpResponse sendSMSInternal(String originatingNumber, String supportNumber, String smsText){
        Http h = new Http();
        HttpResponse res =  new HttpResponse();
        if(String.isNotBlank(originatingNumber) && String.isNotBlank(supportNumber) && String.isNotBlank(smsText) && Util.isHeyWireConnected()){
            smsText = EncodingUtil.urlEncode(smsText, 'UTF-8');
            String body = 'To=' + EncodingUtil.urlEncode(originatingNumber, 'UTF-8') + '&Body=' + smsText;
            String endPoint = String.format(Constant.HEYWIRE_API_SEND_SMS, 
                                        new String[]{supportNumber});
            HTTPRequest req = buildRequest(HTTP_METHOD_POST, endpoint, body);
            req.setHeader(CONTENT_LENGTH, String.valueOf(smsText.length()));
            res = h.send(req);
        }
        return res;
    }
    
    /** 
     * Issues Http callout to LiveText Servers. created this as public in-order to be able to get test coverage.
     */
     public static HttpResponse sendPictureRequest(String originatingNumber, String supportNumber){
        Http h = new Http();
        HttpResponse res =  new HttpResponse();
        if(String.isNotBlank(originatingNumber) && String.isNotBlank(supportNumber) && Util.isHeyWireConnected()){
            String body = 'To=' + originatingNumber;
            String endPoint = String.format(Constant.HEYWIRE_API_SEND_PICTURE_REQUEST, 
                                        new String[]{supportNumber});
            HTTPRequest req = buildRequest(HTTP_METHOD_POST, endpoint, body);
            req.setHeader(CONTENT_LENGTH, String.valueOf(body.length()));
            res = h.send(req);
        }
        return res;
    }
        
    /**
     * @description:future method called from SMSTextTriggerHandler on afterInsertUpdate which calls sendSMS to make Send SMS HeyWire API call.
     * @param: List<Id> of SMS_Text__c object.
     * @return null;.
     */
    @Future(callout = true)
    public static void sendSMSViaTrigger(List < Id > smsObjectList) {
        Boolean smsSent = false;
        List < SMS_Text__c > smsTextList =  [   SELECT Support_Number__c, Source__c, Support_Number__r.Number__c, Originating_Number__c, Name,Message__c, Id, Conversation_Header__c 
                                                FROM SMS_Text__c 
                                                WHERE Id = : smsObjectList[0]
                                            ];

        String offlineMessage = Util.getConfiguredMessage(
                                        new List < String > { smsTextList[0].Support_Number__c },
                                        new List < String > { Constant.offline_Hours_Message}
                                );
        smsSent = sendSMS(smsTextList[0], offlineMessage);
        if (smsSent == false) {
            Util.insertException(smsTextList[0].Id, constant.priority_high, 'API Call Failed for Message:' + smsTextList[0].Message__c);
        }
    }
    
    /**
     * @description:Adds the callout response error to be displayed on pages.
     * @param: res, the HTTPResponse object.
     */
    public static void addResponseError(HttpResponse res){
        addResponseError(res, true);
    }
    
    /**
     * @description:Adds the callout response error to be displayed on pages. Updates the Configuration custom settings
     *              value for valid heywire credentials to false for 401(Unauthorized) error.
     * @param: the HTTPResponse object.
     * @param: boolean to check if other errors should be added or not.
     */
    public static void addResponseError(HttpResponse res, Boolean addError) {
        if(res.getStatusCode() == HTTP_STATUS_CODE_UNAUTHORIZED) {
            confSettings.Is_Valid_Credentials__c = false;
            Util.addMessageOnError(Database.update(confSettings, false));
        }
        if(addError) {
            String errorDescription = res.getStatusCode() + ':' + res.getStatus();
            errorDescription += String.isBlank(res.getBody())?'':':'+res.getBody();
            Util.addMessageOnError(String.format(system.label.APICalloutFailureMsg, new String[]{errorDescription}));
        }
    }
    
    /**
     * @description:Validates the account credentials provided by user against the Heywire system.
     * @param: The configuration settings populated with date as provided by user.
     * @param: Phone number for which the credetials will be validated.
     * @return: true, if credetials are valid.
     */
    public static Boolean validateAccCredentials(ConfigurationSettings__c newSettings, String phoneNumber) {
        Http h = new Http();
        HttpResponse res =  new HttpResponse();
        Boolean isValid = true;
        try {
            if(confSettings != null && String.isNotBlank(phoneNumber)) {
                String endPoint = String.format(Constant.HEYWIRE_API_LOOKUP_ACCOUNT, new String[]{phoneNumber});
                HTTPRequest req = buildRequest(newSettings, HTTP_METHOD_GET, endpoint);
                res = h.send(req);
                if(res.getStatusCode() == HTTP_STATUS_CODE_UNAUTHORIZED) {
                    isValid = false;
                }
            }
        } catch(Exception ex) {
            Util.addMessageOnError(ex.getMessage());
        }
        return isValid;
    }
    
    private static HttpRequest buildRequest(ConfigurationSettings__c newSettings, String method, String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setHeader(ACCOUNT_ID, newSettings.Account_Id__c);
        req.setHeader(AUTH_TOKEN, newSettings.Auth_Token__c);
        req.setHeader(CONTENT_TYPE, 'application/x-www-form-urlencoded'); 
        req.setTimeout(120000);
        req.setEndpoint(newSettings.Endpoint_URL__c + endPoint);
        req.setMethod(method);
        return req; 
    }
    
    private static HttpRequest buildRequest(String method, String endpoint, String body) {
        HttpRequest req = new HttpRequest();
        req.setHeader(ACCOUNT_ID, confSettings.Account_Id__c);
        req.setHeader(AUTH_TOKEN, confSettings.Auth_Token__c);
        req.setHeader(CONTENT_TYPE, 'application/x-www-form-urlencoded'); 
        req.setTimeout(120000);
        req.setEndpoint(confSettings.Endpoint_URL__c + endPoint);
        req.setMethod(method);
        if(String.isNotBlank(body)){
            req.setBody(body);
        }
        return req; 
    }
}