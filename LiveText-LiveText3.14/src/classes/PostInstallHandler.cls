/**
 * @author        Santosh Gudge (santosh@comitydesigns.com)
 * @company       ComityDesigns
 * @date          07/18/2014
 * @description   PostInstall script, runs when package is being installed.
 */
global class PostInstallHandler implements InstallHandler {
    
    global void onInstall(InstallContext context) {
        String result = 'start';
        system.debug('context'+context);
        try{  
            if (context.previousVersion() == null) {
                createConfigurationSettings();
                createGlobalSettings();
                List<PushTopic> pushTopicList = new List<PushTopic>();
                pushTopicList.add(createConversationHeaderPushTopic());
                pushTopicList.add(createSMSTextPushTopic());
                insert pushTopicList; // DO NOT INCLUDE ACCESS CONTROLLER HERE AS IT WILL FAIL.
            } 
            if(context.previousVersion() != null && context.previousVersion().compareTo(new Version(3,5)) < 0){
                setPhoneNumbersActivities();
            }
            
            if(context.previousVersion() != null && context.previousVersion().compareTo(new Version(3,8)) < 0){
                migrateNewTabSettings();
            }
            
            normalizeLiveTextNumbers();
            setPhoneNumbersISOCountryCode();
            setInternationalPhoneNumbers();
            createSemaphores();

        }catch(Exception ex) {
            Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
            list<String> listEmailMembers = new list<String>();
            //remove below code after testing
            listEmailMembers.add(Label.TXT_AdminEmail);
            emailTobeSent.setToAddresses(listEmailMembers);
            emailTobeSent.setSubject('Post install exception');
            emailTobeSent.setHtmlBody('Message : ' + ex.getMessage() + 'Line no : ' + ex.getLineNumber() + ' getStackTraceString ' + ex.getStackTraceString() + '' + ex.getCause());
            Messaging.SendEmailResult [] r1 = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailTobeSent});
        }
    }

    private void createConfigurationSettings(){    
        ConfigurationSettings__c confSettings = new ConfigurationSettings__c(
            Name = Constant.HEYWIRE_CONFIG,
            EndPoint_URL__c = Constant.HEYWIRE_PRODUCTION_URL,
            oAuth_URL__c = Constant.HEYWIRE_PRODUCTION_OAUTH_URL);
        insert confSettings;
    }
    
    private void createGlobalSettings(){
        LiveTextGlobalSettings__c ltgs = LiveTextGlobalSettings__c.getInstance(UserInfo.getOrganizationId());
        if (ltgs.SetupOwnerId == null) {
            insert new LiveTextGlobalSettings__c(GlobalTriggerExecutionEnabled__c = true,
                Active_Status_Purge_Hours__c = 48,
                New_Status_Purge_Hours__c = 1,
                Offline_Status_Purge_Hours__c =1,
                SetupOwnerId = UserInfo.getOrganizationId());
        }
    }
    
    private void createSemaphores(){
        Semaphore.Create(constant.SEMAPHORE_SMS_TEXT_TRIGGER_HANDLER);
        Semaphore.Create(constant.SEMAPHORE_INBOUND_PHONE_FORMAT);
    }
    
    private void migrateNewTabSettings(){
    	
    	List<LiveText_Number__c> ltnObjects = Database.query('SELECT Id, Show_New_Account_Tab__c, Show_New_Contact_Tab__c, Show_New_Lead_Tab__c, Show_New_Case_Tab__c,Show_New_Opportunity_Tab__c, New_Custom_Objects_Tabs__c FROM LiveText_Number__c Where Show_New_Account_Tab__c=true OR Show_New_Contact_Tab__c=true OR Show_New_Lead_Tab__c=true OR Show_New_Case_Tab__c=true OR Show_New_Opportunity_Tab__c=true');
 
 		for(LiveText_Number__c ltnObject : ltnObjects){    	
	   		if(ltnObject.New_Custom_Objects_Tabs__c == null) ltnObject.New_Custom_Objects_Tabs__c = '';
	    	
	    	if(ltnObject.Show_New_Account_Tab__c == true){
	    		ltnObject.New_Custom_Objects_Tabs__c += Util.GLOBAL_DESCRIBE.get(Constant.ACCOUNT_OBJECT).getDescribe().getName() + ';';
	    	}
	    	
	    	if(ltnObject.Show_New_Contact_Tab__c == true){
	    		ltnObject.New_Custom_Objects_Tabs__c += Util.GLOBAL_DESCRIBE.get(Constant.CONTACT_OBJECT).getDescribe().getName() + ';';
	    	}
	    	
	    	if(ltnObject.Show_New_Lead_Tab__c == true){
	    		ltnObject.New_Custom_Objects_Tabs__c += Util.GLOBAL_DESCRIBE.get(Constant.LEAD_OBJECT).getDescribe().getName() + ';';
	    	}
	    	
	    	if(ltnObject.Show_New_Case_Tab__c == true){
	    		ltnObject.New_Custom_Objects_Tabs__c += Util.GLOBAL_DESCRIBE.get(Constant.CASE_OBJECT).getDescribe().getName() + ';';
	    	}   	 	
	    	
	    	if(ltnObject.Show_New_Opportunity_Tab__c == true){
	    		ltnObject.New_Custom_Objects_Tabs__c += Util.GLOBAL_DESCRIBE.get(Constant.OPPORTUNITY_OBJECT).getDescribe().getName() + ';';
	    	}
		}
	 	
	 	if(ltnObjects.size() > 0){
	 		update ltnObjects;
	 	}      
    }
        
    private PushTopic createConversationHeaderPushTopic(){
        String streamingObjectName = Conversation_Header__c.SObjectType.getDescribe().getName();
        String idField = Conversation_Header__c.Id.getDescribe().getName();
        String supportNumberField = Conversation_Header__c.Support_Number__c.getDescribe().getName();
        String originatingNumberField = Conversation_Header__c.Originating_Number__c.getDescribe().getName();
        String formattedOriginatingNumberField = Conversation_Header__c.Formatted_Originating_Number__c.getDescribe().getName();
        String stageField = Conversation_Header__c.Status__c.getDescribe().getName();
        String liveTextNumberField = Conversation_Header__c.LiveText_Number__c.getDescribe().getName();
        String elapsedTimeField = Conversation_Header__c.ElapsedTime__c.getDescribe().getName();
        String formattedOriginatingNumberToDisplay = Conversation_Header__c.Formatted_Originating_Number_To_Display__c.getDescribe().getName();
        String query = 'Select';
        query += ' ' + idField + ', ';
        query += supportNumberField + ', ';
        query += originatingNumberField + ', ';
        query += formattedOriginatingNumberField + ', ';
        query += formattedOriginatingNumberToDisplay + ',';
        query += liveTextNumberField + ', ';
        query += elapsedTimeField + ', ';
        query += stageField + ' ';
        query += 'from ' + streamingObjectName;
        system.debug('query::' + query);
        PushTopic pushTopic = new PushTopic();
        String pushTopicName = Test.isRunningTest()?Constant.conversation_header_push_topic_Test:Constant.conversation_header_push_topic;
        pushTopic.Name = pushTopicName;
        pushTopic.isActive = true;
        pushTopic.Query = query;
        pushTopic.ApiVersion = 31.0;
        pushTopic.NotifyForOperationCreate = true;
        pushTopic.NotifyForOperationUpdate = true;
        pushTopic.NotifyForOperationUndelete = true;
        pushTopic.NotifyForOperationDelete = true;
        pushTopic.NotifyForFields = 'Referenced';
        return pushTopic;
    }
    
    /**
     * @description: Create a PushTopic,for any new records inserted to SMS text object having source as livetext.
     * @param: null.
     * @return null.
     */
    private PushTopic createSMSTextPushTopic() {
        String streamingObjectName = SMS_Text__c.SObjectType.getDescribe().getName();
        String idField = SMS_Text__c.Id.getDescribe().getName();
        String supportNumberField = SMS_Text__c.Support_Number__c.getDescribe().getName();
        String originatingNumberField = SMS_Text__c.Originating_Number__c.getDescribe().getName();
        String formattedOriginatingNumberField = SMS_Text__c.Formatted_Originating_Number__c.getDescribe().getName();
        String SourceField = SMS_Text__c.Source__c.getDescribe().getName();
        String ConversationHeaderField = SMS_Text__c.Conversation_Header__c.getDescribe().getName();
        String smsTextOrigine = 'LiveText';
        String query = 'Select';
        query += ' ' + idField + ', ';
        query += supportNumberField + ', ';
        query += originatingNumberField + ', ';
        query += formattedOriginatingNumberField + ', ';
        query += SourceField + ', ';
       // query += ConversationHeaderField + ', ';
       // query += MessageField + ' ';
        query += ConversationHeaderField + ' ';
        query += 'from ' + streamingObjectName;
        query += ' where  ' + SourceField + '=' + '\'' + smsTextOrigine + '\'';
        PushTopic pushTopic = new PushTopic();
        String pushTopicName = Test.isRunningTest()?Constant.sms_text_push_topic_Test:Constant.sms_text_push_topic;
        pushTopic.Name = pushTopicName;
        pushTopic.Query = query;
        pushTopic.isActive = true;
        pushTopic.ApiVersion = 31.0;
        pushTopic.NotifyForOperationCreate = true;
        pushTopic.NotifyForOperationUpdate = true;
        pushTopic.NotifyForOperationUndelete = true;
        pushTopic.NotifyForOperationDelete = true;
        pushTopic.NotifyForFields = 'Referenced'; 
        return pushTopic;
    }

    private void setPhoneNumbersActivities(){
        List<LiveText_Number__c> updateNumbers = [SELECT Id, CreateEvent__c, CreateTask__c FROM LiveText_Number__c];
        for(LiveText_Number__c n : updateNumbers){
            if(!n.CreateEvent__c && !n.CreateTask__c){
                n.CreateEvent__c = false;
                n.CreateTask__c = true;
            }
        }
        update updateNumbers;
    }
    
    private void normalizeLiveTextNumbers(){
         List<LiveText_Number__c> updateNumbers = [SELECT Id, Number__c FROM LiveText_Number__c WHERE not Number__c like '+%'];
         for(LiveText_Number__c n : updateNumbers){
            n.Number__c = '+' + n.Number__c;
        }
        update updateNumbers;
    }

    private void setPhoneNumbersISOCountryCode(){
        List<LiveText_Number__c> updateNumbers = [SELECT Id, ISOCountryCode__c FROM LiveText_Number__c WHERE ISOCountryCode__c = null];
        for(LiveText_Number__c n : updateNumbers){
            n.ISOCountryCode__c = 'US';
        }
        update updateNumbers;
    }

    private void setInternationalPhoneNumbers() {
        List<LiveText_Number__c> updateNumbers = [SELECT Id, International_Live_Text_Number__c, Number__c FROM LiveText_Number__c WHERE International_Live_Text_Number__c = null];
        for(LiveText_Number__c n : updateNumbers){
            n.International_Live_Text_Number__c = n.Number__c;
        }
        update updateNumbers;
    }

}