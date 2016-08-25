@isTest
private class PostInstallHandlerTest {

    static testMethod void PostInstallHandler_Test() {

        PostInstallHandler postinstall = new PostInstallHandler();
        Test.testInstall(postinstall, null);
        LiveTextGlobalSettings__c ltgs = LiveTextGlobalSettings__c.getOrgDefaults();
        System.assertEquals(ltgs.GlobalTriggerExecutionEnabled__c, true, 'LiveTextGlobalSettings record created');
        List<String> pushTopicNames = new List<String>{constant.conversation_header_push_topic_Test, constant.sms_text_push_topic_Test};
        List<PushTopic> topic = [SELECT Id, Name FROM PushTopic WHERE Name IN:pushTopicNames];
        System.assertEquals(topic.size(), 2, 'PushTopic  found');
        ConfigurationSettings__c confSettings = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
        system.assert(confSettings != null);
    }

    static testMethod void UninstallScriptHandler_Test() {
        UninstallScriptHandler uninstall = new UninstallScriptHandler();
        Test.testUninstall(uninstall);
    }

    static testMethod void migrateNewTabSettings_Test(){
        Test.startTest();

        LiveText_Number__c l = new LiveText_Number__c();
        l.Show_New_Account_Tab__c = false;
        l.Show_New_Contact_Tab__c = true;
        l.Show_New_Lead_Tab__c = true;
        l.Show_New_Case_Tab__c = true;
        l.Show_New_Opportunity_Tab__c = true;
        l.Number__c = '1234567890';
        l.Name = 'testlabel';
        Insert l;
        PostInstallHandler postinstall = new PostInstallHandler();
        Test.testInstall(postinstall, new version(3,6),true);
        List<LiveText_Number__c> ltnObjects = Database.query('SELECT Id, Show_New_Account_Tab__c, Show_New_Contact_Tab__c, Show_New_Lead_Tab__c, Show_New_Case_Tab__c,Show_New_Opportunity_Tab__c, New_Custom_Objects_Tabs__c FROM LiveText_Number__c Where Show_New_Account_Tab__c=true OR Show_New_Contact_Tab__c=true OR Show_New_Lead_Tab__c=true OR Show_New_Case_Tab__c=true OR Show_New_Opportunity_Tab__c=true');
        system.assertEquals(ltnObjects[0].New_Custom_Objects_Tabs__c,'Contact;Lead;Case;Opportunity;');
        Test.stopTest();
    }

    static testMethod void setPhoneNumbersActivities_Test(){
        Test.startTest();
        LiveText_Number__c l = new LiveText_Number__c();
        l.CreateEvent__c = false;
        l.CreateTask__c = true;
        l.Number__c = '1234567890';
        l.Name = 'testlabel';
        Insert l;
        PostInstallHandler postinstall = new PostInstallHandler();
        Test.testInstall(postinstall, new version(3,4),true);
        List<LiveText_Number__c> ltnObjects = Database.query('SELECT Id, CreateEvent__c, CreateTask__c FROM LiveText_Number__c');
        system.assertEquals(ltnObjects[0].CreateEvent__c,false);
        system.assertEquals(ltnObjects[0].CreateTask__c,true);

        Test.stopTest();
    }
    
    
}