@isTest
private class AssignUserHelperTest {
    static SObject ltnObject;
    static List<User> userList;
    static List<Associated_Agents__c> associatedAgentList;
    static String searchText;
    static Set<String> availableMemberList;
    static Set<String> selectedMemberList;
    static User selectedUser;
    static User adminUser;

    static void createAdminUser() {
        adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
    }

    static void initTestData() {
        userList = new List<User>();
        for(Integer i=0; i<2; i++) {
            userList.add(UnitTestObjectBuilder.createAdminUser());
        }
        insert userList;
        UnitTestObjectBuilder.assignPermissionSetToUsers(userList);
        selectedUser = UnitTestObjectBuilder.createAdminUser();
        insert selectedUser;
        UnitTestObjectBuilder.assignPermissionSetToUsers(new List<User>{selectedUser});
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        availableMemberList = new Set<String>();
        selectedMemberList = new Set<String>();
        associatedAgentList = new List<Associated_Agents__c>();
        for(User usr : userList) {
            if(associatedAgentList.size() < 3) {
                associatedAgentList.add(UnitTestObjectBuilder.createAssociatedAgent(ltnObject.Id, usr.Id));
            }
            selectedMemberList.add(usr.Id);
            availableMemberList.add(usr.Id);
        }
        insert associatedAgentList;
        Associated_Agents__c assAgent = UnitTestObjectBuilder.createAssociatedAgent(ltnObject.Id, selectedUser.Id);
        insert assAgent;
        searchText = selectedUser.FirstName;
    }
    
    static testMethod void Test_GetSelectedMembers_Positive() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            AssignUserHelper helper = new AssignUserHelper(ltnObject);
            List<SelectOption> selectedMembers = helper.getSelectedMembers();
            system.assert(selectedMembers != null);
            system.assert(!selectedMembers.isEmpty());
            Test.stopTest();
        }
    }
    
    static testMethod void Test_FindUsersByName_Positive() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            AssignUserHelper helper = new AssignUserHelper(ltnObject);
            List<SelectOption> foundUsers = helper.findUsersByName(searchText, selectedMemberList);
            system.assert(foundUsers != null);
            system.assert(!foundUsers.isEmpty());
            Test.stopTest();
        }
    }
    
    static testMethod void Test_FindUsersByName_EmptySearch() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            AssignUserHelper helper = new AssignUserHelper(ltnObject);
            List<SelectOption> foundUsers = helper.findUsersByName('', selectedMemberList);
            system.assert(foundUsers != null);
            system.assert(!foundUsers.isEmpty());
            Test.stopTest();
        }
    }
    
    static testMethod void Test_RemoveAddAgents_AddNewAgents() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            LiveText_Number__c newLtnObject = UnitTestObjectBuilder.createLiveTextNumber();
            insert newLtnObject;
            AssignUserHelper helper = new AssignUserHelper(newLtnObject);
            helper.removeAddAgents(selectedMemberList, availableMemberList);
            List<Associated_Agents__c> associatedAgents =  [   SELECT Id, User__c, LiveText_Number__c 
                                                               FROM Associated_Agents__c 
                                                               WHERE LiveText_Number__c=:ltnObject.Id
                                                            ];
            system.assert(associatedAgents != null);
            system.assert(!associatedAgents.isEmpty());
            system.assertEquals(associatedAgents.get(0).LiveText_Number__c, ltnObject.Id);
            Test.stopTest();
        }
    }
    
    static testMethod void Test_RemoveAddAgents_Positive() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            AssignUserHelper helper = new AssignUserHelper(ltnObject);
            helper.removeAddAgents(selectedMemberList, availableMemberList);
            List<Associated_Agents__c> associatedAgents =  [   SELECT Id, User__c, LiveText_Number__c 
                                                               FROM Associated_Agents__c 
                                                               WHERE LiveText_Number__c=:ltnObject.Id
                                                            ];
            system.assert(associatedAgents != null);
            system.assert(!associatedAgents.isEmpty());
            system.assertEquals(associatedAgents.get(0).LiveText_Number__c, ltnObject.Id);
            Test.stopTest();
        }
    }
    
    static testMethod void Test_RetrieveFirstFiftyUsers() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            AssignUserHelper helper = new AssignUserHelper(ltnObject);
            List<SelectOption> foundUsers = helper.retrieveFirstFiftyUsers(selectedMemberList);
            system.assert(!foundUsers.isEmpty());
        }
    }
}