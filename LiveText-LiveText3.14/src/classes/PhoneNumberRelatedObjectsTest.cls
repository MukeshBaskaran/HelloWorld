@isTest
private with sharing class PhoneNumberRelatedObjectsTest {
	static LiveText_Number__c LiveTextNumber;
	static User adminUser;
    static Conversation_Header__c tsh;
    static Account acc;

    static Set<String> availableRecordTypeList;
    static Set<String> selectedRecordTypeList;
    static String CaseObjectName;
    static String LeadObjectName;
    static String AccountObjectName;
    static String ContactObjectName;
    static String OpportunityObjectName; 
	
	static void createAdminUser(){
    	adminUser = UnitTestObjectBuilder.createAdminUser();
    	insert adminUser;
    }
  
	static void initTestData(){
		LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
		insert LiveTextNumber;
        acc = UnitTestObjectBuilder.createAccount('16176666666');
        insert acc;
        tsh = UnitTestObjectBuilder.CreateConversationHeader('16176666666', LiveTextNumber.id);
        insert tsh;
    }

    static void initAssignScreenPopTypeHelperData() {
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
        ScreenPopSequence__c seq1 = UnitTestObjectBuilder.createScreenPopSequence(LiveTextNumber.Id,AccountObjectName,1);
        insert seq1;
        ScreenPopSequence__c seq2 = UnitTestObjectBuilder.createScreenPopSequence(LiveTextNumber.Id,CaseObjectName,2);
        insert seq2;
    }
    	
		
	static testMethod void Test_getMRMItem() {
    	createAdminUser();
    	system.runAs(adminUser){		
			test.StartTest();
            List<Account> accToAdd = new List<Account>();
            for(Integer i=0;i<10;i++){
                Account temp = UnitTestObjectBuilder.CreateAccount('16176666666');
                accToAdd.add(temp);
            }
            insert accToAdd;
            List<SObjectWrapper> sobjectWrapperlist = new List<SObjectWrapper>();
            List<Id> accIds = new List<Id>();
            for(Account a : accToAdd){
                accIds.add(a.Id);
            }
            for(Account a : [SELECT Id, Name, LastModifiedDate FROM Account WHERE Id IN :accIds]){
                sobjectWrapperlist.add(new SObjectWrapper(a));
            }
            system.assertNotEquals(PhoneNumberRelatedObjects.getMRMItem(sobjectWrapperlist, 'Account'), null);
            system.assertNotEquals(PhoneNumberRelatedObjects.getMRMItem(sobjectWrapperlist, null), null);
            system.assertEquals(PhoneNumberRelatedObjects.getMRMItem(new List<SObjectWrapper>(), null), null);
            system.assertNotEquals(PhoneNumberRelatedObjects.getMRObject(sobjectWrapperlist, 'Account'), null);
            system.assertNotEquals(PhoneNumberRelatedObjects.getMRObject(sobjectWrapperlist, null), null);
            system.assertEquals(PhoneNumberRelatedObjects.getMRObject(new List<SObjectWrapper>(), null), null);
            initTestData();
            PhoneNumberRelatedObjects relatedObjs = new PhoneNumberRelatedObjects(tsh, LiveTextNumber.Id, '16176666666', sobjectWrapperlist);
            relatedObjs.setOnlySelectedRecords();
            relatedObjs.AutoLink(tsh);
			test.stopTest();
    	}
	}
	
	static testMethod void Test_Properties() {
    	createAdminUser();
    	system.runAs(adminUser){		
			test.StartTest();
			initTestData();		
            initAssignScreenPopTypeHelperData();
            List<Account> accToAdd = new List<Account>();
            for(Integer i=0;i<10;i++){
                Account temp = UnitTestObjectBuilder.CreateAccount('16176666666');
                accToAdd.add(temp);
            }
            insert accToAdd;
			PhoneNumberRelatedObjects relatedObjs = new PhoneNumberRelatedObjects(LiveTextNumber.Id, '16176666666');
			relatedObjs.AutoLink(tsh);
			system.assertEquals(false, relatedObjs.HasItems);		

			test.stopTest();
    	}
	}
	
	

}