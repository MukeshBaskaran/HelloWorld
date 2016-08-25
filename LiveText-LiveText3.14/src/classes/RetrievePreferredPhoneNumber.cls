/**
 * @author         swetha kalluri
 * @data           12.01.2015
 * @description    RetrievePreferredPhoneNumber class contains methods used to retrive the phone number 
 *                 from objects.
 */

global with sharing class RetrievePreferredPhoneNumber {

  /**
    * @description 
    *
    **/
    @TestVisible
    webService static String saveToStorage(String stringToSave){
        Storage__c storage = new Storage__c();
        storage.StorageTextData__c = stringToSave;
        insert storage;
        return (String) storage.Id;
    }
    
    /**
    * @description agentHasShortcodeNumberAssigned returns true if Agend has at least one shortCode number assigned
    *
    **/
    @TestVisible
    webService static Boolean agentHasShortcodeNumberAssigned(){
        for(Associated_Agents__c associatedAgentNumbers : [SELECT id, LiveText_Number__c, LiveText_Number__r.Number__c FROM Associated_Agents__c WHERE User__c = :UserInfo.getUserId() LIMIT 10000]){
            Integer numberLength = associatedAgentNumbers.LiveText_Number__r.Number__c.length();
            if(numberLength == 5 || numberLength == 6)
                return true;
        }
        return false;
    }
    
    /**
    * @description: getToPhoneNumberFromObject returns the toPhoneNumber of the given Id by following conditions stated in LT-1137
    *               if no phone number found method returns null .
    */
    @TestVisible
    webService static String getToPhoneNumberFromObject(Id selectedObjId){
        return retrievePhoneFromIds(new List<Id>{selectedObjId}).get(selectedObjId);
    }

    /**
    * @description: like getToPhoneNumberFromObject but with additional information
    */
    @TestVisible
    webService static String getToPhoneInformationFromObject(Id selectedObjId){
        return JSON.serialize(retrievePhoneAndPhoneInformationFromIds(new List<Id>{selectedObjId}).get(selectedObjId));
    }

    /**
    * @description getToPhoneNumberFromObjects returns JSON with Id -> phone number for given list of Ids. 
    * @important All Id's needs to be the same object type! I didn't do a checker since this funcion uses A LOT of cpu time
    **/
    @TestVisible
    webService static String getToPhoneNumberFromObjects(List<Id> selectedObjIds){
        return JSON.serialize(retrievePhoneFromIds(selectedObjIds));
    }

    public static String getToPhoneInformationFromObjects(List<Id> selectedObjIds){
        return JSON.serialize(retrievePhoneAndPhoneInformationFromIds(selectedObjIds));
    }

    private static Map<String, String> retrievePhoneFromIds(List<Id> selectedObjIds){
        Map<String, String> retMap = new Map<String,String>();
        Map<String, PhoneInformation> temp = retrievePhoneAndPhoneInformationFromIds(selectedObjIds);
        for(String key : temp.keySet()){
            retMap.put(key, temp.get(key).phone);
        }
        return retMap;
    }

    private static Map<String, PhoneInformation> retrievePhoneAndPhoneInformationFromIds(List<Id> selectedObjIds){
        Map<String, PhoneInformation> idToPhoneNumber = new Map<String, PhoneInformation>();
        if(selectedObjIds.isEmpty())
            return idToPhoneNumber;
        String selectedObjectPrefix =  selectedObjIds[0].getSObjectType().getDescribe().getKeyPrefix();
        String objName  = selectedObjIds[0].getsObjectType().getDescribe().getName();
        Boolean isPersonAccountEnabled = Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' );

        List<String> relatedObjectsList = new List<String>();

        Map<String, List<String>> relatedCustomObjectsMap = new Map<String, List<String>>();
        Map<String, List<String>> relatedStandardObjectsMap = new Map<String, List<String>>();
        Map<String, String> fieldNameLowCaseToNormal = new Map<String, String>();

        //This map contains ObjectType - > map: filter ('Phone', 'Mobile', 'Rest') -> list of phone fields
        Map<String, Map<String, List<String>>> objectTypeToPhoneFieldNames = new Map<String, Map<String, List<String>>>();

        Map<String, schema.SObjectField> objFieldMap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
        Set<String> restrictedObjectTyps = Constant.excludeObjectTypes;

        for(String field : objFieldMap.keyset()){
            Schema.DescribeFieldResult dfr = objFieldMap.get(field).getDescribe();
            if(dfr.getReferenceTo().size()>0){
                if(dfr.isAccessible()){
                    String fielddataType = String.valueOf(dfr.getReferenceTo()[0]).toLowerCase();
                    if(fielddataType!=null && !restrictedObjectTyps.contains(fielddataType)){
                        List<String> tempList = new List<String>();
                        String lowerCaseFieldName = field.toLowerCase();
                        if(fielddataType.contains('__c')){
                            if(relatedCustomObjectsMap.containsKey(fielddataType))
                                tempList = relatedCustomObjectsMap.get(fielddataType);
                            tempList.add(lowerCaseFieldName);
                            relatedCustomObjectsMap.put(fielddataType,tempList);
                        }else{
                            if(relatedStandardObjectsMap.containsKey(fielddataType))
                                tempList = relatedStandardObjectsMap.get(fielddataType);
                            tempList.add(lowerCaseFieldName);
                            relatedStandardObjectsMap.put(fielddataType,tempList);
                        }
                        relatedObjectsList.add(lowerCaseFieldName);
                        fieldNameLowCaseToNormal.put(lowerCaseFieldName, field);
                    }
                } 
            }
        }

        relatedObjectsList.sort();

        String relatedFields = String.join(relatedObjectsList,', '); 
        relatedFields = String.isEmpty(relatedFields) ? 'Id' : relatedFields +',Id';
        
        //this query is made to prevent soql error in polymorphic relations
        List<SObject> records = Database.query('SELECT ' +relatedFields + ' FROM ' + objName + ' WHERE Id IN (\'' + String.join(selectedObjIds, '\',\'') + '\')');

        //creating list of phone fields form relationship
        Map<Id, List<Id>> polymorphicFieldsIds = new Map<Id, List<Id>>();
        Set<String> phoneFieldsFromRelationships = new Set<String>();
        for(SObject item : records){
            Id itemId = (Id) item.get('Id');
            List<Id> tempPolymorphicIds = new List<Id>();
            for(String field : relatedObjectsList){
                Id temp = (Id) item.get(field);
                if(temp != null){
                    if(objFieldMap.get(fieldNameLowCaseToNormal.get(field)).getDescribe().isNamePointing()){
                        tempPolymorphicIds.add(temp);
                    }else{
                        if(temp.getsObjectType() != null && temp.getsObjectType().getDescribe() != null){
                            String tempObjName = temp.getsObjectType().getDescribe().getName();
                            phoneFieldsFromRelationships.addAll(Util.getPhoneFieldsFromRelationship(fieldNameLowCaseToNormal.get(field), tempObjName, '', itemId));
                            if(!objectTypeToPhoneFieldNames.containsKey(tempObjName))
                                objectTypeToPhoneFieldNames.put(tempObjName, Util.getPhoneNumberFilteredFieldsByFilter(tempObjName));
                        }
                    }
                }
            }
            polymorphicFieldsIds.put(itemId, tempPolymorphicIds);
        }

        //this record contains all phone fields, and all phone fields from all relationships
        List<String> fieldList = new List<String>(phoneFieldsFromRelationships);
        if(!objectTypeToPhoneFieldNames.containsKey(objName))
            objectTypeToPhoneFieldNames.put(objName, Util.getPhoneNumberFilteredFieldsByFilter(objName));
        for(String key : objectTypeToPhoneFieldNames.get(objName).keyset()){
            fieldList.addAll(objectTypeToPhoneFieldNames.get(objName).get(key));
        }
        fieldList.addAll(relatedObjectsList);
        fieldList.add('ownerid');
        String query = 'SELECT ' + String.join(fieldList, ',')  + ' FROM ' + objName + ' WHERE Id IN (\'' + String.join(selectedObjIds, '\',\'') + '\')';
        System.debug('getToPhoneNmberFromObject POINT QUERY: ' + query);
        records = Database.query(query);

        for(SObject record : records){
            Id selectedObjId = (Id) record.get('Id');
            PhoneInformation toPhoneNumber = retrievePhoneFromSObject(record, selectedObjId, relatedStandardObjectsMap, relatedCustomObjectsMap, polymorphicFieldsIds.get(selectedObjId), isPersonAccountEnabled, objName, objectTypeToPhoneFieldNames);
            idToPhoneNumber.put((String)selectedObjId, toPhoneNumber);
        }
        return idToPhoneNumber;
    }//End of Method

    private static PhoneInformation retrievePhoneFromSObject(SObject record, Id selectedObjId, Map<String,List<String>> relatedStandardObjectsMap, Map<String, List<String>> relatedCustomObjectsMap, List<Id> polymorphicFieldsIds, Boolean isPersonAccountEnabled, String objName, Map<String, Map<String, List<String>>> objectTypeToPhoneFieldNames){

        List<String> sortedStdKeyset = new List<String>(relatedStandardObjectsMap.keySet());
        sortedStdKeyset.sort();
        List<String> sortedCustomKeyset = new List<String>(relatedCustomObjectsMap.keySet());
        sortedCustomKeyset.sort();

        //1. get 'mobile' from current object
        PhoneInformation toPhoneNumber = (isPersonAccountEnabled && Constant.CASE_OBJECT.equalsIgnoreCase(objName)) ? null : getPhoneFromRecord(record, 'Mobile', selectedObjId, objectTypeToPhoneFieldNames);
        if(toPhoneNumber != null){
            return toPhoneNumber;
        }
        //for person accounts
        if(Constant.CASE_OBJECT.equalsIgnoreCase(objName) && isPersonAccountEnabled){
            if(relatedStandardObjectsMap.get('account').size()>0){
                List<String> tempList = relatedStandardObjectsMap.get('account');
                tempList.sort();
                List<Id> tempIds = new List<Id>();
                for(String item:tempList){
                    if((String)record.get(item)!=null){
                        toPhoneNumber = getPhoneFromRecord(record, item, 'Mobile', (Id)record.get(item), objectTypeToPhoneFieldNames);
                        if(toPhoneNumber != null)
                            return toPhoneNumber;
                    }
                }
                for(String item:tempList){
                    if((String)record.get(item)!=null){
                        toPhoneNumber = getPhoneFromRecord(record, item, 'Phone', (Id)record.get(item), objectTypeToPhoneFieldNames);
                        if(toPhoneNumber != null)
                        return toPhoneNumber;
                    }
                }
            }
            if(relatedStandardObjectsMap.get('contact').size()>0){
                List<String> tempList = relatedStandardObjectsMap.get('contact');
                tempList.sort();
                List<Id> tempIds = new List<Id>();
                for(String item:tempList){
                    if((String)record.get(item)!=null){
                        toPhoneNumber = getPhoneFromRecord(record, item, 'Mobile', (Id)record.get(item), objectTypeToPhoneFieldNames);
                        if(toPhoneNumber != null)
                            return toPhoneNumber;
                    }
                }
                for(String item:tempList){
                    if((String)record.get(item)!=null){
                        toPhoneNumber = getPhoneFromRecord(record, item, 'Phone', (Id)record.get(item), objectTypeToPhoneFieldNames);
                        if(toPhoneNumber != null)
                            return toPhoneNumber;
                    }
                }
            }
        }
        //2. get 'mobile' form linked contact
        if(relatedStandardObjectsMap.containsKey('contact')){
            if(relatedStandardObjectsMap.get('contact').size()>0){
                List<String> tempList = relatedStandardObjectsMap.get('contact');
                tempList.sort();
                List<Id> tempIds = new List<Id>();
                for(String item:tempList){
                    if((String)record.get(item)!=null){
                        toPhoneNumber = getPhoneFromRecord(record, item, 'Mobile', (Id)record.get(item), objectTypeToPhoneFieldNames);
                        if(toPhoneNumber != null)
                            return toPhoneNumber;
                    }
                }
            }
        }
        //3. get 'mobile' from other linked std objects a -> z
        if(!relatedStandardObjectsMap.isEmpty()){
            for(String stndMobile : sortedStdKeyset){
                List<String> tempList = stndMobile.equalsIgnoreCase(Constant.CONTACT_OBJECT) ? new List<String>() : relatedStandardObjectsMap.get(stndMobile); 
                if(tempList.size()>0){
                    tempList.sort();
                    for(String item:tempList){
                        if((String)record.get(item)!=null){
                            toPhoneNumber = getPhoneFromRecord(record, item, 'Mobile', (Id)record.get(item), objectTypeToPhoneFieldNames);
                            if(toPhoneNumber != null)
                                return toPhoneNumber;
                        }    
                    }
                }
            }
        }
        //4. get 'mobile' form any linked custom objects a-> z
        if(!relatedCustomObjectsMap.isEmpty()){
            for(String cusMobile : sortedCustomKeyset){
                List<String> tempList = relatedCustomObjectsMap.get(cusMobile); 
                if(tempList.size()>0){
                    tempList.sort();
                    for(String item:tempList){
                        if((String)record.get(item)!=null){
                            toPhoneNumber = getPhoneFromRecord(record, item, 'Mobile', (Id)record.get(item), objectTypeToPhoneFieldNames);
                            if(toPhoneNumber != null)
                                return toPhoneNumber;
                        }   
                    }
                }
            }
        }
        //5.get 'phone' number form current object
        toPhoneNumber = getPhoneFromRecord(record, 'Phone', selectedObjId, objectTypeToPhoneFieldNames);
        if(toPhoneNumber != null)
            return toPhoneNumber;
        //6. get 'phone' number form linked contact linked to std object
        if(relatedStandardObjectsMap.containsKey('contact')){
            if(relatedStandardObjectsMap.get('contact')!=null){
                List<String> tempList = relatedStandardObjectsMap.get('contact');
                tempList.sort();
                for(String item:tempList){
                    toPhoneNumber = getPhoneFromRecord(record, item, 'Phone', (Id)record.get(item), objectTypeToPhoneFieldNames);
                    if(toPhoneNumber != null)
                        return toPhoneNumber;
                }
            }
        }
        //7.get 'phone' number from linked lead to std object
        if(relatedStandardObjectsMap.containsKey('lead')){
            if(relatedStandardObjectsMap.get('lead')!=null){
                List<String> tempList = new List<String>();
                tempList = relatedStandardObjectsMap.get('lead');
                tempList.sort();
                for(String item:tempList){
                    toPhoneNumber = getPhoneFromRecord(record, item, 'Phone', (Id)record.get(item), objectTypeToPhoneFieldNames);
                    if(toPhoneNumber != null)
                        return toPhoneNumber;
                }
            }
        }
        //8.get 'phone' number from linked account to std object
        if(relatedStandardObjectsMap.containsKey('account')){
            if(relatedStandardObjectsMap.get('account')!=null){
                List<String> tempList = new List<String>();
                tempList = relatedStandardObjectsMap.get('account');
                tempList.sort();
                for(String item:tempList){
                    toPhoneNumber = getPhoneFromRecord(record, item, 'Phone', (Id)record.get(item), objectTypeToPhoneFieldNames);
                    if(toPhoneNumber != null)
                        return toPhoneNumber;
                }
            }
        }
        //9.get 'phone' number form other linked std objects to std object a -> z 
        if(!relatedStandardObjectsMap.isEmpty()){
            for(String stndMobile : sortedStdKeyset){
                List<String> tempList = (stndMobile.equalsIgnoreCase(Constant.CONTACT_OBJECT) || 
                                        stndMobile.equalsIgnoreCase(Constant.LEAD_OBJECT) || 
                                        stndMobile.equalsIgnoreCase(Constant.ACCOUNT_OBJECT)) ?
                                        new List<String>() 
                                        : relatedStandardObjectsMap.get(stndMobile); 
                if(tempList.size()>0){
                    tempList.sort();
                    for(String item:tempList){
                        if((String)record.get(item)!=null){
                            toPhoneNumber = getPhoneFromRecord(record, item, 'Phone', (Id)record.get(item), objectTypeToPhoneFieldNames);
                            if(toPhoneNumber != null)
                                return toPhoneNumber;
                        }    
                    }
                }
            }
        }
        //10.get 'phone' number form other linked custom objects to std object a -> z
        if(!relatedCustomObjectsMap.isEmpty()){
            for(String cusMobile : sortedCustomKeyset){
                List<String> tempList = relatedCustomObjectsMap.get(cusMobile); 
                if(tempList.size()>0){
                    tempList.sort();
                    for(String item:tempList){
                        if((String)record.get(item)!=null){
                            toPhoneNumber = getPhoneFromRecord(record, item, 'Phone', (Id)record.get(item), objectTypeToPhoneFieldNames);
                            if(toPhoneNumber != null)
                                return toPhoneNumber;
                        }   
                    }
                }
            }
        }
        //11. get number form phone type field from current object
        toPhoneNumber = getPhoneFromRecord(record, '', selectedObjId, objectTypeToPhoneFieldNames);
        if(toPhoneNumber != null)
            return toPhoneNumber;
        //12.get number form phone type field form linked contact
        if(relatedStandardObjectsMap.containsKey('contact')){
            if(relatedStandardObjectsMap.get('contact')!=null){
                List<String> tempList = new List<String>();
                tempList = relatedStandardObjectsMap.get('contact');
                tempList.sort();
                for(String item:tempList){
                    toPhoneNumber = getPhoneFromRecord(record, item, 'Rest', (Id)record.get(item), objectTypeToPhoneFieldNames);
                    if(toPhoneNumber != null)
                        return toPhoneNumber;
                }
            }
        }
        //13. get number from phone type field from linked lead
        if(relatedStandardObjectsMap.containsKey('lead')){
            if(relatedStandardObjectsMap.get('lead')!=null){
                List<String> tempList = relatedStandardObjectsMap.get('lead');
                tempList.sort();
                for(String item:tempList){
                    toPhoneNumber = getPhoneFromRecord(record, item, 'Rest', (Id)record.get(item), objectTypeToPhoneFieldNames);
                    if(toPhoneNumber != null)
                        return toPhoneNumber;
                }
            }
        }
        //14. get number from phone type field from linked account
        if(relatedStandardObjectsMap.containsKey('account')){
            if(relatedStandardObjectsMap.get('account')!=null){
                List<String> tempList = relatedStandardObjectsMap.get('account');
                tempList.sort();
                for(String item:tempList){
                    toPhoneNumber = getPhoneFromRecord(record, item, 'Rest', (Id)record.get(item), objectTypeToPhoneFieldNames);
                    if(toPhoneNumber != null)
                        return toPhoneNumber;
                }
            }
        }
        //15. get number from phone type field from linked other std objects a -> z 
        if(!relatedStandardObjectsMap.isEmpty()){
            for(String stdPhoneTypeField : sortedStdKeyset){
                List<String> tempList = stdPhoneTypeField.equalsIgnoreCase(Constant.CONTACT_OBJECT) ||
                                        stdPhoneTypeField.equalsIgnoreCase(Constant.LEAD_OBJECT) ||
                                        stdPhoneTypeField.equalsIgnoreCase(Constant.ACCOUNT_OBJECT) ? 
                                        new List<String>() :
                                        relatedStandardObjectsMap.get(stdPhoneTypeField); 
                if(tempList.size()>0){
                    tempList.sort();
                    for(String item:tempList){
                        if((String)record.get(item)!=null){
                            toPhoneNumber = getPhoneFromRecord(record, item, 'Rest', (Id)record.get(item), objectTypeToPhoneFieldNames);
                            if(toPhoneNumber != null)
                                return toPhoneNumber;
                        }    
                    }
                }
            }
        }
        //15. get number from phone type field from linked custom objects a -> z 
        if(!relatedCustomObjectsMap.isEmpty()){
            for(String cusPhoneTypeField : sortedCustomKeyset){
                List<String> tempList = relatedCustomObjectsMap.get(cusPhoneTypeField); 
                if(tempList.size()>0){
                    tempList.sort();
                    for(String item:tempList){
                        if((String)record.get(item)!=null){
                            toPhoneNumber = getPhoneFromRecord(record, item, 'Rest', (Id)record.get(item), objectTypeToPhoneFieldNames);
                            if(toPhoneNumber != null)
                                return toPhoneNumber;
                        }
                    }
                }
            }
        }

        if(!polymorphicFieldsIds.isEmpty()){
            for(Id tempId : polymorphicFieldsIds){
                PhoneInformation tempPhoneInformation = RetrievePreferredPhoneNumber.retrievePhoneAndPhoneInformationFromIds(new List<Id>{tempId}).get(tempId);
                if(!String.isBlank(tempPhoneInformation.phone))
                    return tempPhoneInformation;
            }
        }
        return new PhoneInformation('', '', 'Rest', '');
    }

    private static PhoneInformation getPhoneFromRecord(SObject record, String filter, Id selectedRecordId, Map<String, Map<String, List<String>>> objectTypeToFilteredPhoneFields){
        return getPhoneFromRecord(record, '', filter, selectedRecordId, objectTypeToFilteredPhoneFields);
    }

    /**
     * @description getPhoneFromRecord returns phone from record via relationships, label contain 'filter'
    **/

    private static PhoneInformation getPhoneFromRecord(SObject record, String fieldName, String filter, Id selectedRecordId, Map<String, Map<String, List<String>>> objectTypeToFilteredPhoneFields){
        PhoneInformation ret = new PhoneInformation();
        if(selectedRecordId == null || selectedRecordId.getsObjectType() == null || selectedRecordId.getsObjectType().getDescribe() == null){
            return null;
        }
        filter = String.isBlank(filter) ? 'Rest' : filter;
        ret.phoneType = filter;
        ret.locale = UserInfo.getLocale();
        String apiName = selectedRecordId.getsObjectType().getDescribe().getName();
        if(''.equals(fieldName)){
            for(String field : objectTypeToFilteredPhoneFields.get(apiName).get(filter)){
                if(!'id'.equals(field) && !String.IsBlank((String)record.get(field))){
                    ret.phone = (String) record.get(field);
                    ret.ownerId = (String) record.get('ownerid');
                    return ret;
                }
            }
        }else{
            String relationshipName = record.Id.getsObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getRelationshipName();
            for(String field : objectTypeToFilteredPhoneFields.get(apiName).get(filter)){
                String temp = (String) record.getSObject(relationshipName).get(field);
                if(!String.IsBlank(temp)){
                    ret.phone = temp;
                    ret.ownerId = (String) record.getSObject(relationshipName).get('ownerid');
                    return ret;
                }
            }
        }
        return null;
    }
}