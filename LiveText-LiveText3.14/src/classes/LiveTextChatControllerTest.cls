/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class LiveTextChatControllerTest {
	static LiveText_Number__c LiveTextNumber;
	static SMS_Text__c SMSTextOutbound;
	static SMS_Text__c SMSTextInbound;
	static User restrictedUser;
	static LiveTextGlobalSettings__c m_LiveTextGlobalSettings;
	static List<User> userList;
	static User adminUser;
	
	static void createAdminUser(){
    	adminUser = UnitTestObjectBuilder.createAdminUser();
    	insert adminUser;
    }
  
	private static void SetUp() {
		m_LiveTextGlobalSettings = new LiveTextGlobalSettings__c();
		m_LiveTextGlobalSettings.GlobalTriggerExecutionEnabled__c = true;
		m_LiveTextGlobalSettings.Active_Status_Purge_Hours__c =0;
		insert m_LiveTextGlobalSettings;
	} 
	
	static void initTestData(){
		LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
		insert LiveTextNumber;
        userList = new List<User>();
        for(Integer i=0; i<2; i++){
            userList.add(UnitTestObjectBuilder.createAdminUser());
        }
        insert userList;
        UnitTestObjectBuilder.assignPermissionSetToUsers(userList);
		
        List<Associated_Agents__c> associatedAgentList = new List<Associated_Agents__c>();
        for(User usr : userList){
        	associatedAgentList.add(UnitTestObjectBuilder.createAssociatedAgent(LiveTextNumber.Id, usr.Id));
        }
        insert associatedAgentList; 
        
		restrictedUser = UnitTestObjectBuilder.createRestrictedUser();
    }
	
    static testMethod void LiveTextChatController_Test_insertSMSTextRecordStatic() 
    {
    	createAdminUser();    	
    	system.runAs(adminUser)
    	{   		
			initTestData();		
			
			test.StartTest();	
				String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
				Conversation_Header__c ConversationHeader = UnitTestObjectBuilder.CreateConversationHeader(phoneNumber, LiveTextNumber.Id);  
				insert ConversationHeader; 
				SMSTextOutbound = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, ConversationHeader.Id); 
				insert SMSTextOutbound;  
				LiveTextChatController.insertSMSTextRecordStatic(ConversationHeader.id);
			test.stopTest();    
		}	
    }
	
	static testMethod void LiveTextChatController_Test_Outbound() {
		String outboundObjName;
    	createAdminUser();    	
    	system.runAs(adminUser){  
    		//SetUp();  		
    		initTestData();		
			test.StartTest();		
			List<Conversation_Header__c> chl = new List<Conversation_Header__c>();
			String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
			Conversation_Header__c outboundConversationHeader = UnitTestObjectBuilder.CreateOutboundConversationHeader(phoneNumber, LiveTextNumber.Id);  
			insert outboundConversationHeader;                 
        	
        	outboundConversationHeader = [Select Id, Originating_Number__c, Contact__c From Conversation_Header__c Where Id=:outboundConversationHeader.Id];
        	SMSTextOutbound = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, outboundConversationHeader.Id);      			
  			insert SMSTextOutbound;
			
			LiveTextChatController.insertSMSTextRecordStatic(outboundConversationHeader.Id);
			
  			SMSTextOutbound = [Select Id, Conversation_Header__c From SMS_Text__c Where Id=:SMSTextOutbound.Id];		
			ApexPages.StandardController sc = new ApexPages.StandardController(outboundConversationHeader);
			LiveTextChatController ltcc = new LiveTextChatController(sc);
			//ltcc.init();
			ltcc.convoTypeParam = 'outbound';
            System.assertEquals(LiveTextChatController.getProperLocale('', ''),'en_US');
			ltcc.originatingNumber = outboundConversationHeader.Originating_Number__c;
			ltcc.InitializeConversation();
			LiveTextChatController.ConversationInitialization ci = new LiveTextChatController.ConversationInitialization();		    
    		ci.supportNumber = LiveTextNumber.Number__c;
    		ci.originatingNumber = phoneNumber;
    		ci.conversationType = Constant.ConversationType.Outbound.name();
    	 	ci.message = 'test';
    		ci.objectId = outboundConversationHeader.Contact__c;
			
			
			LiveTextChatController.insertConversationHeaderLinkObject(ci);
			ltcc.objectPrefix = Contact.SObjectType.getDescribe().getKeyPrefix();
			chl.add(outboundConversationHeader);
			ltcc.ConversationHeaderList = chl;
			ltcc.associateSelectedRecords();
			LiveTextChatController.getSMSTextRecord(SMSTextOutbound.Id);
			LiveTextChatController.isOutboundConversationAllowed(LiveTextNumber.Number__c,phoneNumber);
			LiveTextChatController.getQueuedConversation(LiveTextNumber.Number__c,phoneNumber);
			LiveTextChatController.validatePhoneNumbers(LiveTextNumber.Number__c, phoneNumber);
			LiveTextChatController.insertEndChatTextRecord('hi', '1235456', false);
			
			List<SMS_Text__c> smsList = ConsoleIntegrationController.getSMSMessages(outboundConversationHeader.Id);
			system.assert(smsList != null);
			system.assert(!smsList.isEmpty());
   			
			Conversation_Header__c ch = CommonTestHelper.CreateConversationHeader(UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber(),LiveTextNumber.Id); 
			insert ch; 
			ch = [SELECT Id, CreatedDate, Contact__c, Lead__c, Account__c, Case__c, Transcript_Summary_1__c          
					FROM Conversation_Header__c 
					WHERE Id =:ch.Id];	 

			upsert new ConfigurationSettings__c(
			    Name = UserInfo.getOrganizationId(),
			    Endpoint_URL__c = 'https://app.hwlivetext.com/',
			    oAuth_URL__c = 'https://app.hwlivetext.com/oauth',
			    Account_Id__c = '123',
			    Auth_Token__c = '321'
			);
				
	    	Event e = new Event();
	    	e.WhoId = ch.Contact__c;
	    	e.OwnerId = UserInfo.getUserId();
	    	e.Subject = 'Text Session';
			e.StartDateTime = ch.CreatedDate;
		    e.EndDateTime = ch.CreatedDate;
		    e.IsReminderSet = false;   
	    	insert e;
	    	Conversation_Event__c ce = new Conversation_Event__c(); 
	    	ce.Conversation_Header__c = ch.Id;
	    	ce.Event__c = String.ValueOf(e.Id);
	    	ce.Linked_Object__c = ch.Contact__c;
	    	insert ce;
	    	ch.Transcript_Summary_1__c = 'Unit Testing';
	    	ch.Status__c = Constant.STAGE_ACTIVE;
	    	update ch;		
	    	
	    	Conversation_Header__c ch2 = [SELECT Id, CreatedDate, Contact__c, Lead__c, Account__c, Case__c, Transcript_Summary_1__c          
					FROM Conversation_Header__c 
					WHERE Id =:ch.Id];	
					      	
	    	ltcc.conversationRecordId = ch2.Id;
	    	ltcc.getActiveConversationRecordId();
	    	LiveTextChatController.getMessagePayloadResponse('', 0, '','', '', false);
	    	LiveTextChatController.getMessagePayloadResponseWithPicture(null);
			  
			LiveTextChatController.getOptinStatusMessage(LiveTextNumber.Id, phoneNumber, LiveTextNumber.Number__c, 'Contact');
			LiveTextChatController.getSMSTextRecordMap( new List<Id>{outboundConversationHeader.Id});
			LiveTextChatController.insertSMSTextRecord('sms', outboundConversationHeader.Id, false);  
			
			ltcc.endChat();
			Event updateEvent = [SELECT Description FROM Event WHERE Id=:e.Id];
			
			ltcc.SetConversationRecordIdAndLinkObject();
			system.assert(ltcc.initialMessage != null);
    		system.assert(ltcc.source != null); 
    		system.assert(ltcc.liveText != null);
    		system.assert(ltcc.nameSpace != null);
    		system.assert(ltcc.userName != null);
			system.assert(ltcc.ConversationHeaderRecords !=null); 
    		system.assert(ltcc.MyPhoneNumbers != null);
    		//system.assert(ltcc.customObjectsForManualLinking != null);
    		
			ltcc.oid = ch2.Contact__c;//This assignment is just to test the getObjectName method for contact object.
    		ltcc.getObjectName();
			outboundObjName = [SELECT Name FROM Contact WHERE Id=:ch2.Contact__c].Name;
    		System.assert(ltcc.objectName.equals(outboundObjName));

    		
			ltcc.oid = ch2.Lead__c;//This assignment is just to test the getObjectName method for Lead object.
    		ltcc.getObjectName();
			outboundObjName = [SELECT Name FROM Lead WHERE Id=:ch2.Lead__c].Name;
    		System.assert(ltcc.objectName.equals(outboundObjName));

    		ltcc.oid = ch2.Case__c;//This assignment is just to test the getObjectName method for Case object with contact linked.
    		Case caseObj = [SELECT Id FROM Case WHERE Id=:ch2.Case__c];
    		caseObj.ContactId = ch2.Contact__c;
    		update caseObj;
    		ltcc.getObjectName();
			outboundObjName = [SELECT Contact.Name FROM Case WHERE Id=:ch2.Case__c].Contact.Name;
    		//System.assert(ltcc.objectName.equals(outboundObjName));

			//Remove the linked contact object and link with account and test the getObject method    		
    		caseObj.ContactId = null;
    		caseObj.AccountId = ch2.Account__c;
    		update caseObj;
    		ltcc.getObjectName();
			outboundObjName = [SELECT Account.Name FROM Case WHERE Id=:ch2.Case__c].Account.Name;
    		//System.assert(ltcc.objectName.equals(outboundObjName));
    		
			test.stopTest();
    	}
	}
	
	static testMethod void LiveTextChatController_Test_Inbound() {
    	createAdminUser(); 
    	system.runAs(adminUser){
			initTestData();
			test.StartTest();						
			List<Conversation_Header__c> chl = new List<Conversation_Header__c>();
			String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
			Conversation_Header__c inboundConversationHeader = UnitTestObjectBuilder.CreateConversationHeader(phoneNumber, LiveTextNumber.Id);                    
        	insert inboundConversationHeader;
        	inboundConversationHeader = [Select Id, Originating_Number__c From Conversation_Header__c Where Id=:inboundConversationHeader.Id];
        	SMSTextInbound = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, inboundConversationHeader.Id);      			
  			insert SMSTextInbound;  		
			SMSTextInbound = [Select Id, Conversation_Header__c From SMS_Text__c Where Id=:SMSTextInbound.Id];
			ApexPages.StandardController sc = new ApexPages.StandardController(inboundConversationHeader);
			LiveTextChatController ltcc = new LiveTextChatController(sc);
			ltcc.init();
			ltcc.getNumbers();
			ltcc.convoTypeParam = 'inbound';
			ltcc.originatingNumber = inboundConversationHeader.Originating_Number__c;
			ltcc.InitializeConversation();			
			
			LiveTextChatController.getSMSTextRecord(SMSTextInbound.Id);
			LiveTextChatController.insertEndChatTextRecord('hi', '1235478', false);
			LiveTextChatController.validatePhoneNumbers(LiveTextNumber.Number__c, phoneNumber);
			LiveTextChatController.associateRecords(null, '');	

			ltcc.objectPrefix = Contact.SObjectType.getDescribe().getKeyPrefix();
			chl.add(inboundConversationHeader);
			ltcc.ConversationHeaderList = chl;
			ltcc.associateSelectedRecords();
			List<SMS_Text__c> smsList = ConsoleIntegrationController.getSMSMessages(inboundConversationHeader.Id);
			system.assert(smsList != null);
			system.assert(!smsList.isEmpty());
			Conversation_Header__c ch = CommonTestHelper.CreateConversationHeader(UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber(),LiveTextNumber.Id); 
			insert ch; 
			Conversation_Header__c ch2 = [SELECT Id, CreatedDate, Contact__c, Lead__c, Account__c, Case__c, Transcript_Summary_1__c          
					FROM Conversation_Header__c 
					WHERE Id =:ch.Id];	  	
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
	    	
	    	Conversation_Header__c ch3 = [SELECT Id, CreatedDate, Contact__c, Lead__c, Account__c, Case__c, Transcript_Summary_1__c          
					FROM Conversation_Header__c 
					WHERE Id =:ch2.Id];	  
    	
	    	ltcc.conversationRecordId = ch3.Id;   
	    	LiveTextChatController.getInitialMessage(ch3.Id); 	
			ltcc.endChat();
			Event updateEvent = [SELECT Description FROM Event WHERE Id=:e.Id];
			
			ltcc.SetConversationRecordIdAndLinkObject();
			ltcc.ReloadConversation();
			system.assert(ltcc.initialMessage != null);
    		system.assert(ltcc.source != null); 
    		system.assert(ltcc.liveText != null);
    		system.assert(ltcc.nameSpace != null);
    		system.assert(ltcc.userName != null);
			system.assert(ltcc.ConversationHeaderRecords !=null); 
    		system.assert(ltcc.MyPhoneNumbers != null);
    		system.assert(ltcc.casePrefixURL != null);
    		system.assert(ltcc.opportunityPrefixURL != null);
			test.stopTest();
    	}
	}

	static testMethod void Test_CustomObjectSupport(){
		createAdminUser();
		system.runAs(adminUser){
			initTestData();
			Test.startTest();
			String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
			Conversation_Header__c inboundConversationHeader = UnitTestObjectBuilder.CreateConversationHeader(phoneNumber, LiveTextNumber.Id);                    
        	insert inboundConversationHeader;
        	ApexPages.StandardController sc = new ApexPages.StandardController(inboundConversationHeader);
			LiveTextChatController ltcc = new LiveTextChatController(sc);
			system.assert(!ltcc.getCustomObjectKeyPrefixesForEditPages().isEmpty());
			system.assert(!ltcc.customObjectsForManualLinking.isEmpty());
			Test.stopTest();
		}
	}
	
	static testMethod void LiveTextChatController_Test_Deprecated() {
    	createAdminUser(); 
    	system.runAs(adminUser){
			initTestData();
			test.StartTest();	
			LiveTextChatController.sendSMS2(null, '');	
			LiveTextChatController.getSMSTextRecordList(null);				
			test.stopTest();
    	}
	}
	

}