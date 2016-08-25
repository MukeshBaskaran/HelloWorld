global class UpdateInboundItem {
   @InvocableVariable(label='Object Id' description='Identifier for ITR Message object to be updated.' required=true)
   global ID ObjectId;
   
   @InvocableVariable(label='ITR Context' description='Optional ITR Context to set for this ITR Message. If not specified, ITR Context will not be modified.' required=false)
   global String ITRContext;
   
   @InvocableVariable(label='Queue Name' description='Optional Queue Name to set for this ITR Message.  If not specified, Queue Name will not be modified.' required=false)
   global String QueueName;
   
   global UpdateInboundItem(){
    
   }
}