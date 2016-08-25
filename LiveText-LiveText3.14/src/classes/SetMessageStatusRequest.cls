/**
 * @description:    Used to set the status of a previously-queued message. 
  */
 global class SetMessageStatusRequest {
    
    @InvocableVariable(label='Message Id' description='Identifier for previously-queued message.' required=true)
    global ID MessageId;
    
    @InvocableVariable(label='Message Status' description='Status of message - should be one of Queued, Sent, or Error' required=true)
    global String MessageStatus;
    
    @InvocableVariable(label='Error Message' description='Optional error message')
    global String ErrorMessage;
    
    global SetMessageStatusRequest(){
    	
    }

}