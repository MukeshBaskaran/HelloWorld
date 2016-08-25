/**
 * @description:    This class is used to set the status of a previously-queued message.
*/
global class SetMessageStatusAction {

    /**
     * @description Sends the given messages and returns the status of each item. 
     *  
     * @Param       List of previously-queued messages to send.
     *
     * @Return      LiveText_ActionResult records for each item.
     **/ 
    @InvocableMethod(label='Set Message Status' description='Sets the status of the given messages and returns the status of each item.')
    global static  List<ActionResult> setMessagesStatus(List<SetMessageStatusRequest> items) {
        
        List<ActionResult> results = setMessageStatus(items);
  
        return results;
        
    }
    
    private static SMS_Message__c findMessage(List<SMS_Message__c> messages, Id messageId){
    	for(SMS_Message__c message : messages){
    		if(message.Id == messageId) return message;
    	}
    	return null;
    }
    
    /**
     * @description Sets the status of the given message. 
     *  
     * @Param       Message with accompanying status.
     *
     * @Return      Result of action.
     **/ 
    public static List<ActionResult> setMessageStatus(List<SetMessageStatusRequest> requestItems) {
    	
    	List<ID> ids = new List<ID>();
    	for(SetMessageStatusRequest requestItem : requestItems){
    		ids.add(requestItem.MessageId);
   		}
    	
    	SMS_Message__c[] messages = getMessages(ids);
    	List<ActionResult> results = new List<ActionResult>();
    	
    	List <SMS_Message__c> msgs = new List<SMS_Message__c>();
    	for(SetMessageStatusRequest requestItem : requestItems){   
    		SMS_Message__c msg = findMessage(messages, requestItem.MessageId);
    		ActionResult result = new ActionResult(requestItem.MessageId);
    		if(requestItem.MessageId == null){
		    	result.setError('Message id not specified.');
		  	} 
		  	else if(msg == null){
		    	result.setError('Message with id ' + requestItem.MessageId + ' does not exist.');
		   	}
		   	else{
		   		msg.Error_Message__c = requestItem.ErrorMessage;
        		msg.Message_Status__c = requestItem.MessageStatus;
        		msgs.add(msg);                
		   	}
       		results.add(result);
    	}
    	
    	if(msgs.size() > 0){
    		AccessController.updateAsSystem(msgs);
    	}
    	
        return results;
     }
    
   
    
     /**
     * @description Retrieves the SMS_Message record associated with the given Id
     *  
     * @Param       id - the Id of the message from the SMS_Message table 
     *
     * @Return      SMS_Message__c or null if not found.
     **/ 
     private static List<SMS_Message__c> getMessages(List<ID> ids){
        return 
            [SELECT Error_Message__c, LiveText_Number__c, Message__c, Object_Id__c, 
            Opt_in_Status__c, To_Phone_Number__c FROM SMS_Message__c Where ID in:ids];         
      
     }
}