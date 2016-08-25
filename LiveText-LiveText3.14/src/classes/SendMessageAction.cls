/**
 * @description:    This class sends a previously-queued message.
  */
 global class SendMessageAction {
    
    /**
     * @description Sends the given messages and returns the status of each item. 
     *  
     * @Param       List of previously-queued messages to send.
     *
     * @Return      LiveText_ActionResult records for each item.
     **/ 
    @InvocableMethod(label='Send Messages' description='Sends the given messages and returns the status of each item.')
    global static  List<ActionResult> sendMessages(List<SendMessageRequest> items) {
        
        List<ActionResult> results = new List<ActionResult>();
        /*for (SendMessageRequest item : items) {
            results.add(sendMessage(item));
        }*/
        results = sendMessage(items);
        return results;
        
    }
    


    public static List<ActionResult> sendMessage(List<SendMessageRequest> requestItems) {
        List<Id> requestItemIds = new List<Id>();
        List<ActionResult> results = new List<ActionResult>();
        System.debug(LoggingLevel.Info,'======requestItems===='+requestItems);
        //ActionResult result = new ActionResult(requestItem.MessageId);
        for(SendMessageRequest requestItem :requestItems){
           requestItemIds.add(requestItem.MessageId); 
        }
        // Retrieve previously-queued message
        //ID id = requestItem.MessageId;     
        List<SMS_Message__c> msgs = getMessageList(requestItemIds);
        System.debug(LoggingLevel.Info,'======msgs===='+msgs);
        List<string> msgLiveTextNumber = new List<string>();
        for(SMS_Message__c s : msgs){
             msgLiveTextNumber.add(s.LiveText_Number__c);
        }
        Map<Id,string> liveTextNumbersMap = new Map<Id,string>();
        //Map<Id,LiveText_Number__c> liveTextNumbersMap = new Map<Id,LiveText_Number__c>();
        List<LiveText_Number__c> liveTextNumbersList = new List<LiveText_Number__c>();
        liveTextNumbersList = [SELECT Number__c FROM LiveText_Number__c Where Id IN :msgLiveTextNumber];
        System.debug(LoggingLevel.Info,'======liveTextNumbersList===='+liveTextNumbersList);
        for(LiveText_Number__c ltn : liveTextNumbersList){
            liveTextNumbersMap.put(ltn.Id,ltn.Number__c);
        }
        System.debug(LoggingLevel.Info,'======liveTextNumbersMap===='+liveTextNumbersMap);

		List<String> msgIds = new List<String>();
        for(SMS_Message__c msg : msgs){   
                ActionResult result = new ActionResult(null);
                if(msg == null){
                    result.setError('Item with ID ' + msg.Id + ' does not exist.');
                    results.add(result);
                }
                if(result.IsSuccess && msg.EnforceObjectPresence__c == true ){
                    ScheduleItem scheduleItem = new ScheduleItem();
                    scheduleItem.ObjectId = msg.Object_Id__c;
                    if(scheduleItem.AccountObject == null && scheduleItem.ContactObject == null && scheduleItem.LeadObject == null){
                        String errorMsg =  'The original object used to schedule this message no longer exists';
                        SetMessageStatusRequest req = new SetMessageStatusRequest();
			        	req.MessageId = msg.Id;
			        	req.MessageStatus = 'Error';
			    		req.ErrorMessage = errorMsg;   
			        	SetMessageStatusAction.setMessageStatus(new List<SetMessageStatusRequest>{req});
                        result.setError(errorMsg);
                        results.add(result);
                    }
                }
            
                // Phone number to send from
                //LiveText_Number__c[] liveTextNumbers =  [SELECT Number__c FROM LiveText_Number__c Where Id=: msg.LiveText_Number__c];
                if(result.IsSuccess && liveTextNumbersList.size() == 0){
                    result.setError('LiveText phone number does not exist for id ' + msg.Id );
                    results.add(result);
                }
                if(result.IsSuccess){
                	msgIds.add(msg.Id);
                 }
                results.add(result);
        } 
        
        if(msgIds.size() > 0){
     		sendSms(msgIds, liveTextNumbersMap);
        }
   
        System.debug(LoggingLevel.Info,'====results==='+results);       
        return results;
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
    public static void sendSms(List<String>msgIds, Map<Id,string>liveTextNumbersMap) {
    	
    	try{
	    	List<SMS_Message__c> msgs = getMessageList(msgIds);
	    	List<SetMessageStatusRequest> reqs = new List<SetMessageStatusRequest>();
	    	for(SMS_Message__c msg : msgs){
	    		ID msgId = msg.Id;
	    		String toPhone = msg.To_Phone_Number__c;
	    		String fromPhone = liveTextNumbersMap.get(msg.LiveText_Number__c);
	    		String message = msg.Message__c;
	        
	        	System.debug(LoggingLevel.Info,'====sendsms===='+msgId+toPhone+fromPhone+message);
	        	HttpResponse res = Callout.sendSMSInternal(toPhone,fromPhone, message);
	          
	        	String errorMessage = res.getStatusCode() != 204 ? 'Unable to send message' : null;
	        	String status =    res.getStatusCode() != 204 ? 'Error' : 'Sent';
	        
	        	if(msgId != null){
	        		SetMessageStatusRequest req = new SetMessageStatusRequest();
	        		req.MessageId = msgId;
	        		req.MessageStatus = status;
	    			req.ErrorMessage = errorMessage;
	    			reqs.add(req);   
	         	}
	    	}
	    	if(reqs.size() > 0){
	    		SetMessageStatusAction.setMessageStatus(reqs);
	    	}
    	}
    	catch(Exception ex){
    		 Util.insertException('Send SMS Callout', constant.priority_high, ex.getMessage());
    	}
    }
   
    

    private static List<SMS_Message__c> getMessageList(List<ID> ids){
        List<SMS_Message__c> messages = 
            [SELECT Error_Message__c, LiveText_Number__c, Message__c, Object_Id__c, 
            Opt_in_Status__c, To_Phone_Number__c, EnforceObjectPresence__c FROM SMS_Message__c Where ID IN :ids];           
        if(messages != null){
            return messages;
        }
        return null;
    }
}