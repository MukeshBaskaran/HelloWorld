@isTest
public with sharing class ConversationHeaderTriggerHandlerTest {
    private static Conversation_Header__c m_ConversationHeader = null;
    private static SMS_Text__c m_SMSText = null;
    private static LiveTextGlobalSettings__c m_LiveTextGlobalSettings = null;
    private static Case objCaseOne = null;
    private static Case objCaseTwo = null;
    private static Account objAccountOne = null;
    private static Account objAccounttwo = null;    
    private static Contact objContactOne = null;
    private static Contact objContactTwo = null;    
    private static Lead objLeadOne = null;
    private static Lead objLeadTwo = null;  
    private static Opportunity objOppOne = null;
    private static Opportunity objOppTwo = null;    
    private static Sobject ltnObject = null;
    private static void SetUp() {
        m_LiveTextGlobalSettings = new LiveTextGlobalSettings__c();
        m_LiveTextGlobalSettings.GlobalTriggerExecutionEnabled__c = true;
        m_LiveTextGlobalSettings.Active_Status_Purge_Hours__c =0;
        insert m_LiveTextGlobalSettings;
        System.assertNotEquals(m_LiveTextGlobalSettings.Id, null);
        
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        ltnObject.put('CreateEvent__c',true);
        ltnObject.put('CreateTask__c', true);
        insert ltnObject;
        System.assertNotEquals(ltnObject.Id, null);
        
        objAccountOne = UnitTestObjectBuilder.CreateAccount(Constant.OriginatingNumber);
        insert objAccountOne; 
        
        objAccountTwo = UnitTestObjectBuilder.CreateAccount(Constant.OriginatingNumber);
        insert objAccountTwo;
        
        objCaseOne = new Case();
        insert objCaseOne;
        
        objCaseTwo = new Case();
        insert objCaseTwo;
        
        objContactOne = UnitTestObjectBuilder.CreateContact(objAccountOne.Id, Constant.OriginatingNumber);
        insert objContactOne;
        
        objContactTwo = UnitTestObjectBuilder.CreateContact(objAccountTwo.Id, Constant.OriginatingNumber);
        insert objContactTwo;
        
        objLeadOne = UnitTestObjectBuilder.CreateLead(Constant.OriginatingNumber);
        insert objLeadOne;
        
        objLeadTwo = UnitTestObjectBuilder.CreateLead(Constant.OriginatingNumber);
        insert objLeadTwo;
        
        objOppOne = UnitTestObjectBuilder.CreateOpportunity(objAccountOne.id);
        insert objOppOne;
        
        objOppTwo = UnitTestObjectBuilder.CreateOpportunity(objAccountTwo.id);
        insert objOppTwo;
     }
     
    static testMethod void Test_afterUpdate() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        
        Test.startTest();
        conversationHeader.status__c = Constant.stage_offline;
        update conversationHeader;
        List<SMS_Text__c> smsList = [select sms.id,sms.Message__c,sms.Conversation_Header__c from SMS_Text__c sms where sms.Conversation_Header__c =: conversationHeader.id];
        if (!smsList.isEmpty()) {
            system.assertEquals(1, smsList.size());
        }
        Test.stopTest();
    }
    
    static testMethod void Test_afterUpdate_Acc_Linked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Account__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Account__c = objAccountOne.Id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id
                                                ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Acc_Unlinked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        insert conversationHeader;
        Id accObj = conversationHeader.Account__c;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Account__c = null;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [  SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id
                                                            AND ce.Linked_Object__c = :accObj
                                                ];
        System.assert(ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Acc_Change() {

        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Account__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Account__c = objAccountOne.id;
        update conversationHeader;
        Constant.on_after_update_conversationheader_trg = true; 
        conversationHeader.Account__c = objAccountTwo.id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =   [    SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :objAccountOne.id
                                                ];
        System.assert(ceList.isEmpty());
        ceList =    [   SELECT Id 
                        FROM Conversation_Event__c ce 
                        WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :objAccountTwo.id
                    ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Case_Linked(){
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Case__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Case__c = objCaseOne.id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id
                                                ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }


    static testMethod void Test_afterUpdate_Case_Unlinked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        insert conversationHeader;
        Id caseId = conversationHeader.Case__c; 
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Case__c = null;
        update conversationHeader;
        List<Conversation_Event__c> ceList = [  SELECT Id 
                                                FROM Conversation_Event__c ce 
                                                WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :caseId
                                            ];
        System.assert(ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Case_Change() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Case__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Case__c = objCaseOne.Id;
        update conversationHeader;
        Constant.on_after_update_conversationheader_trg = true; 
        conversationHeader.Case__c = objCaseTwo.Id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c =:objCaseOne.Id
                                                ];
        System.assert(ceList.isEmpty());
        ceList =    [   SELECT Id 
                        FROM Conversation_Event__c ce 
                        WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c =:objCaseTwo.Id
                    ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }




    static testMethod void Test_afterUpdate_Contact_Linked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Contact__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Contact__c = objContactOne.Id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id
                                                ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Contact_Unlinked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        insert conversationHeader;
        Id conId = conversationHeader.Contact__c; 
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Contact__c = null;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id   
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :conId
                                                ];
        System.assert(ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Contact_Change() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Contact__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Contact__c = objContactOne.Id;
        update conversationHeader;
        Constant.on_after_update_conversationheader_trg = true;
        conversationHeader.Contact__c = objContactTwo.Id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c =:objContactOne.id
                                                ];
        System.assert(ceList.isEmpty());
        ceList =    [   SELECT Id 
                        FROM Conversation_Event__c ce 
                        WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c =:objContactTwo.id
                    ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Lead_Linked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Lead__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Lead__c = objLeadOne.Id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id
                                                ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Lead_Unlinked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        insert conversationHeader;
        Id leadId = conversationHeader.Lead__c;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Lead__c = null;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c =:leadId
                                                ];
        System.assert(ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Lead_Change() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Lead__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Lead__c = objLeadOne.Id;
        update conversationHeader;
        Constant.on_after_update_conversationheader_trg = true;
        conversationHeader.Lead__c = objLeadTwo.Id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :objLeadOne.Id
                                                ];
        System.assert(ceList.isEmpty());
        ceList =    [   SELECT Id 
                        FROM Conversation_Event__c ce 
                        WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :objLeadTwo.Id
                    ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Opportunity_Linked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Opportunity__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Opportunity__c = objOppOne.id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [   SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id
                                                ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Opportunity_Unlinked() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Opportunity__c = objOppOne.id;
        insert conversationHeader;
        Id leadId = conversationHeader.Opportunity__c;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Opportunity__c = null;
        update conversationHeader;
        List<Conversation_Event__c> ceList = [  SELECT Id 
                                                FROM Conversation_Event__c ce 
                                                WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c =:leadId
                                            ];
        System.assert(ceList.isEmpty());
        Test.stopTest();
    }

    static testMethod void Test_afterUpdate_Opportunity_Change() {
        setUp();
        Conversation_Header__c conversationHeader = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber,ltnObject.Id);
        conversationHeader.Opportunity__c = null;
        insert conversationHeader;
        System.assertNotEquals(conversationHeader.Id, null);
        SMS_Text__c smsTextObject = UnitTestObjectBuilder.CreateSMSTextRecord(ltnObject, conversationHeader.Id);
        insert smsTextObject;
        System.assertNotEquals(smsTextObject.Id, null);
        Test.startTest();
        conversationHeader.status__c = Constant.stage_active;
        conversationHeader.Opportunity__c = objOppOne.Id;
        update conversationHeader;
        Constant.on_after_update_conversationheader_trg = true;
        conversationHeader.Opportunity__c = objOppTwo.Id;
        update conversationHeader;
        List<Conversation_Event__c> ceList =    [  SELECT Id 
                                                    FROM Conversation_Event__c ce 
                                                    WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :objOppOne.Id
                                                ];
        System.assert(ceList.isEmpty());
        ceList  =   [   SELECT Id 
                        FROM Conversation_Event__c ce 
                        WHERE ce.Conversation_Header__c =: conversationHeader.id AND ce.Linked_Object__c = :objOppTwo.Id
                    ];
        System.assert(!ceList.isEmpty());
        Test.stopTest();
    }
    
}