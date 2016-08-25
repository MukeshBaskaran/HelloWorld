/**
 * @description: This class deletes the given entries from SMS_Schedule__c.
*/
global class DeleteMessageAction {
    /**
     * @description Deletes the given entries in SMS_Schedule__c. 
     *  
     * @Param       List of entries to Delete.
     *
     * @Return      LiveText_ActionResult records for each item.
     **/ 
    @InvocableMethod(label='Delete Sms Schedule' description='Deletes the given entries From SMS_Schedule__c')
    global static  List<ActionResult> DeleteSmsScheduleMessages(List<DeleteSmsScheduleItem> items) {
        
        List<ActionResult> results = new List<ActionResult>();
           
        for (DeleteSmsScheduleItem item : items) {
            results.add(DeleteSmsScheduleMessage(item));
        }
        return results;  
    }
    
    public static ActionResult DeleteSmsScheduleMessage(DeleteSmsScheduleItem item) {
        
        ActionResult result = new ActionResult(item.ObjectId);       
        List<SMS_Schedule__c> msgList = [   SELECT Id,Reference_Id__c,Object_Id__c  
                                            FROM SMS_Schedule__c 
                                            WHERE Object_Id__c =: item.ObjectId  AND Reference_Id__c =: item.ReferenceId ];
        if(msgList.size() == 0) {
            result.setError('Item does not exist.');
            Util.insertException('DeleteSmsScheduleMessage', constant.priority_high, 'Record not found to delete from SMS_Schedule__c with specified ObjectId = '+ item.ObjectId+' and ReferenceId = '+item.ReferenceId);
            return result;
        }
        else {
                try {
                    AccessController.deleteAsSystem(msgList);
                } catch(Exception ex) {
                    Util.insertException('DeleteSmsScheduleMessage', constant.priority_high, ex.getMessage());
                } 
            }
        return result;
    }
}