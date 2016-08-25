global class DeleteSmsScheduleItem {
   @InvocableVariable(label='Object Id' description='Identifier for SMS_Schedule__c object record to be deleted.' required=true)
   global ID ObjectId;
   
   @InvocableVariable(label='Reference ID' description='Identifier for SMS_Schedule__c object record to be deleted.' required=true)
   global ID ReferenceId;
   
   global DeleteSmsScheduleItem() {
    
   }
}