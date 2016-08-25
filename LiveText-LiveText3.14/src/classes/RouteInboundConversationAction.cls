global class RouteInboundConversationAction {
 	
  	@InvocableMethod(label='Route Conversations' description='Routes the given conversations to the appropriate queues/console.')
    global static  List<ActionResult> routeConversations(List<RoutableInboundItem> items) {
        List<ActionResult> results = new List<ActionResult>();
           
  		Semaphore sem = new Semaphore(constant.SEMAPHORE_SMS_TEXT_TRIGGER_HANDLER);
        for (RoutableInboundItem item : items) {
        	 if(sem.Acquire()){
            	results.add(routeConversation(item));
            	sem.Release();
        	 }
        }
        return results;  
    }
    
    public static ActionResult routeConversation(RoutableInboundItem item) {
        
        ActionResult result = new ActionResult(item.ObjectId);
                
    	List<ITR_Message__c> msgList = [Select Id, Originating_Number__c, LiveText_Number__c, Queue_Name__c,Is_Within_Business_Hours__c,Message__c from ITR_Message__c where Id =: item.ObjectId];
    	if(msgList.size() == 0){
    		result.setError('Item does not exist.');
            return result;
    	}
    	    	
    	ITR_Message__c firstMsg = msgList.get(0);
    	Id supportNumber = firstMsg.LiveText_Number__c;
    	String originatingNumber =  firstMsg.Originating_Number__c;
    	String queueName = firstMsg.Queue_Name__c;
    	Boolean isWithinBusinessHours = firstMsg.Is_Within_Business_Hours__c;
    	
    	List<Conversation_Header__c> convList = 
    	[
    		Select 
    			Id 
    		from 
    			Conversation_Header__c 
    		where 
    			Support_Number__c =: supportNumber and Originating_Number__c =: originatingNumber and 
    			(Status__c =: Constant.stage_new OR Status__c =: Constant.stage_active)
    	];
    	if(!convList.isEmpty()){
    		return result;
    	}
    	 
                
        Conversation_Header__c convObj = new Conversation_Header__c();
        convObj.Originating_Number__c = originatingNumber;
        convObj.Support_Number__c = supportNumber;
        convObj.Status__c = Constant.stage_new;
        convObj.SessionReopenedTime__c = system.now();
        convObj.ConversationType__c = Constant.ConversationType.Inbound.name();
        if(!String.isBlank(firstMsg.Message__c) && string.valueOf(firstMsg.Message__c).length()>=255){
            convObj.MessagePreview__c = string.valueOf(firstMsg.Message__c).substring(0,255);
        }
        if(!String.isBlank(firstMsg.Message__c) && string.valueOf(firstMsg.Message__c).length()<255){
            convObj.MessagePreview__c = string.valueOf(firstMsg.Message__c);
        }
        
        if(!String.isBlank(item.Status) && (item.Status.equalsIgnoreCase(Constant.stage_offline) || item.Status.equalsIgnoreCase(Constant.stage_new))){
        	 convObj.Status__c = item.Status;
        }
        else if (!isWithinBusinessHours){
        	convObj.Status__c = Constant.stage_offline;
        }
        
        if(!String.isBlank(queueName)){
        	List<Group> queues = [select Id from Group where DeveloperName =: queueName and Type = 'Queue'];
			if(queues.size() > 0){
				convObj.OwnerId =  queues.get(0).Id;
			} else {
                Util.insertException(String.valueOf(firstMsg.Id), Constant.PRIORITY_LOW, 'No Queue Name Exception');
            }
        }
				
		AccessController.insertAsSystem(new list <Conversation_Header__c>{convObj});	
	  
        List<SMS_Text__c> smsList = [Select Id from SMS_Text__c where Support_Number__c =: supportNumber and Originating_Number__c =: originatingNumber and Conversation_Header__c=null];
        if(smsList.size() > 0){
        	for(SMS_Text__c sms : smsList){
        		sms.Conversation_Header__c = convObj.Id;
        	}
        	AccessController.updateAsSystem(smsList);
	    }   
	    
	    AccessController.deleteAsSystem(msgList);
        
        return result;
    
    }
}