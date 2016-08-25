@isTest
private class UtilTest {
    
    static Inbound_Connection_Status__c connStatus;
    static ConfigurationSettings__c confSettings;
    static User restrictedUser;
    static SObject ltnObject;
    static List<SMS_Text__c> smsList;
  
    private static testmethod void Test_smalMethods()
    {
        Account newAcc = new Account();
        newAcc.Name = 'newAccName';
        insert newAcc;

        Util.GetResourceURL('myTestStsRes');

        Util.getPhoneFieldsFromRelationship('phone', 'Account', '', newAcc.Id);

        Util.getAccessibleFields('Account');
        
        Util.createLinkingMessage(newAcc.Id, 'Account', 'Account', false, false);
    }   
  
  
    static void initTestData(){
        restrictedUser = UnitTestObjectBuilder.createRestrictedUser();
        insert restrictedUser;
        system.assertNotEquals(restrictedUser.id,null);
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        system.assertNotEquals(ltnObject.id,null);
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        smsList = new List<SObject>();
        for(Integer i = 0; i<5; i++){
            smsList.add(UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.id));
        }
        insert smsList;
        system.assertNotEquals(smsList[0].id,null);
    }

    static testMethod void Test_InsertException() {
        Test.startTest();
        String objectId = 'TestId';
        String priority = 'High';
        String errDescription = 'Test Error Insertion';
        Util.insertException(objectId, priority, errDescription);
        Exception__c excep = [Select Id, ObjectId__c, Priority__c, ErrorDescription__c From Exception__c Where ObjectId__c='TestId'];
        system.assert(excep != null);
        system.assertEquals(excep.ObjectId__c, objectId);
        system.assertEquals(excep.Priority__c, priority);
        system.assertEquals(excep.ErrorDescription__c, errDescription);
        Test.stopTest();
    }
    
    static testMethod void Test_AddMessageOnError_Message() {
        Test.startTest();
        String errDescription = 'Test Error Insertion';
        Util.addMessageOnError(errDescription);
        System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
        System.AssertEquals(ApexPages.getMessages()[0].getSummary(), errDescription);
        Test.stopTest();
    }
    
    static testMethod void Test_AddMessageOnError_SaveError() {
        Test.startTest();
        try{
            Associated_Agents__c assAgent = new Associated_Agents__c();
            Util.addMessageOnError(Database.insert(assAgent, false));
        } catch(Exception e){
            System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
        }
        Test.stopTest();
    }
    
    static testMethod void Test_AddMessageOnError_DeleteError() {
        Test.startTest();
        initTestData();
        system.runAs(restrictedUser){
            try{
                Util.addMessageOnError(Database.delete(ltnObject, false));
            } catch(Exception e){
                System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
            }
        }
        Test.stopTest();
    }
    
    private static testmethod void Test_getNamespaceAndGetObjectName(){
        Test.startTest();
        String nameSpacePrefix = '';
        for (Schema.SObjectType sObjType : Util.GLOBAL_DESCRIBE.values()){
           String sObjName = String.valueOf(sObjType);
           if(sObjType.getDescribe().isCustom() && sObjName.countMatches('__') == 2){
                nameSpacePrefix = sObjName.substring(0, sObjName.indexOf('__'));
                break;
           }
        }
        if(String.isNotBlank(nameSpacePrefix)){
            nameSpacePrefix += '__';  
            System.AssertEquals(nameSpacePrefix, Util.getNamespace());
        } else{
            System.AssertEquals(nameSpacePrefix, Util.getNamespace());
        }
        Util.getObjectName('testObject');
        Test.stopTest(); 
    }
    
    private static testmethod void Test_isHeyWireConnected_Positive(){
        Test.startTest();
        confSettings = UnitTestObjectBuilder.CreateConfigurationSettings();
        connStatus = UnitTestObjectBuilder.CreateConnectionStatus();
        System.AssertEquals(true, Util.isHeyWireConnected());
        Test.stopTest(); 
    }
    
    private static testmethod void Test_isHeyWireConnected_NoConnStatus(){
        Test.startTest();
        confSettings = UnitTestObjectBuilder.CreateConfigurationSettings();
        Boolean b = Util.isHeyWireConnected();
        System.AssertEquals(ApexPages.getMessages()[0].getSummary(), System.Label.ConnectionExceptionMsg);
        System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
        Test.stopTest(); 
    }
    
    private static testmethod void Test_isHeyWireConnected_NoCustomSetting(){
        Test.startTest();
        Boolean b = Util.isHeyWireConnected();
        System.AssertEquals(ApexPages.getMessages()[0].getSummary(), System.Label.ConnectionExceptionMsg);
        System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
        Test.stopTest(); 
    }
    
    private static testmethod void Test_GetSearchTypeList(){
        Test.startTest();
        initTestData();
        List<SelectOption> searchTypeList = Util.getSearchTypeList();
        system.assert(searchTypeList != null);
        system.assert(!searchTypeList.isEmpty());
        Test.stopTest(); 
    }
    
    private static testmethod void Test_GetLiveTextGlobalSettings(){
        Test.startTest();
        LiveTextGlobalSettings__c ltGlobalSettings = Util.getLiveTextGlobalSettings();
        system.assert(ltGlobalSettings != null);
        Test.stopTest(); 
    }
    
    private static testmethod void Test_ConfiguredMessage(){
        Test.startTest();
        LiveText_Number__c LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
        AccessController.insertAsUser(new list<LiveText_Number__c>{LiveTextNumber});
        system.assert(LiveTextNumber.Id != null);
        SMS_Text__c m_SMSText = CommonTestHelper.CreateSMSTextRecord(Constant.OriginatingNumber, LiveTextNumber.Id, null);
              m_SMSText.Message__c ='hi';
         String autoResponseMessage = Util.getConfiguredMessage(new List < String > {
                        LiveTextNumber.Id
                    },
                    new List < String > {
                        Constant.initial_Message
                    });
          system.assert(m_SMSText != null);
        Test.stopTest(); 
    }
 
    /*
    private static testmethod void Test_isWithinBusinessHours(){
        Test.startTest();
        initTestData();
        smsList = [Select Id, LiveTextNumber__c, CreatedDate From SMS_Text__c Where LiveTextNumber__c=:ltnObject.Id];
        Map<Id, Boolean> smsToBussHourMap = Util.isWithinBusinessHours(smsList);
        system.assert(smsToBussHourMap != null);
        system.assert(!smsToBussHourMap.isEmpty());
        system.assertEquals(smsToBussHourMap.size(), smsList.size());
        Test.stopTest();
    }*/
    
    private static testmethod void Test_smsTextCalloutForEndChat(){
        initTestData();
        Test.startTest();
        Util.smsTextCalloutForEndChat(smsList, smsList[0].Conversation_Header__c);
        Test.stopTest(); 
    }
    
    private static testmethod void Test_smsTextCallout(){
        initTestData();
        Test.startTest();
        system.assertNotEquals(smsList[0].id,null);
        Util.smsTextCallout(new List<ID>{smsList[0].id});
        Test.stopTest(); 
    }
    
    private static testmethod void Test_createTranscript(){
        initTestData();
        Map < Id, List < SMS_Text__c >> conversationHeaderSMSTextMap = new Map < Id, List < SMS_Text__c >>();
        List<SMS_Text__c> newList = new List<SMS_Text__c>();
        Conversation_Header__c ch = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id); 
		insert ch; 
		SMS_Text__c smsBegin = new SMS_Text__c();
        smsBegin.Conversation_Header__c = ch.Id; 
        smsBegin.Message__c = 'Test Begin Message';
        smsBegin.Source__c = constant.salesforce_welcome;
       	newList.add(smsBegin);
        SMS_Text__c newSms = new SMS_Text__c();	
        newSms.Conversation_Header__c = ch.Id; 
        newSms.Message__c = 'Test';
        newSms.Source__c = constant.live_text;
        newList.add(newSms);
        SMS_Text__c smsEnd = new SMS_Text__c();
        smsEnd.Conversation_Header__c = ch.Id; 
        smsEnd.Message__c = 'Test End Message';
        smsEnd.Source__c = constant.salesforce;
        newList.add(smsEnd);        
        insert newList;
        conversationHeaderSMSTextMap.put(ch.Id,newList);
        system.assert(conversationHeaderSMSTextMap !=null);
        Test.startTest();
        Util.createTranscript(conversationHeaderSMSTextMap, DateTime.now());       
        Conversation_Header__c updateConversation = [SELECT Transcript_Summary_1__c          
				FROM Conversation_Header__c 
				WHERE Id =:ch.Id];				
			
        Test.stopTest(); 
    }
    
    private static testmethod void Test_createITRTranscript(){
        initTestData();
        Map < Id, List < SMS_Text__c >> conversationHeaderSMSTextMap = new Map < Id, List < SMS_Text__c >>();
        List<SMS_Text__c> newList = new List<SMS_Text__c>();
        Conversation_Header__c ch = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id); 
		insert ch; 
		SMS_Text__c smsBegin = new SMS_Text__c();
        smsBegin.Conversation_Header__c = ch.Id; 
        smsBegin.Message__c = 'Test Begin Message';
        smsBegin.Source__c = constant.salesforce_welcome;
       	newList.add(smsBegin);
        SMS_Text__c newSms = new SMS_Text__c();	
        newSms.Conversation_Header__c = ch.Id; 
        newSms.Message__c = 'Test';
        newSms.Source__c = constant.live_text;
        newList.add(newSms);
        SMS_Text__c smsEnd = new SMS_Text__c();
        smsEnd.Conversation_Header__c = ch.Id; 
        smsEnd.Message__c = 'Test End Message';
        smsEnd.Source__c = constant.salesforce;
        newList.add(smsEnd);        
        insert newList;
        Test.startTest();
        Util.createITRTranscript('', newList);       			
        Test.stopTest(); 
    }
    
    private static testmethod void Test_createAfterLinkingTranscript(){
        initTestData();
        Map < Id, List < SMS_Text__c >> conversationHeaderSMSTextMap = new Map < Id, List < SMS_Text__c >>();
        List<SMS_Text__c> newList = new List<SMS_Text__c>();
        Conversation_Header__c ch = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id); 
        insert ch; 
        SMS_Text__c smsBegin = new SMS_Text__c();
        smsBegin.Conversation_Header__c = ch.Id; 
        smsBegin.Message__c = 'Test Begin Message';
        smsBegin.Source__c = constant.salesforce_welcome;
        newList.add(smsBegin);
        SMS_Text__c newSms = new SMS_Text__c(); 
        newSms.Conversation_Header__c = ch.Id; 
        newSms.Message__c = 'Test';
        newSms.Source__c = constant.live_text;
        newList.add(newSms);
        SMS_Text__c smsEnd = new SMS_Text__c();
        smsEnd.Conversation_Header__c = ch.Id; 
        smsEnd.Message__c = 'Test End Message';
        smsEnd.Source__c = constant.salesforce;
        newList.add(smsEnd);        
        insert newList;
        conversationHeaderSMSTextMap.put(ch.Id,newList);
        system.assert(conversationHeaderSMSTextMap !=null);
        Test.startTest();
        Util.createTranscript(conversationHeaderSMSTextMap, DateTime.now());  
        ch.Status__c = Constant.stage_ended;
        update ch;
        SMS_Text__c smsLink = new SMS_Text__c();
        smsLink.Conversation_Header__c = ch.Id; 
        smsLink.Message__c = Label.TXT_Transcript_linked_prefix + ' linking test ' + Label.TXT_Transcript_linked_unlinked_postfix;
        smsLink.Source__c = constant.salesforce_linking;     
        insert smsLink;
        Util.createAfterLinkingTranscript(ch, new List<SMS_Text__c>{smsLink});
        Conversation_Header__c updateConversation = [SELECT Transcript_Summary_1__c          
                FROM Conversation_Header__c 
                WHERE Id =:ch.Id];              
        String transcript = (String) updateConversation.Transcript_Summary_1__c;
        System.assert(transcript.contains('linking test'));
        Test.stopTest(); 
    }
    
    private static testmethod void Test_isProductionNamespace(){
        initTestData();
        Test.startTest();
        system.assert(Util.isProductionNamespace());
        Test.stopTest(); 
    }
    
    private static testmethod void Test_convertTranscript(){
        initTestData();
        Test.startTest();
        system.assert(Util.convertTranscriptToPlainText('<b>hello</b>').equals('hello'));
        Test.stopTest(); 
    }
    
    private static testmethod void Test_NameFromAssociatedRecord(){
        Test.startTest();
        system.assert(Util.NameFromAssociatedRecord('<span><i>>>> Linked Contact: <a class="transcriptLink" href="/003j000000APTr0AAH" >Arthur Song</a> <<< </i></span>').equals('Arthur Song'));
        Test.stopTest(); 
    }
    
    private static testmethod void Test_associateRecordsForTranscript(){
        Test.startTest();
        Util.associateSelectedRecordWithTranscript('','','',false, false);
        Test.stopTest(); 
    }
    
       
    private static testmethod void Test_getContactNameFromCase(){
        Test.startTest();
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        Account accObj = UnitTestObjectBuilder.CreateAccount(phoneNumber);
		insert accObj;
        Contact contObj = UnitTestObjectBuilder.CreateContact(accObj.id,phoneNumber);
		insert contObj;
		contObj = [SELECT Id,Name FROM Contact Where Id =:contObj.id];
        Case caseObj = UnitTestObjectBuilder.CreateCase(contObj.id,accObj.id);
		insert caseObj;
		caseObj = [SELECT Id,CaseNumber,Contact.Name FROM Case WHERE Id=:caseObj.id];
	    String testString = '<span><i>>>> Linked Case: <a class="transcriptLink" href="/'+ String.valueOf(caseObj.id) + '" >'+caseObj.casenumber+'</a> <<< </i></span>';
	    system.assert(Util.getContactNameFromCase(testString).equals(caseObj.Contact.Name));
        Test.stopTest(); 
    }
    
    private static testmethod void Test_endChat(){
    
        initTestData();
        Map < Id, List < SMS_Text__c >> conversationHeaderSMSTextMap = new Map < Id, List < SMS_Text__c >>();
        List<SMS_Text__c> newList = new List<SMS_Text__c>();
        Conversation_Header__c ch = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id); 
		insert ch; 
		SMS_Text__c smsBegin = new SMS_Text__c();
        smsBegin.Conversation_Header__c = ch.Id; 
        smsBegin.Message__c = 'Test Begin Message';
        smsBegin.Source__c = constant.salesforce_welcome;
       	newList.add(smsBegin);
        SMS_Text__c newSms = new SMS_Text__c();	
        newSms.Conversation_Header__c = ch.Id; 
        newSms.Message__c = 'Test';
        newSms.Source__c = constant.live_text;
        newList.add(newSms);
        SMS_Text__c smsEnd = new SMS_Text__c();
        smsEnd.Conversation_Header__c = ch.Id; 
        smsEnd.Message__c = 'Test End Message';
        smsEnd.Source__c = constant.salesforce;
        newList.add(smsEnd);        
        insert newList;
        conversationHeaderSMSTextMap.put(ch.Id,newList);
        system.assert(conversationHeaderSMSTextMap !=null);
    	Test.startTest();
		Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id); 
		insert conversationHeader; 
		Conversation_Header__c ch2 = [SELECT Id, CreatedDate, Contact__c, Lead__c, Account__c, Case__c, Transcript_Summary_1__c          
				FROM Conversation_Header__c 
				WHERE Id =:conversationHeader.Id];
				    	
    	Event e = new Event();
    	e.WhoId = ch2.Contact__c;
    	e.OwnerId = UserInfo.getUserId();
    	e.Subject = 'Text Session';
		e.StartDateTime = ch2.CreatedDate;
	    e.EndDateTime = ch2.CreatedDate;
	    e.IsReminderSet = false;   
    	insert e;
    	Conversation_Event__c ce = new Conversation_Event__c(); 
    	ce.Conversation_Header__c = ch2.Id;
    	ce.Event__c = String.ValueOf(e.Id);
    	ce.Linked_Object__c = ch2.Contact__c;
    	insert ce;
    	
    	ch2.Transcript_Summary_1__c = 'Unit Testing';  
    	ch2.Status__c = Constant.STAGE_ACTIVE;
    	  	
    	update ch2;
    	Conversation_Header__c ch3 = [SELECT Id, Transcript_Summary_1__c          
				FROM Conversation_Header__c 
				WHERE Id =:ch2.Id];
		Util.convertTranscriptToPlainText(ch3.Transcript_Summary_1__c);
		 	
		util.endChat(ch3.Id);
		Event updateEvent = [SELECT Description FROM Event WHERE Id=:e.Id];		
    	Test.stopTest();	
    }
    
     private static testmethod void Test_normalization(){
     	Test.startTest();
 	    Util.convertTranscriptToPlainText('nada');	
	    Util.getPermissionMap();
	    Util.insertSMSTextRecord2('dummy','dummy',false);
	    Util.ConvertToE164('6175551515','+1', 10); 
    	Util.NormalizePhoneNumber('6175551212');
    	Util.GetMyPhoneNumbers();
    	String casePrefix = Util.getCasePrefixURL();
    	String opportunityPrefix = Util.getOpportunityPrefixURL();
    	Test.stopTest();	
    }
    
    private static testmethod void Test_validateRecipientPhoneNumberPositive(){
     	Test.startTest();
    	system.assert(String.isBlank(Util.validateRecipientPhoneNumber('16175551212')));
   		Test.stopTest();	
    }
    
  	private static testmethod void Test_validatePhoneNumberLengthPositive(){
     	Test.startTest();
    	system.assert(Util.isValidPhoneNumberLength('16175551212'));
   		Test.stopTest();	
    }    
    
    private static testmethod void Test_GetLiveTextNumberObjectNegative(){
     	Test.startTest();
    	system.assert(Util.GetLiveTextNumberObject('55555555') == null);
   		Test.stopTest();	
    }       
    
      private static testmethod void Test_GetLiveTextNumberObjectByIdNegative(){
     	Test.startTest();
    	system.assert(Util.GetLiveTextNumberObjectById(null) == null);
   		Test.stopTest();	
    }       
    
    private static testmethod void Test_ListContainsObjectPositive(){
     	Test.startTest();
     	List<String> lst = new List<String>();
     	lst.add('test123');
    	system.assert(Util.ListContainsObject(lst,'test123') == true);
   		Test.stopTest();	
    } 
    
     private static testmethod void Test_IsNorthAmericanPhoneNumberPositive(){
     	Test.startTest();
    	system.assert(Util.IsNorthAmericanPhoneNumber('16175551212') == true);
   		Test.stopTest();	
    } 
    
     private static testmethod void Test_IsNorthAmericanPhoneNumberNegative(){
     	Test.startTest();
    	system.assert(Util.IsNorthAmericanPhoneNumber('+40404') == false);
   		Test.stopTest();	
    } 
    
    private static testmethod void Test_GetOptInStatus(){
     	Test.startTest();
     	initTestData();
     	Util.getOptInStatus(ltnObject.id,'+12125551212');
   		Test.stopTest();	
    } 
    
    private static testmethod void Test_BuildUrl(){
     	Test.startTest();
     	Util.buildUrl('003');
   		Test.stopTest();	
    } 
    
    private static testmethod void Test_FormatDate(){
     	Test.startTest();
     	Util.formatDate(DateTime.now());
   		Test.stopTest();	
    } 
    
    private static testmethod void Test_IsAlphaNumeric_Positive(){
     	Test.startTest();
     	system.assert(Util.isAlphaNumeric('abcd123') == true);
   		Test.stopTest();	
    } 
    
     private static testmethod void Test_isITREnabled(){
     	Test.startTest();
     	initTestData();
     	Util.isITREnabled(smsList);
   		Test.stopTest();	
    } 
    
    private static testmethod void Test_GetOptInStatus2(){
     	Test.startTest();
     	initTestData();
     	
     	SMS_Schedule__c smsScheduleObj = new SMS_Schedule__c();
        smsScheduleObj.LiveText_Number__c = ltnObject.id;
        smsScheduleObj.Message__c = 'Test Message';
        smsScheduleObj.Object_Id__c = ltnObject.id;
        smsScheduleObj.Reference_Id__c = '12345';
        Datetime myDT = Datetime.now();
        smsScheduleObj.Schedule_Date__c = myDT.addDays(1);
        smsScheduleObj.To_Phone_Number__c = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        insert smsScheduleObj;
             	
     	Util.getOptInStatus(new List<SMS_Schedule__c>{smsScheduleObj});
   		Test.stopTest();	
    } 
    
    private static testMethod void Test_getAllRelationshipObjects(){
        Test.startTest();
        system.assertNotEquals(Util.getAllRelationshipObjects('Account'), new Set<String>());
        Set<String> relationObjects = Util.getAllRelationshipObjects();
        system.assertNotEquals(relationObjects.size(),0);
        Test.stopTest();
    }

    private static testMethod void Test_createOutboundMessageTranscript(){
        Test.startTest();
        system.assertNotEquals(Util.createOutboundMessageTranscript('message'), '');
        Test.stopTest();
    }
    
     private static testMethod void Test_getPhoneNumberFilteredFields() {
            Test.startTest();
            List<String> pnFieldsList = Util.getPhoneNumberFilteredFields('Account','Phone');
            system.assertNotEquals(pnFieldsList.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_getPhoneNumberFilteredFieldsByFilter() {
            Test.startTest();
            Map<String, List<String>> pnFieldsMap = Util.getPhoneNumberFilteredFieldsByFilter('Account');
            system.assertNotEquals(pnFieldsMap.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_getNeededFieldForQuery() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            insert newAcc;
            List<String> pnFieldsList = Util.getNeededFieldForQuery('Account');
            system.assertNotEquals(pnFieldsList.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_getNeededFieldMap() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            insert newAcc;
            Map<String, List<String>> pnFieldsMap = Util.getNeededFieldMap('Account');
            system.assertNotEquals(pnFieldsMap.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_escapeReservedCharacters() {
            Test.startTest();
            String str = 'a';
            String escapedStr = Util.escapeReservedCharacters(str);
            system.assertEquals(escapedStr,str);
            Test.stopTest();
        }

        private static testMethod void Test_getObjectsData() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            newAcc.Phone = '1234567893';
            insert newAcc;
            List<sObject> objList = Util.getObjectsData(new List<String>{'Account'},'1234567895',1,1);
            system.assertEquals(objList.size(),0);
            Test.stopTest();
        }

        private static testMethod void Test_getFieldsFromRelationship() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            insert newAcc;
            List<String> fieldsList = Util.getFieldsFromRelationship('id','Account','Account');
            system.assertNotEquals(fieldsList.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_getFieldsToRelationshipName() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            insert newAcc;
            Map<String, Map<String,String>> fieldsMap = Util.getFieldsToRelationshipName('Account');
            system.assertNotEquals(fieldsMap.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_getAccessibleFieldsWithRelationshipNameFields() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            insert newAcc;
            List<String> fieldsList = Util.getAccessibleFieldsWithRelationshipNameFields('Account');
            system.assertNotEquals(fieldsList.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_getUpdateableFieldsWithRelationshipNameFields() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            insert newAcc;
            List<String> fieldsList = Util.getUpdateableFieldsWithRelationshipNameFields('Account');
            system.assertNotEquals(fieldsList.size(), 0);
            Test.stopTest();
        }

        private static testMethod void Test_getPhoneNumberVariations() {
            Test.startTest();
            List<String> phnoList = Util.getPhoneNumberVariations('6174444444');
            system.assertNotEquals(phnoList.size(), 0);
            Test.stopTest();
        }
        
        private static testMethod void Test_getLinkedObjectsKeyPrefixToColumnNameMap() {
            Test.startTest();
            Map<String, String> res = Util.getLinkedObjectsKeyPrefixToColumnNameMap(True);
            system.assertNotEquals(res.size(), 0);
            Test.stopTest();
        } 

        private static testMethod void Test_getRelationshipMap() {
            Test.startTest();
            Account newAcc = new Account();
            newAcc.Name = 'newAccName';
            insert newAcc;
            Map<String, List<String>> res = Util.getRelationshipMap('Account');
            system.assertNotEquals(res.size(), 0);
            Test.stopTest();
        } 

        private static testMethod void Test_getRelationshipMapForConversationHeader() {
            Test.startTest();
            Map<String,String> res = Util.getRelationshipMapForConversationHeader();
            system.assertNotEquals(res.size(),0);
            Test.stopTest();
        }

        private static testMethod void Test_getSMSTextList() {
            Test.startTest();
            initTestData();
            ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
            insert ltnObject;
            List<SMS_Text__c> newList = new List<SMS_Text__c>();
            Conversation_Header__c ch = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id); 
            insert ch; 
            SMS_Text__c smsBegin = new SMS_Text__c();
            smsBegin.Conversation_Header__c = ch.Id; 
            smsBegin.Message__c = 'Test Begin Message';
            smsBegin.Source__c = constant.salesforce_welcome;
            newList.add(smsBegin);
            SMS_Text__c newSms = new SMS_Text__c(); 
            newSms.Conversation_Header__c = ch.Id; 
            newSms.Message__c = 'Test';
            newSms.Source__c = constant.live_text;
            newList.add(newSms);
            SMS_Text__c smsEnd = new SMS_Text__c();
            smsEnd.Conversation_Header__c = ch.Id; 
            smsEnd.Message__c = 'Test End Message';
            smsEnd.Source__c = constant.salesforce;
            newList.add(smsEnd);        
            insert newList;
            List<SMS_Text__c> sms = Util.getSMSTextList(ch.Id);
            system.assertEquals(sms.size(),3);
            Test.stopTest();

        }
      
}