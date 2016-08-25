public with sharing class SMSTextTriggerHandler extends TriggerManager.TriggerHandler {
    
   private Semaphore sem = new Semaphore(constant.SEMAPHORE_SMS_TEXT_TRIGGER_HANDLER);

   /**
    * @description Checks if new sms text is received within business hours or not. If not then 
    *               sends the offline hours message to customer and sets the text session header to offline.
    * @param List of new SMS text records.
    * @param Map of new SMS text records.
    */
   public override void onAfterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordsMap) {
        if(Constant.on_after_insert_smstext_trg == true){
            Constant.on_after_insert_smstext_trg = false;
            afterInsertUpdate((List<SMS_Text__c>) newRecords, (Map<Id, SMS_Text__c>) newRecordsMap, null);
            sem.Release();
        }
    }
    
    /**
     * @description Associate the existing conversation header with incoming SMS Text record
     *              -- Create new conversation header if not found and associate it with the incoming SMS Text
     * @param List of new SMS text records.
     */
    public override void onBeforeInsert(List<SObject> newRecords){
        if(sem.Acquire()){
            if (Constant.on_before_insert_smstext_trg == true) {
                Constant.on_before_insert_smstext_trg = false;
                beforeInsert((List<SMS_Text__c> ) newRecords);
            }
        }
    }
    
    private String getKey(SMS_Text__c sms){
        return sms.Originating_Number__c + '-' + sms.Support_Number__c;
    }
    
    private String getKey(Conversation_Header__c ch){
        return ch.Originating_Number__c + '-' + ch.Support_Number__c;
    }
    
    private void beforeInsert(List<SMS_Text__c> newSmsTexList){
        try {
            SMSTextListRoutingInfo routingInfo = null;
            Map<String, List<SMS_Text__c>> smsWithoutConvHeaderMap = new Map<String, List<SMS_Text__c>>();
            Boolean triggerExecutionEnabled = false;
            LiveTextGlobalSettings__c gblSettings = Util.getLiveTextGlobalSettings();
            List<Conversation_Header__c> newConversationHeaderList = new List<Conversation_Header__c>();
            Map<String, Id> smsOriginSupportToConversationHeader = new Map<String, Id>();
            
            Map<String,Datetime> conversationHeaderTimeMap = new Map<String,Datetime>();
            List<Conversation_Header__c> updateStatusToNewList = new List<Conversation_Header__c>();
            Map<String,Conversation_Header__c> updateChHeaderStatusNewMap = new Map<String,Conversation_Header__c>();
            Map<String,Datetime> smsTextTimeMap = new Map<String,Datetime>();
            Map<String,SMS_Text__c> smsTextMap = new Map<String,SMS_Text__c>();
            Set<String> smsSupportNumbers = new Set<String>();
            
            if(gblSettings != null){
                if(gblSettings.GlobalTriggerExecutionEnabled__c != null){
                    triggerExecutionEnabled = gblSettings.GlobalTriggerExecutionEnabled__c;
                }
            }
            if(triggerExecutionEnabled){
                // Create set of incoming SMS Originiating Numbers to limit SOQL query
                Set<String> smsOriginatingNumbers = new Set<String>();
                for(SMS_Text__c sms : newSmsTexList){
                    smsOriginatingNumbers.add(sms.Originating_Number__c);
                    //LT-1274 smsTextTimeMap is the map that contains sms orginating number and support number and the time of the sms
                    smsSupportNumbers.add(sms.Support_Number__c);
                    if(sms.Source__c == 'LiveText'){
                        smsTextTimeMap.put(getKey(sms),System.now());
                        smsTextMap.put(getKey(sms),sms);
                    }
                }
                //Lt-1274
                //Get the configured text session reuse time from LiveTextNumer__C object
                Map<String,Integer> reuseTimeMap = new Map<String,Integer>();
                Integer maxReuseTime = 0; 
                for(LiveText_Number__c l : [SELECT ID,Number__c,Text_Session_Reuse_Time_seconds__c FROM LiveText_Number__c WHERE Id IN :smsSupportNumbers]){
                    if(l.Text_Session_Reuse_Time_seconds__c != null){
                        //Map that contains live text number id and its associated reuse time
                        reuseTimeMap.put(l.Id,Integer.valueOf(l.Text_Session_Reuse_Time_seconds__c));
                        maxReuseTime = Math.max(maxReuseTime, Integer.valueOf(l.Text_Session_Reuse_Time_seconds__c));
                    }
                }
                if(!newSmsTexList.isEmpty()){
                    // process smstext records whose conversation Id is null and has possibility of matching Support_Number__c and Originating_Number__c
                    // with existing conversations header record.
                    for(Conversation_Header__c ch : [SELECT Status__c, Originating_Number__c, Support_Number__c,MessagePreview__c
                                                        FROM Conversation_Header__c 
                                                        WHERE Status__c != :Constant.stage_ended 
                                                            AND Status__c != :Constant.stage_offline 
                                                            AND Originating_Number__c IN :smsOriginatingNumbers 
                                                        ORDER BY LastModifiedDate DESC
                                                        LIMIT 1000]){
                        smsOriginSupportToConversationHeader.put(getKey(ch), ch.Id);
                    }
                    if(!smsTextTimeMap.isEmpty() && maxReuseTime > 0){
                        //Lt-1274 Get the recently ended conversation headers of the day
                        Set<Conversation_Header__c> distinctChList = new Set<Conversation_Header__c>();
                        Map<String,String> timeMap = new Map<String,String>();
                        Map<String,Conversation_Header__c> conversationMap = new Map<String,Conversation_Header__c>();
                        for(Conversation_Header__c rechl : [SELECT Status__c, Originating_Number__c, Support_Number__c,MessagePreview__c,EndedTime__c,ConversationReopened__c
                                                                FROM Conversation_Header__c
                                                                WHERE Status__c = :Constant.stage_ended 
                                                                    AND Originating_Number__c IN :smsOriginatingNumbers 
                                                                    AND Support_Number__c IN :smsSupportNumbers 
                                                                    AND EndedTime__c > :System.Now().addSeconds(-maxReuseTime) 
                                                                    AND ConversationReopened__c = :false
                                                                ORDER BY LastModifiedDate DESC, Originating_Number__c ASC
                                                                LIMIT 10000]){

                            conversationHeaderTimeMap.put(getKey(rechl), rechl.EndedTime__c);
                            timeMap.put(getKey(rechl),rechl.Support_Number__c);
                            conversationMap.put(getKey(rechl),rechl);
                        }
                        
                        for(String cht : conversationHeaderTimeMap.keySet()){
                            Date conversationDate = conversationHeaderTimeMap.get(cht).date();
                            Date smsTextDate = smsTextTimeMap.get(cht).date();
                            if(smsTextDate.isSameDay(conversationDate)){
                                Long seconds = (smsTextTimeMap.get(cht).getTime() - conversationHeaderTimeMap.get(cht).getTime())/1000;
                                if(seconds <= reuseTimeMap.get(timeMap.get(cht))){
                                    if(smsOriginSupportToConversationHeader.get(cht) == null){
                                        smsOriginSupportToConversationHeader.put(cht, conversationMap.get(cht).Id);
                                        //filtering the recently ended conversation list based on the configures reuse time.
                                        distinctChList.add(conversationMap.get(cht));
                                    }
                                }
                            }
                        }
                        if(!distinctChList.isEmpty()){
                            //Reopening the conversation header; distinctChList has no nulls
                            for(Conversation_Header__c ch : distinctChList){
                                ch.Status__c = Constant.stage_new;
                                String smsMessage = smsTextMap.get(getKey(ch)).Message__c;
                                if(!String.isBlank(smsMessage)){
                                    if(smsMessage.length() >= 255){
                                        ch.MessagePreview__c = smsMessage.substring(0,255);
                                    }else{
                                        ch.MessagePreview__c = smsMessage;
                                    }
                                }
                                ch.ConversationReopened__c = true;
                                ch.SessionReopenedTime__c = system.now();
                                ch.AcceptedBy__c = null;
                                updateStatusToNewList.add(ch);
                                updateChHeaderStatusNewMap.put(getKey(ch),ch);        
                            }
                        }
                    }

                    List<Conversation_Header__c> updateMessagePreview = new List<Conversation_Header__c>();
                    Set<Id> chIdtoRetrieve = new Set<Id>();
                    for(SMS_Text__c sms : newSmsTexList){
                        Id chId = smsOriginSupportToConversationHeader.get(getKey(sms));
                        if(chId != null){
                            sms.Conversation_Header__c = chId;
                            if(!String.isBlank(sms.Message__c)){
                                if(!chIdtoRetrieve.contains(chId)){
                                    Conversation_Header__c chl = [SELECT Id, MessagePreview__c FROM Conversation_Header__c WHERE Id =:chId];
                                    String inboundMessage = String.valueOf(sms.Message__c);
                                    if(!String.isBlank(inboundMessage) && inboundMessage.length()>=255 && sms.Source__c =='LiveText'){
                                        chl.MessagePreview__c = inboundMessage.substring(0,255);
                                    }
                                    if(!String.isBlank(inboundMessage) && inboundMessage.length()<255 && sms.Source__c =='LiveText'){
                                        chl.MessagePreview__c = inboundMessage;
                                    }
                                    updateMessagePreview.add(chl);
                                    chIdtoRetrieve.add(chId);
                                }
                            }
                        }else if(sms.Source__c == Constant.live_text) { 
                            // Only for incoming SMS Text we need to create new Conversation header
                            // If Conversation header is not found then create the new conversation header
                            String phNoCombination = getKey(sms);
                            //check if we reopened conversation
                            if(updateChHeaderStatusNewMap.get(phNoCombination) == null){
                                List<SMS_Text__c> smsList = smsWithoutConvHeaderMap.get(phNoCombination);
                                if(smsList == null || smsList.isEmpty()){
                                    smsList = new List<SMS_Text__c>();
                                    smsList.add(sms);
                                }else{
                                    smsList.add(sms);
                                }
                                smsWithoutConvHeaderMap.put(phNoCombination, smsList);
                            }
                        }
                    }

                    if(!updateMessagePreview.isEmpty()){
                        AccessController.upsertAsSystem(updateMessagePreview);
                    }

                    if(!smsWithoutConvHeaderMap.isEmpty()){
                        //get routing info only if needed
                        routingInfo = new SMSTextListRoutingInfo(newSmsTexList);
                        for(String phNoCombination : smsWithoutConvHeaderMap.keySet()){
                            List<SMS_Text__c> smsList = smsWithoutConvHeaderMap.get(phNoCombination);
                            //Lt-1274
                            if(smsList != null && !smsList.isEmpty() && updateChHeaderStatusNewMap.get(phNoCombination) == null){
                                //create new conversation if it's ok to route
                                Boolean okToRoute =  routingInfo.isOkToRoute(smsList.get(0));
                                if(okToRoute){
                                    Conversation_Header__c convObj = new Conversation_Header__c();
                                    convObj.Originating_Number__c = smsList.get(0).Originating_Number__c;
                                    convObj.Support_Number__c = smsList.get(0).Support_Number__c;
                                    convObj.Status__c = Constant.stage_new;
                                    convObj.ConversationType__c = Constant.ConversationType.Inbound.name();
                                    convObj.SessionReopenedTime__c = System.now();
                                    if(!String.isBlank(smsList.get(0).Message__c)){
                                        if(String.valueOf(smsList.get(0).Message__c).length() >= 255){
                                            convObj.MessagePreview__c = String.valueOf(smsList.get(0).Message__c).substring(0,255);
                                        }else{
                                            convObj.MessagePreview__c = String.valueOf(smsList.get(0).Message__c);
                                        }
                                    }
                                    newConversationHeaderList.add(convObj);
                                }
                            }
                        }
                    }
                }
              
                if(!newConversationHeaderList.isEmpty()){
                    AccessController.insertAsSystem(newConversationHeaderList);
                    for(Conversation_Header__c ch : newConversationHeaderList){
                        if(ch != null){
                            String phNoCombination = getKey(ch);
                            List<SMS_Text__c> smsList = smsWithoutConvHeaderMap.get(phNoCombination);
                            for(SMS_Text__c sms : smsList){
                                sms.Conversation_Header__c = ch.Id;
                            }
                        }
                    }
                }
             
                if(!updateStatusToNewList.isEmpty()){
                    AccessController.updateAsSystem(updateStatusToNewList);
                    for(Conversation_Header__c ch : updateStatusToNewList){
                        if(ch != null){
                            String phNoCombination = getKey(ch);
                            SMS_Text__c s = smsTextMap.get(phNoCombination);
                            s.Conversation_Header__c = ch.Id;
                        }
                    }
                }
            }
        } catch (exception e) {
            Util.insertException(Constant.sms_text_obj + Constant.before_insert, Constant.priority_high, e.getMessage() + ', Line number: ' + e.getLineNumber());
        }
    }
    
    private void handleITR(List<SMS_Text__c> newSmsTexList, Map<Id,Boolean> SMSTextBusinessHourValidationMap) {
        try {
            SMSTextListRoutingInfo routingInfo = new SMSTextListRoutingInfo(newSmsTexList);             
            Map<String, List<SMS_Text__c>> smsWithoutConvHeaderMap = new Map<String, List<SMS_Text__c>>();
            Set<String> orginatingPhNoList = new Set<String>();
            Set<String> orginatingNoList = new Set<String>();
            Set<String> supportPhNoList = new Set<String>();
            Set<Id> supportPhNoIdList = new Set<Id>();
            for (SMS_Text__c sms: newSmsTexList) {
                // Only for incoming SMS Text or ITR with no conversation header 
                if((sms.Source__c == Constant.live_text || sms.Source__c == Constant.ITR || sms.Source__c == Constant.permission_marketing) && sms.Conversation_Header__c == null) {
                    String phNoCombination = getKey(sms);
                    List<SMS_Text__c> smsList = smsWithoutConvHeaderMap.get(phNoCombination);
                    if(smsList == null || smsList.isEmpty()){
                        smsList = new List<SMS_Text__c>();
                        smsList.add(sms);
                    }else{
                        smsList.add(sms);
                    }
                    smsWithoutConvHeaderMap.put(phNoCombination, smsList);
                }
              
            }
            Map<Id,String> ltnPhoneMap = new Map<Id,String>();
            for(LiveText_Number__c ltn : [SELECT Id, Number__c FROM LiveText_Number__c]){
                ltnPhoneMap.put(ltn.Id,ltn.Number__c);
            }
            for(String phNoCombination : smsWithoutConvHeaderMap.keySet()) {
                List<SMS_Text__c> smsList = smsWithoutConvHeaderMap.get(phNoCombination);
                if(smsList != null && !smsList.isEmpty()){
                    for(SMS_Text__c sms : smsList) {
                        if(!orginatingPhNoList.contains(sms.Originating_Number__c)){
                            orginatingPhNoList.add(Util.NormalizePhoneNumber(sms.Originating_Number__c));
                            orginatingNoList.add(sms.Originating_Number__c);
                        }
                        
                        String supportNo = ltnPhoneMap.get(sms.Support_Number__c);
                        if(!String.isBlank(supportNo) && !supportPhNoList.contains(supportNo)){
                            supportPhNoList.add(supportNo);
                            supportPhNoIdList.add(sms.Support_Number__c);
                        }
                    }
                }
            }

            Map<String,Id> recentCampaignPhoneMap = new Map<String,Id>();
            List<Recent_Campaign_Send_Member__c> recentCampaignList = new List<Recent_Campaign_Send_Member__c>();
            for(Recent_Campaign_Send_Member__c rcsm :[SELECT Id,CampaignSendMember__c,CampaignSendMember__r.FromNumber__c,CampaignSendMember__r.Phone__c
                                                        FROM Recent_Campaign_Send_Member__c 
                                                        WHERE CampaignSendMember__r.FromNumber__c IN: supportPhNoList 
                                                            AND CampaignSendMember__r.Phone__c IN: orginatingPhNoList
                                                        LIMIT 50000]){
                recentCampaignPhoneMap.put(rcsm.CampaignSendMember__r.FromNumber__c +'->'+ rcsm.CampaignSendMember__r.Phone__c,rcsm.CampaignSendMember__c);
            }

            Map<Id, Set<Id>> ltNumberToAvaliableAgentsMap = Util.getAvailableAgentsMap();
            Map<String,Decimal> ltnOptinStatusMap = Util.getOptInStatus(supportPhNoIdList, orginatingNoList);
            Map<String,ITR_Message__c> existingMsgsMap = new Map<String,ITR_Message__c>();
            for(ITR_Message__c msg : [SELECT Id, HTML_Transcript__c, Mo_Message_Counter__c, Available_Agents__c,LiveText_Number__c,Originating_Number__c,Message__c
                                        FROM ITR_Message__c 
                                        WHERE Originating_Number__c IN: orginatingNoList 
                                            AND  LiveText_Number__c IN: supportPhNoIdList
                                        ORDER BY LastModifiedDate DESC NULLS FIRST LIMIT 50000]){
                existingMsgsMap.put(msg.LiveText_Number__c + '->' + msg.Originating_Number__c,msg);
            }
            for(String phNoCombination : smsWithoutConvHeaderMap.keySet()){
                List<SMS_Text__c> smsList = smsWithoutConvHeaderMap.get(phNoCombination);
                if(smsList != null && !smsList.isEmpty()){
                    handleITRMessagesForSingleConversation(routingInfo, smsList, SMSTextBusinessHourValidationMap,recentCampaignPhoneMap,ltnPhoneMap,ltNumberToAvaliableAgentsMap,ltnOptinStatusMap,existingMsgsMap);
                }
            } 
        } catch (exception e) {
            Util.insertException(Constant.sms_text_obj + Constant.after_insert, Constant.priority_high, e.getMessage());
        }
    }
    
    private void handleITRMessagesForSingleConversation(SMSTextListRoutingInfo routingInfo, List<SMS_Text__c> smsList, Map <Id, Boolean> SMSTextBusinessHourValidationMap,Map<String,ID> recentCampaignPhoneMap,Map<Id,String> ltnPhoneMap,Map<Id, Set<Id>> ltNumberAvaliableAgentsMap,Map<String,Decimal>ltnOptinStatusMap,Map<String,ITR_Message__c> existingMsgsMap){

        if(smsList != null && smsList.size() > 0){
            Map<Id, Set<Id>> ltNumberToAvaliableAgentsMap = new Map<Id, Set<Id>>();
            ltNumberToAvaliableAgentsMap = ltNumberAvaliableAgentsMap;
            SMS_Text__c firstMsg = smsList[0];
            Decimal optInStatus;
            String num = firstMsg.Support_Number__c + '->' + firstMsg.Originating_Number__c;
            if(ltnOptinStatusMap!=null){
                optInStatus = ltnOptinStatusMap.get(firstMsg.Support_Number__c + '->' + firstMsg.Originating_Number__c);
            }
            String msgOptInStatus = null;
            if(optInStatus != null){
                 msgOptInStatus = optInStatus == 1 ? '1' : '0';
            }

            List<ITR_Message__c> existingMsgs = new List<ITR_Message__c>();
            ITR_Message__c msg = new ITR_Message__c();
            String transcript = '';

            if(existingMsgsMap !=null && existingMsgsMap.containsKey(num)) {
                msg = existingMsgsMap.get(num);
                transcript = msg.HTML_Transcript__c;
            }else{
                msg = null;
                transcript = '';
            }
            transcript = Util.createITRTranscript(transcript, smsList);
            PhoneNumberRelatedObjects relatedObjects = null;
            try{
                relatedObjects = new PhoneNumberRelatedObjects(firstMsg.Support_Number__c, firstMsg.Originating_Number__c);
            }
            catch(Exception ex){
                Util.insertException('handleITRMessagesForSingleConversation', constant.priority_high, ex.getMessage());
            }
            for(SMS_Text__c sms : smsList){
                Boolean isWithinBusinessHours = SMSTextBusinessHourValidationMap.get(sms.Id);
                if(msg == null && sms.Source__c == Constant.live_text){
                    msg = new ITR_Message__c();
                    msg.Originating_Number__c = firstMsg.Originating_Number__c;
                    msg.LiveText_Number__c = firstMsg.Support_Number__c;
                    msg.Is_Within_Business_Hours__c = isWithinBusinessHours;
                    msg.HTML_Transcript__c = transcript;
                    msg.Text_Transcript__c = Util.convertTranscriptToPlainText(transcript);
                    if(msg.Mo_Message_Counter__c == null){
                        msg.Mo_Message_Counter__c = 0;
                    }
                    msg.Mo_Message_Counter__c = msg.Mo_Message_Counter__c+1;
                    List<Id> temp = new List<Id>();
                    if(ltNumberToAvaliableAgentsMap.containsKey((Id) firstMsg.Support_Number__c)){
                        temp.addAll(ltNumberToAvaliableAgentsMap.get((Id) firstMsg.Support_Number__c));
                    }
                    msg.Available_Agents__c = temp.size();
                   
                    AccessController.insertAsSystem(new List<ITR_Message__c>{msg});              
                }
                
                if(msg != null){
                    if(sms.Source__c == Constant.live_text){
                    	msg.Campaign_Send_Member__c = null;
                    	if(recentCampaignPhoneMap != null) {
                        	if(firstMsg.Originating_Number__c != null) {
                            	String pnoKey =ltnPhoneMap.get(firstMsg.Support_Number__c) +'->'+ firstMsg.Originating_Number__c; 
                            	if(recentCampaignPhoneMap.containsKey(pnoKey)) {
                                	msg.Campaign_Send_Member__c = recentCampaignPhoneMap.get(pnoKey);
                            	}
                        	}
                    	}
                    
                        msg.Message__c = sms.Message__c;
                        msg.Opt_In_Status__c = msgOptInStatus;
                        msg.Is_Within_Business_Hours__c = isWithinBusinessHours;
                        if(relatedObjects != null){
                            try{
                                if(relatedObjects.HasItems){
                                    Map<String, String> relationshipObjectApiNameToFieldNameMap = new Map<String, String>();
                                    Map<String, Schema.SObjectField> fieldMap = msg.getSObjectType().getDescribe().fields.getMap();
                                    for(String field : fieldMap.keySet()){
                                        if(fieldMap.get(field).getDescribe().getRelationshipName() != null && fieldMap.get(field).getDescribe().isCustom()){
                                            relationshipObjectApiNameToFieldNameMap.put(fieldMap.get(field).getDescribe().getReferenceTo().get(0).getDescribe().getName(), field);
                                        }
                                    }
                                    for(String relationshipName : Util.getAllRelationshipObjects(msg.getSObjectType().getDescribe().getName())){
                                        msg.put(relationshipObjectApiNameToFieldNameMap.get(relationshipName), PhoneNumberRelatedObjects.getMRMItem(relatedObjects.CustomObjects, fieldMap.get(relationshipObjectApiNameToFieldNameMap.get(relationshipName)).getDescribe().getReferenceTo().get(0).getDescribe().getName()));
                                    }
                                }
                            }
                            catch(Exception ex){
                                Util.insertException('handleITRMessagesForSingleConversation', constant.priority_high, ex.getMessage());
                            } 
                        }
                    }
                    msg.HTML_Transcript__c = transcript;
                    msg.Text_Transcript__c = Util.convertTranscriptToPlainText(transcript);
                    if(msg.Mo_Message_Counter__c == null){
                        msg.Mo_Message_Counter__c = 0;
                    }
                    msg.Mo_Message_Counter__c = msg.Mo_Message_Counter__c+1;
                    List<Id> temp = new List<Id>();
                    if(ltNumberToAvaliableAgentsMap.containsKey((Id) firstMsg.Support_Number__c)){
                        temp.addAll(ltNumberToAvaliableAgentsMap.get((Id) firstMsg.Support_Number__c));
                    }
                    msg.Available_Agents__c = temp.size();
                    AccessController.updateAsSystem(new List<ITR_Message__c>{msg});
                } 
            }
        }
    }         
        
    /**
     * @description
     * @param
     * @return void
     */
    private void afterInsertUpdate(List<SMS_Text__c> newRecords, Map<Id, SMS_Text__c> newSmsTextMap, Map<Id, SMS_Text__c> oldSmsTextMap) {
        try {
            Map<Id, SMS_Text__c> referenceSmsTextMap = new Map<Id, SMS_Text__c> ();
            referenceSmsTextMap = newSmsTextMap.clone();
            Map<Id, SMS_Text__c> filteredSmsTextMap = new Map<Id, SMS_Text__c> ();
            Map<Id, Boolean> SMSTextBusinessHourValidationMap = Util.isWithinBusinessHours(newSmsTextMap.values());
            Map<Id, Id> smsConversationHeaderMap = new Map<Id, Id>();
            List<Id> conversationHeaderIdList = new List<Id>();
            
            handleITR(newRecords, SMSTextBusinessHourValidationMap);
            
            // identify if smstext record's source is LiveText.
            // because we need to send them out of business hours message, if message is sent out of business hours.
            for (SMS_Text__c sms : newSmsTextMap.values()){
                if (sms.Source__c == Constant.live_text){
                    filteredSmsTextMap.put(sms.Id, sms);
                    smsConversationHeaderMap.put(sms.Id, sms.Conversation_Header__c);
                }
            }
    
            // We don't want to create conversation header records out of SMSText records if 
            // SMSText records are created outside of business hours. so remove those Id's from original
            // map been passed (newSmsTextMap)
            Map<Id, SMS_Text__c> offlineConversationHeaderMap = new Map<Id, SMS_Text__c>();
            
            for (Id smsTextId : SMSTextBusinessHourValidationMap.KeySet()) {
                // check if conversation header is in offline hours
                if (!SMSTextBusinessHourValidationMap.get(smsTextId)) {
                    offlineConversationHeaderMap.put(smsTextId,referenceSmsTextMap.get(smsTextId));
                    referenceSmsTextMap.remove(smsTextId);
                    conversationHeaderIdList.add(smsConversationHeaderMap.get(smsTextId));
                }
            }
            
            if (!offlineConversationHeaderMap.isEmpty()) {
               // process SMS Texts that came in outside of business hours
               // update conversation header with status of off_line
                List<Conversation_Header__c> chList = [SELECT Id, Status__c, Support_Number__r.Notify_Users_During_Off_Hours__c FROM Conversation_Header__c WHERE Id IN :conversationHeaderIdList];
                if (chList != null && !chList.isEmpty()) {
                    for(Conversation_Header__c ch: chList) {
                        //LT-1166 for itr disabled
                        if(ch.Support_Number__r.Notify_Users_During_Off_Hours__c || ch.Status__c == Constant.stage_active){
                            if(!(ch.Status__c == Constant.stage_ended) && !(ch.Status__c == Constant.stage_active)){
                                ch.Status__c = Constant.stage_new;
                                ch.SessionReopenedTime__c = system.now();

                            }
                        }else{
                            ch.Status__c = Constant.stage_offline;
                        }
                    }
                    AccessController.updateAsUser(chList);
                }
            }
        } catch (exception e) {
            Util.insertException(Constant.conversation_header_obj + Constant.after_insert, Constant.priority_high, e.getMessage());
        }
    }
}