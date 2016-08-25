public with sharing class PhoneNumberRelatedObjects{

    public List<SObjectWrapper> customObjects{get;set;}
    public String AutoFocusItemId{get;set;}
    public String PhoneNumber{get;set;}
    private LiveText_Number__c ltn;

    public PhoneNumberRelatedObjects(Id ltnObjectId, String phoneNumber){   
        initPhoneNumberRelatedObjects(null, ltnObjectId, phoneNumber, null);
    }

    public PhoneNumberRelatedObjects(Conversation_Header__c ch, Id ltnObjectId, String phoneNumber, List<SObjectWrapper> records){   
        initPhoneNumberRelatedObjects(ch, ltnObjectId, phoneNumber, records);
    }

    private void initPhoneNumberRelatedObjects(Conversation_Header__c ch, Id ltnObjectId, String phoneNumber, List<SObjectWrapper> records){ 
        customObjects = records;
        Boolean chReopened = ch == null ? false : ch.ConversationReopened__c;
        this.ltn = Util.GetLiveTextNumberObjectById(ltnObjectId);
        this.PhoneNumber = phoneNumber;

        AssignScreenPopRecordTypeHelper helper = new AssignScreenPopRecordTypeHelper(ltn);
        List<SelectOption> screenPopSequence = helper.getSelectedRecordTypes();

        if(customObjects == null){
            List<String> objectsTemp = new List<String>();
            objectsTemp.addAll(Util.getAllRelationshipObjects());
            List<SObject> objs = Util.getObjectsData(objectsTemp, phoneNumber,2000,10);
            customObjects = new List<SObjectWrapper>();
            for(SObject obj : objs){
                customObjects.add(new SObjectWrapper(obj));
            }
            objectsTemp.clear();
        }
        
        for(SelectOption option : screenPopSequence){ 
            String sequence = option.getValue();
            if(hasItems && !chReopened){
                AutoFocusItemId = getMRMItem(customObjects, sequence);
            }
            if(AutoFocusItemId != null){
               break;
            }
        }
        if(AutoFocusItemId == null && ltn.Screen_Pop_Default_Record_Type__c != null && !chReopened){
            AutoFocusItemId = ltn.Screen_Pop_Default_Record_Type__c;
        }
    }

    /**
    * @desription this method reduces set of sobject to be opened as subtabs
    *
    **/
    public void setOnlySelectedRecords(){
        AssignScreenPopRecordTypeHelper helper = new AssignScreenPopRecordTypeHelper(ltn);
        List<SelectOption> screenPopSequence = helper.getSelectedRecordTypes();
        Set<String> objTypes = new Set<String>();
        for(SelectOption option : screenPopSequence){ 
            objTypes.add(option.getValue());
        }
        this.customObjects = getObjectsWithinSelectedTypes(customObjects, objTypes);
    }
    /**
    *@description Funtion for auto-linking. Links list of objects to passed conversation header id
    *@TODO pass conversation object instead of ID
    **/
    public void AutoLink(Conversation_Header__c conversationRecord){   
        if(hasItems && conversationRecord != null){
            AssignAutoLinkingRecordTypeHelper helper = new AssignAutoLinkingRecordTypeHelper(ltn);
            List<SelectOption> selectedOptions = helper.getSelectedRecordTypes();
            List<SObjectWrapper> objs = new List<SObjectWrapper>();
            for(SelectOption option : selectedOptions){
                SObjectWrapper tempObj = getMRObject(customObjects, option.getValue());
                if(tempObj != null){
                    objs.add(tempObj);
                }
            }
            if(!objs.isEmpty())
                Util.associateSelectedRecordsWithTranscript(conversationRecord, objs, true, true);
        }else{
        	if(conversationRecord == null){
            	String errorMessage =  'No conversation header passed';
            	Util.insertException('Auto-Linking Failed', constant.priority_high, errorMessage);
        	}
        }
    }
    
    //Getting most recent ID form 'objs' only for records with objectType = 'objectType'
    public static String getMRMItem(List<SObjectWrapper> objs, String objectType){
        if(objs == null || objs.size() == 0){
           return null;
        }
        if (objectType == null)
            objectType = objs[0].ObjectType;
        Long mruTime = 0;
        String id = null;
        for(SObjectWrapper obj : objs){
            if(objectType.equals(obj.ObjectType)){
                if(mruTime < obj.LastModifiedTime){
                    id = obj.Id;
                    mruTime = obj.LastModifiedTime;
                }
            }
        }
        return id;
    }

    //Getting most recent SObject form 'objs' only for records with objectType = 'objectType'
    public static SObjectWrapper getMRObject(List<SObjectWrapper> objs, String objectType){
        if(objs == null || objs.size() == 0){
           return null;
        }
        if (objectType == null)
            objectType = objs[0].ObjectType;
        Long mruTime = 0;
        SObjectWrapper retObj = null;
        for(SObjectWrapper obj : objs){
            if(objectType.equals(obj.ObjectType)){
                if(mruTime < obj.LastModifiedTime){
                    retObj = obj;
                    mruTime = obj.LastModifiedTime;
                }
            }
        }
        return retObj;
    }

    /**
    * @description this method filters given list of Sobject by given ObjectTypes
    *
    **/
    private List<SObjectWrapper> getObjectsWithinSelectedTypes(List<SObjectWrapper> objs, Set<String> objectTypes){
        if(objs == null || objs.size() == 0)
           return new List<SObjectWrapper>();
        if(objectTypes == null)
            objectTypes = new Set<String>();
        List<SObjectWrapper> retList = new List<SObjectWrapper>();
        Map<String,SObjectWrapper> objRecMap = new Map<String,SObjectWrapper>();
        Map<String,Long> objTimeMap = new Map<String,Long>();
        for(SObjectWrapper obj : objs) {
            String recType = obj.ObjectType;
            Long mruTime = objTimeMap.containsKey(recType) ? objTimeMap.get(recType) : 0;
            if(obj.LastModifiedTime > mruTime){
                objRecMap.put(recType,obj);
                objTimeMap.put(recType, obj.LastModifiedTime);
            }
        }
        for(String s : objectTypes) {
            if(objRecMap.containsKey(s)) {
                retList.add(objRecMap.get(s));
            }
        }
        List<SObjectWrapper> retRecord = new List<SObjectWrapper>();
        if(retList.size() > 0) {
            retRecord.add(retList[0]);
        }
        this.customObjects = new List<SObjectWrapper>();
        return retRecord;
    }

    public Boolean hasItems{
        get{
            return (customObjects == null ? false : !customObjects.isEmpty());
        }
    }
    
}