@isTest
public with sharing class UpdateITRMessageActionTest { 
    static List<UpdateInboundItem> items;
    static LiveText_Number__c ltNumberObj;
    static ITR_Message__c msg;
    static Contact ct;
    static User adminUser;
    
    static void createAdminUser(){
        adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
    }
    
    static testmethod void initTestData(){ 
        
        ltNumberObj = UnitTestObjectBuilder.createLiveTextNumber();
        ltNumberObj.Number__c = Util.NormalizePhoneNumber(ltNumberObj.Number__c);
        insert ltNumberObj;
         
        ct = new Contact(LastName='John',FirstName='John',mobilephone = '+1 (212) 555-1212');
        insert ct;

        msg = new ITR_Message__c();
        msg.Originating_Number__c = '+1 (212) 555-1212';
        msg.LiveText_Number__c = ltNumberObj.Id;
        msg.Is_Within_Business_Hours__c = false;
        msg.HTML_Transcript__c = '';
        msg.Text_Transcript__c = '';        
        insert msg;

        
        items = new List<UpdateInboundItem>();
        UpdateInboundItem item = new UpdateInboundItem();
        item.ObjectId = msg.Id;
        item.QueueName = 'testQueue';
        item.ITRContext = 'sales';
        items.add(item);
    }
  
    static testMethod void Test_UpdateITRMessageAction(){
        createAdminUser();
        system.runAs(adminUser){
            Test.startTest();
            initTestData();
            UpdateITRMessageAction.updateITRMessages(items);
            Test.stopTest();
        }
    }
  
    
}