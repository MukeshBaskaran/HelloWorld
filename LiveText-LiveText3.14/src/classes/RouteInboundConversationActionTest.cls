@isTest
public with sharing class RouteInboundConversationActionTest { 
	static List<RoutableInboundItem> items;
    static LiveText_Number__c ltNumberObj;
    static ITR_Message__c msg;
     static User adminUser;
    
    static void createAdminUser(){
    	adminUser = UnitTestObjectBuilder.createAdminUser();
    	insert adminUser;
    }
    
    static testmethod void initTestData(){ 
     	
        ltNumberObj = UnitTestObjectBuilder.createLiveTextNumber();
        ltNumberObj.Number__c = Util.NormalizePhoneNumber(ltNumberObj.Number__c);
        insert ltNumberObj;
    	
    	msg = new ITR_Message__c();
        msg.Originating_Number__c = '+12125551212';
	  	msg.LiveText_Number__c = ltNumberObj.Id;
		msg.Is_Within_Business_Hours__c = false;
		msg.HTML_Transcript__c = '';
		msg.Text_Transcript__c = '';		
        insert msg;
        
        items = new List<RoutableInboundItem>();
        RoutableInboundItem item = new RoutableInboundItem();
        item.ObjectId = msg.Id;
        items.add(item);
    }
  
 	static testMethod void Test_RouteInboundConversations(){
    	createAdminUser();
    	system.runAs(adminUser){
    		Test.startTest();
	        initTestData();
	        RouteInboundConversationAction.routeConversations(items);
	        Test.stopTest();
    	}
    }
  
  
  static testMethod void Test_RouteInboundConversation(){
    	createAdminUser();
    	system.runAs(adminUser){
    		Test.startTest();
	        initTestData();
	        RouteInboundConversationAction.routeConversation(items[0]);
	        Test.stopTest();
    	}
    }
  
    
}