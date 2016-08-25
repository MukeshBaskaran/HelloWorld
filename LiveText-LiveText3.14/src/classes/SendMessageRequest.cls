/**
 * @description:    This class represents a request to send a previously-queued item. 
 *                  The identifier of the previously-queued item is the sole variable needed.
 *
 * @author:		 	Fitzroy Robertson
 *
 * @date:			1/5/2015
 */
 global class SendMessageRequest {
    @InvocableVariable(label='Message Id' description='Identifier of message.' required=true)
    global ID MessageId;
    
    global SendMessageRequest(){
    	
    }
}