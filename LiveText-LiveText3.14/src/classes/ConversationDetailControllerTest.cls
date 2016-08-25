@isTest
private class ConversationDetailControllerTest {

    static SObject ltnObject;
    static String phoneNumber;
    static Conversation_Header__c convHeader;
    static void initTestData() {
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        System.assertNotEquals(ltnObject.Id, null); 
        phoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        String formattedPhNumber = UnitTestObjectBuilder.PhoneFormatter(phoneNumber);
        Account acc = UnitTestObjectBuilder.createAccount(formattedPhNumber);
        insert acc;
        System.assertNotEquals(acc.Id, null); 
        Contact cont = UnitTestObjectBuilder.createContact(acc.Id, formattedPhNumber);
        insert cont;
        System.assertNotEquals(cont.Id, null); 
        Lead lead = UnitTestObjectBuilder.createLead(formattedPhNumber);
        insert lead;
        System.assertNotEquals(lead.Id, null);        
        Opportunity op = UnitTestObjectBuilder.CreateOpportunity(acc.Id);
        insert op;
        System.assertNotEquals(op.Id,null);        
        Case caseObj = UnitTestObjectBuilder.CreateCase(cont.Id,acc.Id);
        insert caseObj;
        System.assertNotEquals(caseObj.Id,null);
        convHeader = UnitTestObjectBuilder.CreateConversationHeader(phoneNumber, ltnObject.Id);
        convHeader.Account__c = acc.Id;
        convHeader.Contact__c = cont.Id;
        convHeader.Lead__c = lead.Id;
        insert convHeader;
        System.assertNotEquals(convHeader.Id, null); 
    }
    
    static testMethod void Test_AssociatedRecordList_Positive() {   
        Test.startTest();
        initTestData();
        Test.setFixedSearchResults(new Id[]{convHeader.Account__c, convHeader.Contact__c, convHeader.Lead__c});
        ConversationDetailController cdCon = new ConversationDetailController();
        cdCon.conversationHeaderId = convHeader.Id;
        cdCon.populateAssociatedRecordList();
        cdCon.getAssociatedRecordList();
        system.assert(!cdCon.associatedRecordList.isEmpty());
        Test.stopTest();
    }
    
    static testMethod void Test_LoadTranscript_Positive() {
        Test.startTest();
        initTestData();
        ConversationDetailController cdCon = new ConversationDetailController();
        cdCon.loadSelectedRowTrasncripts();
        Test.stopTest();
    }
    
    static testMethod void Test_InitializeConversation_Inbound() {
        Test.startTest();
        initTestData();
        ConversationDetailController cdCon = new ConversationDetailController();
        cdCon.InitializeConversation();
        String conversationType = cdCon.conversationType;
        cdCon.loadAllTranscripts();
        cdCon.populateAssociatedRecordList();
        Test.stopTest();
    }

    static testMethod void Test_InitializeConversation_Outbound() {
        Test.startTest();
        initTestData();
        ConversationDetailController cdCon = new ConversationDetailController();
        cdCon.originatingObjectId = (String) [SELECT Id FROM Contact LIMIT 1].get(0).get('Id');
        cdCon.InitializeConversation();
        String conversationType = cdCon.conversationType;
        cdCon.loadAllTranscripts();
        cdCon.populateAssociatedRecordList();
        Test.stopTest();
    }

    static testMethod void Test_InitializeConversation_Outbound_for_Account() {
        Test.startTest();
        initTestData();
        ConversationDetailController cdCon = new ConversationDetailController();
        cdCon.originatingObjectId = (String) [SELECT Id FROM Account LIMIT 1].get(0).get('Id');
        cdCon.InitializeConversation();
        String conversationType = cdCon.conversationType;
        cdCon.loadAllTranscripts();
        cdCon.populateAssociatedRecordList();
        Test.stopTest();
    }

    static testMethod void Test_AssociateRecord() {
        Test.startTest();
        initTestData();
        ConversationDetailController cdCon = new ConversationDetailController();
        cdCon.InitializeConversation();
        String conversationType = cdCon.conversationType;
        String linkedObjId = (String)   [   SELECT Id 
                                            FROM Account LIMIT 1].get(0).get('Id');
        ConversationDetailController.associateSelectedRecords(cdCon.conversationHeaderId, '001', linkedObjId, true);
        Test.stopTest();
    }
    
    static testMethod void Test_Misc() {
        Test.startTest();
        initTestData();
        ConversationDetailController cdCon = new ConversationDetailController();
        String objectPrefix = cdCon.objectPrefix;
        String recordId = cdCon.recordId;
        String nameSpace = cdCon.namespace;
        Test.stopTest();
     }
    
}