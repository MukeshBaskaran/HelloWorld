/**
 * @description:    This class represents a request to queue a scheduled item. 
 *                  The identifier of the scheduled item is the sole variable needed. 
 */
 global class QueueItemRequest {
    @InvocableVariable(label='Scheduled Item Id' description='Identifier of scheduled item.' required=true)
    global ID ScheduledItemId;

	global QueueItemRequest(){
	}
}