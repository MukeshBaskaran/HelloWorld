@isTest
public with sharing class DeleteMessageActionTest {

    static Contact conObj;
    static Account accObj;
    static Lead leadObj;
    static LiveText_Number__c ltNumberObj;
    static SMS_Schedule__c smsScheduleObj;
    
    static testmethod void setUp() {
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
        smsScheduleObj.Reference_Id__c = '00Qj000000Ja9nqEAC';
        Datetime myDT = Datetime.now();
        smsScheduleObj.Schedule_Date__c = myDT.addDays(1);
        smsScheduleObj.To_Phone_Number__c = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        insert smsScheduleObj;
    }
    
    static testMethod void DeleteMessages_Test() {
        setUp();
        Test.startTest();
        DeleteSmsScheduleItem delSchItemObj = new DeleteSmsScheduleItem();
        delSchItemObj.ObjectId = accObj.id;
        delSchItemObj.ReferenceId = '00Qj000000Ja9nqEAC';
        
        List<ActionResult> results;
        
        results = DeleteMessageAction.DeleteSmsScheduleMessages(new List<DeleteSmsScheduleItem>{delSchItemObj});
        
        System.assert(!results.isEmpty());
        
        Test.stopTest();
    }
    
}