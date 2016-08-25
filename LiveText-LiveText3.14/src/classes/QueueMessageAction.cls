/**
 * @description:    QueueMessageAction is used to queue a previously scheduled item for immediate delivery.
 *                  Queueing entails inserting the scheduled item into the SMS_Message table. 
 *                  This subsequently triggers a workflow that determines whether or not to actually send
 *                  the message. 
 */
 global class QueueMessageAction {
    
     /**
     * @description Queues the given scheduled items for immediate delivery and returns the status of each item.
      *     
     * @Param       List of scheduled items to queue for delivery.
     *
     * @Return      LiveText_ActionResult records for each item.
     **/ 
    @InvocableMethod(label='Queue Messages' description='Queues the given messages for delivery and returns the status of each item.')
    global static  List<ActionResult> queueMessages(List<QueueItemRequest> items) {
        List<ActionResult> results = new List<ActionResult>();
        results = queueMessage(items);
        return results;  
    }
      
     /**
     * @description Queues the given scheduled item for immediate delivery and returns the status of the item.
      *     
     * @Param       Scheduled item to queue for delivery.
     *
     * @Return      Results of queueing this item.
     **/   
    public static List<ActionResult> queueMessage(List<QueueItemRequest> requestItems) {
       List<ActionResult> results = new List<ActionResult>();
        List<Id> ids = new List<Id>();
        List<Id> liveTextNumbers = new List<Id>();
        List<SMS_Schedule__c> toPhoneNumbers = new List<SMS_Schedule__c>();
        for(QueueItemRequest requestItem :requestItems){
            ActionResult result = new ActionResult(requestItem.ScheduledItemId);
            if(requestItem == null){
                result.setError('Item does not exist.');
                results.add(result);
                return results;
            }
            ids.add(requestItem.ScheduledItemId);
            results.add(result);
        }
        
        
        List<SMS_Schedule__c> scheduleList = getScheduledItemList(ids);
        
        // retrieve current opt-in status between these 2 phone numbers
        Map<String,Decimal> optInStatusMap = Util.getOptInStatus(scheduleList);
        // Insert into SMS_Message table which will trigger a workflow to determine whether or not to actually send the message.

        List<SMS_Message__c> messagesList = new List<SMS_Message__c>();
        for(SMS_Schedule__c schedule : scheduleList){
            //LiveText_Number__c liveTextNumber = schedule.LiveText_Number__r;
            Decimal optInStatus = null;
            if(optInStatusMap!=null){
                optInStatus = optInStatusMap.get(Util.NormalizePhoneNumber(schedule.LiveText_Number__r.Number__c) + '->' + Util.NormalizePhoneNumber(schedule.To_Phone_Number__c));
            }
            SMS_Message__c message = new  SMS_Message__c(Account__c = schedule.Account__c,
                Contact__c = schedule.Contact__c,
                Lead__c = schedule.Lead__c,
                LiveText_Number__c = schedule.LiveText_Number__c,
                Message__c = schedule.Message__c,
                Object_Id__c = schedule.Object_Id__c,
                Opt_in_Status__c = (optInStatus == null) ? null : optInStatus,
                To_Phone_Number__c = schedule.To_Phone_Number__c,
                Message_Status__c = 'Queued',
                EnforceObjectPresence__c =  schedule.EnforceObjectPresence__c ); 
            messagesList.add(message);
        }
        AccessController.insertAsSystem(messagesList);
        return results;
    
    }
    
     /**
     * @description Queues the given scheduled item for immediate delivery and returns the status of the item.
     *  
     * @Param       Scheduled item to queue for delivery.
     *
     * @Return      Results of queueing this item.
     **/   
    public static ActionResult queueItem(ScheduleItem item) {
       
        if(item == null) return null;
        
        ActionResult result = new ActionResult(item.ObjectId);
        String normalizedToNumber = Util.NormalizePhoneNumber(item.ToPhoneNumber);
        
        // retrieve current opt-in status between these 2 phone numbers
        OptInStatus__c optInStatus =  Util.getOptInStatus(item.LiveTextPhoneNumber.Id, item.ToPhoneNumber);
 
        // Insert into SMS_Message table which will trigger a workflow to determine whether or not to actually send the message.
        //-V- ScheduleItem refactor place
        SMS_Message__c message = new  SMS_Message__c(   Account__c = item.AccountId,
                                                        Contact__c = item.ContactId,
                                                        Lead__c = item.LeadId,
                                                        LiveText_Number__c = item.LiveTextPhoneNumber.Id,
                                                        Message__c = item.Message,
                                                        Object_Id__c = item.ObjectId,
                                                        Opt_in_Status__c = (optInStatus == null) ? null : optInStatus.Status__c,
                                                        To_Phone_Number__c = normalizedToNumber,
                                                        Message_Status__c = 'Queued',
                                                        EnforceObjectPresence__c = false //item.EnforceObjectPresence
                                                      );
        AccessController.insertAsSystem(new list < SMS_Message__c >{message});
        
        return result;
    
    }
    
    
    /**
     * @description Retrieves the given scheduled item from the SMS_Schedule table.
     *  
     * @Param       Id of item to retrieve.
     *
     * @Return      SMS_Schedule__c item or null if not found.
     **/ 
     @TestVisible  
     private static SMS_Schedule__c getScheduledItem(ID id){
        SMS_Schedule__c[] schedules = 
            [SELECT Account__c, Contact__c, CreatedById, CreatedDate, IsDeleted, LastModifiedById, LastModifiedDate, 
            Lead__c, LiveText_Number__c,LiveText_Number__r.Number__c,Message__c, Object_Id__c, OwnerId, Id, Reference_Id__c, Name, 
            Schedule_Date__c, SystemModstamp, To_Phone_Number__c, EnforceObjectPresence__c From SMS_Schedule__c Where ID=:id];          
        if(schedules.size() > 0){
            return schedules[0];
        }
        return null;
    }

    @TestVisible  
     private static List<SMS_Schedule__c> getScheduledItemList(List<ID> ids){
        List<SMS_Schedule__c> schedules = 
            [SELECT Account__c, Contact__c, CreatedById, CreatedDate, IsDeleted, LastModifiedById, LastModifiedDate, 
            Lead__c, LiveText_Number__c,LiveText_Number__r.Number__c,Message__c, Object_Id__c, OwnerId, Id, Reference_Id__c, Name, 
            Schedule_Date__c, SystemModstamp, To_Phone_Number__c, EnforceObjectPresence__c From SMS_Schedule__c Where ID IN :ids];          
        if(schedules!=null){
            return schedules;
        }
        return null;
    }
}