@isTest
public with sharing class AssignScreenPopRecordTypeHelperTest {
    static SObject ltnObject;
    static String searchText;
    static Set<String> availableRecordTypeList;
    static Set<String> selectedRecordTypeList;
    static User adminUser;
    static String CaseObjectName;
    static String LeadObjectName;
    static String AccountObjectName;
    static String ContactObjectName;
    static String OpportunityObjectName; 
    
    static void createAdminUser() {
        adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
    }

    static void initTestData() {
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        CaseObjectName = Util.GLOBAL_DESCRIBE.get(Constant.CASE_OBJECT).getDescribe().getName();
        LeadObjectName = Util.GLOBAL_DESCRIBE.get(Constant.LEAD_OBJECT).getDescribe().getName();
        AccountObjectName = Util.GLOBAL_DESCRIBE.get(Constant.ACCOUNT_OBJECT).getDescribe().getName();
        ContactObjectName = Util.GLOBAL_DESCRIBE.get(Constant.CONTACT_OBJECT).getDescribe().getName();
        OpportunityObjectName = Util.GLOBAL_DESCRIBE.get(Constant.OPPORTUNITY_OBJECT).getDescribe().getName();
        availableRecordTypeList = new Set<String>();
        selectedRecordTypeList = new Set<String>();
        selectedRecordTypeList.add(CaseObjectName);
        availableRecordTypeList.add(CaseObjectName);
        selectedRecordTypeList.add(LeadObjectName);
        availableRecordTypeList.add(LeadObjectName);
        selectedRecordTypeList.add(AccountObjectName);
        availableRecordTypeList.add(AccountObjectName);
        selectedRecordTypeList.add(ContactObjectName);
        availableRecordTypeList.add(ContactObjectName);
        selectedRecordTypeList.add(OpportunityObjectName);
        availableRecordTypeList.add(OpportunityObjectName);
        ScreenPopSequence__c seq1 = UnitTestObjectBuilder.createScreenPopSequence(ltnObject.Id,LeadObjectName,1);
        insert seq1;
        ScreenPopSequence__c seq2 = UnitTestObjectBuilder.createScreenPopSequence(ltnObject.Id,CaseObjectName,2);
        insert seq2;
    }

    static testMethod void Test_GetSelectedRecordTypes_Positive() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            AssignScreenPopRecordTypeHelper helper = new AssignScreenPopRecordTypeHelper(ltnObject);
            List<SelectOption> selectedMembers = helper.getSelectedRecordTypes();
            system.assert(selectedMembers != null);
            system.assert(!selectedMembers.isEmpty());
            Test.stopTest();
        }
    }
        
    static testMethod void Test_RemoveAddRecordTypes() {
        createAdminUser();
        system.runAs(adminUser) {
            Test.startTest();
            initTestData();
            LiveText_Number__c newLtnObject = UnitTestObjectBuilder.createLiveTextNumber();
            insert newLtnObject;
            AssignScreenPopRecordTypeHelper helper = new AssignScreenPopRecordTypeHelper(newLtnObject);
            helper.removeAddRecordTypes(selectedRecordTypeList);
            List<ScreenPopSequence__c> seqs =  [    Select Record_Type__c, LiveText_Number__c
                                                    From ScreenPopSequence__c 
                                                    Where LiveText_Number__c=:ltnObject.Id Order By Sequence__c
                                                ];
            system.assert(seqs != null);
            system.assert(!seqs.isEmpty());
            system.assertEquals(seqs.get(0).LiveText_Number__c, ltnObject.Id);
            Test.stopTest();
        }
    }   
}