/**
 * @description:    This class updates the given entries in ITR_Message.
*/
global class UpdateITRMessageAction{

    /**
     * @description Updates the given entries in ITR_Message. 
     *  
     * @Param       List of entries to update.
     *
     * @Return      LiveText_ActionResult records for each item.
     **/ 
    @InvocableMethod(label='Update ITR Message' description='Updates the given entries in ITR_Message__c')
    global static  List<ActionResult> updateITRMessages(List<UpdateInboundItem> items) {
        
        List<ActionResult> results = new List<ActionResult>();
           
        for (UpdateInboundItem item : items) {
            results.add(updateITRMessage(item));
        }
        return results;  
    }
    
    public static ActionResult updateITRMessage(updateInboundItem item) {
        
        ActionResult result = new ActionResult(item.ObjectId);       
        List<ITR_Message__c> msgList = [SELECT Id, LiveText_Number__c, Originating_Number__c, ITR_Context__c, Queue_Name__c,
                                            Is_Within_Business_Hours__c, Available_Agents__c, Mo_Message_Counter__c
                                        FROM ITR_Message__c 
                                        WHERE Id =: item.ObjectId];
        if(msgList.size() == 0){
            result.setError('Item does not exist.');
            return result;
        }else{
            Map<Id, Set<Id>> ltNumberToAvaliableAgentsMap = Util.getAvailableAgentsMap();

            PhoneNumberRelatedObjects relatedObjects = null;
            ITR_Message__c msg = (msgList.size() > 0) ? msgList[0] : null;
            try{
                String  formattedOriginatingNumber = msg.Formatted_Originating_Number__c.subString(msg.Formatted_Originating_Number__c.indexOf('('));
                relatedObjects = new PhoneNumberRelatedObjects(msg.LiveText_Number__c, formattedOriginatingNumber);
            }catch(Exception ex){
                Util.insertException('updateITRMessages', constant.priority_high, ex.getMessage());
            } 
            if (msg != null) {
                if(item.QueueName != null){
                    msg.Queue_Name__c = item.QueueName;
                }
                if(item.ITRContext != null){
                    msg.ITR_Context__c = item.ITRContext;
                }
                if(relatedObjects != null) {
                    try{
                        if(relatedObjects.HasItems){
                            Map<String, String> relationshipObjectApiNameToFieldNameMap = new Map<String, String>();
                            Map<String, Schema.SObjectField> fieldMap = msg.getSObjectType().getDescribe().fields.getMap();
                            for(String field : fieldMap.keySet()){
                                if(fieldMap.get(field).getDescribe().getRelationshipName() != null && fieldMap.get(field).getDescribe().isCustom()){
                                    relationshipObjectApiNameToFieldNameMap.put(fieldMap.get(field).getDescribe().getReferenceTo().get(0).getDescribe().getName(), field);
                                }
                            }
                            for(String relationshipName : Util.getAllRelationshipObjects(msg.getSObjectType().getDescribe().getName())){
                                msg.put(relationshipObjectApiNameToFieldNameMap.get(relationshipName), PhoneNumberRelatedObjects.getMRMItem(relatedObjects.CustomObjects, msg.getSObjectType().getDescribe().fields.getMap().get(relationshipObjectApiNameToFieldNameMap.get(relationshipName)).getDescribe().getReferenceTo().get(0).getDescribe().getName()));
                            }
                        }
                    }catch(Exception ex){
                        Util.insertException('updateITRMessages', constant.priority_high, ex.getMessage());
                    }
                }
                if(msg.Mo_Message_Counter__c == null){
                    msg.Mo_Message_Counter__c = 0;
                }
                msg.Mo_Message_Counter__c = msg.Mo_Message_Counter__c+1;
                List<Id> temp = new List<Id>();
                if(ltNumberToAvaliableAgentsMap.containsKey((Id) msg.LiveText_Number__c)){
                    temp.addAll(ltNumberToAvaliableAgentsMap.get((Id) msg.LiveText_Number__c));
                }
                msg.Available_Agents__c = temp.size();   
                AccessController.updateAsSystem(new list <ITR_Message__c>{msg});                
            } 
        }
        return result;
    }
}