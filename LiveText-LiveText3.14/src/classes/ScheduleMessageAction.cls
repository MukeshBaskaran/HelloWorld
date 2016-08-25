/**
 * @description:    This class is responsible for scheduling messages for immediate or future delivery.
 *                  Scheduled items are inserted into the SMS_Schedule table which triggers a workflow that
 *                  will cause those items to be scheduled within Salesforce. The Salesforce scheduler will invoke
 *                  the Queue Message action which will subsequently deliver the message. 
 */
global class ScheduleMessageAction {
    
     /**
     * @description Schedules the given messages for delivery and returns the status of each item. 
     *              If a delivery date is not specified for an item, it is queued to be sent immediately
     *              and is not stored in the schedule table.
     *  
     * @Param       List of messages to be scheduled.
     *
     * @Return      ActionResult records for each item.
     **/ 
    @InvocableMethod(label='Schedule Messages' description='Schedules the given messages for delivery and returns the status of each item.')
    global static  List<ActionResult> scheduleMessages(List<ScheduleItem> items) {

        List<ActionResult> results = new List<ActionResult>();
        try{
          // Dedupe
          List<ScheduleItem> uniqueItems = new List<ScheduleItem>();
          for (ScheduleItem item : items) {
            // if destination phone number is not specified, attempt to set it based on object
            if(String.isBlank(item.ToPhoneNumber)){
              item.SetPhoneNumberBasedOnObject();
            }

            //If livetext number is not specified,it will select the LiveText Number that was created first
           if(String.isBlank(item.LiveTextNumber)){
              List<LiveText_Number__c> ltn = new List<LiveText_Number__c>();
              ltn = [SELECT Id,Number__c FROM LiveText_Number__c ORDER BY LastModifiedDate ASC LIMIT 1];
              if(ltn.size()>0){
                item.LiveTextNumber = ltn.get(0).Number__c;
              }
              else{
                ActionResult result = new ActionResult(item.ObjectId);
                result.SetError('LiveText Number is required.');
                Util.insertException('LiveText Number Exception', Constant.PRIORITY_HIGH, 'LiveText Number is required.');
              }
            }
            
            if(Util.ListContainsObject(uniqueItems,item)){
              ActionResult result = new ActionResult(item.ObjectId);
              result.setError(item.ToPhoneNumber + ' was selected multiple times');
              results.add(result);
            }
            else{
              uniqueItems.add(item);
            }
            
          }
          // delete any existing schedules for this items
          deleteExistingSchedules(uniqueItems);
          for (ScheduleItem item : uniqueItems) {
              results.add(scheduleMessage(item));
          }
        }
        catch(Exception ex){
          Util.insertException('scheduleMessages', Constant.PRIORITY_HIGH, ex.getMessage());
        }
        return results;  
    }
   
    /**
     * @description Schedules the given message for delivery and returns the status of the item.
     *
     * @Param       Message to be scheduled.
     *
     * @Return      Result for this message.
     **/   
    public static ActionResult scheduleMessage(ScheduleItem item) {
        ActionResult result = new ActionResult(item.ObjectId);
         if(!String.isBlank(item.message) && item.message.length()>480){
              result.SetError('Message length is more than 480 characters.');
              Util.insertException('Message : data value too large exception', Constant.PRIORITY_HIGH, 'Message length is more than 480 characters.');
              return result;
            }

        // Check for validity of LiveText phone number
        LiveText_Number__c liveTextNumber = item.LiveTextPhoneNumber;
        if (liveTextNumber == null){
            result.setError('LiveText phone number ' + item.LiveTextNumber + ' not found.');
            return result;
        }
        
        // Check for validity of destination phone number     
        String errorMsg = Util.validateRecipientPhoneNumber(item.ToPhoneNumber);
        if(!String.isBlank(errorMsg)){
            result.setError(errorMsg + ': ' + item.ToPhoneNumber);
            Util.insertException('scheduleMessage', Constant.PRIORITY_HIGH, errorMsg);
            return result;
        }
        
        // check for reference id on scheduled sends
        if(item.ScheduleDate != null && String.isBlank(item.ReferenceId)){
            result.setError('ReferenceId is required for scheduled sends.');
            return result;
        }
        
        // delete any existing schedule for this item
        //deleteExistingSchedule(item);
        
        Boolean bypassOptin = item.BypassOptinCheck != null && item.BypassOptinCheck == true;
        Boolean isITR = item.MessageSource == Constant.itr || item.MessageSource == Constant.permission_marketing;
        String itrSource = isITR ? item.MessageSource : '';
        
        if(item.ScheduleDate == null || bypassOptin || isITR){
                    
          if(bypassOptin){
            ScheduleMessageAction.sendSms(null, item.ToPhoneNumber, item.LiveTextNumber, item.Message);
          }
          else{   
              result = queueItemForImmediateSend(item);
          }
            
            if(isITR){
            SMS_Text__c smsTextRecord = new SMS_Text__c(
                  Support_Number__c = liveTextNumber.Id,
                  Originating_Number__c = item.ToPhoneNumber,
                  Message__c = item.Message, Source__c = itrSource,
                  Sent_To_Customer__c=result.IsSuccess
              );
              AccessController.insertAsUser(new list < SMS_Text__c > {smsTextRecord});
          }
        }
        else{
                    
            // Insert new item into schedule table
            SMS_Schedule__c schedule = new  SMS_Schedule__c(Account__c = item.AccountId,
                                                            Contact__c = item.ContactId,
                                                            Lead__c = item.LeadId,
                                                            LiveText_Number__c = liveTextNumber.Id,
                                                            Message__c = item.Message,
                                                            Object_Id__c = item.ObjectId,
                                                            Reference_Id__c = item.ReferenceId,
                                                            Schedule_Date__c = item.ScheduleDate,
                                                            To_Phone_Number__c = Util.NormalizePhoneNumber(item.ToPhoneNumber),
                                                            EnforceObjectPresence__c =  false //item.EnforceObjectPresence
                                                          );
            
            AccessController.insertAsSystem(new list < SMS_Schedule__c >{schedule});
        }
        
        return result;
    
    }
    
      /**
     * @description Asynchronously sends a message. 
     *  
     * @Param       msgId - the Id of the message from the SMS_Message table 
     * @Param       toPhone - the phone number to send to
     * @Param       fromPhone - the phone number to send from 
     * @Param       message - the message to send
     *
     * @Return      Result of Send.
     **/ 
    @future (callout=true)
    public static void sendSms(ID msgId, String toPhone,String fromPhone, String message) {
        HttpResponse res = Callout.sendSMSInternal(toPhone,fromPhone, message);
          
        String errorMessage = res.getStatusCode() != 204 ? 'Unable to send message' : null;
        String status =    res.getStatusCode() != 204 ? 'Error' : 'Sent';
        
        if(msgId != null){
          SetMessageStatusRequest requestItem = new SetMessageStatusRequest();
          requestItem.MessageId = msgId;
          requestItem.MessageStatus = status;
          requestItem.ErrorMessage = errorMessage;
          SetMessageStatusAction.setMessageStatus(new List<SetMessageStatusRequest>{requestItem});
        }
    }

          /**
     * @description Asynchronously sends a message to list of recipients. 
     *  
     * @Param       toPhones -the phone numbers to sent to
     * @Param       fromPhone - the phone number to send from 
     * @Param       message - the message to send
     **/ 
    @future (callout=true)
    public static void sendSmsToList(List<String> toPhones, String fromPhone, String message) {
        for(String toPhone : toPhones){
            HttpResponse res = Callout.sendSMSInternal(toPhone,fromPhone, message);
        }
    }
    
     /**
     * @description Schedules the given message for delivery to the given IDs and returns the status of the items.
     *
     * @Param       Message to be scheduled.
     *
     * @Return      Results for each message.
     **/   
    public static List<ActionResult> scheduleMessages(String liveTextNumber, List<ID> objectIds, String message, String referenceId, DateTime scheduleDate ) {
        List<ScheduleItem> scheduleItems = new List<ScheduleItem>();
        List<ActionResult> results = new List<ActionResult>();        
        for(ID objectId : objectIds){
            ScheduleItem scheduleItem = new ScheduleItem();
            scheduleItem.ObjectId = objectId;
            scheduleItem.ReferenceId = referenceId;
            scheduleItem.LiveTextNumber = liveTextNumber;
            scheduleItem.Message = message;
            scheduleItem.ScheduleDate = scheduleDate;
            scheduleItem.SetPhoneNumberBasedOnObject(); 
 
            // until workflows start working, send messages out directly
            ActionResult result = new ActionResult(scheduleItem.ObjectId);


            if(String.isBlank(scheduleItem.ToPhoneNumber)){
                result.setError(Label.ActionResultNoPhoneError);
            }else if(scheduleItem.LiveTextPhoneNumber == null){
                result.setError(Label.ActionResultLTNumberNotFoundError);
            }else if(Util.ListContainsObject(scheduleItems,scheduleItem)){
                result.setError(scheduleItem.ToPhoneNumber + ' ' + Label.ActionResultMultiplePhonesErrorSuffix);
            }else if(!listContainsToPhoneNumber(scheduleItems, scheduleItem)){ //prevent duplicates
              scheduleItems.add(scheduleItem);           
              // for now, just send directly until we can ship workflows
              LiveText_Number__c ltn = scheduleItem.LiveTextPhoneNumber;
              if(ltn != null){
                OptInStatus__c optInStatus = Util.getOptInStatus(ltn.Id,scheduleItem.ToPhoneNumber);
                    if(optInStatus == null||optInStatus.Status__c==1){
                      String fromPhone = ltn.Number__c;      
                      ScheduleMessageAction.sendSms(null, scheduleItem.ToPhoneNumber, fromPhone, message);
                    }else{
                      system.debug(Label.ActionResultPhoneNotOptedIn);
                        result.setError(Label.ActionResultPhoneNotOptedIn);
                    }
              }
          }   
          results.add(result);
        }
                    
       // return ScheduleMessageAction.scheduleMessages(scheduleItems);
       
       return results;       
    
    }

     /**
     * @description Schedules the given message for delivery to the given IDs ->phoneNumber  and returns the status of the items. Used in BulkSMSPage
     *
     * @Return      Results for each message.
     **/   
    public static List<ActionResult> scheduleMessages(LiveText_Number__c ltn, Map<String, String> objectIdToPhoneNumber, String message, String referenceId, DateTime scheduleDate ) {
        List<ScheduleItem> scheduleItems = new List<ScheduleItem>();
        List<ActionResult> results = new List<ActionResult>();
        Map<String, Decimal> phoneNumberToOptinStatus = Util.getOptInStatus(ltn.Id, objectIdToPhoneNumber.values());
        List<List<String>> toPhones = new List<List<String>>();
        List<String> temp = new List<String>();
        Integer count = 0;
        Boolean isShortCode = Util.IsShortCode(ltn.Number__c);

        for(String objectId : objectIdToPhoneNumber.keySet()){
            String phone = objectIdToPhoneNumber.get(objectId);
            if(!String.isBlank(phone)){
                //checking country code only for shortcode
                ScheduleItem scheduleItem = new ScheduleItem();
                scheduleItem.ObjectId = objectId;
                scheduleItem.ReferenceId = referenceId;
                scheduleItem.LiveTextNumber = ltn.Number__c;
                scheduleItem.Message = message;
                scheduleItem.ScheduleDate = scheduleDate;
                scheduleItem.ToPhoneNumber = phone;
                // until workflows start working, send messages out directly
                ActionResult result = new ActionResult(scheduleItem.ObjectId);
                if(String.isBlank(scheduleItem.ToPhoneNumber)){
                    result.setError(Label.ActionResultNoPhoneError);
                }else if(ltn == null){
                    result.setError(Label.ActionResultLTNumberNotFoundError);
                }else if(!CountryCodeUtil.isPhoneFromLocale(phone, ltn.ISOCountryCode__c) && isShortCode){
                    result.setError(Label.ActionResultShortCodeInternationalAttemptError);
                }else if(Util.ListContainsObject(scheduleItems,scheduleItem)){
                    result.setError(scheduleItem.ToPhoneNumber + ' ' + Label.ActionResultMultiplePhonesErrorSuffix);
                }else if(!listContainsToPhoneNumber(scheduleItems, scheduleItem)){ //prevent duplicates
                    scheduleItems.add(scheduleItem);           
                    // for now, just send directly until we can ship workflows
                    if(ltn != null){
                       Decimal optInStatus = phoneNumberToOptinStatus.containsKey(scheduleItem.ToPhoneNumber) ? phoneNumberToOptinStatus.get(scheduleItem.ToPhoneNumber) : null;
                        if(optInStatus == null||optInStatus == 1){
                            temp.add(scheduleItem.ToPhoneNumber);
                            count++;
                        }else{
                            system.debug(Label.ActionResultPhoneNotOptedIn);
                            result.setError(Label.ActionResultPhoneNotOptedIn);
                        }
                    }
                }   
                results.add(result);
            }
            if(count == 100){
                toPhones.add(temp);
                temp = new List<String>();
                count = 0;
            }
        }
        if(!temp.isEmpty())
            toPhones.add(temp);
        if(!toPhones.isEmpty() && ltn != null){
            for(List<String> toPhonesInner : toPhones){
                sendSmsToList(toPhonesInner, ltn.Number__c, message);
            }
        }
       return results;       
    
    }

    /**
    * @description Schedules the given message for delivery to the given IDs ->phoneNumber  and returns the status of the items.
    *
    * @Return      Results for each message.
    **/   
    public static List<ActionResult> scheduleMessagesForBatch(LiveText_Number__c ltn, Map<String, String> objectIdToPhoneNumber, String message, String referenceId, DateTime scheduleDate) {
        List<ScheduleItem> scheduleItems = new List<ScheduleItem>();
        List<ActionResult> results = new List<ActionResult>();
        List<List<String>> toPhones = new List<List<String>>();
        List<String> temp = new List<String>();
        Integer count = 0;
        Map<String, Decimal> phoneNumberToOptinStatus = Util.getOptInStatus(ltn.Id, objectIdToPhoneNumber.values());

        for(String objectId : objectIdToPhoneNumber.keySet()){
            if(!String.isBlank(objectIdToPhoneNumber.get(objectId))){
                ScheduleItem scheduleItem = new ScheduleItem();
                scheduleItem.ObjectId = objectId;
                scheduleItem.ReferenceId = referenceId;
                scheduleItem.LiveTextNumber = ltn.Number__c;
                scheduleItem.Message = message;
                scheduleItem.ScheduleDate = scheduleDate;
                scheduleItem.ToPhoneNumber = Util.NormalizePhoneNumber(objectIdToPhoneNumber.get(objectId));

                // until workflows start working, send messages out directly
                ActionResult result = new ActionResult(scheduleItem.ObjectId);
                if(String.isBlank(scheduleItem.ToPhoneNumber)){
                    result.setError(Label.ActionResultNoPhoneError);
                }else if(ltn == null){
                    result.setError(Label.ActionResultLTNumberNotFoundError);
                }else if(Util.ListContainsObject(scheduleItems,scheduleItem)){
                    result.setError(scheduleItem.ToPhoneNumber + ' ' + Label.ActionResultMultiplePhonesErrorSuffix);
                }else {
                  Decimal optInStatus = phoneNumberToOptinStatus.containsKey(scheduleItem.ToPhoneNumber) ? phoneNumberToOptinStatus.get(scheduleItem.ToPhoneNumber) : null;
                  Boolean isOptedIn = (optInStatus == null||optInStatus == 1);
                    if(isOptedIn){
                        temp.add(scheduleItem.ToPhoneNumber);
                        count++;
                        if(!listContainsToPhoneNumber(scheduleItems, scheduleItem)){ //prevent duplicates
                        scheduleItems.add(scheduleItem);
                    }  
                    }else{
                        result.setError(Label.ActionResultPhoneNotOptedIn);
                    }
                }
                results.add(result);
            }
            if(count == 100){
                toPhones.add(temp);
                temp = new List<String>();
                count = 0;
            }
        }
        if(!temp.isEmpty())
            toPhones.add(temp);
        if(!toPhones.isEmpty() && ltn != null){
            for(List<String> toPhonesInner : toPhones){
              for(String toPhone : toPhonesInner){
                  HttpResponse res = Callout.sendSMSInternal(toPhone,ltn.Number__c, message);
              }
            }
        }
       return results;       
    
    }

    /**
    * @description Check if recipient phone is in list of scheduleItems
    **/

    private static Boolean listContainsToPhoneNumber(List<ScheduleItem> scheduleItems, ScheduleItem item){
        for(ScheduleItem si : scheduleItems){
            if(item.ToPhoneNumber.equals(si.ToPhoneNumber)){
                return true;
            }    
        }
        return false;
    }
    
       
    /**
    * @description  Schedules the given message for delivery and returns the status of the item.
    *
    * @Param        Message to be scheduled.
    *
    * @Return       Result for this message.
    **/  
    private static ActionResult queueItemForImmediateSend(ScheduleItem item){
        return QueueMessageAction.queueItem(item);
    }
    
    /**
    * @description  Deletes any existing schedule for the given item.
    *
    * @Param        Item whose schedules it to be deleted. Uniqueness is determined by a combination of
    *               LiveText Number, Destination Phone Number, and Reference Id
    *
    * @Return       void.
    **/  
    private static void deleteExistingSchedule(ScheduleItem item){
        
        LiveText_Number__c liveTextNumber = item.LiveTextPhoneNumber;
        
        // Find items with this LiveText Number, Destination Phone Number, and Reference Id
        SMS_Schedule__c[] schedules = 
          item.IsAlterScheduleBasedOnReferenceId ?
            [SELECT 
                Id  
            FROM 
                SMS_Schedule__c 
            Where 
                Reference_Id__c=:item.ReferenceId
            ] :
            [SELECT 
                Id  
            FROM 
                SMS_Schedule__c 
            Where 
                Reference_Id__c=:item.ReferenceId AND 
                LiveText_Number__c=:liveTextNumber.Id AND 
                To_Phone_Number__c=:Util.NormalizePhoneNumber(item.ToPhoneNumber) 
            ];          
                
        if(schedules.size() > 0){
            AccessController.deleteAsUser(schedules);
        }
    }

    /**
    * @description  Deletes any existing schedules for the given items.
    *
    * @Param        Item whose schedules it to be deleted. Uniqueness is determined by a combination of
    *               LiveText Number, Destination Phone Number, and Reference Id
    *
    * @Return       void.
    **/  
    private static void deleteExistingSchedules(List<ScheduleItem> items){
        List<Id> liveTextNumbers = new List<Id>();
        List<SMS_Schedule__c> smsSchedules = new List<SMS_Schedule__c>();
        List<SMS_Schedule__c> schedules = new List<SMS_Schedule__c>();
        List<String> toPhoneNumbers = new List<String>();
        List<ScheduleItem> isAlterScheduleBasedOnReferenceIdList = new List<ScheduleItem>();
        List<ScheduleItem> isAlterScheduleBasedOnNumbersList = new List<ScheduleItem>();
        List<String> referenceIdsList = new List<String>();
        for(ScheduleItem item : items) {
            if(item.ReferenceId !=null) {
                referenceIdsList.add(item.ReferenceId);
            }
            if(item.IsAlterScheduleBasedOnReferenceId) {
                isAlterScheduleBasedOnReferenceIdList.add(item);
            }
            else {
                    LiveText_Number__c liveTextNumber = item.LiveTextPhoneNumber;
                    liveTextNumbers.add(liveTextNumber.Id);
                    toPhoneNumbers.add(Util.NormalizePhoneNumber(item.ToPhoneNumber));
                    isAlterScheduleBasedOnNumbersList.add(item);
            }
        }
        if(isAlterScheduleBasedOnReferenceIdList != null) {
            smsSchedules = [    SELECT  Id  
                                FROM    SMS_Schedule__c 
                                WHERE   Reference_Id__c IN: referenceIdsList ];
            for(SMS_Schedule__c smsSchedule : smsSchedules){
                schedules.add(smsSchedule);
            }
        }
        if(isAlterScheduleBasedOnNumbersList != null) {
            smsSchedules =  [   SELECT  Id  
                                FROM    SMS_Schedule__c 
                                WHERE   Reference_Id__c IN: referenceIdsList AND 
                                        LiveText_Number__c IN: liveTextNumbers AND 
                                        To_Phone_Number__c IN: toPhoneNumbers
                            ]; 
            for(SMS_Schedule__c smsSchedule : smsSchedules){
                schedules.add(smsSchedule);
            }
        }
                
        if(schedules.size() > 0){
            AccessController.deleteAsUser(schedules);
        }
    }
}