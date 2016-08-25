global with sharing class LiveTextChatController {
	
	public Boolean isconversationEnded{get;set;}
  public Boolean isRecordLinked {get;set;}
  public SObject conversationHeader {get;set;}
	public String convHeaderStatus{get;set;}
	public String contactPrefix {get;set;}
	public String accountPrefix {get;set;}
  public String conversationRecordId {get;set;}
  public String objectPrefix {get;set;}
  public String linkedObjId {get;set;} //This variable refers to the Id to which the Text Session Header is linked
  public String messageToSend {get;set;}
  public String originatingNumber {get;set;}
  public String unNormalizedOriginatingNumber {get;set;}    
 	public String objectName{get;set;}
	public Constant.ConversationType conversationType {get;set;}
	public String convoTypeParam{get;set;}
	public String oid{get;set;}
	public String phoneType{get;set;}
  public List<SMS_Text__c> initialMessageList {get;set;}
	public List<Conversation_Header__c> ConversationHeaderList {get;set;}
	public String activeSupportNumber {get;set{this.activeSupportNumber = value;}}
	public Boolean numbersDisabled {get;set;}
	public List<Id> phoneIds;
	public Map<String, List<String>> phoneNumbersMap;
	public String ITRName {get{return Constant.ITR;}}
	public String OptInName {get{return Constant.permission_marketing;}}
	public Boolean isConversationInQueue {get; set;}

  
  public String activeSupportPhoneNumber {get;set;}

  @RemoteAction 
    public static List<SMS_Text__c> insertSMSTextRecordStatic(String conversationHeaderId) {
        if(String.isNotBlank(conversationHeaderId)){
            Boolean isSent = false;
            Conversation_Header__c conv = [SELECT ConversationType__c FROM Conversation_Header__c WHERE Id =:conversationHeaderId LIMIT 1];
            if(conv.ConversationType__c == 'Outbound'){
              return getInitialMessage(conversationHeaderId);
            }
            List<SMS_Text__c> smsTextList = Util.getSMSTextList(conversationHeaderId);
            for(SMS_Text__c item : smsTextList){
               if(item.Unique_SMS__c == conversationHeaderId + constant.salesforce_welcome){
                  return getInitialMessage(conversationHeaderId);
               }
            }
            if(!smsTextList.isEmpty() && String.isNotBlank(smsTextList[0].Initial_Message__c)){
                OptInStatus__c optInStatus = Util.getOptInStatus(smsTextList[0].Support_Number__c,smsTextList[0].Originating_Number__c);
                if(optInStatus == null||optInStatus.Status__c==1){
                  isSent = Callout.sendSMS(smsTextList[0], smsTextList[0].Initial_Message__c);
                }
             }
            
            if(isSent){
                 SMS_Text__c smsTextRecord = new SMS_Text__c( Conversation_Header__c = conversationHeaderId
                    ,Support_Number__c = smsTextList[0].Support_Number__c
                    ,Originating_Number__c = smsTextList[0].Originating_Number__c 
                    ,Message__c = smsTextList[0].Initial_Message__c 
                    ,Source__c = constant.salesforce_welcome
                    ,Sent_To_Customer__c = true
                    ,Unique_SMS__c = conversationHeaderId + constant.salesforce_welcome
                );
                List<SMS_Text__c> resultList = new List<SMS_Text__c> {smsTextRecord};
                AccessController.insertAsUser(resultList);
            }
            
            if(!smsTextList.isEmpty()){
              return getInitialMessage(conversationHeaderId);
            }
        }
        return null;
    }
	
  public List<CustomObjectManualLinkingWrapper> customObjectsForManualLinking {
      get{
        return populateCustomObjectsForManualLinking();
      }
      set;
    }
		
	public List<SelectOption> getNumbers() {
		List<SelectOption> options = new List<SelectOption>();
		phoneIds = new List<Id>();
		String uid = UserInfo.getUserId(); 
		List<Id> ids = new List<Id>();
		List<Associated_Agents__c> agents = [SELECT LiveText_Number__c FROM Associated_Agents__c WHERE User__c=:uid]; 		
		for(Associated_Agents__c a : agents){
			ids.add(a.LiveText_Number__c);
		}
		phoneNumbersMap = new Map<String, List<String>>();
		List<LiveText_Number__c> phoneNumbers = [SELECT Id, Name, Formatted_Support_Number__c, Critical_Alert_Time__c FROM LiveText_Number__c WHERE Id IN :ids];
		for(LiveText_Number__c n : phoneNumbers){
			options.add(new SelectOption(n.Id, n.Name));
			phoneIds.add(n.Id);	
			phoneNumbersMap.put(n.Id, new List<String>{n.Formatted_Support_Number__c, n.Critical_Alert_Time__c == null ? 'null' : String.valueOf(n.Critical_Alert_Time__c)});		
		}
    return options;
  }
             
  public String initialMessage {
    get {
        return JSON.serialize(initialMessageList);
    }
    set;
  }
  
  public String source {
    get {
        return constant.source_field;
    }
    set;
  }

  public String liveText {
    get {
        return constant.live_text;
    }
    set;
  }

  public String nameSpace {
    get {
        return util.getNamespace();
    }
    set;
  }
  
  public String userName {
    get {
        return string.valueOf(UserInfo.getName());
    }
    set;
  }

  public String ConversationHeaderRecords {
    get {
        getCurrentConversationHeaderList();
        return JSON.serialize(ConversationHeaderList);
    }
    set;
  }        

  public String MyPhoneNumbers {
    get {
       return JSON.serialize(phoneNumbersMap);
    }
    set;
  }

  /*string returns keyPrefixURL*/
  public String casePrefixURL {
    get {
        return Util.getCasePrefixURL();
    }
  }
  
  public String opportunityPrefixURL{
    get{
      return Util.getOpportunityPrefixURL();
    }
  }

 /**
  * @description: Controller constructor method, used to intialize the collections, 
  *               variables and load the static data(like object prefixes) for the LiveText page.
  */ 
  public LiveTextChatController(ApexPages.StandardController stdController) {
    this.conversationHeader = stdController.getRecord();
    Schema.DescribeSObjectResult objAccountPrefix = account.SObjectType.getDescribe();
    this.accountPrefix = objAccountPrefix.getKeyPrefix();
    Schema.DescribeSObjectResult objContactPrefix = contact.SObjectType.getDescribe();
    this.contactPrefix = objContactPrefix.getKeyPrefix();
  }

  /**
   * @description: Action method for End Text Session button on the page. Performs below operation for end chat,
   *         1. Retrieves the initial message for the conversation header.
   *         2. Makes API callout to send the initial message to customer.
   *         3. Inserts the initial message to the database.
   *         4. Creates the transcript and set it to Text session header.
   *         5. Delete all the SMSes associated to Text session.
   *         6. Updates the status of Text session header to Ended.
   * @returns PageReference object.
   */ 
  public PageReference endChat() {
    System.debug(LoggingLevel.Info,'========endChatLiveTextChatController======'+conversationRecordId);
    Util.endChat(conversationRecordId);
    convHeaderStatus = constant.stage_ended;
    return null;
  }
  
   /**
   * @description: pagereference for setting the conversation id on an outbound message.
   * @param
   * @return  null
   */
  public PageReference SetConversationRecordIdAndLinkObject() {
    //this is already done in insertconversationheader since the links need to be returned in the result
    //associateRecords(oid, conversationRecordId);
    return null;
  }
    
  public PageReference getCurrentConversationHeaderList(){    
    ConversationHeaderList = Util.getCurrentConversationHeaderList(conversationRecordId);   
    return null;
  }
   /**
   * @description: pagereference for setting the conversation id on an outbound message.
   * @param
   * @return  null
   * @TODO rewrite to use 1 soql instead of 5 -_- -V-
   */
  public PageReference InitializeConversation() {
    try{
      this.isConversationInQueue = false;
      //originatingNumber needs to be E164
      String phoneNumber = originatingNumber;
      if(conversationRecordId == 'null' || String.isBlank(conversationRecordId)){
        List<Conversation_Header__c> conversations = [SELECT Id, Status__c, Support_Number__r.Number__c, Formatted_Originating_Number__c, 
                                                      Originating_Number__c, Lead__r.Name, Lead__c, Contact__r.Name, Contact__c, 
                                                      Case__r.CaseNumber, Case__c, Opportunity__r.Name, Opportunity__c, ConversationType__c 
                                                      FROM Conversation_Header__c 
                                                      WHERE Status__c = 'New' AND Originating_Number__c LIKE :phoneNumber LIMIT 1];
        if(!conversations.isEmpty()){
            this.conversationHeader = conversations[0];
            this.isConversationInQueue = true;
            this.conversationRecordId = conversationHeader.Id;
            List<Conversation_Header__c> chUpdateList = new List<Conversation_Header__c>();
            Conversation_Header__c chUpdate = (Conversation_Header__c) conversations[0];
            chUpdate.Status__c = constant.stage_active;
            chUpdateList.add(chUpdate);
            AccessController.updateAsUser(chUpdateList);
        }
      }             
      this.conversationType = convoTypeParam.equals('outbound') ? Constant.ConversationType.Outbound : Constant.ConversationType.Inbound;
      this.unNormalizedOriginatingNumber = this.originatingNumber;
      this.getNumbers();

      if(isOutboundConversation()){
        this.numbersDisabled = false;
        getObjectName();
        List<Conversation_Header__c> outboundChl = [SELECT Id FROM Conversation_Header__c 
                                                    WHERE AcceptedBy__c = :UserInfo.getUserId() 
                                                    AND ConversationType__c = 'Outbound'
                                                    AND Status__c =:Constant.stage_active
                                                    AND Originating_Number__c LIKE :phoneNumber
                                                    ORDER BY LastModifiedDate DESC LIMIT 1];
        conversationRecordId = outboundChl.isEmpty() ? conversationRecordId : outboundChl[0].Id;
        //set the default support number to the last number the customer used to contact the company
        //as long as the agent is assigned to that number 
        Map<String, String> relationshipMapForConversationHeader = Util.getRelationshipMapForConversationHeader();
        String query = 'SELECT Originating_Number__c, LastModifiedDate, Support_Number__r.Id ';
        query += 'FROM Conversation_Header__c ';
        query += 'WHERE Support_Number__r.Id IN :phoneIds ';
        query += 'AND (';
        for(String value : relationshipMapForConversationHeader.values()){
          query += value + '=:oid OR ';
        }
        query += 'Originating_Number__c= \''+ this.originatingNumber +'\') ORDER BY LastModifiedDate DESC LIMIT 1';
        System.debug('POINT QUERY: ' + query);
        List<Conversation_Header__c> chl = Database.query(query);                                            

        if(chl.size() > 0){
          this.activeSupportNumber = chl.get(0).Support_Number__r.Id; 
        }else {
          //set the default support number to the last number the agent used
          List<Conversation_Header__c> chl2 = [SELECT LastModifiedDate, Support_Number__r.Id 
                                               FROM Conversation_Header__c
                                               WHERE Support_Number__r.Id IN :phoneIds
                                               ORDER BY LastModifiedDate DESC LIMIT 1];
          if(chl2.size() > 0){
            this.activeSupportNumber = chl2.get(0).Support_Number__r.Id;
          }
        }
      }else {
        this.numbersDisabled = true;          
        Conversation_Header__c ch = [SELECT Originating_Number__c, Support_Number__r.Number__c FROM Conversation_Header__c 
                                    WHERE Id=:this.conversationRecordId];
        //this should already be converted to E164    
        this.originatingNumber = ch.Originating_Number__c; 
        this.unNormalizedOriginatingNumber = this.originatingNumber;
        this.activeSupportNumber = ch.Support_Number__r.Id;        
      }
      if(!hasConversationId() && isOutboundConversation()){
        String cvid =  getActiveConversationRecordId();
        if(!String.isBlank(cvid)){
           this.conversationRecordId = cvid;
        }
      }
      // add check that conversationRecordId is of type Id
      if(hasConversationId()){
        this.numbersDisabled = true;
        ConversationHeaderList = Util.getCurrentConversationHeaderList(this.conversationRecordId);     
        if(!ConversationHeaderList.isEmpty()){
          convHeaderStatus = ConversationHeaderList.get(0).Status__c;             
          if(convHeaderStatus == constant.stage_ended){
            isconversationEnded = true;
          }
          
        }
        for(Conversation_Header__c ch :ConversationHeaderList){
            if((ch.ConversationReopened__c == true && ch.Status__c == Constant.stage_active) || (ch.ConversationReopened__c == false)){
              this.initialMessageList = getInitialMessage(this.conversationRecordId);
            }
          } 

      }
    }catch (Exception ex){
      Util.addMessageOnError(ex.getMessage());
      Util.insertException(constant.conversation_header_obj, constant.priority_high, ex.getMessage() + ex.getLineNumber());
      System.debug('ERROR: ' + ex.getMessage() + ', line number: ' + ex.getLineNumber());
    }
    return null;
  }

  /**
  * @description: pagereference for reloading a conversation when connectivity is dropped then restored.
  * @param
  * @return  null
  */
  public PageReference ReloadConversation() {
    try{                     
      if(hasConversationId()){
        this.initialMessageList = getInitialMessage(this.conversationRecordId);
      }
    }catch (Exception ex){
      Util.addMessageOnError(ex.getMessage());
      Util.insertException(constant.conversation_header_obj, constant.priority_high, ex.getMessage());
    }
    return null;
  }
    
  /**
   * @description: whether or not the conversion is outbound
   */
  private Boolean isOutboundConversation(){
    return conversationType == Constant.ConversationType.Outbound;
  }
    
  /**
   * @description: determines if there's an outbound conversation with the given number
   */
  @TestVisible
  private String getActiveConversationRecordId(){   
    String uid = UserInfo.getUserId(); 
    List<SMS_Text__c> smsTextList = [Select Id, Message__c, Support_Number__c, Originating_Number__c, Source__c, Formatted_Originating_Number__c, Conversation_Header__c 
                                    FROM SMS_Text__c 
                                    WHERE Support_Number__c=:this.activeSupportNumber
                                    AND Originating_Number__c =:this.originatingNumber 
                                    AND OwnerId=:uid 
                                    ORDER BY CreatedDate DESC  limit 1];
    if(!smsTextList.isEmpty()){
      SMS_Text__c smsText = smsTextList[0];  
      List<Conversation_Header__c> chList = [Select Id, Case__c, Support_Number__c, Originating_Number__c,  ConversationType__c, Lead__c, Contact__c,  Opportunity__c, Account__c 
                                            FROM Conversation_Header__c 
                                            WHERE id=:smsText.Conversation_Header__c 
                                            AND Status__c=:'Active' limit 1];
      if(!chList.isEmpty()){
        Conversation_Header__c ch = chList[0];  
        return ch.Id;
      }
    }
    return null;  
  }
     
  private Boolean hasConversationId(){
    return !String.isBlank(conversationRecordId);
  }

  /**
   * @description: init method called when page loads to get initial message for auto response.
   */
  public void init() {    
  }
    
  /**
   * @description: Action method called when user associates/disassociates either case, contact or lead to a chat. Creates 
   *         a linked/unlinked SMS record, which is displayed in the previous transcript section.
   * @return  PageReference object.
   */
  public PageReference associateSelectedRecords(){
      Util.associateSelectedRecordWithTranscript(conversationRecordId,objectPrefix,linkedObjId,isRecordLinked, false); //not auto
    return null;
  }

  public List<String> getCustomObjectKeyPrefixesForEditPages(){
    List<String> retList = new List<String>();
    for (String keyPrefix : Util.getLinkedObjectsKeyPrefixToApiNameMap().keySet()){
      retList.add(new PageReference('/' + keyPrefix + '/e').getUrl());
    }
    return retList;
  }
    
  @RemoteAction
  global static String getMessagePayloadResponse(String message, Integer messageId, String conversationId, String originatingNumber, String supportNumber, Boolean isFirstOutboundMessage) {
    return null;
  }
    
  @RemoteAction
  public static String getOptinStatusMessage(Id liveTextNumberId, String phoneNumber, String supportNumberName, String objectName) {
    OptInStatus__c optInStatus =  Util.getOptInStatus(liveTextNumberId, phoneNumber);
    if(optInStatus == null||optInStatus.Status__c==1){
      return null;
    }
    String supportNumberLabels = supportNumberName;
    List<LiveText_Number__c> myPhoneNumbers = Util.GetMyPhoneNumbers(); 
    for (LiveText_Number__c supportNumber : myPhoneNumbers) {
      if(supportNumber.Id != liveTextNumberId){
        optInStatus =  Util.getOptInStatus(supportNumber.Id, phoneNumber);
        if(optInStatus != null && optInStatus.Status__c != 1){
          supportNumberLabels += ', ' + supportNumber.Name;
        }
      }
    } 
    return String.format(system.label.OptOutStatusMsg, new String[]{objectName, supportNumberLabels});
  }
  /**
   * @description: Remote action method called when user sends a message to customer while chat. 
   *         Method makes API callout to send the message to customer, if the message fails to deliver
   *         then shows the error image for undelivered message in chat panel.
   * @param message, will be send to customer using API callout.
   * @param messageId, used to display error image to user in case message is not delivered.
   * @param conversationId, conversation header Id for the chat session.
   * @param originatingNumber, customer's contact number.
   * @param supportNumber, to which message is sent.
   * @return  JSON string containing the api callout response.
   */
   @RemoteAction
  public static String getMessagePayloadResponseWithPicture(MessagePayload messagePayload) {
    JSONGenerator resultJson = JSON.creategenerator(true);
    resultJson.writeStartObject(); 
    if(messagePayload == null) 
      return '';  
    resultJson.writeNumberField('messageId', messagePayload.messageId);
    try {
      // 1.make heywire callout
      HttpResponse res = (messagePayload.isPictureRequest) ? 
            Callout.sendPictureRequest(messagePayload.originatingNumber,messagePayload.supportNumber) :
            Callout.sendSMSInternal(messagePayload.originatingNumber,messagePayload.supportNumber,messagePayload.rawMessage);
      Boolean isSuccess = (messagePayload.isPictureRequest && res.getStatusCode() == 200) ||  (!messagePayload.isPictureRequest && res.getStatusCode() == 204); 
      if(!isSuccess){
        resultJson.writeStringField('errorMessage', system.label.SMSNotDeliveredLbl);
        resultJson.writeBooleanField('success', false);
        if(messagePayload.isFirstOutboundMessage)
          insertSMSTextRecord(messagePayload.message.length()>480?messagePayload.message.substring(0, 480):messagePayload.message, messagePayload.conversationId, false);
        else
          Util.insertSMSTextRecord2(messagePayload.message.length()>480?messagePayload.message.substring(0, 480):messagePayload.message, messagePayload.conversationId, false);
      }else{
        if(messagePayload.isPictureRequest){
          messagePayload.message = res.getBody().replace('"','');
          resultJson.writeStringField('message', messagePayload.message);
        }
        // 2.save record.
        if(messagePayload.isFirstOutboundMessage)
          insertSMSTextRecord(messagePayload.message.length()>480?messagePayload.message.substring(0, 480):messagePayload.message, messagePayload.conversationId, true);
        else
          Util.insertSMSTextRecord2(messagePayload.message.length()>480?messagePayload.message.substring(0, 480):messagePayload.message, messagePayload.conversationId, true);
          resultJson.writeBooleanField('success', true);
      }
      resultJson.writeEndObject();
    }catch (Exception ex) {
      resultJson.writeStringField('errorMessage', ex.getMessage());
      resultJson.writeBooleanField('success', false);
    }
    system.debug('resultJson.getAsString()::'+resultJson.getAsString()); 
    return resultJson.getAsString();
  } 
    
  /**
  * @description:  Determines if an outbound conversation between the 2 phone numbers is allowed. 
  *          1) The same outbound and inbound number cannot be used be used if an active or new text session already exists with the same 2 numbers.
  *          2) The system will display an error message when the send button is clicked if an active or new text session already exists with the same 2 numbers.
  * @param supportNumberId, Support phone number Id.
  * @param phoneNumber, customer's contact number.
  * @return  true/false.
  */
  public static Boolean isOutboundConversationAllowed(String supportNumberId,  String phoneNumber){
    String normalizedPhoneNumber = Util.NormalizePhoneNumber(phoneNumber);                   
    List<Conversation_Header__c> chList = [SELECT Id FROM Conversation_Header__c 
                                          WHERE Originating_Number__c=:normalizedPhoneNumber 
                                          AND Support_Number__c=:supportNumberId
                                          AND Status__c = :Constant.stage_active LIMIT 1];
    if (!chList.isEmpty()) {  
      return false;
    }
    return true;
  }
    
  /**
  * @description:  Returns queued conversation, if any, between the two given numbers
  * @param supportNumberId, Support phone number Id.
  * @param phoneNumber, customer's contact number.
  * @return  true/false.
  */
  public static Conversation_Header__c getQueuedConversation(String supportNumberId,  String phoneNumber){
    String normalizedPhoneNumber = Util.NormalizePhoneNumber(phoneNumber);                       
    List<Conversation_Header__c> chList = [SELECT Id, Status__c, Support_Number__r.Number__c, Formatted_Originating_Number__c, 
                                                  Originating_Number__c, Lead__r.Name, Lead__c, Contact__r.Name, ConversationType__c, 
                                                  Case__r.CaseNumber, Case__c, Opportunity__r.Name, Opportunity__c,
                                                  Account__r.Name,Account__c, Contact__c 
                                          FROM Conversation_Header__c 
                                          WHERE Originating_Number__c=:normalizedPhoneNumber 
                                          AND Support_Number__c=:supportNumberId
                                          AND Status__c = :Constant.stage_new];
    return !chList.isEmpty() ? chList.get(0) : null;
  }
    
  /**
  * @description:  Remote action method called when user sends first outbound message to determine if the 
  *          current user can message the given phone number.
  *          1) The destination phone number must be a valid phone number
  *          2) Business rules for LT-630 
  * @param supportNumberId, Support phone number Id.
  * @param phoneNumber, customer's contact number.
  * @return  JSON string containing the api callout response.
  */
  @RemoteAction
  global static String validatePhoneNumbers(String supportNumberId, String phoneNumber) {
    phoneNumber = phoneNumber.trim();
    JSONGenerator resultJson = JSON.creategenerator(true);
    resultJson.writeStartObject(); 
    String errorMessage = Util.validateRecipientPhoneNumber(phoneNumber);
    if(errorMessage == null && !isOutboundConversationAllowed(supportNumberId, phoneNumber)){
      errorMessage = System.Label.DuplicateTextSessionMsg;
    }
    if(errorMessage != null){
      resultJson.writeStringField('errorMessage', errorMessage);
      resultJson.writeBooleanField('success', false);
    }else{
      resultJson.writeBooleanField('success', true);
    }
    resultJson.writeEndObject();
    return resultJson.getAsString();
  } 

  /*
  *  this is no longer used. remote method changed to take a class/object with properties as a parameter 
  *
  */
  @RemoteAction
  global static List<Conversation_Header__c> insertConversationHeader(String supportNumber, String originatingNumber, String conversationType, String message) {       
    return null;   
  }
    
  /**
  * @description: Remote action method called when user sends first outbound message to customer to update the phone numbers 
  *         being used in the conversation header
  * @param supportNumber
  * @param originatingNumber
  */
  @RemoteAction
  global static List<Conversation_Header__c> insertConversationHeaderLinkObject(ConversationInitialization ci) {       
    List<Conversation_Header__c> chl =  new List<Conversation_Header__c>();
    try {
      if(isOutboundConversationAllowed(ci.supportNumber, ci.originatingNumber)){        
        //insert new conversation header with phone numbers for outbound when send is pressed for the first time (message count=1)
        Conversation_Header__c ch = getQueuedConversation(ci.supportNumber, ci.originatingNumber);
        if(ch != null){
          ch.Status__c = constant.stage_active;
          ch.Formatted_Originating_Number_To_Display__c = ci.originatingFormattedNumber;
          AccessController.updateAsUser(new List<sObject>{ch});
        }else{ 
          ch = new Conversation_Header__c();
          ch.Status__c = constant.stage_active;
          ch.Support_Number__c = ci.supportNumber;
          ch.Originating_Number__c = Util.NormalizePhoneNumber(ci.originatingNumber);
          ch.Formatted_Originating_Number_To_Display__c = ci.originatingFormattedNumber;
          ch.ConversationType__c = ci.conversationType;
          ch.isAccepted__c = true;
          ch.AcceptedBy__c = UserInfo.getUserId();
          AccessController.insertAsUser(ch);
          //LiveTextChatController.associateRecords(ci.objectId,string.valueof(ch.Id));
          Util.associateSelectedRecordWithTranscript(String.valueOf(ch.Id), String.valueof(ci.objectId).left(3), ci.objectId, true, false);
        }
        chl = Util.getCurrentConversationHeaderList(ch.id);
      }
    }catch(Exception ex){
      Util.insertException('Error occured starting outbound', constant.priority_high, ex.getMessage());       
    } 
    return chl;
  } 
  
  @RemoteAction
  public static void removeAttachment(String conversationHeaderId, String imgName)
  {

      Attachment attachment = new Attachment();
      for(Attachment item:[Select Id
                          From Attachment 
                          Where ParentId =:conversationHeaderId 
                          AND Name =:imgName 
                          ORDER BY LastModifiedDate 
                          ASC NULLS LAST 
                          Limit 1])
      {
          attachment = item;
      }
      if(attachment.id != null)
      {
        delete attachment;
      }
  }

  @RemoteAction
  public static Integer sendMMSAsAttachment(String conversationHeaderId, String originatingNumber,  String supportNumber, String attachmentId, String imgName, String supportId, String imgType){
    try{
      if(attachmentId != null && conversationHeaderId != null){
        Integer statusCode =  Callout.sendMMSInternal(originatingNumber, supportNumber, attachmentId, imgName, imgType).getStatusCode();
        SMS_Text__c newSMSText = new SMS_Text__c();
        newSMSText.Conversation_Header__c = conversationHeaderId;
        newSMSText.Message__c = '>>> MMS Message Sent: '+imgName+' <<<';
        newSMSText.Originating_Number__c = originatingNumber;
        newSMSText.Support_Number__c = supportId;
        newSMSText.Source__c = 'Salesforce';
        newSMSText.Sent_To_Customer__c = statusCode == 204;
        insert newSMSText;
        return statusCode; 
      }
      return 500;
    }catch(Exception ex){
       Util.insertException('sendMMSAsAttachment', constant.priority_high, ex.getMessage());
       return 500;
    }
  }
     
  /**
  * @description: Remote action method called when a new message arrives in the chat to get the additional message for the SMS.
  * @param smsTextRecord, Id of the SMS record.
  * @return SMS_Text__c, found sms record.
  */
  @RemoteAction
  global static SMS_Text__c getSMSTextRecord(String smsTextRecord) {
    List<SMS_Text__c> smsTextList = [Select Id, Message__c, Support_Number__c, Originating_Number__c, Source__c, 
                                            Formatted_Originating_Number__c, Conversation_Header__c 
                                    FROM SMS_Text__c 
                                    WHERE Id =:smsTextRecord];
    return smsTextList[0];
  }
    
  //@deprecated
  @RemoteAction
  global static SMS_Text__c createSMSTextRecord(String message, String conversationId) {
      return null;
  }
    
  //@deprecated
  @RemoteAction
  global static String sendSMS2(SObject smsObject, String smsText){
    return null;
  }    

  global static void associateRecords(Id objectId, String chId){
    associateRecordsEx(objectId, chId, false);
  }
    
	public static void associateRecordsEx(Id objectId, String chId, Boolean isAuto){
		try{  
    		if(objectId != null){
          	String objectPrefix = objectId.getSObjectType().getDescribe().getKeyPrefix();
            Util.associateSelectedRecordWithTranscript(chId, objectPrefix, objectId, true, isAuto);
    		}
      }catch (Exception ex) {
          Util.insertException('Object Association Failed(3)', constant.priority_high, ex.getMessage());
      }
  }
    
  @RemoteAction
  public static List<SMS_Text__c> getInitialMessage (String conversationRecordId){
    List<SMS_Text__c> smsList = new List<SMS_Text__c>();
    List<LiveText_Number__c> livetextList = new List<LiveText_Number__c> ();
    List<Conversation_Header__c> temp = [SELECT id, EndedTime__c FROM Conversation_Header__c WHERE Id = :conversationRecordId];
    if(temp.isEmpty())
      return smsList;
    Datetime endedTime = temp[0].EndedTime__c;
    // have to do 2 soql because sms text with auto response is not retrived most of the time.
    List<SMS_Text__c> smsTextList = [SELECT SystemModstamp,Support_Number__r.Number__c,Originating_Number__c,
                                               Source__c,Message__c,Id,Formatted_Originating_Number__c,
                                               Sent_To_Customer__c,Conversation_Header__c,CreatedDate 
                                       FROM SMS_Text__c 
                                       WHERE Conversation_Header__c = :conversationRecordId 
                                       AND Source__c != :Constant.SALESFORCE_LINKING
                                       AND ((Conversation_Header__r.ConversationReopened__c = true AND CreatedDate > :endedTime) 
                                            OR Conversation_Header__r.ConversationReopened__c = false)
                                       ORDER BY CreatedDate ASC LIMIT 1000];
    return smsTextList;
  }
  
  //used in utils
  public static List<SMS_Text__c> getSMSTextRecordList(List<Id> conversationIdList) {
    if(conversationIdList == null) return null;
    List<SMS_Text__c> smsTextList = [SELECT Source__c,Message__c,Formatted_Originating_Number__c,Originating_Number__c,
                                               Support_Number__r.Number__c,Support_Number__c,End_Chat_Message__c,
                                               CreatedDate,CreatedBy.Name,CreatedById,Conversation_Header__c 
                                       FROM SMS_Text__c 
                                       WHERE Conversation_Header__c IN :conversationIdList 
                                       ORDER BY CreatedDate ASC];
     return smsTextList;
  }

  //used only in batch
  public static Map<Id, List<SMS_Text__c>> getSMSTextRecordMap(List<Id> conversationIdList) {
    if(conversationIdList == null) return null;
        Map<Id, List<SMS_Text__c> > smsTextMap = new Map<Id, List<SMS_Text__c> >();

        List<SMS_Text__c> smsList = [SELECT Source__c,Message__c,Formatted_Originating_Number__c,
                                            Originating_Number__c,Support_Number__r.Number__c,
                                            Support_Number__c,End_Chat_Message__c,CreatedDate,
                                            CreatedBy.Name,CreatedById,Conversation_Header__c
                                    FROM SMS_Text__c 
                                    WHERE Conversation_Header__c IN :conversationIdList
                                    ORDER BY CreatedDate ASC];
    for(SMS_Text__c s : smsList){
      if(smsTextMap.get(s.Conversation_Header__c) == null){
        List<SMS_Text__c> sm = new List<SMS_Text__c>();
        sm.add(s);
        smsTextMap.put(s.Conversation_Header__c,sm);
      }else{
        List<SMS_Text__c> sm = smsTextMap.get(s.Conversation_Header__c);
        sm.add(s);
        smsTextMap.put(s.Conversation_Header__c,sm);
      }
    }
    return smsTextMap;
  }
    
  public static  List<SMS_Text__c> insertEndChatTextRecord(String message, String chId, Boolean sentToCustomer) {
    List<SMS_Text__c> smsText;
    List<SMS_Text__c> smsTextList = [SELECT Source__c,Message__c,Originating_Number__c,Support_Number__r.Number__c,
                                            Support_Number__c,CreatedDate,Conversation_Header__c 
                                    FROM SMS_Text__c 
                                    WHERE Conversation_Header__c = :chId 
                                    LIMIT 1];
    if(!smsTextList.isEmpty()){
        SMS_Text__c smsTextRecord = new SMS_Text__c(Conversation_Header__c = chId,
            Support_Number__c = smsTextList[0].Support_Number__c,
            Originating_Number__c = smsTextList[0].Originating_Number__c,
            Message__c = message, 
            Source__c = Constant.salesforce,
            Sent_To_Customer__c = sentToCustomer);

        AccessController.insertAsUser(new List<SMS_Text__c> {smsTextRecord});
        // query after insert to get the value of Formatted_Originating_Number__c field,
        // which will be required while creating transcript.
        smsTextRecord = [SELECT Source__c,Message__c,Formatted_Originating_Number__c,Originating_Number__c,
                                Support_Number__r.Number__c,Support_Number__c,CreatedDate,Conversation_Header__c 
                        FROM SMS_Text__c 
                        WHERE Id = :smsTextRecord.Id 
                        LIMIT 1];
        smsText = new List<SMS_Text__c> {smsTextRecord};
    }
    return smsText;
  }
    
  public static  void insertSMSTextRecord(String message, String chId, Boolean sentToCustomer) {	
  	Conversation_Header__c ch = [SELECT Id, Status__c, Support_Number__r.Number__c, Formatted_Originating_Number__c, 
                                        Originating_Number__c, Lead__r.Name, Lead__c, Contact__r.Name, Contact__c, ConversationType__c, 
                                        Case__r.CaseNumber, Case__c, Opportunity__r.Name, Opportunity__c,
                                        Account__r.Name,Account__c
                                FROM Conversation_Header__c 
                                WHERE Id=:chId  limit 1];
    if(ch != null){   	
     SMS_Text__c smsTextRecord = new SMS_Text__c(Conversation_Header__c = chId,
       	Support_Number__c = ch.Support_Number__c,
        Originating_Number__c = ch.Originating_Number__c,
        Message__c = message, Source__c = constant.salesforce,
        Sent_To_Customer__c=sentToCustomer);
      AccessController.insertAsUser(new list < SMS_Text__c > {smsTextRecord});
    }
  }
    
  @TestVisible    
  private void getObjectName(){
    Id objectId = (Id) oid;
    String keyPrefix = objectId.getSobjectType().getDescribe().getKeyPrefix();
    String fieldName = keyPrefix == '500' 
                       ? 'CaseNumber' 
                       : keyPrefix == '800'
                       ? 'ContractNumber'
                       : keyPrefix == '801'
                       ? 'OrderNumber'
                       : 'Name';
    String query = 'SELECT ' + fieldName + ' FROM ' + objectId.getSObjectType().getDescribe().getName() + ' WHERE Id = \'' +oid+'\'';
    this.objectName = (String) Database.query(query)[0].get(fieldName);
  }

  @RemoteAction
    public static String getProperLocale(String objId, String ownerId){
        if(String.isBlank(objId))
            return UserInfo.getLocale();
        String ownerLocale = '';
        if(String.isBlank(ownerId)){
            Id objectId = (Id) objId;
            try{
                String query = 'SELECT OwnerId FROM ' + objectId.getSObjectType().getDescribe().getName() + ' WHERE Id = \'' +objId+'\'';
                List<SObject> obj = Database.query(query);
                String oid = (String) obj[0].get('OwnerId');
                ownerLocale = (String) [SELECT localesidkey FROM User WHERE Id = :oid][0].get('localesidkey');
            }catch (Exception ex){
                
            }
        }else{
            try{
               ownerLocale = (String) [SELECT localesidkey FROM User WHERE Id = :ownerId][0].get('localesidkey');
            }catch (Exception ex){
                //user do not have permission to get owner locale - do nothing.
            }
        }
        return String.isBlank(ownerLocale) ? UserInfo.getLocale() : ownerLocale;
    }

  /**
  * @description Function for custom object manual linking. It check for all linked custom objects, and for all custom object relationships in text session header object
  **/
  private List<CustomObjectManualLinkingWrapper> populateCustomObjectsForManualLinking(){
    //get all custom objects linked to junction obj and check if there are linked to conversation header
    Map<String, CustomObjectManualLinkingWrapper> customObjectRecordsMap = new Map <String, CustomObjectManualLinkingWrapper>(); //record apiName -> wrapper
    List<Schema.DescribeTabSetResult> tabSetPerApp = Schema.describeTabs();
	Set<Schema.DescribeTabResult> allTabs = new Set<Schema.DescribeTabResult>();
    Set<String> allRelationshipObjects = Util.getAllRelationshipObjects();

    for(Schema.DescribeTabSetResult tabSet : tabSetPerApp){
  		allTabs.addAll(tabSet.getTabs());
    }

    Map<String, String> apiNameToRelationshipName = Util.getRelationshipMapForConversationHeader(); // to change if we start support multi object linking
    Map<String, String> objectsKeyPrefixToColumnNameMap = Util.getLinkedObjectsKeyPrefixToColumnNameMap(true);
    if(conversationRecordId != null){
      for(Conversation_Header__c conv : Util.getCurrentConversationHeaderList(conversationRecordId)){
        for(String apiname : allRelationshipObjects){
          if(!String.isEmpty( (String) conv.get(apiNameToRelationshipName.get(apiname)))){
            CustomObjectManualLinkingWrapper wrapper = new CustomObjectManualLinkingWrapper();
            Schema.DescribeSObjectResult dsor = Schema.describeSObjects(new List<String>{apiName})[0];
            wrapper.recordType = apiname;
            wrapper.recordPrefix = dsor.getKeyPrefix();
            wrapper.recordId = (String) conv.getSObject(apiNameToRelationshipName.get(apiname).removeEnd('c') + 'r').get('Id');
            wrapper.recordNameField = '500'.equals(wrapper.recordPrefix) 
                                ? 'CaseNumber'
                                : '800'.equals(wrapper.recordPrefix)
                                ? 'ContractNumber'
                                : '801'.equals(wrapper.recordPrefix)
                                ? 'OrderNumber'
                                : 'Name';
            wrapper.recordName = (String) conv.getSObject(apiNameToRelationshipName.get(apiname).removeEnd('c') + 'r').get(wrapper.recordNameField);
            wrapper.recordLabel = dsor.getLabel();
            wrapper.recordLabelPlural = dsor.getLabelPlural();
            wrapper.relationshipName = objectsKeyPrefixToColumnNameMap.get(dsor.getKeyPrefix());
            wrapper.isLinked = true;
            wrapper.rendered = true;
           
            PageReference pRef = Page.CustomLookup;
            pRef.getParameters().put('oldVal', wrapper.recordName);
            pRef.getParameters().put('recType', apiName); 
            for(Schema.DescribeTabResult tab : allTabs){
              if(tab.getSobjectName().endsWith(apiname)){
                wrapper.iconUrl = tab.getIconUrl();
                wrapper.miniIconUrl = tab.getMiniIconUrl();
                break;
              }
            }
            customObjectRecordsMap.put(apiname, wrapper);
          }
        }
      }
    }
    for (String apiname : allRelationshipObjects){
      if(!customObjectRecordsMap.containsKey(apiname)){
        CustomObjectManualLinkingWrapper wrapper = new CustomObjectManualLinkingWrapper();
        Schema.DescribeSObjectResult dsor = Schema.describeSObjects(new List<String>{apiName})[0];
        wrapper.recordType = apiname;
        wrapper.recordPrefix = dsor.getKeyPrefix();
        wrapper.recordId = null;
        wrapper.recordName = '';
        wrapper.recordNameField = '500'.equals(wrapper.recordPrefix) 
                                ? 'CaseNumber'
                                : '800'.equals(wrapper.recordPrefix)
                                ? 'ContractNumber'
                                : '801'.equals(wrapper.recordPrefix)
                                ? 'OrderNumber'
                                : 'Name';
        wrapper.recordLabel = dsor.getLabel();
        wrapper.recordLabelPlural = dsor.getLabelPlural();
        wrapper.relationshipName = objectsKeyPrefixToColumnNameMap.get(dsor.getKeyPrefix());
        wrapper.isLinked = false;
        wrapper.rendered = true;
       
        PageReference pRef = new PageReference('/apex/CustomLookup');
        pRef.getParameters().put('oldVal', wrapper.recordName);
        pRef.getParameters().put('recType', apiName);
        wrapper.lookUpUrl =  pRef.getUrl();
         for(Schema.DescribeTabResult tab : allTabs){
          if(tab.getSobjectName().endsWith(apiname)){
            wrapper.iconUrl = tab.getIconUrl();
            wrapper.miniIconUrl = tab.getMiniIconUrl();
            break;
          }
        }
        customObjectRecordsMap.put(apiname, wrapper);
      }
    }
    return customObjectRecordsMap.values();
  }
    
  global class ConversationInitialization {
    public String supportNumber{get;set;}
    public String originatingNumber{get;set;}
    public String originatingFormattedNumber{get;set;}
    public String conversationType{get;set;}
    public String message{get;set;}
    public Id objectId{get;set;}        
  } 
  
  global class MessagePayload {
    public String message {get;set;}
    public String rawMessage {get;set;} 
    public Integer messageId {get;set;} 
    public String conversationId {get;set;} 
    public String originatingNumber {get;set;} 
    public String supportNumber {get;set;} 
    public Boolean isFirstOutboundMessage {get;set;} 
    public Boolean isPictureRequest {get;set;}
  }

  global class CustomObjectManualLinkingWrapper {
    public String recordType {get;set;}
    public String relationshipName {get;set;}
    public String recordLabel {get;set;}
    public String recordLabelPlural {get;set;}
    public String recordPrefix {get;set;}
    public String recordId {get;set;}
    public String recordName {get;set;}
    public String recordNameField {get;set;}
    public String lookUpUrl{get;set;}
    public String iconUrl {get;set;}
    public String miniIconUrl{get;set;}
    public Boolean isLinked {get;set;}
    public Boolean rendered {get;set;} 
  }
}