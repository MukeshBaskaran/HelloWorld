/**
* 
* @author        Santosh Gudge(santosh@comitydesigns.com)
* @date          06.13.2014
* @description   Util class contains utility methods used by the apex classes 
*                in Agent One for Salesforce application
*
*
* @important! before writting any function that operate on String please check String class in System namespace:
*             https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_string.htm
*             before writting any function that operate on std types please check docs first, thanks MM
*
**/
public with sharing class Util {

    public static final Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
    private static final String cssLineSpacingPTagOpening = '<p style="margin-top:0.5%;margin-bottom:0.5%">';
    private static final String cssLineSpacingPTagClosing = '</p>';
    private static final Integer northAmericanPhoneNumberLength = 11;
    private static final String northAmericaCountryCode = '+1';
    public static String namespace =  getNamespace();
    public static final Integer CampaignShortcodeRecordLimit = 10000;
    public static final Integer BulkSmsShortcodeRecordLimit = 200;
    public static final Integer LongcodeRecordLimit = 25;

    public static String GetResourceURL(String resourceName) {

        List<StaticResource> resourceList = [
           SELECT Name, NamespacePrefix, SystemModStamp
           FROM StaticResource
           WHERE Name = :resourceName
        ];

        if (resourceList.size() == 1) {
           String namespaceRes = resourceList[0].NamespacePrefix;
           return '/resource/'
              + resourceList[0].SystemModStamp.getTime() + '/'
              + (namespaceRes != null && namespaceRes != '' ? namespaceRes + '__' : '')
              + resourceName;
        } else return '';
    }

    /**
    * @description getPhoneFieldsFromRelationship returns 'phone' type field list with relationship prefix from the given object which label contains 'filter'
    **/

    public static List<String> getPhoneFieldsFromRelationship(String fieldName, String objApiName, String filter, Id objectId){
        Schema.DescribeFieldResult dfr = objectId.getsObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<String> fieldList = new List<String>();
        if(dfr.isNamePointing())
            return fieldList;
        String relationshipName = objectId.getsObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getRelationshipName() + '.';
        for(String phoneField : Util.getPhoneNumberFilteredFields(objApiName, filter)){
            if(!'id'.equals(phoneField))
                fieldList.add(relationshipName + phoneField);
        }
        return fieldList;
    }

    /**
     * @description getPhoneNumberFilteredFields returns 'phone' type field list from the given object which label contains 'filter'
     * @param objName, filter
     * @return List of phone type fields filtered by filter sorted by label name
    **/

    public static List<String> getPhoneNumberFilteredFields(String objName, String filter){
        if(objName == null)
            return null;
        String textInLabel = filter != null ? filter : '';
        List<String> fieldList = new List<String>{'id','ownerid'};
        Boolean shouldAddNamespace = objName.startsWithIgnoreCase(namespace);
         //Getting all fields from specified object
        Map<String, Schema.SObjectField> objFieldMap = Schema.describeSObjects(new String[]{objName})[0].fields.getMap();
        Map<String,List<String>> fieldLabelMap = new Map<String,List<String>>();
        for(String fieldName : objFieldMap.keyset()){
            if(objFieldMap.get(fieldName).getDescribe().isAccessible()){
                String label = objFieldMap.get(fieldName).getDescribe().getLabel().toLowerCase();
                String fielddataType = String.valueOf(objFieldMap.get(fieldName).getDescribe().getType());
                List<String> tempList = new List<String>();
                //Checking if field is Phone type and contains filter
                if(fielddataType == 'Phone' && label.containsIgnoreCase(textInLabel)){
                    //If labels are the same, sort fields by api name
                    if(fieldLabelMap.containsKey(label))
                        tempList = fieldLabelMap.get(label);
                    String namespaceField = fieldName.endsWithIgnoreCase('__c') && shouldAddNamespace ? namespace + fieldName : fieldName;
                    tempList.add(namespaceField);
                    tempList.sort();
                    fieldLabelMap.put(label,tempList);
                }
            }
        }
        List<String> sortedLabels = new List<String>(fieldLabelMap.keySet());
        sortedLabels.sort();
        for(String l : sortedLabels){
            fieldList.addAll(fieldLabelMap.get(l));
        }
        return fieldList;
    }

    /**
     * @description getPhoneNumberFilteredFieldsByFilter returns 'phone' type field map from the given object which label contains filters 'phone', 'mobile', and rest phone fields
     * @param objName
     * @return Map filter -> List of phone type fields sorted by label name
    **/

    public static Map<String, List<String>> getPhoneNumberFilteredFieldsByFilter(String objName){
        if(objName == null)
            return null;
        Boolean shouldAddNamespace = objName.startsWithIgnoreCase(namespace);
         //Getting all fields from specified object
        Map<String, Schema.SObjectField> objFieldMap = Schema.describeSObjects(new String[]{objName})[0].fields.getMap();
        Map<String,List<String>> phoneFieldLabelMap = new Map<String,List<String>>();
        Map<String,List<String>> mobileFieldLabelMap = new Map<String,List<String>>();
        Map<String,List<String>> restNonFilteredFieldLabelMap = new Map<String,List<String>>();

        Map<String, List<String>> retMap = new Map<String, List<String>>();

        for(String fieldName : objFieldMap.keyset()){
            if(objFieldMap.get(fieldName).getDescribe().isAccessible()){
                String label = objFieldMap.get(fieldName).getDescribe().getLabel().toLowerCase();
                String fielddataType = String.valueOf(objFieldMap.get(fieldName).getDescribe().getType());
                List<String> tempList = new List<String>();
                //Checking if field is Phone type and contains filter
                if(fielddataType == 'Phone'){
                    //If labels are the same, sort fields by api name
                    if(label.containsIgnoreCase('Mobile')){
                        if(mobileFieldLabelMap.containsKey(label))
                            tempList = mobileFieldLabelMap.get(label);
                        String namespaceField = fieldName.endsWithIgnoreCase('__c') && shouldAddNamespace ? namespace + fieldName : fieldName;
                        tempList.add(namespaceField);
                        tempList.sort();
                        mobileFieldLabelMap.put(label,tempList);
                    }else if(label.containsIgnoreCase('Phone')){
                        if(phoneFieldLabelMap.containsKey(label))
                            tempList = phoneFieldLabelMap.get(label);
                        String namespaceField = fieldName.endsWithIgnoreCase('__c') && shouldAddNamespace ? namespace + fieldName : fieldName;
                        tempList.add(namespaceField);
                        tempList.sort();
                        phoneFieldLabelMap.put(label,tempList);
                    }else{
                        if(restNonFilteredFieldLabelMap.containsKey(label))
                            tempList = restNonFilteredFieldLabelMap.get(label);
                        String namespaceField = fieldName.endsWithIgnoreCase('__c') && shouldAddNamespace ? namespace + fieldName : fieldName;
                        tempList.add(namespaceField);
                        tempList.sort();
                        restNonFilteredFieldLabelMap.put(label,tempList);
                    }
                }
            }
        }
        List<String> sortedLabels = new List<String>(phoneFieldLabelMap.keySet());
        sortedLabels.sort();
        List<String> fieldList = new List<String>();
        for(String l : sortedLabels){
            fieldList.addAll(phoneFieldLabelMap.get(l));
        }
        retMap.put('Phone', fieldList);

        sortedLabels = new List<String>(mobileFieldLabelMap.keySet());
        sortedLabels.sort();
        fieldList = new List<String>();
        for(String l : sortedLabels){
            fieldList.addAll(mobileFieldLabelMap.get(l));
        }
        retMap.put('Mobile', fieldList);

        sortedLabels = new List<String>(restNonFilteredFieldLabelMap.keySet());
        sortedLabels.sort();
        fieldList = new List<String>();
        for(String l : sortedLabels){
            fieldList.addAll(restNonFilteredFieldLabelMap.get(l));
        }
        retMap.put('Rest', fieldList);
        return retMap;
    }


    /**
    * @description this function retrieve fields from object that we might use, and only them.
    * @return list of object fields with related object names
    **/

    public static List<String> getNeededFieldForQuery(String apiName){
        Set<String> avoidThisFields = new Set<String>{'contactName', 'leadName', 'accountName', 'caseFromRelationship'};
        Set<String> relationshipNames = new Set<String>{'accountRelationship', 'leadRelationship', 'contactRelationship', 'caseRelationship'};
        List<String> childFieldList = new List<String>();
        Set<String> preventDuplicates = new Set<String>();
        Map<String, List<String>> neededFieldMap = Util.getNeededFieldMap(apiName);
        for(String key : neededFieldMap.keySet()){
            if(!avoidThisFields.contains(key)){
                if(relationshipNames.contains(key)){
                    String namefield = 'caseRelationship'.equals(key) ? '.casenumber' : '.name';
                    for(String field : neededFieldMap.get(key)){
                        preventDuplicates.add(field + namefield);
                    }
                }else{
                    preventDuplicates.addAll(neededFieldMap.get(key));
                }
            }else{
                for(String field : neededFieldMap.get(key)){
                    preventDuplicates.add(field);
                }
            }
        }
        childFieldList.addAll(preventDuplicates);
        childFieldList.add('Id');
        childFieldList.add('LastModifiedDate');
        return childFieldList;
    }

    /**
    * @description this function retrieve fields from object that we might use.
    * @return Map logic type -> list of objet fields used by logic
    **/

    public static Map<String, List<String>> getNeededFieldMap(String apiName){
        Map<String, Schema.SObjectField> objFieldMap = Schema.getGlobalDescribe().get(apiName).getDescribe().fields.getMap();
        List<String> sortedFieldName = new List<String>(objFieldMap.keySet());

        Map<String,List<String>> fieldMap = new Map<String,List<String>>();

        String objectName = Schema.getGlobalDescribe().get(apiName).getDescribe().getLocalName().removeEnd('__c');
        sortedFieldName.sort();

        List<String> temp = new List<String>();
        Set<String> searchableDataTypes = new Set<String>();
        searchableDataTypes.add('PHONE');
        searchableDataTypes.add('EMAIL');
        searchableDataTypes.add('STRING');
        searchableDataTypes.add('PICKLIST');

        for(String fieldName : sortedFieldName){
            Schema.DescribeFieldResult dfr = objFieldMap.get(fieldName).getDescribe();
            if(dfr.isAccessible()){
                String fieldDataType = String.valueOf(dfr.getType());
                String fieldLabel = dfr.getLabel();
                //get fields from which we can get name
                if(searchableDataTypes.contains(fieldDataType)){
                    if(fieldName.containsIgnoreCase(objectName) && fieldName.containsIgnoreCase('Name')){
                        temp = fieldMap.get('objectAndNameInApiName') == null ? new List<String>() : fieldMap.get('objectAndNameInApiName');
                        temp.add(fieldName);
                        fieldMap.put('objectAndNameInApiName', temp);
                    }else if(dfr.isNameField()){
                        temp = fieldMap.get('name') == null ? new List<String>() : fieldMap.get('name');
                        temp.add(fieldName);
                        fieldMap.put('name',temp);
                    }else if(!fieldName.containsIgnoreCase(objectName) && fieldName.containsIgnoreCase('Name')){
                        temp = fieldMap.get('nameInApiName') == null ? new List<String>() : fieldMap.get('nameInApiName');
                        temp.add(fieldName);
                        fieldMap.put('nameInApiName', temp);
                    }

                    //get all other data no matter if 'Name' is in apiName or Label
                    if(fieldLabel.containsIgnoreCase('Case Number') || fieldName.containsIgnoreCase('CaseNumber')){
                        temp = fieldMap.get('caseNumber') == null ? new List<String>() : fieldMap.get('caseNumber');
                        temp.add(fieldName);
                        fieldMap.put('caseNumber', temp);
                    }else if(fieldDataType.equalsIgnoreCase('Phone') && !fieldLabel.containsIgnoreCase('Mobile') && !fieldLabel.containsIgnoreCase('Fax')){
                        temp = fieldMap.get('phone') == null ? new List<String>() : fieldMap.get('phone');
                        temp.add(fieldName);
                        fieldMap.put('phone', temp);
                    }else if(fieldDataType.equalsIgnoreCase('Email')){
                        temp = fieldMap.get('email') == null ? new List<String>() : fieldMap.get('email');
                        temp.add(fieldName);
                        fieldMap.put('email', temp);
                    }else if(fieldLabel.containsIgnoreCase('Status')){
                        temp = fieldMap.get('status') == null ? new List<String>() : fieldMap.get('status');
                        temp.add(fieldName);
                        fieldMap.put('status', temp);
                    }else if(fieldLabel.containsIgnoreCase('Stage')){
                        temp = fieldMap.get('stage') == null ? new List<String>() : fieldMap.get('stage');
                        temp.add(fieldName);
                        fieldMap.put('stage', temp);
                    }
                    else if(fieldName.containsIgnoreCase('IsPersonAccount')){
                       temp = fieldMap.get('IsPersonAccount') == null ? new List<String>() : fieldMap.get('IsPersonAccount');
                       temp.add(fieldName);
                       fieldMap.put('IsPersonAccount', temp);
                    }
                }

                if(dfr.getReferenceTo().size() > 0){
                    if(dfr.getReferenceTo().get(0).getDescribe().isSearchable()){
                        String relationshipObjectName = String.valueOf(dfr.getReferenceTo()[0]);
                        if(relationshipObjectName.equals(Constant.CONTACT_OBJECT)){
                            temp = fieldMap.get('contactName') == null ? new List<String>() : fieldMap.get('contactName');
                            temp.add(fieldName);
                            fieldMap.put('contactName', temp);
                            temp = fieldMap.get('contactRelationship') == null ? new List<String>() : fieldMap.get('contactRelationship');
                            temp.add(dfr.getRelationshipName());
                            fieldMap.put('contactRelationship', temp);
                        }else if(relationshipObjectName.equals(Constant.LEAD_OBJECT)){
                            temp = fieldMap.get('leadName') == null ? new List<String>() : fieldMap.get('leadName');
                            temp.add(fieldName);
                            fieldMap.put('leadName', temp);
                            temp = fieldMap.get('leadRelationship') == null ? new List<String>() : fieldMap.get('leadRelationship');
                            temp.add(dfr.getRelationshipName());
                            fieldMap.put('leadRelationship', temp);
                        }else if(relationshipObjectName.equals(Constant.ACCOUNT_OBJECT)){
                            temp = fieldMap.get('accountName') == null ? new List<String>() : fieldMap.get('accountName');
                            temp.add(fieldName);
                            fieldMap.put('accountName', temp);
                            temp = fieldMap.get('accountRelationship') == null ? new List<String>() : fieldMap.get('accountRelationship');
                            temp.add(dfr.getRelationshipName());
                            fieldMap.put('accountRelationship', temp);
                        }else if(relationshipObjectName.equals(Constant.CASE_OBJECT)){
                            temp = fieldMap.get('caseFromRelationship') == null ? new List<String>() : fieldMap.get('caseFromRelationship');
                            temp.add(fieldName);
                            fieldMap.put('caseFromRelationship', temp);
                            temp = fieldMap.get('caseRelationship') == null ? new List<String>() : fieldMap.get('caseRelationship');
                            temp.add(dfr.getRelationshipName());
                            fieldMap.put('caseRelationship', temp);
                        }
                    }
                }
            }
        }
        return fieldMap;
    }

    /**
    * @description this function escapes all restricted characters for SOSL and SOQL
    *
    **/

    public static String escapeReservedCharacters(String stringToEscape){
        List<String> reservedChars = new List<String>();
        reservedChars.add('&');
        reservedChars.add('|');
        reservedChars.add('!');
        reservedChars.add('(');
        reservedChars.add(')');
        reservedChars.add('{');
        reservedChars.add('}');
        reservedChars.add('[');
        reservedChars.add(']');
        reservedChars.add('^');
        reservedChars.add('~');
        reservedChars.add('*');
        reservedChars.add('?');
        reservedChars.add(':');
        reservedChars.add('-');
        reservedChars.add('\'');
        reservedChars.add('\\');
        String retString = stringToEscape;
        for(String character : reservedChars){
            retString = retString.replace(character, '\\' + character);
        }
        return retString;
    }

    /**
    * @description function checks for 10 most recent objects which have phoneNumber or have link to objects that have phoneNumber
    *              i.e. if we call this function for Case object it will return Cases which linked Account/Contact/OtherObject has phoneNumber
    *              also every retutned record will have Name(or CaseNumber for Cases) of linked record
    * @param list of objects to be returned
    * @param phoneNumber to search for
    **/

    public static List<sObject> getObjectsData(List<String> customObjectsTemp, String phoneNumber, Integer soslLimit , Integer soqlLimit){
        //apiName -> list of records found in all queries
        Set<String> allObjects = new Set<String>();

        //main objets that needs to be returned
        Map<String, List<sObject>> objectApiNameToFoundRecords = new Map<String, List<sObject>>();

        //main objects -> list of relationship objects
        Map<String, List<String>> mainObjectWithRelationships = new Map<String, List<String>>();

        //main objects -> relationship object Type -> list of record Ids
        Map<String, Map<String, List<String>>> mainObjectWithRelationshipsFound = new Map<String, Map<String, List<String>>>();

        //  objType    fieldName   fieldData
        Map<String, Map<String, Map<String, String>>> objectsFieldToRelationshipName = new Map<String, Map<String, Map<String, String>>>();
        for(String item: customObjectsTemp){
            List<String> tempList = new List<String>();
            tempList = Util.getCustomObjectsRelationships(item);
            mainObjectWithRelationships.put(item, tempList);
            objectsFieldToRelationshipName.put(item, Util.getFieldsToRelationshipName(item));
            allObjects.addAll(tempList);
        }

        //Search for all objects and all linkedObjects in SOSL
        allObjects.addAll(customObjectsTemp);
        if(!allObjects.isEmpty()){
            String soslQuery = 'FIND \'';
            for(String item : getPhoneNumberVariations(phoneNumber)){
                soslQuery += Util.escapeReservedCharacters(item) + ' OR ';
            }
            soslQuery = soslQuery.removeEnd('OR ').trim();
            soslQuery += '\' IN Phone FIELDS RETURNING ';
            for(String item : allObjects){
                Set<String> avoidDuplicateFields = new Set<String>();
                avoidDuplicateFields.addAll(Util.getNeededFieldForQuery(item));
                List<String> fields = new List<String>();//Util.getNeededFieldForQuery(item);
                //adding fields from relatiomnships
                if(objectsFieldToRelationshipName.containsKey(item)){
                    Map<String, Map<String,String>> fieldToRelationshipName = objectsFieldToRelationshipName.get(item);
                    for(String fieldName : fieldToRelationshipName.keySet()){
                        //fields
                        avoidDuplicateFields.addAll(Util.getFieldsFromRelationship(fieldName, fieldToRelationshipName.get(fieldName).get('objectType'), fieldToRelationshipName.get(fieldName).get('relationshipName')));
                    }
                }
                fields.addAll(avoidDuplicateFields);
                if(!fields.isEmpty())
                    soslQuery += item+' (' + String.join(fields,', ') +'  Order By LastModifiedDate DESC LIMIT ' + soslLimit + '),';
            }
            soslQuery = soslQuery.removeEnd(',');
            System.debug('POINT QUERY: ' + soslQuery);
            List<List<SObject>> resultSet = Search.query(soslQuery);
            for(List<SObject> item : resultSet){
                if(!item.isEmpty()){
                    String itemType = String.valueOf(item[0].getSObjectType());
                    for(SObject itemSobject:item){
                        List<SObject> tempObjList = objectApiNameToFoundRecords.containsKey(itemType)
                                                    ? objectApiNameToFoundRecords.get(itemType)
                                                    : new List<SObject>();
                        tempObjList.add(itemSobject);
                        objectApiNameToFoundRecords.put(itemType, tempObjList);

                        //getting linked records
                        if(objectsFieldToRelationshipName.containsKey(itemType)){
                            for(String field : objectsFieldToRelationshipName.get(itemType).keySet()){
                                Id temp = (Id)itemSobject.get(field);
                                if(temp != null){
                                    if(temp.getsObjectType() != null && temp.getsObjectType().getDescribe() != null && temp.getsObjectType().getDescribe().isAccessible()){
                                        String objType = temp.getsObjectType().getDescribe().getName();
                                        String relationshipFieldName = objectsFieldToRelationshipName.get(itemType).get(field).get('relationshipName');
                                        SObject obj = itemSobject.getSObject(relationshipFieldName);
                                        tempObjList = objectApiNameToFoundRecords.containsKey(objType)
                                                    ? objectApiNameToFoundRecords.get(objType)
                                                    : new List<SObject>();
                                        tempObjList.add(obj);
                                        objectApiNameToFoundRecords.put(objType, tempObjList);
                                    }
                                }
                            }
                        }

                        //for linked objects
                        for(String itemKey : mainObjectWithRelationships.keySet()){
                            for(String rItem : mainObjectWithRelationships.get(itemKey)){
                                if(rItem == itemType){
                                    Map<String, List<String>> tempMap = new Map<String, List<String>>();
                                    if(mainObjectWithRelationshipsFound.containsKey(itemKey))
                                        tempMap = mainObjectWithRelationshipsFound.get(itemKey);
                                    List<String>  tempList = new List<String>();
                                    if(tempMap.containsKey(itemType))
                                        tempList = tempMap.get(itemType);
                                    tempList.add((String)itemSobject.get('Id'));
                                    tempMap.put(itemType, tempList);
                                    mainObjectWithRelationshipsFound.put(itemKey, tempMap);
                                }
                            }
                        }
                    }
                }
            }
            //If there are linked objects found for primary objects look for primary objects in SOQL
            List<String> soqlQueries = new List<String>();
            if(!mainObjectWithRelationshipsFound.isEmpty()){
                for(String item:mainObjectWithRelationshipsFound.keySet()){
                    String soqlQuery = '';
                    List<String> fields = Util.getNeededFieldForQuery(item);
                    if(!fields.isEmpty()){
                        soqlQuery = 'Select ' + String.join(fields,', ') + ' From ' +item+ ' Where ';

                        Map<String, List<String>> tempMap = new Map<String, List<String>>();
                        Map<String, String> tempMapChild = new Map<String, String>();
                        tempMap = Util.getRelationshipMap(item);
                        for(String itemType:mainObjectWithRelationshipsFound.get(item).keySet()){
                            Set<String> avoidDuplicateIds = new Set<String>();
                            avoidDuplicateIds.addAll(mainObjectWithRelationshipsFound.get(item).get(itemType));
                            String tempList = '\'' + String.join(new List<String>(avoidDuplicateIds), '\',\'') + '\'';
                            if(tempMap.containsKey(itemType)){
                                for(String fieldName : tempMap.get(itemType)){
                                    soqlQuery += fieldName +' in (' + tempList + ')';
                                    soqlQuery += ' OR ';
                                }
                            }
                        }
                        soqlQuery = soqlQuery.removeEnd('OR ').trim();
                        soqlQuery += ' ORDER BY LastModifiedDate DESC LIMIT ' + soqlLimit;
                        soqlQueries.add(soqlQuery);
                    }
                }
            }
            if(!soqlQueries.isEmpty()){
                for(String item:soqlQueries){
                    system.debug('POINT QUERY: ' + item);
                    for(List<sObject> result:Database.query(item)){
                        if(!result.isEmpty()){
                            String itemType = String.valueOf(result[0].getSObjectType());
                            List<SObject> tempObjList = objectApiNameToFoundRecords.containsKey(itemType)
                                                    ? objectApiNameToFoundRecords.get(itemType)
                                                    : new List<SObject>();
                            for(sObject itemSobject:result){
                                tempObjList.add(itemSobject);
                            }
                            objectApiNameToFoundRecords.put(itemType, tempObjList);
                        }
                    }
                }
            }
        }
        //Sorting results by LastModifiedDate, taking only 10 per object type with elimination duplicates
        Set<Id> preventDuplicates = new Set<Id>();
        List<sObject> resultList = new List<sObject>();
        List<SObjectSorter> finalSorter = new List<SObjectSorter>();
        for(String objType : mainObjectWithRelationships.keySet()){
            if(objectApiNameToFoundRecords.get(objType) != null){
                List<SObjectSorter> tempSorter = new List<SObjectSorter>();
                for(SObject obj : objectApiNameToFoundRecords.get(objType)){
                    if(!preventDuplicates.contains((Id)obj.get('Id'))){
                        tempSorter.add(new SObjectSorter(obj));
                        preventDuplicates.add((Id)obj.get('Id'));
                    }
                }
                tempSorter.sort();
                List<SObjectSorter> tempToRet = new List<SObjectSorter>();
                for(SObjectSorter sortedObj : tempSorter){
                    if(tempToRet.size()<10){
                        String itemType = String.valueOf(sortedObj.obj.getSObjectType());
                        if(!sortedObj.isPersonContact){
                            tempToRet.add(sortedObj);
                        }else{
                            system.debug('Contact.IsPersonAccount is true for id='+sortedObj.obj);
                        }
                    }else{
                        break;
                    }
                }
            finalSorter.addAll(tempToRet);
            }
        }
        finalSorter.sort();
        for(SObjectSorter sortedObj : finalSorter){
            resultList.add(sortedObj.obj);
        }
        return resultList ;
    }

    public static List<String> getFieldsFromRelationship(String fieldName, String objApiName, String relationshipName){
        List<String> fieldList = new List<String>();
        Map<String, Schema.SObjectField> describeFieldsMap = Schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();
        for(String field : Util.getNeededFieldForQuery(objApiName)){
            if(!'id'.equals(field))
                fieldList.add(relationshipName + '.' + field);
        }
        return fieldList;
    }

    public static Map<String, Map<String,String>> getFieldsToRelationshipName(String objName){
        Map<String, Map<String, String>> fieldToRelationshipNameMap  = new Map<String, Map<String,String>>();
        if(String.isEmpty(objName))
            return fieldToRelationshipNameMap;
        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(objName).getDescribe();
        Set<String> linkedObjects = Util.getAllRelationshipObjects();

        Map<string, schema.SObjectField> objFieldMap = dsr.fields.getMap();
        for(String field : objFieldMap.keyset()){
            Schema.DescribeFieldResult dfr = objFieldMap.get(field).getDescribe();
            if(dfr.getReferenceTo().size()>0){
                if(dfr.getReferenceTo().get(0).getDescribe().isSearchable() && dfr.isAccessible()){
                    String fielddataType = String.valueOf(dfr.getReferenceTo()[0]);
                    if(linkedObjects.contains(fielddataType) && dfr.getReferenceTo()[0].getDescribe().isAccessible()){
                        if(!dfr.getRelationshipName().endsWithIgnoreCase('__pr') && !dfr.getRelationshipName().endsWithIgnoreCase('__pc')){
                            Map<String, String> fieldData = new Map<String, String>();
                            fieldData.put('relationshipName', dfr.getRelationshipName());
                            fieldData.put('objectType', dfr.getReferenceTo()[0].getDescribe().getName());
                            fieldToRelationshipNameMap.put(field, fieldData);
                        }
                    }
                }
            }
        }
        return fieldToRelationshipNameMap;
    }

    /**
    *@description finction returns list of fields respecting FLS
    *
    **/
    public static List<String> getAccessibleFields(String objectApiName){
        Map<String, Schema.SObjectField> objFieldMap = Schema.describeSObjects(new String[]{objectApiName})[0].fields.getMap();
        List<String> retFields = new List<String>();
        for(String fieldName : objFieldMap.keySet()){
            if(objFieldMap.get(fieldName).getDescribe().isAccessible())
                retFields.add(fieldName);
        }
        return retFields;
    }

    /**
    *@description finction returns list of fields, with Name fields of related objects respecting FLS for read
    *
    **/
    public static List<String> getAccessibleFieldsWithRelationshipNameFields(String objectApiName){
        Map<String, Schema.SObjectField> objFieldMap = Schema.describeSObjects(new String[]{objectApiName})[0].fields.getMap();
        List<String> retFields = new List<String>();
        for(String fieldName : objFieldMap.keySet()){
            Schema.DescribeFieldResult dfr = objFieldMap.get(fieldName).getDescribe();
            if(dfr.isAccessible())
                retFields.add(dfr.getName());
            if(dfr.getRelationshipName() != null){
                if(dfr.getReferenceTo().size()>0){
                    if(dfr.getReferenceTo().get(0).getDescribe().isSearchable() && dfr.isAccessible()){
                        String prefix = dfr.getReferenceTo().get(0).getDescribe().getKeyPrefix();
                        String nameField = '.Name';
                        if('500'.equals(prefix)){
                            nameField = '.CaseNumber';
                        }else if('800'.equals(prefix)){
                            nameField = '.ContractNumber';
                        }else if('801'.equals(prefix)){
                            nameField = '.OrderNumber';
                        }
                        retFields.add(dfr.getRelationshipName() + nameField);
                    }
                }
            }
        }
        return retFields;
    }
    /**
    *@description function returns list of fields, with Name fields of related objects respecting FLS for update
    *
    **/
    public static List<String> getUpdateableFieldsWithRelationshipNameFields(String objectApiName){
        Map<String, Schema.SObjectField> objFieldMap = Schema.describeSObjects(new String[]{objectApiName})[0].fields.getMap();
        List<String> retFields = new List<String>();
        for(String fieldName : objFieldMap.keySet()){
            Schema.DescribeFieldResult dfr = objFieldMap.get(fieldName).getDescribe();
            if((dfr.isAccessible() && dfr.isUpdateable()))
                retFields.add(fieldName);
            if(dfr.getRelationshipName() != null){
                if(dfr.getReferenceTo().size()>0){
                    if(dfr.getReferenceTo().get(0).getDescribe().isSearchable()){
                        String prefix = dfr.getReferenceTo().get(0).getDescribe().getKeyPrefix();
                        String nameField = '.Name';
                        if('500'.equals(prefix)){
                            nameField = '.CaseNumber';
                        }else if('800'.equals(prefix)){
                            nameField = '.ContractNumber';
                        }else if('801'.equals(prefix)){
                            nameField = '.OrderNumber';
                        }
                        retFields.add(dfr.getRelationshipName() + nameField);
                    }
                }
            }
        }
        return retFields;
    }

    /**
    * @descrption This function creates list of phone number variations to search for.
    *             If new variation will be used by customers, please add it to this function
    * @param phone number in any format
    **/
    @TestVisible
    public static List<String> getPhoneNumberVariations(String phoneNumber){
        Set<String> lst = new Set<String>();
        Boolean isNorthAmericanNumber = Util.IsNorthAmericanPhoneNumber(phoneNumber);
        String phoneNumberCleaned = phoneNumber.replaceAll('\\D', '');// remove all non numeric
        lst.add(phoneNumberCleaned);

        if(isNorthAmericanNumber){
            String temp = phoneNumberCleaned.right(10);
            lst.add(temp);
            lst.add('1' + temp);
            //lst.add('+1' + temp);
            //lst.add('+1' + temp.left(5) + '-'+temp.right(4));
            //lst.add('+1 ' + temp.left(5) + '-'+temp.right(4));
            //lst.add('(' + temp.left(3) + ')' + temp.mid(3, 3) + '-' + temp.right(4));
            //lst.add('+1(' + temp.left(3) + ')' + temp.mid(3, 3) + '-' + temp.right(4));
            //lst.add('+1(' + temp.left(3) + ')-' + temp.mid(3, 3) + '-' + temp.right(4));
            //lst.add('+1 (' + temp.left(3) + ')' + temp.mid(3, 3) + '-' + temp.right(4));
            //lst.add('+1 (' + temp.left(3) + ')-' + temp.mid(3, 3) + '-' + temp.right(4));
            //lst.add('(' + temp.left(3) + ') ' + temp.mid(3, 3) + '-' + temp.right(4));
            //lst.add('+1(' + temp.left(3) + ') ' + temp.mid(3, 3) + '-' + temp.right(4));
            //lst.add('+1 (' + temp.left(3) + ') ' + temp.mid(3, 3) + '-' + temp.right(4));
        }
        List<String> retList = new List<String>();
        retList.addAll(lst);
        List<String> formattedRetList = new List<String>();
        for(String phone : retList){
            formattedRetList.add('\"'+phone+'\"');
        }
        return formattedRetList;
    }

    /**
    * @description Retrieve available objects (api name) linked to ConversationHeader
    *
    **/
    public static Set<String> getAllRelationshipObjects(){
        return Util.getAllRelationshipObjects('Conversation_Header__c');
    }

    public static Set<String> getAllRelationshipObjects(String objectName){
        Set<String> allObjects = new Set<String>();
        if(String.isBlank(objectName))
            return allObjects;
        /*for(String item:getCustomObjectsRelationships(objectName)){
            if(CanAddObject(item)){
                allObjects.add(item);
            }
        }*/
        allObjects.addAll(Util.getCustomObjectsRelationships(objectName));
        return allObjects;
    }

    /**
    * @description retrieve object ApiName for relationships within param, excluding Constant.excludedObjectTypes
    * @param objectApiName
    **/
    public static List<String> getCustomObjectsRelationships(String objectApiName){
        List<String> relationshipsList = new List<String>();
        Set<String> excludeObjectTypes = Constant.excludeObjectTypes;

        Map<String, Schema.SObjectField> objFieldMap = Schema.describeSObjects(new String[]{objectApiName})[0].fields.getMap();
        for(String fieldName : objFieldMap.keySet()){
            Schema.DescribeFieldResult dfr = objFieldMap.get(fieldName).getDescribe();
            if(dfr.getRelationshipName() != null && dfr.getReferenceTo().size()>0){
                if(dfr.getReferenceTo().get(0).getDescribe().isSearchable()
                            && dfr.getReferenceTo().get(0).getDescribe().isAccessible()
                            && !excludeObjectTypes.contains(String.valueOf(dfr.getReferenceTo().get(0)).toLowerCase())){
                    relationshipsList.add(String.valueOf(dfr.getReferenceTo().get(0)));
                }
            }
        }
        return relationshipsList;
    }

    public static Map<String, String> getLinkedObjectsKeyPrefixToColumnNameMap(Boolean isGetRelationship){
        return getLinkedObjectsKeyPrefixToColumnNameMap(isGetRelationship, 'Conversation_Header__c');
    }

    public static Map<String, String> getLinkedObjectsKeyPrefixToColumnNameMap(Boolean isGetRelationship, String CustomObjectName){
        Map<String, String> objectsKeyPrefixToColumnNameMap = new Map<String, String>();
        Set<String> excludeObjectTypes = Constant.excludeObjectTypes;

        for(Schema.DescribeSobjectResult schemaResult : Schema.describeSObjects(new String[]{CustomObjectName})){
            for(SObjectField customField : schemaResult.fields.getMap().values()){
                Schema.DescribeFieldResult dfr = customField.getDescribe();
                if(dfr.getRelationshipName() != null && dfr.getReferenceTo().size()>0){
                    if(!excludeObjectTypes.contains(String.valueOf(dfr.getReferenceTo().get(0)).toLowerCase())){
                        if(dfr.getReferenceTo().get(0).getDescribe().isSearchable()){
                            String keyPrefix = dfr.getReferenceTo().get(0).getDescribe().getKeyPrefix();
                            objectsKeyPrefixToColumnNameMap.put(keyPrefix, (isGetRelationship || dfr.getName() == null) ? dfr.getRelationshipName() : dfr.getName());
                        }
                    }
                }
            }
        }
        return objectsKeyPrefixToColumnNameMap;
    }

    /**
     * @Date 11/20/2015
     * @Description Retrieve key prefixes for all custom objects linked to Conversation_Header__c
     * @Param none
     * @Return Map<String, String> (objectPrefix -> apiName)
    */

    public static Map<String, String> getLinkedObjectsKeyPrefixToApiNameMap(){
        return Util.getLinkedObjectsKeyPrefixToApiNameMap('Conversation_Header__c');
    }

    public static Map<String, String> getLinkedObjectsKeyPrefixToApiNameMap(String objectApiName){
        Map<String, String> objectsKeyPrefixToApiNameMap = new Map<String, String>();
        for (Schema.DescribeSObjectResult dsor : Schema.describeSObjects(new List<String>(Util.getAllRelationshipObjects(objectApiName))))
        {
            objectsKeyPrefixToApiNameMap.put(dsor.getKeyPrefix(), dsor.getName());
        }
        return objectsKeyPrefixToApiNameMap;
    }

    /**
    * @description Retrieve object API name -> list of fields API Name for linked objects that are not in excludeObjectTypes Set in param
    * @param Object Api Name
    * @return Map<String, String> (ObjectApiName -> FieldAPiName)
    **/

    public static Map<String, List<String>> getRelationshipMap(String objectApiName){
        Map<String, List<String>> relationshipsMap = new Map<String, List<String>>();
        Set<String> excludeObjectTypes = Constant.excludeObjectTypes;

        Map<String, Schema.SObjectField> objFieldMap = Schema.describeSObjects(new String[]{objectApiName})[0].fields.getMap();
        List<String> fieldList = new List<String>();
        for(String fieldName : objFieldMap.keySet()){
            Schema.DescribeFieldResult dfr = objFieldMap.get(fieldName).getDescribe();
            if(dfr.getRelationshipName() != null && dfr.getReferenceTo().size()>0){
                String objApiName = String.valueOf(dfr.getReferenceTo().get(0));
                if(dfr.getReferenceTo().get(0).getDescribe().isSearchable()
                            && dfr.getReferenceTo().get(0).getDescribe().isAccessible()
                            && !excludeObjectTypes.contains((objApiName).toLowerCase())){
                    fieldList = new List<String>();
                    if(relationshipsMap.containsKey(objApiName))
                        fieldList = relationshipsMap.get(objApiName);
                    fieldList.add(dfr.getName());
                    relationshipsMap.put(objApiName, fieldList);
                }
            }
        }
        return relationshipsMap;
    }

    /**
    * @description Retrieve object API name -> field API Name for linked objects that are not in excludeObjectTypes Set for Conversation Header
    * @return Map<String, String> (ObjectApiName -> FieldAPiName)
    **/

    public static Map<String,String> getRelationshipMapForConversationHeader(){
        Map<String, List<String>>  tempMapToFieldNameList = Util.getRelationshipMap('Conversation_Header__c');
        Map<String, String> retMap = new Map<String,String>();
        for(String key : tempMapToFieldNameList.keySet()){
            retMap.put(key, tempMapToFieldNameList.get(key)[0]);
        }
        return retMap;
    }

    /**
     * @description Retrieve default enable application values from custom settings
     * @Param  none
     * @Return LiveTextGlobalSettings__c records
     **/
    public static LiveTextGlobalSettings__c getLiveTextGlobalSettings()
    {
        // Retrieve default enable application values from custom settings
        LiveTextGlobalSettings__c returnValue;
        LiveTextGlobalSettings__c ltgsUser = LiveTextGlobalSettings__c.getInstance(UserInfo.getUserId());
        LiveTextGlobalSettings__c ltgsGlobal = LiveTextGlobalSettings__c.getOrgDefaults();
        returnValue = ltgsUser == null?(ltgsGlobal == null?null:ltgsGlobal):ltgsUser;
        return returnValue;
    }

    /**
     *  @description Returns a field map for a given sobject type.
     *  @param objectId
     *  @param priority
     *  @param error description
     */
    public static void insertException(String objectId, String priority, String errorDescription)
    {
        try{
            Exception__c exObject = new Exception__c();
            exObject.AssociatedUser__c = UserInfo.getUserId();
            exObject.ErrorDescription__c = errorDescription;
            exObject.ObjectId__c = objectId;
            exObject.Priority__c = priority;
            AccessController.insertAsUser(exObject);
        }catch (Exception ex){
            System.debug('ERROR during exception insert.');
        }
    }

   /**
    * @description: Adds the provided message to the ApexPages to be displayed on VF page.
    * @param msg, the message string.
    */
    public static void addMessageOnError(String msg){
        if(String.isNotBlank(msg)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, msg));
        }
    }

   /**
    * @description: Adds the save result message to the ApexPages, to be displayed on VF page.
    * @param result, object of Database.SaveResult as return by Database.update call.
    */
    public static void addMessageOnError(Database.SaveResult result){
        if(!result.isSuccess()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, result.getErrors()[0].getMessage()));
        }
    }

   /**
    * @description: Adds the delete result message to the ApexPages, to be displayed on VF page.
    * @param result, object of Database.DeleteResult as return by Database.delete call.
    */
    public static void addMessageOnError(Database.DeleteResult result){
        if(!result.isSuccess()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, result.getErrors()[0].getMessage()));
        }
    }

   /**
    * @description: Finds the namespace for the managed package.
    * @returns the namespace string.
    */
    public static String getNamespace(){
        String nameSpacePrefix = '';

        for (Schema.SObjectType sObjType : GLOBAL_DESCRIBE.values()){
            String sObjName = String.valueOf(sObjType);
            if(sObjType.getDescribe().isCustom() && sObjName.indexOf('LiveText') == 0 && sObjName.countMatches('__') == 2){
                nameSpacePrefix = sObjName.substring(0, sObjName.indexOf('__'));
                break;
            }
        }
        return (String.isNotBlank(nameSpacePrefix) ?  nameSpacePrefix + '__' :  nameSpacePrefix);
    }

    /**
    * @description: Determines if the current namespace is out production namespace
    * @returns true/false.
    */
    public static Boolean isProductionNamespace(){
       return namespace.equals('LiveText__');
    }

   /**
    * @description: Prepends the namespace for the managed package to the object name.
    * @returns the object name with namespace prefix.
    */
    public static String getObjectName(String objectName){
        return namespace+objectName;
    }

   /**
    * @description: Checks if LiveText application is conencted to Heywire APIs or not.
    * @returns true if connected.
    */
    public static Boolean isHeyWireConnected(){
        ConfigurationSettings__c configSettings = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
        Inbound_Connection_Status__c connectionStatus = Inbound_Connection_Status__c.getInstance(Constant.HEYWIRE_STATUS);

        if(configSettings != null){
            if(connectionStatus != null){
                return true;
            }else{
                addMessageOnError(System.Label.ConnectionExceptionMsg);
                return false;
            }
        }else{
            addMessageOnError(System.Label.ConnectionExceptionMsg);
            return false;
        }
    }

   /**
    * @description: Creates list of search type options for assign users functionality.
    * @returns List of select options to be displayed on admin page.
    */
    public static List<SelectOption> getSearchTypeList(){
        List<SelectOption> searchTypeList = new List<SelectOption>();
        searchTypeList.add(new SelectOption('User', 'User'));
        return searchTypeList;
    }

   /**
    * @description: Checks whether the list of given incoming message falls within the businesss hours
    *               associated with the support number in SMS_Text object.
    * @param List of SMS_Text__c smsList.
    * @returns Map of SMS_Text__c Id to boolean value, which shows if the sms is within business hours.
    */
    public static Map<Id, Boolean> isWithinBusinessHours(List<SMS_Text__c> smsList){
        Set<Id> liveTextNumberIds = new Set<Id>();
        Map<Id, Id> numberToBusinessHoursIdMap = new Map<Id, Id>();
        Map<Id, Boolean> smsToIsWithinBussinesHoursMap = new Map<Id, Boolean>();
        if(smsList != null && !smsList.isEmpty()){
            for(SMS_Text__c sms : smsList){
                liveTextNumberIds.add(sms.Support_Number__c);
            }
            List<LiveText_Number__c> liveTextNumberList = [Select Id, Business_Hours__c From LiveText_Number__c Where Id IN: liveTextNumberIds];
            if (liveTextNumberList != null && liveTextNumberList.size() > 0) {
                for (LiveText_Number__c liveTextNumber: liveTextNumberList) {
                   if(liveTextNumber.Business_Hours__c != null){
                        numberToBusinessHoursIdMap.put(liveTextNumber.Id, liveTextNumber.Business_Hours__c);
                   }
                }
            }

            for(SMS_Text__c sms : smsList){
                String businessHoursId = numberToBusinessHoursIdMap.get(sms.Support_Number__c);
                Boolean isWithinBusinessHours = String.isBlank(businessHoursId)
                                                ? true
                                                : sms.CreatedDate != null ? Businesshours.isWithin(businessHoursId, sms.CreatedDate)
                                                : Businesshours.isWithin(businessHoursId, System.now()) ;
                smsToIsWithinBussinesHoursMap.put(sms.Id, isWithinBusinessHours);
            }
        }
        return smsToIsWithinBussinesHoursMap;
    }

     /**
    * @description: Checks whether the list of given incoming message falls within the businesss hours
    *               associated with the support number in SMS_Text object.
    * @param List of SMS_Text__c smsList.
    * @returns Map of SMS_Text__c Id to boolean value, which shows if the sms is within business hours.
    */
    public static Map<Id, Boolean> isITREnabled(List<SMS_Text__c> smsList){
        Set<Id> liveTextNumberIds = new Set<Id>();
        Map<Id, Boolean> numberToITREnabledMap = new Map<Id, Boolean>();
        Map<Id, Boolean> smsToIsItrEnabledMap = new Map<Id, Boolean>();
        if(smsList != null && !smsList.isEmpty()){
            for(SMS_Text__c sms : smsList){
                liveTextNumberIds.add(sms.Support_Number__c);
            }
            List<LiveText_Number__c> liveTextNumberList = [Select Id, ITR_Enabled__c From LiveText_Number__c Where Id IN: liveTextNumberIds];
            if (liveTextNumberList != null && liveTextNumberList.size() > 0){
                for (LiveText_Number__c liveTextNumber: liveTextNumberList){
                    numberToITREnabledMap.put(liveTextNumber.Id, (liveTextNumber.ITR_Enabled__c == true) ? true : false);
                }
            }

            for(SMS_Text__c sms : smsList){
                Boolean itrEnabled = numberToITREnabledMap.get(sms.Support_Number__c);
                if(itrEnabled == null){
                    itrEnabled = false;
                }
                smsToIsItrEnabledMap.put(sms.Id, itrEnabled);
            }
        }
        return smsToIsItrEnabledMap;
    }

   /**
    * @description: Checks if the provided string contains only alphanumeric characters or not.
    * @param String that needs to be checked for alphanumeric characters..
    * @returns true if string contains alphanumeric characters and hyphen only.
    * @TODO get rid of this function since SF provide us with String.isAlphanumeric()
    */
    public static Boolean isAlphaNumeric(String s){
        return (String.isNotBlank(s) && Pattern.matches('^[a-zA-Z0-9-]*$',s));
    }

    /**
    * @description: Gets Auto generated messages from associated LiveText number.
    * @param LiveText Number.
    * @returns LiveText configured Message.
    */
    public static String getConfiguredMessage(List < String > liveTextNumberList, List < String > fldNameList){
        String liveTextInitialMessage;
        String liveTextNumber = liveTextNumberList[0];
        String fldName = fldNameList[0];
        // get auto response, based on livetext number
        if (liveTextNumber != null && liveTextNumber.length() != 0) {
            String idField = Constant.rec_Id;
            String fldInitialMessage = namespace + Constant.initial_Message;
            String fldOfflineHoursMessage = namespace + Constant.offline_Hours_Message;
            String fldChatEndMessage = namespace + Constant.chat_End_Message;
            String objLiveTextNumber = namespace + Constant.liveText_Number;

            String query = 'Select';
            query += ' ' + idField + ', ';
            query += fldInitialMessage + ', ';
            query += fldOfflineHoursMessage + ', ';
            query += fldChatEndMessage + ' ';
            query += 'from ' + objLiveTextNumber;
            query += ' where  ' + idField + '=' + '\'' + liveTextNumber + '\'';
            List < LiveText_Number__c > liveTextList = Database.query(query);
            if (!liveTextList.isEmpty()) {
                if (fldName == Constant.initial_Message) {
                    liveTextInitialMessage = liveTextList[0].Initial_Message__c;
                } else if (fldName == Constant.offline_Hours_Message) {
                    liveTextInitialMessage = liveTextList[0].Offline_Hours_Message__c;
                } else if (fldName == Constant.chat_End_Message){
                    liveTextInitialMessage = liveTextList[0].Chat_End_Message__c;
                }
            }
        }
        return liveTextInitialMessage;
    }

    /**
    * @description: Gets SMSText List from conversationHeader Id.
    * @param List of conversationHeader Id.
    * @returns List of SMSText Record.
    */
    public static List<SMS_Text__c> getSMSTextList(String conversationHeaderId) {
        List<SMS_Text__c> smsTextList ;
        if (String.isNotBlank(conversationHeaderId)) {
            smsTextList = [SELECT Source__c, Message__c, Originating_Number__c, Support_Number__r.Number__c,
                                  Initial_Message__c, Support_Number__c, Conversation_Header__c,
                                  Unique_SMS__c
                           FROM SMS_Text__c
                           WHERE Conversation_Header__c = :conversationHeaderId  ORDER BY Name ASC];
        }
        return smsTextList;
    }


    /**
    * @description: This function returns the formatted date as mentioned in the Lt-677.
    * @param DateTime stamp.
    * @returns formatted string datetime.
    */
    public static String formatDate(DateTime dateValue){
        String dayValue = String.valueOf(dateValue.day());
        String format = '';
        if(dayValue.endsWith('1') && !dayValue.endsWith('11')){
            format = 'EEEEEEEEE,' + ' MMMMMMMMMM'+' '+'d\'st\', yyyy \'at\' h:mm:ss a';
        }else if(dayValue.endsWith('2') && !dayValue.endsWith('12')){
            format = 'EEEEEEEEE,' + ' MMMMMMMMMM'+' '+'d\'nd\', yyyy \'at\' h:mm:ss a';
        }else if(dayValue.endsWith('3') && !dayValue.endsWith('13')){
            format = 'EEEEEEEEE,' + ' MMMMMMMMMM'+' '+'d\'rd\', yyyy \'at\' h:mm:ss a';
        }else {
            format = 'EEEEEEEEE,' + ' MMMMMMMMMM'+' '+'d\'th\', yyyy \'at\' h:mm:ss a';
        }
        return dateValue.format(format,UserInfo.getTimeZone().toString());
    }

    /**
    * @description this function retrieves time from dateTime
    *
    **/
    public static String getTimeFromDateTime(DateTime dateValue){
        return dateValue.format('h:mm:ss a',UserInfo.getTimeZone().toString());
    }

    /**
    * @description: This method is to retrieve the contact or lead name linked while in the chat session with the user.
    *               When user clicks on the link contact/lead sms message is prepared as '<span><i>>>> Linked Contact: <a class="transcriptLink" href="/003j000000APTr0AAH" >Arthur Song</a> <<< </i></span>'
    *               This method retrieves the name 'Arthur song' from the argument string using regular expression.
    * @param String sms message.
    * @returns String retrieved contact or lead name from the sms message.
    */
    public static String NameFromAssociatedRecord(String text) {
        /*This regular expression is to extract the contact name from the text:
         * <span><i>>>> Linked Contact: <a class="transcriptLink" href="/003j000000APTr0AAH" >Arthur Song</a> <<< </i></span>
         * In this case it will extract name as 'Arthur Song'*/
        Pattern patternObj = Pattern.compile('(?<=>)[^<>]*(?=<'+'\\'+'/a)');

        Matcher matcherObj = patternObj.matcher(text);

        String associatedRecordName = '';
        if(matcherObj.find()){
            associatedRecordName = matcherObj.group();
        }
        return associatedRecordName;
    }

    public static String getContactNameFromCase(String text){
        Pattern patternObj = Pattern.compile('(?<=>)[^<>]*(?=<'+'\\'+'/a)');

        Matcher matcherObj = patternObj.matcher(text);

        String associatedRecordName = '';
        if(matcherObj.find()){
            associatedRecordName = matcherObj.group();
        }
        List<Case> tempCaseList = [SELECT Contact.Name FROM Case WHERE CaseNumber=:associatedRecordName LIMIT 1];
        String contactName = tempCaseList.isEmpty() ? '' : tempCaseList[0].Contact.Name;
        return contactName;
    }




    /*
    * Create the whole transcript when chat is ended. Start chat and end chat labels are added by VF components for display purpose only
    */
    public static void createTranscript(Map<Id, List<SMS_Text__c>> conversationHeaderSMSTextMap, DateTime endDateTime){
        try{
            // list to store conversation header records to update.
            List<Conversation_Header__c> conversationHeaderToUpdate = new List<Conversation_Header__c> ();
            Datetime creationDateTime = Datetime.now();
            // get conversation header records, from conversationHeaderSMSTextMap Id's
            List<Conversation_Header__c> conversationHeaderList = [SELECT Transcript_Summary_2__c, Transcript_Summary_1__c, Status__c, Id,Support_Number__c, Formatted_Originating_Number_To_Display__c, Originating_Number__c,Formatted_Originating_Number__c
                                                                    FROM Conversation_Header__c
                                                                    WHERE Id IN: conversationHeaderSMSTextMap.KeySet()];

            for (Conversation_Header__c cv: conversationHeaderList){
                String messageSourceName = ''; //This variable holds the name of the contact or lead that agent selects while in chat session LT-677
                String leadMessageSourceName = '';
                String caseMessageSourceName = '';
                Boolean contactLinked = false;
                Boolean leadLinked = false;
                Boolean caseLinked = false;
                Boolean addITRstarted = false;
                String transcript = '';
                // list of all smstext records to be processed.
                List<SMS_Text__c> smsTextList = conversationHeaderSMSTextMap.get(cv.id);
                LiveText_Number__c ltn = [SELECT ITR_Enabled__c FROM LiveText_Number__c WHERE id =: cv.Support_Number__c];
                for (SMS_Text__c sms: smsTextList){
                    DateTime smsDate = null;
                    String tempSMSDate = null;
                    String creationTimeFormat = formatDate(smsTextList[0].CreatedDate);
                    if (cv.Id == sms.Conversation_Header__c){
                        if (sms.CreatedDate !=null){
                            smsDate = sms.CreatedDate;
                            tempSMSDate = ' at ' + getTimeFromDateTime(smsDate);
                        }else{
                            tempSMSDate = ' at ' + getTimeFromDateTime(system.now());
                        }
                        if (sms.Source__c == Constant.live_text){
                            //Checking if we have name of person we are chatting with
                            String tempSource = String.isBlank(messageSourceName) ? sms.Originating_Number__c == cv.Originating_Number__c ? cv.Formatted_Originating_Number__c : sms.Formatted_Originating_Number__c : messageSourceName;
                            tempSource += tempSMSDate;
                            if (!String.isBlank(transcript)){
                                transcript += cssLineSpacingPTagOpening + '<b>' + tempSource + '</b>: <br/>' + sms.Message__c + cssLineSpacingPTagClosing;
                            }else {
                                //LT-1274
                                transcript += cssLineSpacingPTagOpening + '<b>' + tempSource + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                            }
                        }else if (sms.Source__c == Constant.salesforce ||  sms.Source__c == Constant.salesforce_linking){
                            String tempMsg = String.valueOf(sms.Message__c);
                            //fix for LT-450
                            if (tempMsg != null && tempMsg.contains(Label.TXT_Transcript_linked_unlinked_postfix)){  //This call is to determine if there is link or unlink
                                String tempLinkingMsg = tempMsg.left(tempMsg.lastIndexOf(Label.TXT_Transcript_linked_unlinked_postfix)) + ' ' + tempSMSDate + ' ' + Label.TXT_Transcript_linked_unlinked_postfix;
                                transcript = transcript + tempLinkingMsg + '<br/>';
                                if(tempMsg.contains(Label.TXT_Transcript_unlinked_prefix)){ //This block is when something Unlinked
                                    if(tempMsg.containsIgnoreCase('Contact')){
                                        contactLinked = false;
                                        if(!contactLinked && leadLinked){
                                            messageSourceName = leadMessageSourceName;
                                        }else if(!contactLinked && !leadLinked && caseLinked){
                                            messageSourceName = caseMessageSourceName;
                                        }else if(!contactLinked && !leadLinked && !caseLinked){
                                            messageSourceName = '';
                                        }
                                    }else if(tempMsg.containsIgnoreCase('Lead')){
                                            leadLinked = false;
                                            leadMessageSourceName = '';
                                        if(!contactLinked && caseLinked){
                                            messageSourceName = caseMessageSourceName;
                                        }else if(!contactLinked && !caseLinked){
                                            messageSourceName = '';
                                        }
                                    }else if(tempMsg.containsIgnoreCase('Case')){
                                        caseLinked = false;
                                        caseMessageSourceName = '';
                                        if(!contactLinked && !leadLinked){
                                            messageSourceName = '';
                                        }
                                    }
                                }else{ // This block is when something linked
                                    if(tempMsg.containsIgnoreCase('Contact')){
                                        contactLinked = true;
                                        messageSourceName = NameFromAssociatedRecord(sms.Message__c);
                                    }else if(tempMsg.containsIgnoreCase('lead')){
                                        leadLinked = true;
                                        leadMessageSourceName = NameFromAssociatedRecord(sms.Message__c);
                                        if(!contactLinked){
                                            messageSourceName = leadMessageSourceName;
                                        }
                                    }else if(tempMsg.containsIgnoreCase('Case')){
                                        caseLinked = true;
                                        caseMessageSourceName = getContactNameFromCase(sms.Message__c);
                                        if((!contactLinked) && (!leadLinked)){
                                            messageSourceName = caseMessageSourceName;
                                        }
                                    }
                                }
                            }else{
                                transcript += cssLineSpacingPTagOpening + '<b>' +string.valueOf(UserInfo.getName()) + ' ' + tempSMSDate + '</b>:<br/> ' + sms.Message__c +cssLineSpacingPTagClosing;
                            }
                        }else if(sms.Source__c == Constant.salesforce_welcome){
                            if(addITRstarted){
                                transcript += cssLineSpacingPTagOpening + '<b>&middot;&middot;&middot;&middot;</b>'+label.TXT_Chat_Started +': <b>'+ formatDate(sms.CreatedDate) + '</b> <b>&middot;&middot;&middot;&middot;</b> <br/>' + cssLineSpacingPTagClosing;
                            }
                            transcript += cssLineSpacingPTagOpening + '<b>' + Label.InitialMsgLbl + ' ' + tempSMSDate + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                        }else if(sms.Source__c == Constant.salesforce_goodbye){
                            transcript += cssLineSpacingPTagOpening + '<b>' +Label.ChatEndMsgLbl + ' ' + tempSMSDate + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                        }else if(sms.Source__c == Constant.salesforce_offline){
                            transcript += cssLineSpacingPTagOpening + '<b>' +Label.OfflineHrsMsgLbl + ' ' + tempSMSDate + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                        }else if(sms.Source__c == Constant.salesforce_auto_response){
                            transcript += cssLineSpacingPTagOpening + '<b>' +Label.AutoResponseMsgLbl + ' ' + tempSMSDate + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                        }else if (sms.Source__c == Constant.permission_marketing){
                            transcript += cssLineSpacingPTagOpening + '<b><i>' +label.TXT_OPT_Messaging + ' ' + tempSMSDate + '</i></b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                            addITRstarted = true;
                        }else if (sms.Source__c == Constant.itr){
                            transcript += cssLineSpacingPTagOpening + '<b><i>' +Constant.itr + ' ' + tempSMSDate + '</i></b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                            addITRstarted = true;
                        }
                    }
                }
                String tempTranscript;
                String nonEncodedString;
                String creationTimeFormat = formatDate(smsTextList[0].CreatedDate);
                String creationTime;
                if(!smsTextList.isEmpty()){
                    //Lt-1274
                    if(addITRstarted){
                        transcript = cssLineSpacingPTagOpening + '<b>&middot;&middot;&middot;&middot;</b>'+label.TXT_ITR_Started +': <b>'+ creationTimeFormat + '</b> <b>&middot;&middot;&middot;&middot;</b> <br/>' + cssLineSpacingPTagClosing + transcript;
                    }else{
                        transcript = cssLineSpacingPTagOpening + '<b>&middot;&middot;&middot;&middot;</b>'+label.TXT_Chat_Started +': <b>'+ creationTimeFormat + '</b> <b>&middot;&middot;&middot;&middot;</b> <br/>' + cssLineSpacingPTagClosing + transcript;
                    }
                }

                if(cv.Transcript_Summary_1__c != null){
                    if(cv.Transcript_Summary_1__c.contains(cssLineSpacingPTagClosing)){
                        tempTranscript = cv.Transcript_Summary_1__c+transcript;
                    }else{
                        tempTranscript = convertTranscriptToPlainText(cv.Transcript_Summary_1__c) + transcript;
                    }
                }else{
                    tempTranscript = transcript;
                }

                if (tempTranscript.length() > 32768){
                    tempTranscript = '';
                    tempTranscript = cv.Transcript_Summary_2__c + transcript;
                    if (tempTranscript.length() > 32768){
                        insertException(constant.conversation_header_obj, constant.priority_high, 'Error Creating Conversation Transcript, Transcript_Summary_2__c over limit.');
                    }else{
                        //nonEncodedString = creationTime + tempTranscript;
                        //LT-1274
                        if(creationTime!=null){
                            nonEncodedString = creationTime + tempTranscript;
                        }else{
                            nonEncodedString = tempTranscript;
                        }
                        cv.Transcript_Summary_2__c = nonEncodedString;
                    }
                }else{
                    //nonEncodedString = creationTime + tempTranscript;
                    //Lt-1274
                    if(creationTime!=null){
                        nonEncodedString = creationTime +tempTranscript;
                    }else{
                        nonEncodedString = tempTranscript;
                    }
                    nonEncodedString = nonEncodedString + '<b><b>&middot;&middot;&middot;&middot;</b></b> Text Session Ended: <b>'+ formatDate(endDateTime) + '</b> <b>&middot;&middot;&middot;&middot;</b> <br/>';
                    cv.Transcript_Summary_1__c = nonEncodedString;
                }
                conversationHeaderToUpdate.add(cv);
            }

            if (!conversationHeaderToUpdate.isEmpty()){
                AccessController.updateAsUser(conversationHeaderToUpdate);
            }
        }catch (Exception ex){
            insertException('Error Creating Conversation Transcript.', constant.priority_high, ex.getMessage());
        }
    }

    /*
    * Create the interim transcript to this point for ITR.
    */
    public static String createITRTranscript(String existingTranscript, List<SMS_Text__c> SMSTextList) {
        try {
            Boolean showCreateTime = String.isBlank(existingTranscript);
            String transcript = (existingTranscript == null) ? '' : existingTranscript;
            for (SMS_Text__c sms: SMSTextList) {
                if (sms.Source__c == constant.live_text) {
                    transcript += cssLineSpacingPTagOpening + '<b>' +sms.Formatted_Originating_Number__c + '</b>: <br/>' + sms.Message__c + cssLineSpacingPTagClosing;
                } else if (sms.Source__c == constant.ITR){
                    transcript += cssLineSpacingPTagOpening + '<b>' + constant.ITR + '</b>:<br/> ' + sms.Message__c +cssLineSpacingPTagClosing;
                }else if(sms.Source__c == constant.salesforce_welcome){
                    transcript += cssLineSpacingPTagOpening + '<b>' + Label.InitialMsgLbl + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                }else if(sms.Source__c == constant.salesforce_goodbye){
                    transcript += cssLineSpacingPTagOpening + '<b>' +Label.ChatEndMsgLbl + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                }else if(sms.Source__c == constant.salesforce_offline){
                    transcript += cssLineSpacingPTagOpening + '<b>' +Label.OfflineHrsMsgLbl + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                }else if(sms.Source__c == constant.salesforce_auto_response){
                    transcript += cssLineSpacingPTagOpening + '<b>' +Label.AutoResponseMsgLbl + '</b>:<br/> ' + sms.Message__c + cssLineSpacingPTagClosing;
                }
            }
            String nonEncodedString = transcript;
            if(showCreateTime){
                String creationTimeFormat = formatDate(SMSTextList[0].CreatedDate);
                String creationTime = cssLineSpacingPTagOpening + '<b>&middot;&middot;&middot;&middot;</b>'+label.TXT_ITR_Started +': <b>'+ creationTimeFormat + '</b> <b>&middot;&middot;&middot;&middot;</b> <br/>' + cssLineSpacingPTagClosing;
                nonEncodedString = creationTime + transcript;
            }
            nonEncodedString += '<br/>';
            return nonEncodedString;
        } catch (Exception ex) {
            insertException('Error Creating Interim Transcript.', constant.priority_high, ex.getMessage());
        }

        return '';
    }

    public static String createOutboundMessageTranscript(String message){
        String transcript = '';
        transcript = cssLineSpacingPTagOpening + '<b><b>&middot;&middot;&middot;&middot;</b></b>'+ Label.OutBoundTxt_SentMsg +': '+ formatDate(DateTime.Now())+ '<b><b> &middot;&middot;&middot;&middot;</b></b>' + cssLineSpacingPTagClosing;
        transcript += cssLineSpacingPTagOpening + message + cssLineSpacingPTagClosing;
        transcript += cssLineSpacingPTagOpening + '<b><b>&middot;&middot;&middot;&middot;</b></b>'+ Label.OutBoundTxt_EndMsg+'<b><b> &middot;&middot;&middot;&middot;</b></b>' + cssLineSpacingPTagClosing;
        String description = Util.convertTranscriptToPlainText(transcript);
        return description;
    }

    /* 12/10/2015
    * Add to transcript information about linking objects, after ending text session
    */
    public static void createAfterLinkingTranscript(Conversation_Header__c ch, List<SMS_Text__c> smsList){
        Boolean shouldUpdate = false;
        String transcript = '';
        for (SMS_Text__c sms : smsList){
            String tempMsg = (String) sms.Message__c;
            if (tempMsg != null && tempMsg.contains(Label.TXT_Transcript_linked_unlinked_postfix)){
                tempMsg = tempMsg.left(tempMsg.lastIndexOf(Label.TXT_Transcript_linked_unlinked_postfix)) + ' at ' + getTimeFromDateTime(system.now()) + ' ' + Label.TXT_Transcript_linked_unlinked_postfix;
                transcript = transcript + '<br/>' + tempMsg;
            }
        }
        String tempTranscript = '';
        if (ch.Transcript_Summary_1__c != null){
            tempTranscript = ch.Transcript_Summary_1__c + transcript;
        }else{
            tempTranscript = transcript;
        }

        if (tempTranscript.length() > 32768){
            tempTranscript = '';
            tempTranscript = ch.Transcript_Summary_2__c + transcript;
            if (tempTranscript.length() > 32768){
                insertException(constant.conversation_header_obj, constant.priority_high, 'Error Creating Conversation Transcript, Transcript_Summary_2__c over limit.');
            }else {
                ch.Transcript_Summary_2__c = tempTranscript;
                shouldUpdate = true;
            }
        }else {
            ch.Transcript_Summary_1__c = tempTranscript;
            shouldUpdate = true;
        }

        if(shouldUpdate){
            AccessController.updateAsUser(ch);
            Util.updateEvents(ch.Id, null);
        }
    }

      /**
     * @description: converts the transcript to plain text
     * @param: html transcript.
     * @return converted transcript.
     */
    public static String convertTranscriptToPlainText(String transcript){
        String newLineMarker = 'TEMP-NEW-LINE-MARKER';
        String plainText = transcript;
        plainText = plainText.replace(cssLineSpacingPTagOpening,cssLineSpacingPTagOpening + newLineMarker);
        plainText = plainText.replace(cssLineSpacingPTagClosing,cssLineSpacingPTagClosing + newLineMarker);
        plainText = plainText.stripHtmlTags();
        plainText = plainText.replace(newLineMarker, '\r\n');
        plainText = plainText.replace('>>>', '\r\n>>>');
        plainText = plainText.replace('···· Text Session Ended','\r\n···· Text Session Ended');
        return plainText;
    }

     /**
     * @description: send sms text to heywire. and delete all sms text records associated with conversation Id
     * @param: List <Id>, smsTextListId's in list format.
     * @return null.
     */
    public static void smsTextCalloutForEndChat(List<SMS_Text__c> smsTextList, Id convId){
        if (!smsTextList.isEmpty()){
            Conversation_Header__c conversationHeaderRecord = new Conversation_Header__c();
            conversationHeaderRecord.Id = convId;
            conversationHeaderRecord.Status__c = constant.stage_ended;
            conversationHeaderRecord.ConversationReopened__c = false;
            AccessController.deleteAsUser(smsTextList);
            AccessController.upsertAsUser(new list<Conversation_Header__c>{ conversationHeaderRecord });
        }
    }

    /*
    * Send SMS Text with list of them to Heywire
    */
    @Future(callout = true)
    public static void smsTextCallout(List<Id> smsTextListId) {
        try {
            List<SMS_Text__c> smsTextList = [SELECT Support_Number__c, Support_Number__r.Number__c, Originating_Number__c,
                                                    Message__c, Id, Conversation_Header__c
                                             FROM SMS_Text__c WHERE Id = : smsTextListId];
            if(smsTextList != null && !smsTextList.isEmpty()){
                for (SMS_Text__c sms: smsTextList) {
                    Boolean isSendMessageSuccess = callout.sendSMS(sms, sms.Message__c);
                    sms.Sent_To_Customer__c = isSendMessageSuccess;
                    if (isSendMessageSuccess =false) {
                        Util.insertException(sms.Id, constant.priority_high, 'API Call Failed for Message:'+sms.Message__c);
                    }
                }
                AccessController.upsertAsUser(smsTextList);
            }
        }catch (exception ex){
            Util.insertException(constant.sms_text_obj, constant.priority_high, ex.getMessage());
        }
    }

    /**
     * Send initial SMS message to customers
     */
    @Future(callout = true)
    public static void sendInitialMessage(Set<Id> convHdrIds) {
        //callout.sendInitialMessage(convHdrIds);
        try {
            //Queries only for NEW Status records to prevent sending the messages to Text Requests that arrive during offline hours.
            List<Conversation_Header__c> cHdrRecs = [SELECT Id, Originating_Number__c, Support_Number__c, Support_Number__r.Number__c, ConversationType__c,
                                                    Support_Number__r.Auto_Response_Message__c, Support_Number__r.Notify_Users_During_Off_Hours__c,
                                                    Support_Number__r.Offline_Hours_Message__c, Support_Number__r.Business_Hours__c, Support_Number__r.No_Available_Users_Message__c
                                                    FROM Conversation_Header__c
                                                    WHERE Id IN :convHdrIds
                                                    AND Status__c = :Constant.stage_new];
            Map<Id, Set<Id>> ltNumberToAvailableAgentsMap = Util.getAvailableAgentsMap();
            for(Conversation_Header__c ch : cHdrRecs)
            {
                if(ch.ConversationType__c == Constant.ConversationType.Inbound.name())
                {
                    Boolean smsSent = false;
                    OptInStatus__c optInStatus = Util.getOptInStatus(ch.Support_Number__c, ch.Originating_Number__c);
                    Boolean isWithinBusinessHours = String.isBlank(ch.Support_Number__r.Business_Hours__c)
                                                    ? true
                                                    : Businesshours.isWithin(ch.Support_Number__r.Business_Hours__c, System.now());
                    if(optInStatus == null || optInStatus.Status__c == 1)
                    {
                        SMS_Text__c smsTextRecord = new SMS_Text__c (Conversation_Header__c = ch.Id,
                                                                 Support_Number__c = ch.Support_Number__c,
                                                                 Originating_Number__c = ch.Originating_Number__c,
                                                                 Source__c = Constant.salesforce_auto_response);
                        String message = '';
                        if(!isWithinBusinessHours && ch.Support_Number__r.Notify_Users_During_Off_Hours__c)
                        {
                            message = ch.Support_Number__r.Offline_Hours_Message__c;
                        }
                        else if(isWithinBusinessHours && !ltNumberToAvailableAgentsMap.containsKey(ch.Support_Number__c))
                        {
                            message = ch.Support_Number__r.No_Available_Users_Message__c;
                            if(String.isBlank(message))
                            {
                                message = ch.Support_Number__r.Auto_Response_Message__c;
                            }
                        }
                        else
                        {
                            message = ch.Support_Number__r.Auto_Response_Message__c;
                        }
                        if(String.isNotBlank(message))
                        {
                            HttpResponse res = callout.sendSMSInternal(ch.Originating_Number__c, ch.Support_Number__r.Number__c, message);
                            smsTextRecord.Message__c = message;
                            if(res.getStatusCode() == 204){
                                smsSent = true;
                            }
                            smsTextRecord.Sent_To_Customer__c = smsSent;
                            AccessController.insertAsUser(new List<SMS_Text__c>{smsTextRecord});
                        }
                    }
                }
            }
        }catch(Exception e) {
            Util.insertException(constant.sms_text_obj, constant.priority_high, e.getMessage() + ', line: ' + e.getLineNumber());
        }
    }

    /**
    * @description getAvailableAgentsMap retrieves set of available agents (userId) for every LTNumber
    *              it checkes:
    *               1. if associated agent has "Available" status set
    *               2. if associated agent session is valid (almost == is logged)
    **/

    public static Map<Id, Set<Id>> getAvailableAgentsMap(){
        Map<Id, Set<Id>> ltNumberToAvailableAgentsMap = new Map<Id, Set<Id>>();
        List<AggregateResult> loggedUsers = [SELECT UsersId, MAX(LastModifiedDate) validSince, MAX(NumSecondsValid) validFor FROM AuthSession WHERE SessionType = 'Visualforce' OR SessionType = 'UI' GROUP BY UsersId LIMIT 10000];
        Map<Id, Boolean> loggedUsersMap = new Map<Id, Boolean>();
        for(AggregateResult  loggedUser : loggedUsers){
            if(!loggedUsersMap.containsKey((Id)loggedUser.get('UsersId'))){
                Datetime validSince = (Datetime) loggedUser.get('validSince');
                Boolean isSessionValid = validSince.addSeconds((Integer)loggedUser.get('validFor')) > System.now();
                loggedUsersMap.put((Id)loggedUser.get('UsersId'), isSessionValid);
            }
        }
        Set<Id> availableAgents = new Set<Id>();
        for(Agent_Status__c agentStatus : [SELECT id, User__c, Status__c FROM Agent_Status__c WHERE User__c In :loggedUsersMap.keySet() LIMIT 10000]){
            if('Available'.equals(agentStatus.Status__c))
                availableAgents.add(agentStatus.User__c);
        }
        for(Associated_Agents__c associatedAgent : [SELECT id, User__c, LiveText_Number__c FROM Associated_Agents__c WHERE User__c IN :availableAgents LIMIT 10000]){
            Set<Id> temp = new Set<Id>();
            if(ltNumberToAvailableAgentsMap.containsKey(associatedAgent.LiveText_Number__c))
                temp = ltNumberToAvailableAgentsMap.get(associatedAgent.LiveText_Number__c);
            if(loggedUsersMap.get(associatedAgent.User__c))
                temp.add(associatedAgent.User__c);
            ltNumberToAvailableAgentsMap.put(associatedAgent.LiveText_Number__c, temp);
        }
        return ltNumberToAvailableAgentsMap;
    }

    /**
     * @description: Retrieves the permission map for Account, Case, Contact, Lead, and Opportunity objects.
     * @param: String message.
     * @return Map<String, Boolean>
     */
    public static Map<String, Boolean> getPermissionMap(){
        Map<String, Boolean> permissionMap = new Map<String, Boolean>();
        for(String apiName : Util.getAllRelationshipObjects()){
            permissionMap.put(apiName, GLOBAL_DESCRIBE.get(apiName).getDescribe().isAccessible());
        }
        return permissionMap;
    }

    /**
     * @description: Insert smstext record with associate conversationId to it..
     * @param: String message.
     * @return List<SMS_Text__c>.
     */
    public static List <SMS_Text__c> insertSMSTextRecord2(String message, String conversationRecordId, Boolean sentToCustomer) {
        List<SMS_Text__c> smsText;
        try {
            List<SMS_Text__c> smsTextList = [SELECT Source__c,
                                                    Message__c,
                                                    Originating_Number__c,
                                                    Support_Number__r.Number__c,
                                                    Support_Number__c,
                                                    CreatedDate,
                                                    Conversation_Header__c FROM
                                                    SMS_Text__c WHERE
                                                    Conversation_Header__c = :conversationRecordId limit 1
                                                    ];
            if (!smsTextList.isEmpty()){
                SMS_Text__c smsTextRecord = new SMS_Text__c(Conversation_Header__c = conversationRecordId,
                                                    Support_Number__c = smsTextList[0].Support_Number__c,
                                                    Originating_Number__c = smsTextList[0].Originating_Number__c,
                                                    Message__c = message, Source__c = constant.salesforce,
                                                    Sent_To_Customer__c = sentToCustomer);

                AccessController.insertAsUser(new List<SMS_Text__c>{smsTextRecord});
                smsText = new List<SMS_Text__c> {smsTextRecord};
            }
        }
        catch (Exception ex) {
            Util.insertException('Insert Failed on SMS Text Record.!', constant.priority_high, ex.getMessage());
        }
        return smsText;
    }

     /**
     * @description: Determines whether or not a given phone number is a North American phone number
     * @param phoneNumber - phone number in question
     * @return True/False.
     */
    public static Boolean IsNorthAmericanPhoneNumber(String phoneNumber) {
        if(String.isBlank(phoneNumber))
            return false;
        // Remove non numeric characters
        phoneNumber = phoneNumber.replaceAll('\\D', '');
        // Remove all leading zeros
        phoneNumber = phoneNumber.replaceFirst('^0+', '');

        // number, including country code starts with
        if (phoneNumber.length() == northAmericanPhoneNumberLength && phoneNumber.startsWith('1'))
            return true;

        if ((phoneNumber.length() == northAmericanPhoneNumberLength -1) && !phoneNumber.startsWith('1'))
            return true;

        return false;
    }

    /**
     * @description: Converts a number to E164 format - Used by NormalizePhoneNumber
     * @param phoneNumber - phone number to normalize
     * @param dialCode - dialcode for current user, e.g. +1
     * @param minNumberLength - minimum number of characters for a typical phone number in the current user's environment
     * @return Normalized phone number.
     */
    public static String ConvertToE164(String phoneNumber, String dialCode, Integer minNumberLength){
        if(String.isBlank(phoneNumber))
            return '';
            
        if(phoneNumber.trim().startsWith('+')){
        	return '+'  + phoneNumber.replaceAll('\\D', '');
        }
        
        // Remove non numeric characters
        phoneNumber = phoneNumber.replaceAll('\\D', '');
        // Remove all leading zeros
        phoneNumber = phoneNumber.replaceFirst('^0+', '');

        if(IsShortCode(phoneNumber)){
            return phoneNumber;
        }

        // If the number is not long enough, add the country code
        if ((phoneNumber.length() < minNumberLength) && (phoneNumber.length() + (dialCode.length() - 1) >= minNumberLength))
            return dialCode + phoneNumber;

        return '+' + phoneNumber;

    }

    /**
     * @description: Normalizes a phone number
     * @param phoneNumber - phone number to normalize
     * @return Normalized phone number.
     */
    public static String NormalizePhoneNumber(String phoneNumber) {
        return Util.ConvertToE164(phoneNumber, northAmericaCountryCode, northAmericanPhoneNumberLength);
    }

    /**
     * @description: Determines if a phone number is a Short Code
     * @param phoneNumber - phone number to check
     * @return true/false
     */
    public static Boolean IsShortCode(String phoneNumber){
    	if(String.isBlank(phoneNumber))
            return false;
        // Remove non numeric characters
        phoneNumber = phoneNumber.replaceAll('\\D', '');
        // Remove all leading zeros
        phoneNumber = phoneNumber.replaceFirst('^0+', '');

        return  phoneNumber.length() == 5 || phoneNumber.length() == 6;
    }

    /**
     * @description: returns custom url by getting object prefix
     * @param
     * @return  custom partial url for Case
     */
    public static String getCasePrefixURL() {
        Schema.DescribeSObjectResult DescribeObjectResult = Case.sObjectType.getDescribe();
        String keyPrefix = buildUrl(String.valueOf(DescribeObjectResult.getKeyPrefix()).subString(0, 3));
        return keyPrefix;
    }

     /**
     * @description: returns custom url by getting object prefix
     * @param
     * @return  custom partial url for Case
     */
    public static String getOpportunityPrefixURL() {
        Schema.DescribeSObjectResult DescribeObjectResult = Opportunity.sObjectType.getDescribe();
        String keyPrefix = buildUrl(String.valueOf(DescribeObjectResult.getKeyPrefix()).subString(0, 3));
        return keyPrefix;
    }

    /**
     * @description: returns custom format url for object prefix passed
     * @param
     * @return  custom partial url (/a05/e?retURL=/a05/o format)
     */
    @TestVisible
    private static String buildUrl(String Prefix) {
        String url = '/' + Prefix + '/e?';
        return url;
    }

    /**
     * @description: Returns a list of my phone numbers //to change into one soql -V-!!
     * @return List.
     */
    public static List<LiveText_Number__c> GetMyPhoneNumbers() {

        String uid = UserInfo.getUserId();
        List<Id> ids = new List<Id>();
        List<Associated_Agents__c> agents = [SELECT LiveText_Number__c FROM Associated_Agents__c WHERE User__c=:uid];
        for(Associated_Agents__c a : agents){
            ids.add(a.LiveText_Number__c);
        }

        List<LiveText_Number__c> phoneNumbers = [SELECT Id, Name, Number__c, Formatted_Support_Number__c FROM LiveText_Number__c WHERE Id IN :ids];
        return phoneNumbers;
     }

     /**
     * @description Asynchronously sends a message.
     *
     * @Param       msgId - the Id of the message from the SMS_Message table
     * @Param       toPhone - the phone number to send to
     * @Param       fromPhone - the phone number to send from
     * @Param       message - the message to send
     *
     * @Return      Result of Send.
     **/
    @future (callout=true)
    public static void sendSmsAsync(String toPhone,String fromPhone, String message) {
        HttpResponse res = Callout.sendSMSInternal(toPhone,fromPhone, message);
        String errorMessage = res.getStatusCode() != 204 ? 'Unable to send message' : null;
        String status =    res.getStatusCode() != 204 ? 'Error' : 'Sent';
    }

     /**
     * @description: method for End Text Session button on the page. Performs below operation for end chat,
     *               1. Retrieves the initial message for the conversation header.
     *               2. Makes API callout to send the initial message to customer.
     *               3. Inserts the initial message to the database.
     *               4. Creates the transcript and set it to Text session header.
     *               5. Delete all the SMSes associated to Text session.
     *               6. Updates the status of Text session header to Ended.
     * @returns PageReference object.
     */
     public static void endChat(String conversationRecordId){
        try{
            List<Conversation_Header__c> chl = [SELECT Id, Status__c ,Transcript_Summary_1__c
                FROM Conversation_Header__c
                WHERE Id=:conversationRecordId];

            if(!chl.isEmpty()){
                String convHeaderStatus = chl.get(0).Status__c;
                if(convHeaderStatus.equals(Constant.STAGE_ACTIVE) || convHeaderStatus.equals(Constant.STAGE_NEW)  || convHeaderStatus.equals(Constant.STAGE_OFFLINE)){
                    Map<Id, List<SMS_Text__c>> conversationHeaderSMSTextMap = new Map<Id, List<SMS_Text__c>> ();
                    DateTime endDateTime = DateTime.now();
                    // get all smstext records associated with conversationRecordId passed
                    List<SMS_Text__c> smsTextList = LiveTextChatController.getSMSTextRecordList(new List<Id>{conversationRecordId});
                    if (!smsTextList.isEmpty()){
                        OptInStatus__c optInStatus = Util.getOptInStatus(smsTextList[0].Support_Number__c, smsTextList[0].Originating_Number__c);
                        if(optInStatus == null || optInStatus.Status__c == 1){
                            //LT-1274 String.isBlank(chl.get(0).Transcript_Summary_1__c) this condition prevents sending End text message for the reopened text session
                            if(String.isNotBlank(smsTextList[0].End_Chat_Message__c) && String.isBlank(chl.get(0).Transcript_Summary_1__c)){
                                LiveText_Number__c supportNumber = GetLiveTextNumberObjectById(smsTextList[0].Support_Number__c);
                                if(supportNumber != null){
                                    // callout to heywire servers to send end chat message
                                    sendSmsAsync(smsTextList[0].Originating_Number__c, supportNumber.Number__c, smsTextList[0].End_Chat_Message__c);
                                    smsTextList.addAll(LiveTextChatController.insertEndChatTextRecord(smsTextList[0].End_Chat_Message__c, conversationRecordId, true));
                                }
                            }
                        }
                        // create smstext with end chat message.
                        conversationHeaderSMSTextMap.put(conversationRecordId, smsTextList);
                        // Creating Chat transcript
                        if (!conversationHeaderSMSTextMap.isEmpty()){
                            Util.smsTextCalloutForEndChat(smsTextList, conversationRecordId);
                            // delete sms text records.
                            Util.createTranscript(conversationHeaderSMSTextMap, endDateTime);
                        }
                        convHeaderStatus = Constant.stage_ended;
                        Util.updateEvents(conversationRecordId, endDateTime);
                    }else{
                        Util.insertException('NO RECORDS', constant.priority_high, 'NO RECORDS');
                    }
                }else{
                    System.debug('End Chat called with status ' + convHeaderStatus);
                }
            }else{
                Util.insertException('End Chat', constant.priority_high, 'Conversation not found!: '  + conversationRecordId);
            }
        }catch (exception ex){
            Util.addMessageOnError(ex.getMessage());
            Util.insertException('Error occured while ending chat session', constant.priority_high, ex.getMessage());
        }
    }

    @TestVisible
    public static void updateEvents(String conversationRecordId, DateTime endDateTime){
        //find any associated events and update them with chat transcripts - query the conversation header for Ids
        List<SObject> updateActivityList = new List<SObject>();
        List<Id> activityIds = new List<Id>();
        for(Conversation_Event__c ce : [SELECT Event__c FROM Conversation_Event__c WHERE Conversation_Header__c=:conversationRecordId]){
            activityIds.add(ce.Event__c);
        }
        if(!activityIds.isEmpty()){
            Conversation_Header__c ch = [SELECT Transcript_Summary_1__c
                                            FROM Conversation_Header__c
                                            WHERE Id=:conversationRecordId limit 1];
            List<Event> eventList = [SELECT Description,EndDateTime FROM Event WHERE Id IN :activityIds];
            String description = Util.convertTranscriptToPlainText(ch.Transcript_Summary_1__c);
            for(Event e : eventList){
                e.Description = description;
                if(endDateTime != null) e.EndDateTime =  endDateTime;
                    updateActivityList.add(e);
            }
            List<Task> taskList = [SELECT Description, ActivityDate FROM Task WHERE Id IN :activityIds];
            for(Task t : taskList){
                t.Description = description;
                if(endDateTime != null) t.ActivityDate = Date.newinstance(endDateTime.year(), endDateTime.month(), endDateTime.day());
                    updateActivityList.add(t);
            }
            AccessController.updateAsUser(updateActivityList);
        }
        if(endDateTime != null){
            Conversation_Header__c aa = [SELECT EndedTime__c FROM Conversation_Header__c WHERE Id=:conversationRecordId ];
            aa.EndedTime__c=endDateTime;
            update aa;
        }
    }

    /**
    * @description function to get conversation for given Id for READ only. Use !ONLY! this function to query for conversationHeader
    *              if you need additional field add it to this function
    *
    **/
    public static List<Conversation_Header__c> getCurrentConversationHeaderList(String conversationRecordId) {
        String query = 'SELECT ' + String.join(Util.getAccessibleFieldsWithRelationshipNameFields(namespace+'Conversation_Header__c'), ',');
        query += ' FROM Conversation_Header__c WHERE id=: conversationRecordId limit 1';
        List<Conversation_Header__c> conversationHeaderList = Database.query(query);
        return conversationHeaderList;
    }
    /**
    * @description function to get conversation for given Id for UPDATE. Use !ONLY! this function to query for conversationHeader
    *              if you need additional field add it to this function
    *
    **/
    public static List<Conversation_Header__c> getCurrentConversationHeaderListForUpdate(String conversationRecordId) {
        String query = 'SELECT ' + String.join(Util.getUpdateableFieldsWithRelationshipNameFields(namespace+'Conversation_Header__c'), ',');
        query += ' FROM Conversation_Header__c WHERE id=: conversationRecordId limit 1';
        List<Conversation_Header__c> conversationHeaderList = Database.query(query);
        return conversationHeaderList;
    }

    /**
     * @description: Method called when user associates/disassociates record to a chat. Creates
     *               a linked/unlinked SMS record, which is displayed in the previous transcript section.
     * @what? associateSelectedRecordsWithAuto + associateRecordsForTranscriptEx
     * @TODO pass conversationHeader object as param, passlinked object as param - if is possible delete this function and use associateSelectedRecordsWithTranscript instead
     **/
    public static void associateSelectedRecordWithTranscript(String conversationRecordId,String objectPrefix, String objectId, Boolean isRecordLinked,Boolean isAuto){
        //associate variables
        Map<String, String> objectsKeyPrefixToApiNameMap = Util.getLinkedObjectsKeyPrefixToApiNameMap();
        Map<String, String> objectsKeyPrefixToColumnNameMap = Util.getLinkedObjectsKeyPrefixToColumnNameMap(false);

        if(!String.isBlank(conversationRecordId) && !String.isBlank(objectId)){
            if(String.isBlank(objectPrefix))
                objectPrefix = objectId.substring(0,3);
            try {
                if(objectsKeyPrefixToApiNameMap.containsKey(objectPrefix) && objectsKeyPrefixToColumnNameMap.containsKey(objectPrefix)){
                    //linking
                    String columnName = objectsKeyPrefixToColumnNameMap.get(objectPrefix);
                    //linking or unlinking based on isRecordLinked
                    String query = 'SELECT Id, Support_Number__c, Originating_Number__c, Status__c, Transcript_Summary_1__c, Transcript_Summary_2__c, ';
                    query += columnName + ' FROM Conversation_Header__c WHERE Id =: conversationRecordId';
                    Conversation_Header__c conversationHeaderToUpdate = (Conversation_Header__c) Database.query(query)[0];
                    SMS_Text__c sms = new SMS_Text__c();
                    sms.Conversation_Header__c = conversationHeaderToUpdate.Id;
                    sms.Support_Number__c = conversationHeaderToUpdate.Support_Number__c;
                    sms.Originating_Number__c = conversationHeaderToUpdate.Originating_Number__c;
                    List<SMS_Text__c> smsToInsert = new List<SMS_Text__c>();
                    String oldval = isRecordLinked ?  (String) conversationHeaderToUpdate.put(columnName, objectId) :  (String) conversationHeaderToUpdate.put(columnName, null);

                    AccessController.upsertAsUser(conversationHeaderToUpdate);

                    String objectApiName = objectsKeyPrefixToApiNameMap.get(objectPrefix);
                    String objectNameField = '500'.equals(objectPrefix)
                                                ? 'CaseNumber'
                                                : '801'.equals(objectPrefix)
                                                ? 'OrderNumber'
                                                : '800'.equals(objectPrefix)
                                                ? 'ContractNumber'
                                                : 'Name';
                    query = 'SELECT ' + objectNameField + ' FROM ' + objectApiName +' WHERE Id = \''+ objectId + '\' LIMIT 1'; //change to pass object as argument
                    String objectName = (String) Database.query(query)[0].get(objectNameField);
                    String objLabel = (String) Schema.describeSObjects(new List<String>{objectApiName})[0].getLabel();
                    sms.Message__c = createLinkingMessage(objectId, objLabel, objectName, isRecordLinked, isAuto);
                    sms.Source__c = Constant.salesforce_linking;
                    //if link was before we unlink it first
                    if(!String.isBlank(oldval) && isRecordLinked){
                        SMS_Text__c unlinkingSMS = sms.clone(false, true, false, false);
                        query = 'SELECT ' + objectNameField + ' FROM ' + objectApiName +' WHERE Id = \''+ oldval + '\' LIMIT 1'; //change to pass object as argument
                        objectName = (String) Database.query(query)[0].get(objectNameField);
                        unlinkingSMS.Message__c = createLinkingMessage(oldval, objLabel, objectName, false, isAuto);
                        smsToInsert.add(unlinkingSMS);
                    }
                    //end chat linking transcript creation
                    smsToInsert.add(sms);
                    if(Constant.stage_ended.equals(conversationHeaderToUpdate.Status__c)){
                        createAfterLinkingTranscript(conversationHeaderToUpdate, smsToInsert);
                    }else{
                        AccessController.insertAsUser(smsToInsert);
                    }
                }
            } catch (Exception ex) {
                insertException('Object Association Failed(4)', constant.priority_high, ex.getMessage());
            }
        } else {
            insertException('Object Association Failed', constant.priority_high, 'No conversation header id passed');
        }
    }

    /**
    * @description this function creates message for SMS_Text__c used to create linking infromation in transcript
    *
    **/
    public static String createLinkingMessage(String objectId, String objLabel, String fieldName, Boolean isRecordLinked, Boolean isAuto){
        String retString = '<span>';
        retString += isRecordLinked ?
                            isAuto ? label.TXT_Transcript_auto_linked_prefix : label.TXT_Transcript_linked_prefix
                            : label.TXT_Transcript_unlinked_prefix;
        retString += ' ' + objLabel + ': ';
        retString += '<a class="transcriptLink" href="/' + objectId + '" ';
        retString += '>' + fieldName + '</a>' + ' '+ label.TXT_Transcript_linked_unlinked_postfix + '</span>';

        return retString;
    }

    /**
     * @description: Method called for auto-link list of objects
     * @what?  bulkified associateSelectedRecordWithTranscript
     * @important! only for auto-linking in this form, without creating unlinking SMS_Text__c
     **/

    public static void associateSelectedRecordsWithTranscript (Conversation_Header__c conversationRecord, List<SObjectWrapper> objs, Boolean areLinked,Boolean isAuto){
        //associate variables
        Map<String, String> objectsKeyPrefixToColumnNameMap = Util.getLinkedObjectsKeyPrefixToColumnNameMap(false);

        if(conversationRecord != null  && !objs.isEmpty()){
            SMS_Text__c sms = new SMS_Text__c();
            sms.Conversation_Header__c = conversationRecord.Id;
            sms.Support_Number__c = conversationRecord.Support_Number__c;
            sms.Originating_Number__c = conversationRecord.Originating_Number__c;
            try {
                List<SMS_Text__c> smsToInsert = new List<SMS_Text__c>();
                for(SObjectWrapper obj : objs){
                    String objectId = obj.Id;
                    String objectPrefix = obj.ObjectPrefix;
                    if(objectsKeyPrefixToColumnNameMap.containsKey(objectPrefix)){
                        //linking
                        String columnName = objectsKeyPrefixToColumnNameMap.get(objectPrefix);
                        //linking or unlinking based on areLinked
                        String oldval = areLinked ?  (String) conversationRecord.put(columnName, objectId) :  (String) conversationRecord.put(columnName, null);
                        //transcript creation
                        SMS_Text__c tempMsg = sms.clone(false, true, false, false);
                        tempMsg.Message__c = createLinkingMessage(objectId, obj.ObjectLabel, obj.ObjectName, areLinked, isAuto);
                        tempMsg.Source__c = constant.salesforce_linking;
                        smsToInsert.add(tempMsg);
                    }
                }
                AccessController.upsertAsUser(conversationRecord);
                //end chat linking transcript creation
                if(Constant.stage_ended.equals(conversationRecord.Status__c)){
                    createAfterLinkingTranscript(conversationRecord, smsToInsert);
                }else{
                    AccessController.insertAsUser(smsToInsert);
                }
            } catch (Exception ex) {
                insertException('Object Association Failed(4)', constant.priority_high, ex.getMessage());
            }
        } else {
            String errorMessage = conversationRecord == null ? 'No conversation header passed' : 'Object list is empty';
            insertException('Object Association Failed', constant.priority_high, errorMessage);
        }
    }

     /**
     * @description: Validates a recipient's phone number for length and format
     * @return  Error message or null
     */
    public static String validateRecipientPhoneNumber(String phoneNumber){
        String errorMessage = null;
        if(phoneNumber == null){
            errorMessage = System.Label.RecipientNumberRequiredLbl;
        }else{
            phoneNumber = phoneNumber.trim();
            if(String.isBlank(phoneNumber)){
                errorMessage = System.Label.RecipientNumberRequiredLbl;
            }else if(!Pattern.matches(Constant.REGEX_VALID_PHONE_NO, phoneNumber)){
                errorMessage = System.Label.InvalidPhoneNoMsg;
            }else if(!isValidPhoneNumberLength(phoneNumber)){
                errorMessage = System.Label.PhoneNoLengthMsg;
            }
        }

        return errorMessage;
     }

       /**
     * @description: Determines if the given phone number has a valid length.
     * @param phoneNumber, contact's number.
     * @return  true/false.
     */
    public static Boolean isValidPhoneNumberLength(String phoneNumber){
        phoneNumber = phoneNumber.replaceAll(Constant.REGEX_REMOVE_UNWANTED_CH, '');
        Integer phNoLength = phoneNumber.length();
        return (phNoLength > 7 && phNoLength < 18);
    }

    /**
    * @description  Retrieves the LiveText phone number object for a given phone number
    **/
    public static LiveText_Number__c GetLiveTextNumberObject(String phoneNumber){
         String normalizedSupportNumber = Util.NormalizePhoneNumber(phoneNumber);
         LiveText_Number__c[] liveTextNumbers = [SELECT Auto_Response_Message__c, Business_Hours__c, Chat_End_Message__c, CreateEvent__c, CreateTask__c,ISOCountryCode__c,
                                                    CreatedById, CreatedDate, IsDeleted, Formatted_Support_Number__c, Initial_Message__c,
                                                    LastModifiedById, LastModifiedDate, Offline_Hours_Message__c, OwnerId, Name, Id, Number__c,
                                                    SystemModstamp, Validated__c,Screen_Pop_Default_Record_Type__c,Prepend_Country_Code__c FROM LiveText_Number__c Where Number__c=:normalizedSupportNumber LIMIT 1];
        if(liveTextNumbers.size() > 0){
            return liveTextNumbers[0];
        }
        return null;
    }

    /**
    * @description  Retrieves the LiveText phone number object for a given phone number
    **/
    public static LiveText_Number__c GetLiveTextNumberObjectById(String phoneNumberId){
         LiveText_Number__c[] liveTextNumbers = [SELECT Auto_Response_Message__c, Business_Hours__c, Chat_End_Message__c, CreateEvent__c, CreateTask__c,ISOCountryCode__c,
                                                    CreatedById, CreatedDate, IsDeleted, Formatted_Support_Number__c, Initial_Message__c,
                                                    LastModifiedById, LastModifiedDate, Offline_Hours_Message__c, OwnerId, Name, Id, Number__c,
                                                    SystemModstamp, Validated__c,Screen_Pop_Default_Record_Type__c,Prepend_Country_Code__c FROM LiveText_Number__c Where Id=:phoneNumberId];
        if(liveTextNumbers.size() > 0){
            return liveTextNumbers[0];
        }
        return null;
    }

    /**
    * @description  Retrieves the LiveText phone number object for a given phone number
    **/
    public static Boolean ListContainsObject(List<Object> listOfObjs, Object obj){
        for(Object listObj : listOfObjs){
            if(listObj.equals(obj)){
                return true;
            }
        }
        return false;
    }

     /**
     * @description Retrieves the most recent opt-instatus between the 2 given phone numbers.
     *
     * @Param       Id of LiveText phone number, destination phone number.
     *
     * @Return      Opt-in status between the 2 numbers, null if no records found.
     **/
    public static OptInStatus__c getOptInStatus(ID liveTextNumberId, String phoneNumber){
        OptInStatus__c[] optinstatuses = [SELECT CreatedDate, LiveTextNumber__c, Name, Id, Status__c, SubscriberPhoneNumber__c
                                            FROM OptInStatus__c
                                            WHERE LiveTextNumber__c=:liveTextNumberId AND SubscriberPhoneNumber__c =: Util.NormalizePhoneNumber(phoneNumber)
                                            ORDER BY CreatedDate DESC LIMIT 1 ];
        if(optinstatuses.size() > 0){
            return optinstatuses[0];
        }
        return null;
    }

    public static Map<String,Decimal> getOptInStatus(Id liveTextNumber, List<String> phoneNumbers){

        // Normalize Phone Numbers
        List<String> normalizedPhoneNumbers = new List<String>();
        for(String phoneNumber : phoneNumbers){
            if(!String.isBlank(phoneNumber)){
                normalizedPhoneNumbers.add(Util.NormalizePhoneNumber(phoneNumber));
            }
        }

        Map<String,Decimal> optInStatusMap = new Map<String,Decimal>();
        List<OptInStatus__c> optinstatuses = [SELECT CreatedDate, LiveTextNumber__c, Name, Id, Status__c, SubscriberPhoneNumber__c
                                                FROM OptInStatus__c  Where LiveTextNumber__c = :liveTextNumber AND SubscriberPhoneNumber__c IN :normalizedPhoneNumbers
                                                ORDER BY CreatedDate DESC LIMIT 45000 ];

        for(OptInStatus__c ois: optinstatuses){
            if(!optInStatusMap.containsKey(ois.SubscriberPhoneNumber__c)){
                optInStatusMap.put(ois.SubscriberPhoneNumber__c,ois.Status__c);
            }
        }
        return optInStatusMap;
    }

    public static Map<String,Decimal> getOptInStatus(List<SMS_Schedule__c> schedules){
        List<string> toPhoneNumbers = new List<string>();
        List<string> liveTextNumbers = new List<string>();
        Map<String,Decimal> optInStatusMap = new Map<String,Decimal>();

        for(SMS_Schedule__c s: schedules){
            liveTextNumbers.add(s.LiveText_Number__r.Number__c);
            toPhoneNumbers.add(NormalizePhoneNumber(s.To_Phone_Number__c));
        }
        List<OptInStatus__c> optinstatuses = [  SELECT CreatedDate, LiveTextNumber__c, Name, Id, Status__c, SubscriberPhoneNumber__c
                                                FROM OptInStatus__c  Where LiveTextNumber__c In :liveTextNumbers AND SubscriberPhoneNumber__c IN :toPhoneNumbers
                                                ORDER BY CreatedDate DESC LIMIT 45000 ];

        for(OptInStatus__c ois: optinstatuses){
            String phoneNumber = NormalizePhoneNumber(ois.LiveTextNumber__r.Number__c) + '->' + ois.SubscriberPhoneNumber__c;
            if(!optInStatusMap.containsKey(phoneNumber)){
                optInStatusMap.put(phoneNumber,ois.Status__c);
            }
        }

        if(optInStatusMap.size() > 0){
            return optInStatusMap;
        }
        return null;
    }

    public static Map<String,Decimal> getOptInStatus(Set<Id> liveTextNumbers, Set<String> toPhoneNumbers){

        Map<String,Decimal> optInStatusMap = new Map<String,Decimal>();
        List<OptInStatus__c> optinstatuses = [  SELECT CreatedDate, LiveTextNumber__c, LiveTextNumber__r.Number__c,Name, Id, Status__c, SubscriberPhoneNumber__c
                                                FROM OptInStatus__c  Where LiveTextNumber__c In :liveTextNumbers AND SubscriberPhoneNumber__c IN :toPhoneNumbers
                                                ORDER BY CreatedDate DESC LIMIT 45000 ];

        for(OptInStatus__c ois: optinstatuses){
            String phoneNumber = ois.LiveTextNumber__c + '->' + ois.SubscriberPhoneNumber__c;
            if(!optInStatusMap.containsKey(phoneNumber)){
                optInStatusMap.put(phoneNumber,ois.Status__c);
            }
        }

        if(optInStatusMap.size() > 0){
            return optInStatusMap;
        }
        return null;
    }

    /**
    * @description sObjec wrapper made only to sort List<Sobject> by LastModifiedDate DESC
    * @TODO delete if getObjectsData function is replaced by getSObjectsData function
    **/
    public class SObjectSorter implements Comparable {
        public SObject obj {get; set;}
        public Boolean isPersonContact {get;set;}

        public SObjectSorter(SObject obj){
            this.obj = obj;
            try{
                isPersonContact = 'Contact'.equals(String.valueOf(obj.getSObjectType())) ? (Boolean) obj.get('IsPersonAccount') : false;
            }catch(Exception ex){
                isPersonContact = false;
            }
        }

        public Integer compareTo(Object compareToObj){
            SObjectSorter compareToSObj = (SObjectSorter) compareToObj;
            if(String.valueOf(obj.get('LastModifiedDate')) < String.valueof(compareToSObj.obj.get('LastModifiedDate'))){
                return 1;
            }
            if(String.valueOf(obj.get('LastModifiedDate')) > String.valueOf(compareToSObj.obj.get('LastModifiedDate'))){
                return -1;
            }
            return 0;
        }
    }

}