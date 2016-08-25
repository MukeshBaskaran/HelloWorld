@isTest
public with sharing class QueueMessageActionTest {
    
    static Contact conObj,conObj2;
    static Account accObj,accObj2;
    static Lead leadObj,leadObj2;
    static LiveText_Number__c ltNumberObj;
    static SMS_Schedule__c smsScheduleObj,smsScheduleObj2;

    
    static testmethod void setUp(){
        conObj = new Contact(LastName='John',FirstName='John');
        insert conObj;
        accObj = new Account(Name='Test Acc Name');
        insert accObj;
        leadObj = new Lead(LastName='Test Lead Last Name',company='Test Lead Company');
        insert leadObj;

        conObj2 = new Contact(LastName='John1',FirstName='John1');
        insert conObj2;
        accObj2 = new Account(Name='Test Acc Name1');
        insert accObj2;
        leadObj2 = new Lead(LastName='Test Lead Last Name1',company='Test Lead Company1');
        insert leadObj2;

        ltNumberObj = UnitTestObjectBuilder.createLiveTextNumber();

        ltNumberObj.Number__c = Util.NormalizePhoneNumber(ltNumberObj.Number__c);   
        insert ltNumberObj;

        Datetime myDT;

        List<SMS_Schedule__c> sms = new List<SMS_Schedule__c>();
        smsScheduleObj = new SMS_Schedule__c();
        smsScheduleObj.Contact__c = conObj.id;
        smsScheduleObj.Lead__c = leadObj.id;
        smsScheduleObj.LiveText_Number__c = ltNumberObj.id;
        smsScheduleObj.Message__c = 'Test Message1';
        smsScheduleObj.Object_Id__c = accObj.id;
        smsScheduleObj.Reference_Id__c = '12345';
        myDT = Datetime.now();
        smsScheduleObj.Schedule_Date__c = myDT.addDays(2);
        smsScheduleObj.To_Phone_Number__c = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        insert smsScheduleObj;
        smsScheduleObj2 = new SMS_Schedule__c();
        smsScheduleObj2.Contact__c = conObj2.id;
        smsScheduleObj2.Lead__c = leadObj2.id;
        smsScheduleObj2.LiveText_Number__c = ltNumberObj.id;
        smsScheduleObj2.Message__c = 'Test Message2';
        smsScheduleObj2.Object_Id__c = accObj2.id;
        smsScheduleObj2.Reference_Id__c = '12345';
        myDT = Datetime.now();
        smsScheduleObj2.Schedule_Date__c = myDT.addDays(2);
        smsScheduleObj2.To_Phone_Number__c = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        insert smsScheduleObj2;
        List<AggregateResult> counter = [select Count(id) from SMS_Schedule__c];
    }
    
    static testmethod void queueMessages_Test(){
        setUp();
        Test.startTest();
        QueueItemRequest qirObj = new QueueItemRequest();
        qirObj.ScheduledItemId = smsScheduleObj.id;
        QueueItemRequest qirObj2 = new QueueItemRequest();
        qirObj2.ScheduledItemId = smsScheduleObj2.id;
        List<QueueItemRequest> qtr = new List<QueueItemRequest>();
        for(integer i=0;i<30;i++) {
            qtr.add(qirObj);
        }
        for(integer i=0;i<30;i++) {
            qtr.add(qirObj2);
        }   
        List<ActionResult> ltaResultListObj;
        
        ltaResultListObj = QueueMessageAction.queueMessages(qtr);
        System.assert(!ltaResultListObj.isEmpty());
        Test.stopTest();
    }
    
    static testmethod void queueItem_Test(){
        setUp();
        Test.startTest();
        ScheduleItem schItemObj = new ScheduleItem();
        schItemObj.ObjectId = conObj.id; 
        schItemObj.ToPhoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        schItemObj.LiveTextNumber = ltNumberObj.Number__c;
        ActionResult ltaResultListObj;
        ltaResultListObj = QueueMessageAction.queueItem(schItemObj);
        System.assert(ltaResultListObj!= null);
        Test.stopTest();
    }

}