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
private class LiveTextControllerTest {

  static LiveText_Number__c LiveTextNumber;
	static SMS_Text__c SMSText;
	static Conversation_Header__c conversationHeader;
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
        
        
        String phoneNumber = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        conversationHeader = UnitTestObjectBuilder.CreateOutboundConversationHeader(phoneNumber, LiveTextNumber.Id);                    
        insert conversationHeader;
               
 		restrictedUser = UnitTestObjectBuilder.createRestrictedUser();
    }
    
	static testMethod void LiveTextController_Test() {
    	createAdminUser();
    	system.runAs(adminUser){		
			test.StartTest();
			//SetUp() ;
			initTestData();
			ApexPages.StandardController sc = new ApexPages.StandardController(conversationHeader);
			LiveTextController ltcc = new LiveTextController(sc);
			
			ltcc.init();
			ltcc.getCurrentConversationHeaderList();
			LiveTextController.getMessagePayloadResponse('', 0, '', '', '');
			LiveTextController.getSMSTextRecord('');
			LiveTextController.createSMSTextRecord('','');
			LiveTextController.sendSMS2(null,'');

			List<SMS_Text__c> smsList = ConsoleIntegrationController.getSMSMessages(conversationHeader.Id);
			system.assert(smsList != null);
			system.assert(ltcc.source != null);
			system.assert(ltcc.liveText != null);
			system.assert(ltcc.nameSpace != null);
     		system.assert(ltcc.userName != null);
			system.assert(ltcc.ConversationHeaderRecords != null);
			test.stopTest();
    	}
	}

	static testMethod void LiveTextController_Test_Ended() {
    	createAdminUser();
    	system.runAs(adminUser){		
			test.StartTest();
			//SetUp() ;
			initTestData();
			conversationHeader.Status__c = constant.stage_ended;
			update conversationHeader;
			ApexPages.StandardController sc = new ApexPages.StandardController(conversationHeader);
			LiveTextController ltcc = new LiveTextController(sc);

			ltcc.init();
	
			test.stopTest();
    	}
	}
}