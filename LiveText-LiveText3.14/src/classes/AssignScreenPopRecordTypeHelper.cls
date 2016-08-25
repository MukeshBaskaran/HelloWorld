/**
 * @author         Fitzroy Robertson
 * @version        1.0
 * @date           07.28.2015
 * @description    This is helper class for Assign Screen pop Record Type functionality on the admin page. It contain methods to perform followin functionalities, 
 *                 1. Retrieves the already associated record types with the LiveText Number.
 *                 2. Removes the Record Types provided in available record types list.
 *                 3. Adds the Record Types provided in selected record types list.
 *  
*/
public with sharing class AssignScreenPopRecordTypeHelper {
    private SObject ltnObject;  
    /**
     * @description: Constructor method, used to intialize the LiveText Number Object, object name. 
     * @param: LiveText Number Object.
    */  
    public AssignScreenPopRecordTypeHelper(SObject ltnObject) {
        this.ltnObject = ltnObject;
    }
    
    /**
     * @description: Retrieves the list of record types already associated with a given LiveText Number object.
     * @return List of SelectOption object, which is displayed in selected member list.
    */
    public List<SelectOption> getSelectedRecordTypes() {
        List<SelectOption> selectedRecordTypes = new List<SelectOption>();
        if(ltnObject != null && ltnObject.Id != null) {
            List<ScreenPopSequence__c> associatedRecordTypesList = retrieveAssociatedRecordTypes();
            if(associatedRecordTypesList != null && !associatedRecordTypesList.isEmpty()) {
                for(ScreenPopSequence__c sequence : associatedRecordTypesList) {
                    String recordType = sequence.Record_Type__c;
                    selectedRecordTypes.add(new SelectOption(recordType, Schema.describeSObjects(new List<String>{recordType})[0].getLabel()));
                }
            }
        }
        return selectedRecordTypes;
    }
    
    /**
     * @description: Removes the record types given in the selected record types list and adds the record types given in the available list.
     * @param: selectedRecordTypesList, set of selected record types to be removed.
    */
    public void removeAddRecordTypes(Set<String> selectedRecordTypesList) {
        removeRecordTypes();
        addRecordTypes(selectedRecordTypesList);
    }
    
    private void removeRecordTypes() {
        List<ScreenPopSequence__c> associatedRecordTypesList = retrieveAssociatedRecordTypes();
        if(associatedRecordTypesList != null && !associatedRecordTypesList.isEmpty()) {
            AccessController.deleteAsUser(associatedRecordTypesList);
        }
    }
    
    private void addRecordTypes(Set<String> selectedRecordTypesList) {
        List<ScreenPopSequence__c> addRecordTypeList = new List<ScreenPopSequence__c>();
        Integer sequenceOrder = 1;
        for(String recordType : selectedRecordTypesList) {
            addRecordTypeList.add(createScreenPopSequence(recordType, sequenceOrder));
            sequenceOrder++;
        }
        if(!addRecordTypeList.isEmpty()) {
            AccessController.insertAsUser(addRecordTypeList);
        }
    }
    
    private ScreenPopSequence__c createScreenPopSequence(String recordType, Integer sequenceOrder) {
        ScreenPopSequence__c sequence = new ScreenPopSequence__c();
        sequence.LiveText_Number__c = this.ltnObject.Id;
        sequence.Record_Type__c = recordType;
        sequence.Sequence__c = sequenceOrder;
        return sequence;
    }
 
    /**
     * @description: Retrieves the record types for the given Live Text Number 
    */   
    private List<ScreenPopSequence__c> retrieveAssociatedRecordTypes() { 
        Set<String> linkedObjects = Util.getAllRelationshipObjects();
        return [    Select Record_Type__c 
                    From ScreenPopSequence__c 
                    Where LiveText_Number__c=:this.ltnObject.Id 
                    AND Record_Type__c IN :linkedObjects
                    Order By Sequence__c
                ];
    }   
}