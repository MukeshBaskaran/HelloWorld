@isTest
private class TranscriptControllerTest {
	
	static SObject ltnObject;
	static String phoneNumber;
	static Conversation_Header__c convHeader;
	
	static void initTestData(){
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        system.assertNotEquals(ltnObject.Id, null);
        phoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        Account acc = UnitTestObjectBuilder.createAccount(phoneNumber);
        insert acc;
        system.assertNotEquals(ltnObject.Id, null);
        Contact cont = UnitTestObjectBuilder.createContact(acc.Id, phoneNumber);
        insert cont;
        system.assertNotEquals(cont.Id, null);
        Lead lead = UnitTestObjectBuilder.createLead(phoneNumber);
        insert lead;
        system.assertNotEquals(lead.Id, null);
        Case caseObj = UnitTestObjectBuilder.createCase(cont.Id,acc.Id);
        insert caseObj;
        system.assertNotEquals(caseObj.Id, null);
        convHeader = UnitTestObjectBuilder.CreateConversationHeader(phoneNumber, ltnObject.Id);
        convHeader.Account__c = acc.Id;
        convHeader.Contact__c = cont.Id;
        convHeader.Lead__c = lead.Id;
        convHeader.Case__c = caseObj.Id;
        convHeader.Transcript_Summary_1__c = 'How are you?';
        convHeader.Transcript_Summary_2__c = 'How are you?';
        insert convHeader;
        system.assertNotEquals(convHeader.Id, null);
    }
    
    static testMethod void Test_GetTranscript_Positive() {
    	Test.startTest();
    	initTestData();
    	TranscriptController tcCon = new TranscriptController();
    	tcCon.recordId = convHeader.Account__c;
    	List<Conversation_Header__c> conHeaderList = tcCon.getConvHeaderList();
    	system.assert(conHeaderList != null);
    	system.assert(!conHeaderList.isEmpty());
    	System.assert(tcCon.nameSpace !=null); //Added to increase the code coverage.
    	Test.stopTest();
    }
}