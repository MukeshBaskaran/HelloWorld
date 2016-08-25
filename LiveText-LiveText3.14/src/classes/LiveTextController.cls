/**
 * @author         Santosh Gudge(santosh@comitydesigns.com)
 * @data           08.08.2014
 * @description    LiveTextController class contains methods used by the LiveText Chat Panel
 *                 in LiveText for Salesforce application.
 */
global with sharing class LiveTextController { 
	
	public Boolean isconversationEnded{get;set;}
    public SObject conversationHeader {get;set;}
	public String convHeaderStatus{get;set;}
    public String conversationRecordId {get;set;}
    public String originatingNumber {get;set;}
 	public List <Conversation_Header__c> ConversationHeaderList {get;set;}
 	public String  originatingObjectId{get;set;}
 	public String originatingObjectPrefix{get;set;}
      
    public String source {
        get {
            return constant.source_field;
        }
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
           return JSON.serialize(ConversationHeaderList);
        }
        set;
    }          

   /**
    * @description: Controller constructor method, used to intialize the collections, 
    *               variables and load the static data(like object prefixes) for the LiveText page.
    */ 
    public LiveTextController(ApexPages.StandardController stdController) {
        this.conversationHeader = stdController.getRecord();      
    }

	

    /**
     * @description: init method called when page loads to get initial message for auto response.
     */
    public void init() {
    	this.conversationRecordId = ApexPages.currentPage().getParameters().get('cvid');
    	this.originatingNumber = Apexpages.CurrentPage().getParameters().get('phone');
    	this.originatingObjectId = Apexpages.CurrentPage().getParameters().get('oid'); 
    	this.originatingObjectPrefix = Apexpages.CurrentPage().getParameters().get('objectprefix');
    	
    	   //check if there is any incoming conversation for this number
        if(originatingNumber != null && (conversationRecordId == 'null' || String.isBlank(conversationRecordId) || conversationRecordId == null)){
            String phoneNumber = originatingNumber.replaceAll('\\D', '');
            phoneNumber = (phoneNumber.startsWith('1')) ? 
                '+' + phoneNumber :
                '+1' + phoneNumber;
            List<Conversation_Header__c> conversations = [SELECT id FROM Conversation_Header__c WHERE Status__c = 'New' AND Originating_Number__c = :phoneNumber];
            if(!conversations.isEmpty()){
                this.conversationRecordId = conversations[0].id;
            }  
        }    	 
       
        // add check that conversationRecordId is of type Id
        ConversationHeaderList = [SELECT Id, Status__c, Support_Number__r.Number__c, Formatted_Originating_Number__c, 
        							Originating_Number__c, Lead__r.Name, Lead__c, Contact__r.Name, Contact__c, 
        							Case__r.CaseNumber, Case__c, Opportunity__r.Name, Opportunity__c 
        							FROM Conversation_Header__c 
        							WHERE Id=:conversationRecordId];
    
    	
        if(!ConversationHeaderList.isEmpty()){
	        convHeaderStatus = ConversationHeaderList.get(0).Status__c;
	        if (convHeaderStatus == constant.stage_ended) {
	        	isconversationEnded = true;
	        }
        }
        
  	
    }
                   
    public List<Conversation_Header__c> getCurrentConversationHeaderList() {
    	List<Conversation_Header__c> conversationHeaderList = [Select Id, Case__c, Support_Number__c,
    					Originating_Number__c,  ConversationType__c, Lead__c, Contact__c, Opportunity__c from Conversation_Header__c where id=: conversationRecordId limit 1];
    	return conversationHeaderList;
           			
    }  
    
    //@deprecated
    @RemoteAction
    global static String getMessagePayloadResponse(String message, Integer messageId, String conversationId, String originatingNumber, String supportNumber) {
    	return '';
    }
    
    @RemoteAction
    global static SMS_Text__c getSMSTextRecord(String smsTextRecord) {
    	return null;
    }
    
    @RemoteAction
    global static SMS_Text__c createSMSTextRecord(String message, String conversationId) {
        return null;
    }
    
	@RemoteAction
	global static String sendSMS2(SObject smsObject, String smsText){
		return null;
	}
    
}