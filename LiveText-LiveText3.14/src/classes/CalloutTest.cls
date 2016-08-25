@isTest
private class CalloutTest {    
    static Inbound_Connection_Status__c connStatus;
    static ConfigurationSettings__c confSettings;
    static Conversation_Header__c conversationHeader;
    static SMS_Text__c smsTextObject;
    static SObject ltnObject;    
    static {
        confSettings = UnitTestObjectBuilder.CreateConfigurationSettings();
        connStatus = UnitTestObjectBuilder.CreateConnectionStatus();
    }

    /*
     *  Create Livetext number
     * Creating conversation header
     * Creating SMS Text Object
    */
    static void initTestData() {
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        System.assertNotEquals(ltnObject.Id, null);
        conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
    }
    
    static testMethod void Test_SendSMS_Positive() {
        HttpResponse response;
        initTestData();
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_SEND_SMS, 
                                        new String[]{(String)ltnObject.get('Number__c')});
        System.assertNotEquals(endPoint, null);
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(204, 'OK', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put(endPoint, fakePhNoExistResp);
        HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
        Boolean smsSent = Callout.sendSMS(smsTextObject, 'Hi how are you?');
        system.assertEquals(smsSent, true);
        Test.stopTest();
    }
    
    static testMethod void Test_SendSMS_Negative() {
        initTestData();
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_SEND_SMS, 
                                        new String[]{(String)smsTextObject.get('Support_Number__c')});
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(500, 'OK', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Test.setMock(HttpCalloutMock.class, fakePhNoExistResp);
        Boolean smsSent = Callout.sendSMS(smsTextObject, 'Hi how are you?');
        System.assertNotEquals(smsSent, true);
        Test.stopTest();
    }
    
    static testMethod void Test_addResponseError() {
        initTestData();
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_SEND_SMS, 
                                        new String[]{(String)smsTextObject.get('Support_Number__c')});
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(500, 'OK', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Test.setMock(HttpCalloutMock.class, fakePhNoExistResp);
        Boolean smsSent = Callout.sendSMS(smsTextObject, 'Hi how are you?');
        System.assertNotEquals(smsSent, true);
        Test.stopTest();
    }
    
    static testMethod void Test_doesPhoneNoExistInternal() {
        initTestData();
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(401, 'OK', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Test.setMock(HttpCalloutMock.class, fakePhNoExistResp);
        HttpResponse response = Callout.doesPhoneNoExistInternal(phoneNumber);
        System.assertNotEquals(response, null);
        Test.stopTest();
    }
    
    static testMethod void Test_DoesPhNoExist_Positive() {
        HttpResponse response;
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + phoneNumber;
        System.assertNotEquals(endPoint, null);
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(200, 'OK', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put(endPoint, fakePhNoExistResp);
        HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
        System.assertNotEquals(httpRequestCalloutMock, null);
        Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
        
        Boolean phExist = Callout.doesPhoneNoExist(phoneNumber);
        system.assert(phExist);
        Test.stopTest();
    }
    
    static testMethod void Test_CanDeletePhoneNo_Positive() {
        HttpResponse response;
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + phoneNumber;
        System.assertNotEquals(endPoint, null);
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(404, 'OK', null, null);
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put(endPoint, fakePhNoExistResp);
        HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
        System.assertNotEquals(httpRequestCalloutMock, null);
        Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
        
        Boolean canDelete = Callout.canDeletePhoneNo(phoneNumber);
        system.assert(canDelete);
        Test.stopTest();
    }
    
    static testMethod void Test_CanDeletePhoneNo_200Response() {
        HttpResponse response;
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + phoneNumber;
        System.assertNotEquals(endPoint, null);
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(200, 'OK', null, null);
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put(endPoint, fakePhNoExistResp);
        HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
        System.assertNotEquals(httpRequestCalloutMock, null);
        Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
        
        Boolean canDelete = Callout.canDeletePhoneNo(phoneNumber);
        system.assertEquals(canDelete, false);
        System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
        System.AssertEquals(ApexPages.getMessages()[0].getSummary(), system.label.CannotDeleteSupportNoMsg);
        Test.stopTest();
    }
    
    static testMethod void Test_CanDeletePhoneNo_Negative() {
        HttpResponse response;
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + phoneNumber;
        System.assertNotEquals(endPoint, null);
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(401, 'OK', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put(endPoint, fakePhNoExistResp);
        HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
        
        Boolean canDelete = Callout.canDeletePhoneNo(phoneNumber);
        system.assertEquals(canDelete, false);
        System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
        Test.stopTest();
    }
    
    static testMethod void Test_SendSMSViaTrigger() {
        HttpResponse response;
        initTestData();
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        System.assertNotEquals(phoneNumber, null);
        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_SEND_SMS, 
                                        new String[]{(String)ltnObject.get('Number__c')});
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(500, 'OK', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put(endPoint, fakePhNoExistResp);
        HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
        System.assertNotEquals(httpRequestCalloutMock, null);
        Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
        Callout.sendSMSViaTrigger(new List<Id>{smsTextObject.Id});
        Test.stopTest();
        List<Exception__c> ex = [Select Id From Exception__c Where ObjectId__c=:smsTextObject.Id];
        System.assert(!ex.isEmpty());
    }
    
    static testMethod void Test_ValidateAccCredentials_Positive() {
        HttpResponse response;
        //Prudhvi: Did not use the initTestData as the conversations are not required for the account validation.
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        
        Test.startTest();
        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_LOOKUP_ACCOUNT, 
                                        new String[]{(String)ltnObject.get('Number__c')});
        HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(401, 'Unauthorized', null, null);
        System.assertNotEquals(fakePhNoExistResp, null);
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put(endPoint, fakePhNoExistResp);
        HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
        System.assertNotEquals(httpRequestCalloutMock, null);
        Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
        Boolean isValid = Callout.validateAccCredentials(confSettings, (String)ltnObject.get('Number__c'));
        system.assertEquals(isValid, false);
        system.assertEquals(false, isValid);
        Test.stopTest();
    }
}