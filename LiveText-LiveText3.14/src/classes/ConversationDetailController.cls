/**
 * @author         Amit Madhoriya(amit@comitydesigns.com)
 * @version        1.0
 * @date           08.19.2014
 * @description    Controller class for the conversation detail section displayed beside Chat Panel on Converation tab in the console. 
 *                 It contains methods to perform below requirements,
 *                 1. Retrieve Account/Contact/Lead for the originating number in conversation header/sms text.
 *                 2. Creates a list of all the retrieved records and display it on the page.
 *                 3. Displays the lis of previous transcripts for the selectd record on the page.
*/
public with sharing class ConversationDetailController {
    public String conversationHeaderId{ get; set; }
    public String selectedRecId{ get; set; }
    public List<AssociatedRecord> associatedRecordList;
    public List<SObjectWrapper> associatedSObjects = new List<SObjectWrapper>();
    public String objectPrefix{ get; set; }
    public Boolean showAllLink{ get; set; }
    public String recordId{ get; set; }
    public String transcriptHeader{ get; set; } //This variable is set to the appropriate text to show whether we are displaying all the Transcripts vs Selected Record Transcripts
    public String linkedObjId { get; set; }
    public Boolean isRecordLinked{ get; set; }
    public List <Conversation_Header__c> ConversationHeaderList { get; set; }
    
    public String conversationType{ get; set; }
    public String originatingObjectId{ get; set; }
    public String originatingObjectPrefix{ get; set; }
    public String ConversationHeaderRecords {
        get{
            return JSON.serialize(ConversationHeaderList);
        }
        set;
    }   
    
    public String nameSpace {
        get {
            return Util.getNamespace();
        }
        set;
    }
    
     public String AssociatedObjectsJSON {
        get{
            return associatedSObjects == null ? JSON.serialize(new List<SObjectWrapper>()) : JSON.serialize(associatedSObjects);
        }
        set;
    }   

    /**
     *@description this function gets 10 most recent SObjects per objectType for given phone number
     *             Next it checks for every ObjectType in which fields we need to look for data
    **/
    private void retrieveObjectsAssociatedRecords(String phoneNumber) {
        fillAssociatedRecordsWithSObjects(Util.getObjectsData(new List<String>(Util.getAllRelationshipObjects()), phoneNumber, 2000 , 10));
    }


    /**
     *@description this function fills associated records list with giver SObjects
     *
    **/
    private void fillAssociatedRecordsWithSObjects(List<SObject> allObjects) {
        Boolean hasAccountPermission = Util.getPermissionMap().get(Constant.ACCOUNT_OBJECT);
        Map<String, Map<String, List<String>>> apiNameToFieldNames = new Map<String,Map<String,List<String>>>();
        for(SObject sobj : allObjects) {
            String apiName = (String) sobj.getSObjectType().getDescribe().getName();
            if(!apiNameToFieldNames.containsKey(apiName)) {
                apiNameToFieldNames.put(apiName, Util.getNeededFieldMap(apiName));
            }
        }
        Map<String, String> objNameToIconUrl = new Map<String,String>();	
        List<Schema.DescribeTabSetResult> tabSetPerApp = Schema.describeTabs();
		Set<Schema.DescribeTabResult> allTabs = new Set<Schema.DescribeTabResult>();
		for(Schema.DescribeTabSetResult tabSet : tabSetPerApp){
			allTabs.addAll(tabSet.getTabs());
		}
		for(Schema.DescribeTabResult tab : allTabs){
			if(!objNameToIconUrl.containsKey(tab.getSobjectName()))
				objNameToIconUrl.put(tab.getSobjectName(), tab.getMiniIconUrl());
		}

        for(Sobject sobj : allObjects) {
            String apiName = (String) sobj.getSObjectType().getDescribe().getName();
            String iconUrl = objNameToIconUrl.containsKey(apiName) ? objNameToIconUrl.get(apiName) : 'customObject';
 			AssociatedRecord ar = new AssociatedRecord(sobj, hasAccountPermission, conversationType, apiNameToFieldNames.get(apiName), iconUrl);
            this.associatedRecordList.add(ar);
            this.associatedSObjects.add(new SObjectWrapper(sobj));
        }
    }

    /**
     * @description: Controller constructor method.
    */  
    public ConversationDetailController() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    }
    
    public void InitializeConversation() {  
        populateAssociatedRecordList();                 
    }

    public PageReference getCurrentConversationHeaderList() {       
        ConversationHeaderList = Util.getCurrentConversationHeaderList(conversationHeaderId);           
        return null;
    }
        
    /**
     * @description: Retrieves the originating number(phone number from which SMS is received) from the given conversation header Id.
     *               Using the originating number finds the Account/Contact/Lead records and then creates a list of AssociatedRecord
     *               which is displayed on the page.
     * @return List of AssociatedRecord objects.
    */
    public List<AssociatedRecord> getAssociatedRecordList() {
        return associatedRecordList == null ? new List<AssociatedRecord>() : associatedRecordList;
    }
    
    /**
     * @description: Loads the transcripts for the selected associated record in the table.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference loadSelectedRowTrasncripts() {
        showAllLink = true;
        Map<Id,AssociatedRecord> associatedRecordMap = new Map<Id,AssociatedRecord>();
        if(associatedRecordList != null) {
            for(AssociatedRecord ar: associatedRecordList) {
                associatedRecordMap.put((Id)ar.recordId,ar);
            }
        }
        AssociatedRecord arObj = associatedRecordMap.get((Id)selectedRecId);
        if(arObj != null) {
            String arObjName = arObj.caseClickable 
                                ? arObj.caseNumber 
                                : '001'.equals(arObj.objectPrefix) 
                                    ? arObj.accountName 
                                    : arObj.name;
			transcriptHeader = Label.PrevTextSessionsLbl2 + ' ' + arObj.recordType + ' - '+ arObjName;
        }
        return null;
    }
    
    /**
     * This method is created as part of LT-685, which is to load all the transcripts for all the objects displayed in the screenpopup table.
     * @return Returning null so that the page is not redirected to any another page after method executes. 
    */  
    public PageReference loadAllTranscripts() {
        showAllLink = false;
        String tempString = '';
        if(associatedRecordList != null) {                  
            for(AssociatedRecord ar: associatedRecordList) {
                tempString = tempString + ar.recordId + ',';
            }
        }
        //selectedRecID will contain all the IDs of all the objects in the form csv form for eg: 'ID1,ID2'
        selectedRecId = '\''+tempString+'\''; 
        transcriptHeader = Label.PrevTextSessionsLbl1;
        return null;
    }   
    
    public void populateAssociatedRecordList() {
        this.associatedRecordList = new List<AssociatedRecord>();
        if (!String.isBlank(originatingObjectId)) {
            conversationType = 'outbound';
            retrieveAndAssociateOriginatingObjectLinkedRecords();
        } else {
                conversationType = 'inbound';
                List<Conversation_Header__c> convHeaderList =   [   SELECT Id,Originating_Number__c,Formatted_Originating_Number__c
                                                                    FROM Conversation_Header__c 
                                                                    WHERE Id=:this.conversationHeaderId
                                                                ];
            if(!convHeaderList.isEmpty()) {
                Conversation_Header__c convHeader = convHeaderList.get(0);
                retrieveObjectsAssociatedRecords(convHeader.Originating_Number__c);
                //This call is needed otherwise the 'hiddenconvheaderlist' is always set to null on the page
                getCurrentConversationHeaderList();
            }
        } 
    }

    /**
     * @description This method is called only for outbound text sessions to display the screen pop table with the related records.
     *              This method is to retrieve all parent objects, and most recent 10 objects form child objects
    */
    public void retrieveAndAssociateOriginatingObjectLinkedRecords() {
        Map<String, List<SObject>> mapObjectTypeToListOfSObjects = retrieveRecordsFromId(originatingObjectId);
        Id tempId = (Id) originatingObjectId;
        if(tempId.getsObjectType().getDescribe().getName() == Constant.ACCOUNT_OBJECT) {
            try {
                    String queryString = 'Select  PersonContactId From Account Where id =:tempId AND IsPersonAccount = true';
                    for(Account item:Database.query(queryString)) {
                        if(item.get('PersonContactId') != null) {
                            Map<String, List<SObject>> personContactDataMap = retrieveRecordsFromId((String)item.get('PersonContactId'));
                            List<SObject> temp = new List<SObject>();
                            for(String objName : personContactDataMap.keySet()) {
                                temp = new List<SObject>();
                                if(mapObjectTypeToListOfSObjects.containsKey(objName))
                                    temp = mapObjectTypeToListOfSObjects.get(objName);
                                    temp.addAll(personContactDataMap.get(objName));
                                    mapObjectTypeToListOfSObjects.put(objName, temp);
                            }
                        }
                    }
                } catch(exception ex) {      
                    //if not a person acc       
                }      
            }
            //sorting objects by lastModifiedDate, and return only 10 per object type
            Set<Id> preventDuplicates = new Set<Id>();
            List<SObject> retList = new List<SObject>();
            List<Util.SObjectSorter> finalSorter = new List<Util.SObjectSorter>();
            for(String objType : mapObjectTypeToListOfSObjects.keySet()) {
                if(mapObjectTypeToListOfSObjects.get(objType) != null) {
                    List<Util.SObjectSorter> tempSorter = new List<Util.SObjectSorter>();
                    for(SObject obj : mapObjectTypeToListOfSObjects.get(objType)) {
                        if(obj != null && !preventDuplicates.contains(obj.Id)) {
                            tempSorter.add(new Util.SObjectSorter(obj));
                            preventDuplicates.add(obj.Id);
                        }
                    }
                    tempSorter.sort();
                    List<Util.SObjectSorter > tempToRet = new List<Util.SObjectSorter >();
                    for(Util.SObjectSorter sortedObj : tempSorter) {
                        if(tempToRet.size()<10) {
                            String itemType = String.valueOf(sortedObj.obj.getSObjectType());
                            if(itemType != Constant.CONTACT_OBJECT || (itemType == Constant.CONTACT_OBJECT && !AccountWrapper.IsPersonContact((Contact)sortedObj.obj))) {
                                tempToRet.add(sortedObj);
                            } else {
                                system.debug('Contact.IsPersonAccount is true for id='+sortedObj.obj);
                            }
                        } else{
                            break;
                        }
                    }
                    finalSorter.addAll(tempToRet);
                }
            }
            finalSorter.sort();
            for(Util.SObjectSorter s : finalSorter) {
                retList.add(s.obj);
            }
        fillAssociatedRecordsWithSObjects(retList);
    }

    /**
     * @description retrieveRecordsFromId retrieve all linked records, and up to 10 records per child from given record id. 
     *              cost of this method is related to number of child relationship (basic 2soqls, and additional 1 per 20 child relationships)
     * @return map Object Api Name -> List of records
    **/

    private  Map<String, List<SObject>> retrieveRecordsFromId(String objId) {
        Id tempId = (Id) objId;
        String objName = tempId.getsObjectType().getDescribe().getName();
        Map<String,String> fieldToRelationshipNameMap  = new Map<String, String>();
        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(objName).getDescribe();
        Set<String> linkedObjects = Util.getAllRelationshipObjects();
        Map<string, schema.SObjectField> objFieldMap = dsr.fields.getMap();
        for(String field : objFieldMap.keyset()) {
            Schema.DescribeFieldResult dfr = objFieldMap.get(field).getDescribe();
            if(dfr.getReferenceTo().size()>0) {
                if(dfr.getReferenceTo().get(0).getDescribe().isSearchable() && dfr.isAccessible()) {
                    String fielddataType = String.valueOf(dfr.getReferenceTo()[0]);
                    if(linkedObjects.contains(fielddataType) && dfr.getReferenceTo()[0].getDescribe().isAccessible()) {
	                	if(!dfr.getRelationshipName().endsWithIgnoreCase('__pc') && !dfr.getRelationshipName().endsWithIgnoreCase('__pr'))
                            fieldToRelationshipNameMap.put(field.toLowerCase(), dfr.getRelationshipName());
                    }
                }
            }
        }
        List<String> tempFieldList = new List<String>();
        tempFieldList.addAll(fieldToRelationshipNameMap.keySet());
        String relatedFields = String.join(tempFieldList,', ');
        relatedFields = String.isEmpty(relatedFields) ? 'Id' : relatedFields +',Id';
        //query to get relationship objects with id filled
        SObject records = Database.query('SELECT ' + relatedFields + ' FROM ' + objName + ' WHERE id =\'' + String.escapeSingleQuotes(objId) + '\'' + ' LIMIT 1');
        List<String> fieldsFromRelationships = new List<String>();
        List<String> notNullRelationships = new List<String>();
        for(String field : fieldToRelationshipNameMap.keySet()) {
            Id temp = (Id)records.get(field);
            if(temp != null) {
                if(temp.getsObjectType() != null && temp.getsObjectType().getDescribe() != null && temp.getsObjectType().getDescribe().isAccessible()) {
                    //String relationshipName = field.endsWithIgnoreCase('__c') ? field.removeEnd('c') + 'r' : field.endsWithIgnoreCase('id') ? field.removeEnd('id') : field;
                    //relationshipName = relationshipName.endsWithIgnoreCase('__pc') ? relationshipName.removeEnd('c') + 'r' : relationshipName.endsWithIgnoreCase('id') ? relationshipName.removeEnd('id') : relationshipName;
                    notNullRelationships.add(fieldToRelationshipNameMap.get(field));
                    fieldsFromRelationships.addAll(getFieldsFromRelationship(field, temp.getsObjectType().getDescribe().getName(), fieldToRelationshipNameMap.get(field)));
                }
            }
        }
        fieldsFromRelationships.addAll(objFieldMap.keyset());
        Map<String, String> childObjectRelationshipNamesToApiName = new Map<String, String>();
        for(Schema.ChildRelationship cr : dsr.getChildRelationships()) {
            if(!String.isEmpty(cr.getRelationshipName()) && linkedObjects.contains(cr.getChildSObject().getDescribe().getName()) && cr.getChildSObject().getDescribe().isAccessible())
                childObjectRelationshipNamesToApiName.put(cr.getRelationshipName(), cr.getChildSObject().getDescribe().getName());
        }
        List<String> subQueriesList = new List<String>();
        Integer subQueriesLimitNumber = 20;
        String subQueries = '';
        for(String child : childObjectRelationshipNamesToApiName.keySet()) {
            subQueriesLimitNumber--;
            if(subQueriesLimitNumber == 0) {
                subQueriesLimitNumber = 19;
                subQueriesList.add(subQueries);
                subQueries = '';
            }
            subQueries += ',(SELECT ' + String.join(Util.getNeededFieldForQuery(childObjectRelationshipNamesToApiName.get(child)), ',') + ' FROM ' + child + ' ORDER BY LastModifiedDate DESC LIMIT 10)'; 
        } 
        if(!String.isEmpty(subQueries)) 
            subQueriesList.add(subQueries);
        List<SObject> listRecords = new List<SObject>();
        for(String item:subQueriesList) {
            String q = 'SELECT ' + String.join(fieldsFromRelationships, ',') + item + ' FROM ' + objName + ' WHERE Id =\'' + String.escapeSingleQuotes(objId) + '\'' + ' LIMIT 1';
            SObject record = Database.query(q);
            listRecords.add(record);
        }
        Map<String, List<SObject>> mapObjectTypeToListOfSObjects = new Map<String, List<SObject>>();
        List<SObject> temp = new List<SObject>();
        //getting all linked records - only for first query to prevent duplicates
        SObject masterRecord = null;
        if(listRecords.isEmpty()) {
            masterRecord = Database.query( 'SELECT ' + String.join(fieldsFromRelationships, ',') + ' FROM ' + objName + ' WHERE Id =\'' + String.escapeSingleQuotes(objId) + '\'' + ' LIMIT 1');
        } else {
            masterRecord = listRecords[0];
        }
        mapObjectTypeToListOfSObjects.put(objName, new List<Sobject>{masterRecord});
        for(String relationshipName : notNullRelationships) {
            String tempObjName = childObjectRelationshipNamesToApiName.get(objName);
            temp = new List<SObject>();
            if(mapObjectTypeToListOfSObjects.containsKey(tempObjName))
                temp = mapObjectTypeToListOfSObjects.get(tempObjName);
            SObject obj = masterRecord.getSObject(relationshipName);
            temp.add(obj);
            mapObjectTypeToListOfSObjects.put(tempObjName, temp);
        }

        //getting all child records
        for(SObject record:listRecords) {
            String jsonRecord = JSON.serialize(record);
            Map<String, Object> jsonRecordMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRecord );
            for(String child : childObjectRelationshipNamesToApiName.keySet()) {
                Object preventNullRelationshipFromBeingAccessed = record.get('Id');
                if(jsonRecordMap.keySet().contains(child)) {   
                    List<Object> childObjects = new List<Object>();
                    for(SObject ob:record.getSObjects(child)) {
                        childObjects.add(ob);
                    }
                    if(childObjects != null) {  
                        String childObjType = childObjectRelationshipNamesToApiName.get(child);
                        temp = new List<SObject>();
                        if(mapObjectTypeToListOfSObjects.containsKey(childObjType)) {   
                            temp = mapObjectTypeToListOfSObjects.get(childObjType);
                        }
                        for(Object childObj : childObjects) {
                            SObject tempSObj = (SObject) childObj;
                            temp.add(tempSObj);
                        }
                        mapObjectTypeToListOfSObjects.put(childObjType, temp);
                    }
                }
            }
        }
        return mapObjectTypeToListOfSObjects;
    }


    private List<String> getFieldsFromRelationship(String fieldName, String objApiName, String relationshipName){
        List<String> fieldList = new List<String>();
        Map<String, Schema.SObjectField> describeFieldsMap = Schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();
        for(String field : Util.getNeededFieldForQuery(objApiName)){//Util.getAccessibleFieldsWithRelationshipNameFields(objApiName)){
            if(!'id'.equals(field))
                fieldList.add(relationshipName + '.' + field);
        }
        return fieldList;
    }

    /**
        * @description associates/unassociates linked/unlinked objects from screen pop table and create transcript 
        * @TODO -V- try to pass whole object
    **/
    @RemoteAction
    public static void associateSelectedRecords(string conversationHeaderId, string objectPrefix, string linkedObjId, Boolean isRecordLinked) {
        Util.associateSelectedRecordWithTranscript(conversationHeaderId, objectPrefix, linkedObjId, isRecordLinked, false);
    }   
    
    /**
        * @description  Inner wrapper class which contains the value of Account/Contact/Lead objects to be displayed on page.
        * LT-649 -- implementing the class Comparable Interface, As we need to sort objects based on LastModifiedDate
    */
    public with sharing class AssociatedRecord {
        public String recordId{ get; set; }
        public String recordType{ get; set; }
        public String objectPrefix{ get; set; }
        public String name{ get; set; }
        public String caseNumber{ get; set; } //LT-649      
        public String phone{ get; set; }
        public String email{ get; set; }
        public String status{ get; set; }
        public String title{ get; set; }
        public String accountName{ get; set; }
        public Boolean hasAccountPermission{ get; set; }
        public DateTime lastModifiedDate{ get; set; }
        public String conversationType{ get; set; }
        public String iconUrl{ get; set; }
        public Boolean nameClickable { get; set; }
        public Boolean caseClickable { get; set; }
        public String objectType { get; set; }
        public String linkName{ get; set; }
        public String pluralLabel{ get; set; }
        private SObject sobj;
        
        /**
            * @description: Constructor sets the field of the class based on the give object Type (Account/Contact/Lead/Opportunity).
            * @param sobj, SObject using which field values are populated.
            * @param hasAccountPermission
            * @param conversationType
            * @param fieldMap, Map used to get data from SObject fields, for each wrapper field it contains ordered List (Lists) of fieldNames (LT-1276)
        */ 
		public AssociatedRecord(SObject sobj, Boolean hasAccountPermission, String conversationType, Map<String,List<String>> fieldMap, String iconUrl)
		{            
			this.conversationType = conversationType;
            this.sobj = sobj;           
            this.recordId = this.sobj.Id;
            Id id = sobj.Id;
            this.objectType = (String) id.getSObjectType().getDescribe().getName();
            this.objectPrefix = (String) id.getSObjectType().getDescribe().getKeyPrefix();
            this.pluralLabel = (String) id.getSObjectType().getDescribe().getLabelPlural();
            this.hasAccountPermission = hasAccountPermission;
            this.iconUrl = iconUrl;
            this.caseClickable = false;
            setFields(fieldMap);

            if(caseClickable) {
                linkName = caseNumber;
            } else if(objectType == Constant.ACCOUNT_OBJECT) {
                linkName = accountName;
            } else {
                linkName = name;
            }
        }

        private String getDataFromField(Map<String,List<String>> fieldMap, String field, SObject obj){
            String retData = '';
            for(String fieldName : fieldMap.get(field)){
            	Object fieldObj = obj.get(fieldName);
            	if(fieldObj != null){
                	retData = (String)fieldObj;
                	if(!String.isBlank(retData))
                    	return retData;
            	}
            }
            return retData;
        }

        private String getDataFromNameField(Map<String,List<String>> fieldMap, SObject obj){
            String retData = '';
            for(String fieldName : fieldMap.get('name')){
                if(fieldName.equalsIgnoreCase('name')){
                    retData = (String) obj.get(fieldName);
                    if(!String.isBlank(retData))
                        return retData;  
                }else{
                    retData = (String) obj.get(fieldName);
                }
            }
            return retData;
        }

        private String getDataFromRelatedRecord(Map<String,List<String>> fieldMap, String field, SObject obj, Map<String, Schema.SObjectField> objFieldMap){
            String retData = '';
            String nameField = 'caseFromRelationship'.equals(field) ? 'CaseNumber' : 'Name';
            for(String fieldName : fieldMap.get(field)){
                retData = obj.get(fieldName) != null ? (String) obj.getSObject(objFieldMap.get(fieldName).getDescribe().getRelationshipName()).get(nameField) : '' ;
                if(!String.isBlank(retData)){
                    return retData;
                }
            }
            return retData;
        }

        private void setFields(Map<String,List<String>> fieldMap){
			this.name = '';
			this.recordType = (String) this.sobj.getSObjectType().getDescribe().getLabel();
			this.caseNumber = '';
			this.phone = '';
			this.email = '';
			this.status = '';
			this.accountName ='';
			this.title = '';
			this.nameClickable = true;
			this.caseClickable = false;
			Map<String, Schema.SObjectField> objFieldMap = Schema.getGlobalDescribe().get(this.sobj.getSObjectType().getDescribe().getName()).getDescribe().fields.getMap();

			//Name logic, for accountName we take alwayes Name from Account
			if('001'.equals(objectPrefix)){
				this.nameClickable = false;
				this.accountName = /*new AccountWrapper((Account)this.sobj).IsPersonAccount
								 ? (String) this.sobj.getSObject(objFieldMap.get('personcontactid').getDescribe().getRelationshipName()).get('Name') 
								 : */(String) this.sobj.get('name');
				this.name = '';
				this.caseNumber = '';
				this.caseClickable = false;
			}else{
				if(fieldMap.containsKey('objectAndNameInApiName') && String.isBlank(this.name)){
                    this.name = getDataFromField(fieldMap, 'objectAndNameInApiName', this.sobj);
				}
				if(fieldMap.containsKey('name') && String.isBlank(this.name)){
                    this.name = getDataFromNameField(fieldMap, this.sobj);
				}
				if(fieldMap.containsKey('nameInApiName') && String.isBlank(this.name)){
                    this.name = getDataFromField(fieldMap, 'nameInApiName', this.sobj);
				}
				if(fieldMap.containsKey('contactName') && String.isBlank(this.name)){
                    name = getDataFromRelatedRecord(fieldMap, 'contactName', sobj, objFieldMap);
                    if(!String.isBlank(name)){
                        nameClickable = false;
                    }
				}
				if(fieldMap.containsKey('leadName') && String.isBlank(this.name)){
                    name = getDataFromRelatedRecord(fieldMap, 'leadName', sobj, objFieldMap);
                    if(!String.isBlank(name)){
                        nameClickable = false;
                    }
				}
				//Case number logic
				if(fieldMap.containsKey('caseNumber')){
                    this.caseNumber = getDataFromField(fieldMap, 'caseNumber', this.sobj);
				    caseClickable = true;
                }
				//AccountName logic
				if(fieldMap.containsKey('accountName')){
                    accountName = getDataFromRelatedRecord(fieldMap, 'accountName', sobj, objFieldMap);
				}
			}
			//Phone logic
			if(fieldMap.containsKey('phone')){
                this.phone = getDataFromField(fieldMap, 'phone', this.sobj);
			}
			//Email logic
			if(fieldMap.containsKey('email')){
                this.email = getDataFromField(fieldMap, 'email', this.sobj);
			}
			//Status logic
			if(fieldMap.containsKey('status')){
                this.status = getDataFromField(fieldMap, 'status', this.sobj);
			}if(fieldMap.containsKey('stage') && String.isBlank(this.status)){
                this.status = getDataFromField(fieldMap, 'stage', this.sobj);
			}

			//prevent duplicate in caseNumber and Name fields
			if(!String.isBlank(caseNumber)){
				if(this.caseNumber.equalsIgnoreCase(this.name)){
					this.name = '';
					this.caseClickable = true;
                    this.nameClickable = false;
                    if(fieldMap.containsKey('nameInApiName') && String.isBlank(name)){
                        this.name = getDataFromField(fieldMap, 'nameInApiName', this.sobj);
                    }
                    if(fieldMap.containsKey('contactName') && String.isBlank(this.name)){
                        this.name = getDataFromRelatedRecord(fieldMap, 'contactName', this.sobj, objFieldMap);
                    }
                    if(fieldMap.containsKey('leadName') && String.isBlank(this.name)){
                        this.name = getDataFromRelatedRecord(fieldMap, 'leadName', this.sobj, objFieldMap);
                    }
				}
            }else{
                if(fieldMap.containsKey('caseFromRelationship')){
                    this.caseNumber = getDataFromRelatedRecord(fieldMap, 'caseFromRelationship', this.sobj, objFieldMap);
                    caseClickable = false;
                }
            }

			TimeZone tz = UserInfo.getTimeZone();
			DateTime now = DateTime.now();
			tz.getOffset(now);
			Double OffSet=(tz.getOffset(now)/(3600000));
			Double absoluteOffSet= Math.abs(OffSet);
			this.lastModifiedDate = (DateTime)this.sobj.get('LastModifiedDate')+((0.2*OffSet)/4.8);
		}
	}
	
}