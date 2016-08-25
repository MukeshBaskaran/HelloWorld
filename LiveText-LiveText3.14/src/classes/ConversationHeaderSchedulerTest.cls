@isTest
private class ConversationHeaderSchedulerTest {
 
    static testMethod void ConversationHeaderScheduler_Test() {
        test.StartTest();
        LiveText_Number__c LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
        insert LiveTextNumber;
        System.assertNotEquals(LiveTextNumber.Id, null);
        String orginatingNumber = '6171234567'; 
        for(Integer i=0 ; i<5 ; i++){
        	UnitTestObjectBuilder.CreateConversationHeader(orginatingNumber+i,LiveTextNumber.Id);
        }
        ConversationHeaderScheduler chs = new ConversationHeaderScheduler();
        String sch = '20 30 8 10 2 ?';
        String jobID = system.schedule('Update Status Job', sch, chs);
        test.StopTest();
    }
}