@isTest
public with sharing class ScheduleMessageActionTest {

    static Contact conObj;
    static Account accObj;
    static Lead leadObj;
    static LiveText_Number__c ltNumberObj;
    static SMS_Schedule__c smsScheduleObj;
    
    static testmethod void setUp(){
        conObj = new Contact(LastName='John',FirstName='John');
        conObj.mobilephone = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        insert conObj;
        accObj = new Account(Name='Test Acc Name');
        accObj.phone = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        insert accObj;
        leadObj = new Lead(LastName='Test Lead Last Name',company='Test Lead Company');
        leadObj.phone = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
        insert leadObj;
        ltNumberObj = UnitTestObjectBuilder.createLiveTextNumber();

        ltNumberObj.Number__c = Util.NormalizePhoneNumber(ltNumberObj.Number__c);
        
        insert ltNumberObj;
        
        smsScheduleObj = new SMS_Schedule__c();
        smsScheduleObj.Contact__c = conObj.id;
        smsScheduleObj.Lead__c = leadObj.id;
        smsScheduleObj.LiveText_Number__c = ltNumberObj.id;
        smsScheduleObj.Message__c = 'Test Message';
        smsScheduleObj.Object_Id__c = accObj.id;
        smsScheduleObj.Reference_Id__c = '12345';
        Datetime myDT = Datetime.now();
        smsScheduleObj.Schedule_Date__c = myDT.addDays(1);
        smsScheduleObj.To_Phone_Number__c = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        insert smsScheduleObj;
    }
    
    static testMethod void scheduleMessages_Test(){
        setUp();
        Test.startTest();
        ScheduleItem schItemObj = new ScheduleItem();
        schItemObj.ObjectId = conObj.id; 
        schItemObj.ToPhoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        schItemObj.LiveTextNumber = ltNumberObj.Number__c;
        
        List<ActionResult> results;
        
        results = ScheduleMessageAction.scheduleMessages(new List<ScheduleItem>{schItemObj});
        
        System.assert(!results.isEmpty());
        
        Test.stopTest();
    }
    
     static testMethod void scheduleMessages_BasedOnObject_Test(){
        setUp();
        Test.startTest();
        ScheduleItem schItemObj = new ScheduleItem();
        schItemObj.ObjectId = conObj.id; 
        schItemObj.LiveTextNumber = ltNumberObj.Number__c;
        schItemObj.SetPhoneNumberBasedOnObject();
        
        List<ActionResult> results;
        
        results = ScheduleMessageAction.scheduleMessages(new List<ScheduleItem>{schItemObj});
        
        System.assert(!results.isEmpty());
        System.assert(schItemObj.EventObject == null);
        System.assert(schItemObj.EventId == null);
        System.assert(schItemObj.IsAlterScheduleBasedOnReferenceId == false);
        
        Test.stopTest();
    }
    
    static testMethod void scheduleMessages_setOtherObjectPhoneNumber_Test(){
        setUp();
        Test.startTest();
        ScheduleItem schItemObj = new ScheduleItem();
        schItemObj.ObjectId = conObj.id; 
        schItemObj.LiveTextNumber = ltNumberObj.Number__c;
        schItemObj.ToPhoneNumber = ScheduleItem.getOtherObjectPhoneNumber(conObj.id);
        
        List<ActionResult> results;
        
        results = ScheduleMessageAction.scheduleMessages(new List<ScheduleItem>{schItemObj});
        
        System.assert(!results.isEmpty());
        
        Test.stopTest();
    }

 	
    static testMethod void scheduleMessages_Test_parameters(){
        setUp();
        Test.startTest();
        String liveTextNumber = ltNumberObj.Number__c;
        List<Id> objectIds = new List<Id>{conObj.Id,accObj.Id,leadObj.Id};
        String message = 'test';
        String referenceId = '12345';
        Datetime schDate = Datetime.now();

        List<ActionResult> results;
        
        results = ScheduleMessageAction.scheduleMessages(liveTextNumber,objectIds,message,referenceId,schDate);
        
        System.assert(!results.isEmpty());
        
        Test.stopTest();
    }
    
    
    static testMethod void scheduleMessage_Test(){
        setUp();
        Test.startTest();
        ScheduleItem schItemObj = new ScheduleItem();
        schItemObj.ObjectId = conObj.id; 
        schItemObj.ToPhoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        
        ActionResult result;
        
        result = ScheduleMessageAction.scheduleMessage(schItemObj);
        
        System.assert(result.ErrorMessage.contains('LiveText phone number '));

        Test.stopTest();
    }

    static testMethod void scheduleMessage_Test_NoReferenceId(){
        setUp();
        Test.startTest();
        ScheduleItem schItemObj = new ScheduleItem();
        schItemObj.ObjectId = conObj.id; 
        schItemObj.ToPhoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        schItemObj.LiveTextNumber = ltNumberObj.Number__c;
        schItemObj.ReferenceId = '';
        schItemObj.ScheduleDate = Datetime.now();
        
        ActionResult result;
        
        result = ScheduleMessageAction.scheduleMessage(schItemObj);
        
        System.debug('result object is'+ result);
        
        System.assert(result.ErrorMessage.contains('ReferenceId is required for scheduled sends.'));

        Test.stopTest();
    }
    
    static testMethod void scheduleMessage_Test_Positive(){
        setUp();
        Test.startTest();
        ScheduleItem schItemObj = new ScheduleItem();
        schItemObj.ObjectId = conObj.id; 
        schItemObj.ToPhoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        schItemObj.LiveTextNumber = ltNumberObj.Number__c;
        schItemObj.ReferenceId = '12345';
        schItemObj.ScheduleDate = Datetime.now();
        
        ActionResult result;
        
        result = ScheduleMessageAction.scheduleMessage(schItemObj);
        System.assert(result!=null);

        Test.stopTest();
    }
    
}