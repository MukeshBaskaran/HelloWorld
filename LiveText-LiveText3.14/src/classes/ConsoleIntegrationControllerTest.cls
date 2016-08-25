@isTest
private class ConsoleIntegrationControllerTest { 
    static LiveText_Number__c LiveTextNumber;
    static SMS_Text__c SMSText;
    static Conversation_Header__c conversationHeader;
    static User restrictedUser;
    static LiveTextGlobalSettings__c m_LiveTextGlobalSettings;
    static List<User> userList;
    static User adminUser;
    static void createAdminUser() {
        adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
    }
  
    private static void SetUp() {
        m_LiveTextGlobalSettings = new LiveTextGlobalSettings__c();
        m_LiveTextGlobalSettings.GlobalTriggerExecutionEnabled__c = true;
        m_LiveTextGlobalSettings.Active_Status_Purge_Hours__c =0;
        insert m_LiveTextGlobalSettings;
    } 
    
    static void initTestData() {
        LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
        insert LiveTextNumber;
        userList = new List<User>();
        for(Integer i=0; i<2; i++) {
            userList.add(UnitTestObjectBuilder.createAdminUser());
        }
        insert userList;
        UnitTestObjectBuilder.assignPermissionSetToUsers(userList);
        List<Associated_Agents__c> associatedAgentList = new List<Associated_Agents__c>();
        for(User usr : userList){
            associatedAgentList.add(UnitTestObjectBuilder.createAssociatedAgent(LiveTextNumber.Id, usr.Id));
        }
        insert associatedAgentList;
        SMSText = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, null);
        insert SMSText;
        SMSText =   [   SELECT Id, Conversation_Header__c 
                        FROM SMS_Text__c 
                        WHERE Id=:SMSText.Id
                    ];
        conversationHeader = Util.getCurrentConversationHeaderList(SMSText.Conversation_Header__c)[0]; 
        restrictedUser = UnitTestObjectBuilder.createRestrictedUser();
    }

    static testMethod void ConsoleIntegrationController_Test() {
        createAdminUser();
        system.runAs(adminUser) {       
            test.StartTest();
            SetUp();
            initTestData();
            ApexPages.StandardController sc = new ApexPages.StandardController(conversationHeader);
            ConsoleIntegrationController cic = new ConsoleIntegrationController(sc);
            cic.getLiveTextRecordSize();
            System.assertEquals(cic.getUserLocale(),'en_US');
            System.assertEquals(cic.totalSize, 1);
            String nameSpace = cic.nameSpace;
            String conversationSessionPrefix = cic.conversationSessionPrefix;
            System.assertNotEquals(conversationSessionPrefix, null);
            String LeadSource = cic.LeadSource;
            System.assertNotEquals(LeadSource, null);
            
            String keyPrefix = cic.keyPrefix;
            String formattedOriginatingNumber = cic.formattedOriginatingNumber;
            String openPrimaryTabName = cic.openPrimaryTabName;
            String autoResponseMessage = cic.autoResponseMessage;
            List < Conversation_Header__c > conversationHeaderListProp = cic.conversationHeaderList;
            List<LiveText_Number__c> phoneNumbers = cic.phoneNumbers;
            String MyPhoneNumbers = cic.MyPhoneNumbers;
            List < Conversation_Header__c > conversationHeaderList = cic.getConversationHeaderList();
            ConsoleIntegrationController.getPhoneNumberAccounts('+12125551212');
            ConsoleIntegrationController.getPhoneNumberContacts('+12125551212');
            ConsoleIntegrationController.getPhoneNumberLeads('+12125551212');
                                  
            cic.conversationHeaderId = conversationHeader.Id;
            PageReference pageRef;
            pageRef = cic.getConversationHeaderRecords();
            System.assertEquals(pageRef, null);
            cic.conversationHeaderId = conversationHeader.Id;
            ConsoleIntegrationController.AcceptRemote(cic.conversationHeaderId);
            ConsoleIntegrationController.isConversationHeaderActive(conversationHeader.Id);
            ConsoleIntegrationController.isNewConversationHeader(conversationHeader.Id);
            ConsoleIntegrationController.GetRelatedObjectsAndAutoLink(Util.getCurrentConversationHeaderList(conversationHeader.Id).get(0),'+16175551212', new List<SObjectWrapper>());
            
            ConsoleIntegrationController.getCustomLogo('test', 'test');
            ConsoleIntegrationController.dummyRemoteAction();
            LiveText_Number__c LiveTextNumberObj = UnitTestObjectBuilder.createLiveTextNumber();
            Insert LiveTextNumberObj;
            
            String userStatus = cic.getCurrentUserStatus();
            String convPrefix1 = cic.getConversationSessionPrefix();
            String buildUrl = cic.buildUrl('myPrefix');
            String leadSourceVal = ConsoleIntegrationController.findLeadSourceVal();
             
            List < SelectOption > items = cic.getItems();
            System.assertNotEquals(items, null);
            String status = cic.status;
            String jsonStr = cic.currentConversationHeader;
            System.assertNotEquals(jsonStr, null);
            List<SMS_Text__c> smsList = ConsoleIntegrationController.getSMSMessages(conversationHeader.Id);
            system.assert(smsList != null);
            system.assert(!smsList.isEmpty());
            test.stopTest();
        }
    }


    static testMethod void Test_UpdateAgentStatus_Positive() {
        createAdminUser();
        system.runAs(adminUser){
            Test.startTest();
            SetUp() ;
            initTestData();
            ApexPages.StandardController sc = new ApexPages.StandardController(conversationHeader);
            ConsoleIntegrationController cic = new ConsoleIntegrationController(sc);
            String status = cic.status;
            system.assertEquals(status, Constant.STATUS_OFFLINE);
            cic.updateAgentStatus();
            Agent_Status__c agentStatus = [Select Id From Agent_Status__c Where User__c=:UserInfo.getUserId()];
            system.assert(agentStatus != null);
            system.assert(agentStatus.Id != null);
            cic.status = null;
            status = cic.status;
            system.assertEquals(status, Constant.STATUS_OFFLINE );
            status = Constant.STATUS_AVAIALBLE;
            cic.updateAgentStatus();
            Test.stopTest();
        }
    }
    
    static testMethod void Test_UpdateAgentStatus_Negative() {
        createAdminUser();
        system.runAs(adminUser){
            Test.startTest();
            SetUp() ;
            initTestData();
            ApexPages.StandardController sc = new ApexPages.StandardController(conversationHeader);
            ConsoleIntegrationController cic = new ConsoleIntegrationController(sc);
            system.runAs(restrictedUser){
                String status = cic.status;
                system.assertNotEquals(status, Constant.STATUS_AVAIALBLE);
                try {
                    cic.updateAgentStatus();
                } 
                catch (Exception ex) {
                    system.assertEquals(ex.getTypeName(), AccessController.CRUDException.class.getName());
                }
                List<Agent_Status__c> agentStatus = [Select Id From Agent_Status__c Where User__c=:UserInfo.getUserId()];
                system.assert(agentStatus != null);
                system.assert(agentStatus.isEmpty());
            }
            Test.stopTest();
        }
    }
    
    static testMethod void Test_IsRoutedToCurrentUser_Positive() {
        createAdminUser();
        system.runAs(adminUser){
            Test.startTest();
            SetUp() ;
            initTestData();
            system.runAs(userList.get(0)){
                Boolean isRouted = ConsoleIntegrationController.isRoutedToCurrentUser(LiveTextNumber.Id);
                system.assert(isRouted);
                system.assert(ConsoleIntegrationController.isConversationRoutedToCurrentUser((String)conversationHeader.get('Originating_Number__c'), (String) LiveTextNumber.Id));
            }
            Test.stopTest();
        }
    }
    
    static testMethod void Test_EndConversation_Negative() {
        createAdminUser();
        system.runAs(adminUser){
            Test.startTest();
            SetUp() ;
            initTestData();
            system.runAs(userList.get(0)){
                ConsoleIntegrationController.endChat('123');
            }
            Test.stopTest();
        }
    }   
}