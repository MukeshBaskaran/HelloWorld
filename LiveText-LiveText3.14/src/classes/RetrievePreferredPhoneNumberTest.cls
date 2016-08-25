@isTest
public with sharing class RetrievePreferredPhoneNumberTest {

    
    static String ToPhoneNumber,ToPhoneNumber2,ToPhoneNumber3,ToPhoneNumber4;
    static ITR_Message__c msg,msg1,msg2,msg3;
    static User adminUser;
    static LiveText_Number__c ltNumberObj;
    
    static void createAdminUser(){
        adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
    }
    
    static testmethod void initTestData(){
        ltNumberObj = UnitTestObjectBuilder.createLiveTextNumber();
        ltNumberObj.Number__c = Util.NormalizePhoneNumber(ltNumberObj.Number__c);
        insert ltNumberObj;
        
        msg = new ITR_Message__c();
        msg.Originating_Number__c = '+1 (212) 555-1212';
        msg.LiveText_Number__c = ltNumberObj.Id;
        msg.Is_Within_Business_Hours__c = false;
        msg.HTML_Transcript__c = '';
        msg.Text_Transcript__c = '';        
        insert msg;

        msg1 = new ITR_Message__c();
        msg1.Originating_Number__c = '+1 (212) 555-1212';
        msg1.LiveText_Number__c = ltNumberObj.Id;
        msg1.Is_Within_Business_Hours__c = false;
        msg1.HTML_Transcript__c = '';
        msg1.Text_Transcript__c = '';        
        insert msg1;

        msg2 = new ITR_Message__c();
        msg2.Originating_Number__c = '+1 (212) 555-1212';
        msg2.LiveText_Number__c = ltNumberObj.Id;
        msg2.Is_Within_Business_Hours__c = false;
        msg2.HTML_Transcript__c = '';
        msg2.Text_Transcript__c = '';        
        insert msg2;

        msg3 = new ITR_Message__c();
        msg3.Originating_Number__c = '+1 (212) 555-1212';
        msg3.LiveText_Number__c = ltNumberObj.Id;
        msg3.Is_Within_Business_Hours__c = false;
        msg3.HTML_Transcript__c = '';
        msg3.Text_Transcript__c = '';        
        insert msg3;

       
    }

    static testMethod void Test_RetrievePhoneNumber(){
        createAdminUser();
        system.runAs(adminUser){
            Test.startTest();
            initTestData();
            ToPhoneNumber = RetrievePrefferedPhoneNumber.getToPhoneNumberFromObject(msg.Id);
            ToPhoneNumber = RetrievePreferredPhoneNumber.getToPhoneNumberFromObject(msg.Id);
            ToPhoneNumber2 = RetrievePreferredPhoneNumber.getToPhoneNumberFromObject(msg1.Id);
            ToPhoneNumber3 = RetrievePreferredPhoneNumber.getToPhoneNumberFromObject(msg2.Id);
            ToPhoneNumber4 = RetrievePreferredPhoneNumber.getToPhoneNumberFromObject(msg3.Id);
            system.assertEquals(ToPhoneNumber,'');
            
            RetrievePrefferedPhoneNumber.DummyTest();
            Test.stopTest();
        }
    }

}