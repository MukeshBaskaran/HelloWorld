@isTest 
private class ConversationHeaderBatchTest {
    private static Conversation_Header__c m_ConversationHeader = null;
    private static SMS_Text__c m_SMSText = null;
    private static LiveTextGlobalSettings__c m_LiveTextGlobalSettings = null;
  
    private static void SetUp() {
        LiveTextGlobalSettings__c ltgs = LiveTextGlobalSettings__c.getInstance(UserInfo.getOrganizationId());
        if (ltgs.SetupOwnerId == null) {
            insert new LiveTextGlobalSettings__c(GlobalTriggerExecutionEnabled__c = true, Active_Status_Purge_Hours__c =0,
            New_Status_Purge_Hours__c =0, Offline_Status_Purge_Hours__c =0,
            SetupOwnerId = UserInfo.getOrganizationId());
        }
    }
 
    static testMethod void ConversationHeaderBatch_Test() {
        test.StartTest();
        SetUp() ;
        LiveText_Number__c LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
        insert LiveTextNumber;
        
        Conversation_Header__c conversationHeaderNew = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,LiveTextNumber.Id);
        conversationHeaderNew.Status__c = Constant.stage_active;
        insert conversationHeaderNew;
        System.assertNotEquals(conversationHeaderNew.Id, null);

        Conversation_Header__c conversationHeaderActive = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber +'1',LiveTextNumber.Id);
        conversationHeaderActive.Status__c = Constant.stage_new;
        insert conversationHeaderActive;
        System.assertNotEquals(conversationHeaderActive.Id, null);

        Conversation_Header__c conversationHeaderOffline = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber+'2',LiveTextNumber.Id);
        conversationHeaderOffline.Status__c = Constant.stage_offline;
        insert conversationHeaderOffline;
        System.assertNotEquals(conversationHeaderOffline.Id, null);
          
        SMS_Text__c SMSTextSourceLiveText = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, conversationHeaderNew.Id);
        SMSTextSourceLiveText.Source__c = constant.live_text;
        insert SMSTextSourceLiveText;
        System.assertNotEquals(SMSTextSourceLiveText.Id, null);
           
        SMS_Text__c SMSTextSourceLiveText2 = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, conversationHeaderActive.Id);
        SMSTextSourceLiveText2.Source__c = constant.live_text;
        insert SMSTextSourceLiveText2;
        System.assertNotEquals(SMSTextSourceLiveText2.Id, null);
      
        SMS_Text__c SMSTextSourceLiveText3 = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, conversationHeaderOffline.Id);
        SMSTextSourceLiveText3.Source__c = constant.live_text;
        insert SMSTextSourceLiveText3;
        System.assertNotEquals(SMSTextSourceLiveText3.Id, null);
      
        SMS_Text__c SMSTextSourceSalesforce = UnitTestObjectBuilder.CreateSMSTextRecord(LiveTextNumber, conversationHeaderNew.Id);
        SMSTextSourceSalesforce.Source__c = constant.salesforce;
        insert SMSTextSourceSalesforce;
        System.assertNotEquals(SMSTextSourceSalesforce.Id, null);
       
        ConversationHeaderBatch chs = new ConversationHeaderBatch();
        Database.executeBatch(chs); 
        test.StopTest();
    }
}