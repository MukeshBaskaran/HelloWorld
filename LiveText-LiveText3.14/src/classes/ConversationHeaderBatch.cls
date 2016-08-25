/**
* @author        Santosh Gudge
* @company       Comity Designs
* @date          08.20.2014
* @description   This class is used for batch Apex and changing Conversation Header Record Status
*/
global with sharing class ConversationHeaderBatch implements Database.Batchable < sObject > , Database.AllowsCallouts { 
    private static final String[] STATUS_TYPES = new String[] {
        Constant.stage_new, Constant.stage_active, Constant.stage_offline
    };

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String stageField = Conversation_Header__c.Status__c.getDescribe().getName();
        String ConversationHeaderObjectName = Conversation_Header__c.SObjectType.getDescribe().getName();
        String elapsedTimeField = Conversation_Header__c.ElapsedTime__c.getDescribe().getName();
        String endChatMessageField = Conversation_Header__c.End_Chat_Message__c.getDescribe().getName();
        return  Database.getQueryLocator('SELECT Id, CreatedDate , ' + stageField + ', ' + endChatMessageField + ', ' + elapsedTimeField + ' From ' +
                ConversationHeaderObjectName + ' WHERE ' + stageField + ' IN:STATUS_TYPES');
    }

    global void execute(Database.BatchableContext BC, List < sObject > scope) {
        try {
            List < Conversation_Header__c > conversationHeaderNewList = new List < Conversation_Header__c > ();
            List < Conversation_Header__c > conversationHeaderActiveList = new List < Conversation_Header__c > ();
            List < Conversation_Header__c > conversationHeaderOfflineList = new List < Conversation_Header__c > ();
            Set < Id > conversationIdSet = new Set < Id > ();
            Map < Id, List < SMS_Text__c >> conversationHeaderSMSTextMap = new Map < Id, List < SMS_Text__c >> ();
            Integer configActiveHours = 48;
            Integer configNewHours = 1;
            Integer configOfflineHours = 1;
            LiveTextGlobalSettings__c gblSettings = Util.getLiveTextGlobalSettings();
            if (gblSettings != null) {
                if (gblSettings.Active_Status_Purge_Hours__c != null) {
                    configActiveHours = integer.valueOf(gblSettings.Active_Status_Purge_Hours__c);
                }
                if (gblSettings.New_Status_Purge_Hours__c != null) {
                    configNewHours = integer.valueOf(gblSettings.New_Status_Purge_Hours__c);
                }
                if (gblSettings.Offline_Status_Purge_Hours__c != null) {
                    configOfflineHours = integer.valueOf(gblSettings.Offline_Status_Purge_Hours__c);
                }
            }
            List<Id> conversationHeaderIds = new List<Id>();
            for(Sobject s: scope){
                conversationHeaderIds.add(s.id);
            }
            Map<Id, Conversation_Header__c> conversationHeaderMap = new Map<Id, Conversation_Header__c>([SELECT Id, Status__c,EndedTime__c,Transcript_Summary_1__c FROM Conversation_Header__c WHERE Id In :conversationHeaderIds]);
            Map < Id, List<SMS_Text__c> > sMSTextRecordMap = new Map < Id, List<SMS_Text__c> >();
            sMSTextRecordMap = LiveTextChatController.getSMSTextRecordMap(conversationHeaderIds); 
            DateTime endDateTime = DateTime.now();
            for (SObject s: scope){ 
                Conversation_Header__c ch = (Conversation_Header__c) s;
                integer hours = Integer.valueOf((ch.ElapsedTime__c / 3600));
                if ((ch.Status__c == Constant.stage_new && hours >= configNewHours) || (ch.Status__c == Constant.stage_active && hours >= configActiveHours)|| (ch.Status__c == Constant.stage_offline && hours >= configOfflineHours)) {
                    try {
                        if(ch.Id!=null){
                            String convHeaderStatus = ch.Status__c; 
                            if(sMSTextRecordMap.get(ch.Id)!=null && sMSTextRecordMap.get(ch.Id).size()>0){
                                Map < Id, List < SMS_Text__c >> conversationHeaderSMSTextMapToDelete = new Map < Id, List < SMS_Text__c >> ();
                                conversationHeaderSMSTextMapToDelete.put(ch.Id,sMSTextRecordMap.get(ch.Id));
                                if(!conversationHeaderSMSTextMapToDelete.isEmpty()){
                                    Util.createTranscript(conversationHeaderSMSTextMapToDelete,endDateTime);
                                    // delete sms text records.
                                    Util.smsTextCalloutForEndChat(sMSTextRecordMap.get(ch.Id),ch.Id);
                                }
                                convHeaderStatus = Constant.stage_ended;
                                Util.updateEvents(ch.Id, endDateTime);
                            }
                            else {
                                System.debug('NO RECORDS');
                            }
                        }
                        else{
                            System.debug('Conversation not found!: '  + ch.Id);
                        }
                    }
                    catch (exception ex) {
                        Util.insertException('Error occured while ending chat session', constant.priority_high, ex.getMessage());          
                    } 
                }
                else {
                    System.debug('End Chat called with status ' + ch.Status__c);
                } 
            }  
            
        } 
        catch (exception ex) {
                   Util.insertException('Conversation Header Batch failure.', constant.priority_high, ex.getMessage());
        }
    }
    global void finish(Database.batchableContext info) {}
}