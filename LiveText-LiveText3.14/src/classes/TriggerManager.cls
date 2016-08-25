/**
* @author        Santosh Gudge (santosh@comitydesigns.com)
* @company       ComityDesigns
* @date          07/07/2014          
* @description   Generic Manager to dispatch trigger execution flow
*/
public with sharing class TriggerManager {
    public interface ITriggerHandler {
        void onBeforeInsert(List<sObject> newRecords);
        void onAfterInsert(List<sObject> newRecords, Map<ID, sObject> newRecordsMap);
    }             
    
    public abstract class TriggerHandler implements ITriggerHandler {
       public virtual void onBeforeInsert(List<sObject> newRecords) {}
       public virtual void onAfterInsert(List < sObject > newRecords, Map < ID, sObject > newRecordsMap) {}
       public virtual void onAfterUpdate(List < sObject > newRecords, Map < ID, sObject > newRecordsMap, Map < ID, sObject > oldRecordsMap) {}

       private void invoke(
           Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete,
           List < SObject > oldRecords, List < SObject > newRecords, Map < ID, SObject > oldRecordsMap, Map < ID, SObject > newRecordsMap) {
             if(isBefore) {
                if (isInsert) { 
                    onBeforeInsert(newRecords);
                }
          
            }
            else {
                if (isInsert) {
                    onAfterInsert(newRecords, newRecordsMap); 
                }
                if (isUpdate) {
                    onAfterUpdate(newRecords, newRecordsMap, oldRecordsMap); 
                }
            }
       }
   }
    
    /**
    * @author        
    * @date         
    * @description  Invoke trigger handler by type Usage: in trigger make call like  TriggerManager.invoke(ContactTriggerhandler.class);
    */
    public static void invoke(Type type) {
        Object handler = type.newInstance();
        if (handler instanceof TriggerHandler) {
            invoke((TriggerHandler) handler);
        }
        else {            
            system.debug(LoggingLevel.ERROR, type + ' type doesn\'t extend TriggerHandler class');
        }        
    }
    
    /**
    * @author        
    * @date         
    * @description  Invoke trigger handler by existing instance. Usage: in trigger make call like  TriggerManager.invoke(new ContactTriggerhandler());
    */
    public static void invoke(TriggerHandler handler) {
        handler.invoke(
            Trigger.isBefore, 
            Trigger.isAfter, 
            Trigger.isInsert, 
            Trigger.isUpdate, 
            Trigger.isDelete,
            Trigger.old, 
            Trigger.new, 
            Trigger.oldMap,
            Trigger.newMap);
    }
}