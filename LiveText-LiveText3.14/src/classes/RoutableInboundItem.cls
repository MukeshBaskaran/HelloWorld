global class RoutableInboundItem {
   @InvocableVariable(label='Object Id' description='Identifier for ITR Message object to be routed.' required=true)
   global ID ObjectId;
   
   @InvocableVariable(label='Text Session Status' description='Optional status for conversation. If not specified, conversation will be New' required=false)
   global String Status;
   
   global RoutableInboundItem(){
   	
   }
}