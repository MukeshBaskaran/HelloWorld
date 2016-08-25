@isTest
public with sharing class SetMessageStatusActionTest {

    static Contact conObj;
    static Account accObj;
    static Lead leadObj;
    static LiveText_Number__c ltNumberObj;
    static SMS_Message__c smsMessageObj;
    static User adminUser;  
    
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
        
        smsMessageObj = new SMS_Message__c();
        smsMessageObj.Account__c = accObj.id;
        smsMessageObj.Contact__c = conObj.id;
        smsMessageObj.Error_Message__c = 'Test Error Message';
        smsMessageObj.Lead__c = leadObj.id;
        smsMessageObj.LiveText_Number__c = ltNumberObj.id;
        smsMessageObj.Message__c = 'Test Message';
        smsMessageObj.Object_Id__c = accObj.id;
        smsMessageObj.Message_Status__c = 'Queued';
        smsMessageObj.To_Phone_Number__c = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        insert smsMessageObj;
    }
    
    
    
    static testMethod void setMessagesStatus_Test(){
        setUp();
        Test.startTest();
        SetMessageStatusRequest statusReqObj = new SetMessageStatusRequest();
        statusReqObj.MessageId = smsMessageObj.Id;
        statusReqObj.MessageStatus='Queued';
        statusReqObj.ErrorMessage = 'Test Error Message';
        
        List<ActionResult> results;
        
        results = SetMessageStatusAction.setMessagesStatus(new List<SetMessageStatusRequest>{statusReqObj});
        
        System.assert(!results.isEmpty());
        Test.stopTest();
    }

    static testMethod void setMessagesStatus_Test_Negative(){
        setUp();
        Test.startTest();
        SetMessageStatusRequest statusReqObj = new SetMessageStatusRequest();
        statusReqObj.MessageId = null;
        statusReqObj.MessageStatus='Queued';
        statusReqObj.ErrorMessage = 'Test Error Message';
        
        List<ActionResult> results;
        
        results = SetMessageStatusAction.setMessagesStatus(new List<SetMessageStatusRequest>{statusReqObj});
        
        System.assert(results.get(0).ErrorMessage.contains('Message id not specified'));
        Test.stopTest();
    }

}