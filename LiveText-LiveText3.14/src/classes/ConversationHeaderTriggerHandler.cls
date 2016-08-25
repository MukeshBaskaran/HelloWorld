/**
 * @author         Santosh Gudge(santosh@comitydesigns.com)
 * @date           08.05.2014
 * @description    ConversationHeaderTriggerHandler class handles CRUD logic for Conversation_Header__c trigger
 *                 in LiveText for Salesforce application
*/

public with sharing class ConversationHeaderTriggerHandler extends TriggerManager.TriggerHandler  { 
    
    public override void onAfterUpdate(List < sObject > newRecords, Map < ID, SObject > newRecordsMap, Map < ID, SObject > oldRecordsMap) {
        if (Constant.on_after_update_conversationheader_trg == true) { 
            Constant.on_after_update_conversationheader_trg = false;
            afterUpdate((Map < Id, Conversation_Header__c > ) newRecordsMap, (Map < Id, Conversation_Header__c > ) oldRecordsMap);
            Constant.on_after_update_conversationheader_trg = true;
        }
        
    } 

    /**
     * @description Sets the static flag to true indicating that the after insert is executed.
     * @param List of newRecords, null
     * @ruturn null
    */
    public override void onAfterInsert(List <sObject> newRecords, Map<ID, sObject> newRecordsMap) {
        if(Constant.on_after_insert_conversationheader_trg == true) {
            Constant.on_after_insert_conversationheader_trg = false;
            afterInsert((List<Conversation_Header__c>) newRecords, (Map<Id,Conversation_Header__c>)newRecordsMap);
        }
    }

    public override void onBeforeInsert(List <sObject> newRecords){
        if(Constant.on_before_insert_conversationheader_trg == true) {
            Constant.on_before_insert_conversationheader_trg = false;
            beforeInsert((List<Conversation_Header__c>) newRecords);
        }
    }

    /**
     * @description  Check if conversations during offline hours are available
     * @param List of Conversation Headers for which the initial sms should be sent.
     * @return void 
     */  
    private void beforeInsert(List<Conversation_Header__c> convHeaderRecords) {
        List<Id> phoneNumbersId = new List<Id>();
        for(Conversation_Header__c ch : convHeaderRecords) {
            phoneNumbersId.add(ch.Support_Number__c);
        }
        Map<Id, LiveText_Number__c> phoneNubers = new Map<Id, LiveText_Number__c>([SELECT Id, Notify_Users_During_Off_Hours__c FROM LiveText_Number__c]);
        for(Conversation_Header__c ch : convHeaderRecords) {
            if(ch.Support_Number__c != null) {
                if(phoneNubers.get(ch.Support_Number__c).Notify_Users_During_Off_Hours__c && ch.Status__c == Constant.stage_offline) {
                    ch.Status__c = Constant.stage_new;
                }
            }
        }
    }


    /**
     * @description  Sends the initial conversation header message to the customer
     * @param List of Conversation Headers for which the initial sms should be sent.
     * @return void 
     */  
    private void afterInsert(List<Conversation_Header__c> convHeaderRecords, Map <Id, Conversation_Header__c> newConversationHeaderMap) {
        //TODO: Logic to send the Initial SMS record
        System.debug('##### Current message in conversation header after insert trigger ######');
        Util.sendInitialMessage(newConversationHeaderMap.keySet());
        handleOfflineConversationHeaders(newConversationHeaderMap);
    }

    private void handleOfflineConversationHeaders(Map <Id, Conversation_Header__c> newConversationHeaderMap){
        List<SMS_Text__c> smsEndChatList = new List<SMS_Text__c>();
        for (Conversation_Header__c ch: newConversationHeaderMap.values()) {
            if (ch.Status__c == Constant.stage_offline) {
                SMS_Text__c smsEndChat = new SMS_Text__c();
                smsEndChat.Conversation_Header__c = ch.Id;
                smsEndChat.Message__c = ch.Offline_Hours_Message__c;
                smsEndChat.Originating_Number__c = ch.Originating_Number__c;
                smsEndChat.Support_Number__c = ch.Support_Number__c;
                smsEndChat.Source__c = Constant.salesforce;
                smsEndChatList.add(smsEndChat);
            }
        } 
        if (!smsEndChatList.isEmpty()) {
            AccessController.insertAsUser(smsEndChatList);
            // Make callout to send SMS to end users
            List<Id> smsendChatIds = new List<ID>();
            for (SMS_Text__c sms: smsEndChatList) {
                smsendChatIds.add(sms.Id);
            }
            Util.smsTextCallout(smsendChatIds);
        }
    }


    /**
     * @description  takes new and old map of Conversation_Header__c records.
     * @param Map < Id, Conversation_Header__c > newMap,Map < Id, Conversation_Header__c > OldMap
     * @return void 
    */  
    private void afterUpdate(Map < Id, Conversation_Header__c > newConversationHeaderMap, Map < Id, Conversation_Header__c > oldConversationHeaderMap) {
        try {
            // If status is off-line then
            // a. insert end chat sms message to this
            //b. make callout
            List<Event> eventList = new List<Event>();
            List<Task> taskList = new List<Task>();
            List<Event> eventList2 = new List<Event>();
            List<Task> taskList2 = new List<Task>();
            Map<Id, Conversation_Event__c> conversationEventMap = new Map<Id, Conversation_Event__c>();
            Map<Id, Conversation_Event__c> conversationTaskMap = new Map<Id, Conversation_Event__c>();
            List<Conversation_Event__c> conversationEventList = new List<Conversation_Event__c>();        
            Map<Id, Conversation_Header__c> linkMap = new Map<Id, Conversation_Header__c>();
            Map<Id, Id> unlinkMap = new Map<Id, Id>();
            Map<Id, Id> linkIdUpdateMap = new Map<Id, Id>();        
            Map<Id, Id> linkUpdateMap = new Map<Id, Id>();
            Map<Id, LiveText_Number__c> liveTextNumberMap = new Map<Id, LiveText_Number__c>([SELECT Id, CreateTask__c, CreateEvent__c FROM LiveText_Number__c]);
            List<String> linkItemRelationshipList = new List<String>();
            //to change if we start support multi object linking
            linkItemRelationshipList = Util.getRelationshipMapForConversationHeader().values();
            //get all object api names for which activities can be created
            Set<String> objectsWithActivitiesEnabled = new Set<String>();
            for (Schema.SObjectType objectType : Task.WhatId.getDescribe().getReferenceTo()) {
               objectsWithActivitiesEnabled.add(String.valueOf(objectType));
            }
            handleOfflineConversationHeaders(newConversationHeaderMap);
            for(Conversation_Header__c ch : oldConversationHeaderMap.values()) {
                if(!linkItemRelationshipList.isEmpty()){
                    for(String item:linkItemRelationshipList){
                        if (ch.get(item) != newConversationHeaderMap.get(ch.Id).get(item)){
                            if(ch.get(item) == null)//create a new event
                                linkMap.put((Id)newConversationHeaderMap.get(ch.Id).get(item), newConversationHeaderMap.get(ch.Id));
                            else if(newConversationHeaderMap.get(ch.Id).get(item) == null)//unlink the old event
                                unlinkMap.put((Id)ch.get(item), ch.Id);
                            else { //create a copy of the event, unlink/delete the old event 
                                linkIdUpdateMap.put((Id)ch.get(item), (Id)newConversationHeaderMap.get(ch.Id).get(item));
                                linkUpdateMap.put((Id)ch.get(item), ch.Id);
                            }
                        }
                    }
                }       
            }

            String objectType = '';
            //if old value was null create new events
            if(!linkMap.isEmpty()){
                for(Id id : linkMap.keySet()) {
                    objectType = id.getSObjectType().getDescribe().getName();
                    Conversation_Header__c c = linkMap.get(id); 
                    Conversation_Event__c ce = new Conversation_Event__c();
                    ce.Conversation_Header__c = c.Id;
                    ce.Linked_Object__c = id;
                    conversationEventMap.put(id, ce);
                    ce = new Conversation_Event__c();
                    ce.Conversation_Header__c = c.Id;
                    ce.Linked_Object__c = id;
                    conversationTaskMap.put(id, ce);                
                    if(liveTextNumberMap.get(c.Support_Number__c).CreateEvent__c) {
                        Event e = new Event();
                        e.OwnerId = UserInfo.getUserId(); 
                        e.Subject = 'Text Session';
                        e.StartDateTime = c.CreatedDate;
                        e.EndDateTime = c.CreatedDate;
                        e.IsReminderSet = false;        
                        if(Constant.LEAD_OBJECT.equals(id.getSObjectType().getDescribe().getName()) || Constant.CONTACT_OBJECT.equals(id.getSObjectType().getDescribe().getName()))
                            e.WhoId = id;
                        else
                            e.WhatId = id;
                        //check to see if the event is being created after the conversation has ended
                        if(c.Transcript_Summary_1__c != null)
                            e.Description =  Util.convertTranscriptToPlainText(c.Transcript_Summary_1__c);
                        eventList.add(e);
                    }
                    if(liveTextNumberMap.get(c.Support_Number__c).CreateTask__c) {
                        Task t = new Task();
                        t.OwnerId = UserInfo.getUserId();
                        t.Subject = 'Text Session';
                        t.IsReminderSet = false;
                        t.ActivityDate = Date.newinstance(c.CreatedDate.year(), c.CreatedDate.month(), c.CreatedDate.day());
                        t.Status = 'Completed';//required
                        t.Priority = 'Normal';//required
                        if(Constant.LEAD_OBJECT.equals(id.getSObjectType().getDescribe().getName()) || Constant.CONTACT_OBJECT.equals(id.getSObjectType().getDescribe().getName()))
                            t.WhoId = id;
                        else
                            t.WhatId = id;
                        if(c.Transcript_Summary_1__c != null)
                            t.Description =  Util.convertTranscriptToPlainText(c.Transcript_Summary_1__c);
                        taskList.add(t);
                    }
                }
                if(!eventList.isEmpty())
                    AccessController.insertAsUser(eventList);
                if(!taskList.isEmpty())
                    AccessController.insertAsUser(taskList);
                for(Event e : eventList) {
                    Conversation_Event__c ce = null;
                    if(e.WhoId != null) {
                        ce = conversationEventMap.get(e.WhoId);
                        ce.Event__c = e.Id;
                    } else if (e.WhatId != null) {
                        ce = conversationEventMap.get(e.WhatId);
                        ce.Event__c = e.Id;
                    }
                    conversationEventList.add(ce);  
                }
                for(Task t : taskList) {
                    Conversation_Event__c ce = null;
                    if(t.WhoId != null) {
                        ce = conversationTaskMap.get(t.WhoId);
                        ce.Event__c = t.Id;
                    } else if (t.WhatId != null) {
                        ce = conversationTaskMap.get(t.WhatId);
                        ce.Event__c = t.Id;
                    }
                    conversationEventList.add(ce);
                }
                if(!conversationEventList.isEmpty())    
                    AccessController.insertAsUser(conversationEventList);
            }
            
            //if copying from one object to another
            if(!linkIdUpdateMap.isEmpty() && !linkUpdateMap.isEmpty()) { 
                //event links to update/events to delete
                conversationEventList = [   SELECT Event__c, Linked_Object__c          
                                            FROM Conversation_Event__c 
                                            WHERE (Linked_Object__c IN:linkUpdateMap.keySet()) AND (Conversation_Header__c IN:linkUpdateMap.values())
                                        ];  

                List<Id> activityIds = new List<Id>();
                for(Conversation_Event__c ce : conversationEventList){
                    activityIds.add(ce.Event__c);
                }
                if(!activityIds.isEmpty()) {
                    //check for associated events
                    //old events to copy to new ones/delete
                    eventList = [   SELECT  OwnerId, Description, Subject, StartDateTime, EndDateTime, IsReminderSet, WhatId, WhoId         
                                    FROM Event 
                                    WHERE Id IN :activityIds
                                ];
                    taskList = [    SELECT OwnerId, Subject, Description, Status, WhatId, WhoId, Priority
                                    FROM Task
                                    WHERE Id IN :activityIds
                                ];
                }   
                if(!eventList.isEmpty()) {     
                    for(Event e : eventList) {
                        Event e2 = new Event();
                        e2.OwnerId = UserInfo.getUserId();
                        e2.Subject = e.Subject;
                        e2.StartDateTime = e.StartDateTime;
                        e2.EndDateTime = e.EndDateTime;
                        e2.IsReminderSet = e.IsReminderSet;
                        e2.Description = e.Description;         
                        //first check the WhoId
                        Id id = e.WhoId;
                        if(id != null) {
                            objectType = id.getSObjectType().getDescribe().getName();
                            e2.WhoId = linkIdUpdateMap.get(e.WhoId);  
                        }
                        else {
                            id = e.WhatId;
                            if(id != null)   
                                e2.WhatId = linkIdUpdateMap.get(e.WhatId);
                        }                       
                        eventList2.add(e2);
                    }             
                    AccessController.insertAsUser(eventList2);//insert the new events              
                    AccessController.deleteAsUser(eventList);//delete the old events                
                }
                if(!taskList.isEmpty()){     
                    for(Task t : taskList){
                        Task t2 = new Task();
                        t2.OwnerId = UserInfo.getUserId();
                        t2.Status = t.Status;
                        t2.Priority = t.Priority;
                        t2.Description = t.Description;
                        t2.Subject = t.Subject;
                        
                        //first check the WhoId
                        Id id = t.WhoId;
                        if(id != null){
                            objectType = id.getSObjectType().getDescribe().getName();
                                t2.WhoId = linkIdUpdateMap.get(t.WhoId);  
                        }else{
                            id = t.WhatId;
                            if(id != null)   
                                t2.WhatId = linkIdUpdateMap.get(t.WhatId);
                        }                       
                        taskList2.add(t2);
                    }               
                    AccessController.insertAsUser(taskList2);//insert the new events               
                    AccessController.deleteAsUser(taskList);//delete the old events             
                }
                            
                List<Conversation_Event__c> updateCEList = new List<Conversation_Event__c>();
                for(Conversation_Event__c c : conversationEventList){
                    //update the linked object id
                    Id newId = linkIdUpdateMap.get(c.Linked_Object__c);
                    c.Linked_Object__c = newId;
                    updateCEList.add(c);                
                }
                    
                List<Conversation_Event__c> updateCEList2 = new List<Conversation_Event__c>();
                for(Event ev : eventList2) {
                    Id id = null;
                    if(ev.WhoId != null)
                        id = ev.WhoId;
                    else if (ev.WhatId != null) 
                        id = ev.WhatId;
                    for(Conversation_Event__c ce : updateCEList){
                        //update the event id
                        if(id == ce.Linked_Object__c && ce.Event__c.startsWithIgnoreCase('00U')){
                            ce.Event__c = string.valueOf(ev.Id);
                            updateCEList2.add(ce); 
                        }               
                    }           
                }
                for(Task t : taskList2) {
                    Id id = null;
                    if(t.WhoId != null)
                        id = t.WhoId;
                    else if (t.WhatId != null) 
                        id = t.WhatId;
                    for(Conversation_Event__c ce : updateCEList){
                        //update the event id
                        if(id == ce.Linked_Object__c && ce.Event__c.startsWithIgnoreCase('00T')){
                            ce.Event__c = string.valueOf(t.Id);
                            updateCEList2.add(ce); 
                        }               
                    }           
                }
                
                if(!updateCEList2.isEmpty()) {  
                    AccessController.updateAsUser(updateCEList2);//update the links
                }
                   
            }
            
            //if new value is null 
            if(!unlinkMap.isEmpty()) {
                for(Id id : unlinkMap.keySet()) {
                    //check for associated conversation events 
                    conversationEventList = [   SELECT Event__c 
                                                FROM Conversation_Event__c 
                                                WHERE (Linked_Object__c IN:unlinkMap.keySet()) AND (Conversation_Header__c IN:unlinkMap.values())
                                            ];              
                }
                List<Id> activityIds = new List<Id>();
                for(Conversation_Event__c ce : conversationEventList) {
                    activityIds.add(ce.Event__c);
                }
                List<SObject> activitiesToDelete = new List<SObject>();
                if(!activityIds.isEmpty()) {
                    //check for associated events
                    eventList = [   SELECT Id 
                                    FROM Event 
                                    WHERE Id IN :activityIds
                                ];  
                    taskList = [    SELECT Id 
                                    FROM Task
                                    WHERE Id IN :activityIds
                                ];
                    activitiesToDelete.addAll( (List<SObject>) eventList);
                    activitiesToDelete.addAll( (List<SObject>) taskList);
                }

                if(!activitiesToDelete.isEmpty()) {
                    AccessController.deleteAsUser(conversationEventList);            
                    AccessController.deleteAsUser(activitiesToDelete);
                }
                
            }
        }
        catch(Exception ex) {
             System.debug('after update trigger ' +  ex.getMessage()); 
             System.debug('after update trigger ' +  ex.getLineNumber()); 
        }   
    }
}