/**
 * @description:    This class represents an item to be scheduled for delivery. All fields except ScheduleDate are required.
 *                  If ScheduleDate is not specified, the item is queued for immediate delivery.
 *                  
 */
 global class ScheduleItem {
    @InvocableVariable(label='Object Id' description='Identifier for object that triggered this scheduled item.' required=true)
    global ID ObjectId;

    @InvocableVariable(label='Reference Id' description='Reference identifier for this scheduled item.' required=true)
    global String ReferenceId;
  
    @InvocableVariable(label='LiveText Number' description='Phone number to send the message from.' required=false)
    global String LiveTextNumber;

    @InvocableVariable(label='To' description='Phone number to send the message to.' required=false)
    global String ToPhoneNumber;

    @InvocableVariable(label='Message' description='Message to send.' required=true)
    global String Message;
  
    @InvocableVariable(label='Schedule Date' description='Date and time to send the message.')
    global DateTime ScheduleDate;
    
    @InvocableVariable(label='Enforce Object Presence' description='If checked and the object specified by ObjectId is is deleted prior to send, the send will fail.')
    global Boolean  EnforceObjectPresence;
    
    @InvocableVariable(label='Bypass Opt-in' description='If checked, this message will be sent without verification of opt in.')
    global Boolean  BypassOptinCheck = false;
    
    @InvocableVariable(label='Message Source' description='Optional message source (ITR, etc)')
    global String  MessageSource;
 
    
    /**
    * @description  Salesforce prefix for an account.
    **/   
    public static String accountPrefix {get;set;}
    
    /**
    * @description  Salesforce prefix for a contact.
    **/   
    public static String contactPrefix {get;set;}
    
    /**
    * @description  Salesforce prefix for a lead.
    **/   
    public static String leadPrefix {get;set;}
    
    /**
    * @description  Salesforce prefix for a case.
    **/   
    public static String casePrefix {get;set;}
    
    /**
    * @description  Salesforce prefix for an event.
    **/   
    public static String eventPrefix {get;set;}
    
     /**
    * @description  Salesforce prefix for a task.
    **/   
    public static String taskPrefix {get;set;}

     /**
    * @description  Salesforce prefix for a opportunity.
    **/   
    public static String opportunityPrefix {get;set;}
    
    
    /**
    * @description  Saved account object to prevent multiple queries.
    **/ 
    private AccountWrapper accObj;
    
    /**
    * @description  Saved contact object to prevent multiple queries.
    **/ 
    private Contact conObj;
    
    /**
    * @description  Saved lead object to prevent multiple queries.
    **/ 
    private Lead ldObj;
    
    /**
    * @description  Saved case object to prevent multiple queries.
    **/ 
    private Case caseObj;
    
    /**
    * @description  Saved Event object to prevent multiple queries.
    **/ 
    private Event eventObj;
    
     /**
    * @description  Saved Task object to prevent multiple queries.
    **/ 
    private Task taskObj;

     /**
    * @description  Saved Opportunity object to prevent multiple queries.
    **/ 
    private Opportunity oppObj;
    
    public Boolean IsAlterScheduleBasedOnReferenceId{
    	get{
    		return ReferenceId != null && ReferenceId.equals((String)ObjectId);
    	}
    }
    
    /**
    * @description  Constructor
    **/   
    //-V- ScheduleItem refactor place - whole class. If we use RetrievePreferredPhoneNumber class, we can operate only on object id, SObject to store this object, and RetrievePreferredPhoneNumber to get phone number
    global ScheduleItem(){
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        accountPrefix = getKeyPrefix(gd, 'Account');
        contactPrefix = getKeyPrefix(gd, 'Contact');
        leadPrefix = getKeyPrefix(gd, 'Lead');
        casePrefix = getKeyPrefix(gd, 'Case');
        eventPrefix = getKeyPrefix(gd, 'Event');
        taskPrefix = getKeyPrefix(gd, 'Task');
        opportunityPrefix = getKeyPrefix(gd, 'Opportunity');
    }
    
    
    private String getKeyPrefix(Map<String, Schema.SObjectType> gd, String objectName){
        try{
            return gd.get(objectName).getDescribe().getKeyPrefix();
        }
        catch(Exception ex){
            return 'NA';
        }
    }
    
    private String objectPrefix{
        get{
            return ObjectId == null ? null : ObjectId.getSObjectType().getDescribe().getKeyPrefix();
        }
    } 
    
    /**
    * @description  If the specifed object id represents an account then return the object id otherwise null.
    **/  
    public ID AccountId{
        get{
            return (objectPrefix == accountPrefix) ? ObjectId : null;
        }
    }
    
    /**
    * @description  If the specifed object id represents an account then return the account object otherwise null.
    **/  
    public AccountWrapper AccountObject{
        get{
            if(accObj != null) return accObj;
            accObj = (objectPrefix == accountPrefix) 
            ?  AccountWrapper.QueryAccount(ObjectId)
            : null;
            return accObj;  
        }
    }
    
    /**
    * @description  If the specifed object id represents a contact then return the object id otherwise null.
    **/  
    public ID ContactId{
        get{
            return (objectPrefix == contactPrefix) ? ObjectId : null;
        }
    }
    
    /**
    * @description  If the specifed object id represents a contact then return the contact object otherwise null.
    **/  
    public Contact ContactObject{
        get{
            if(conObj != null) return conObj;
            conObj = (objectPrefix == contactPrefix) 
            ? [SELECT Id,Name,Email,Title,Phone,LastModifiedDate,MobilePhone FROM Contact Where Id=:ObjectId]
            : null;
            return conObj;
        }
    }
    
    /**
    * @description  If the specifed object id represents a lead then return the object id otherwise null.
    **/  
    public ID LeadId{
        get{
            return (objectPrefix == leadPrefix) ? ObjectId : null;
        }
    }
        
    /**
    * @description  If the specifed object id represents a lead then return the lead object otherwise null.
    **/  
    public Lead LeadObject{
        get{
            if(ldObj != null) return ldObj;
            ldObj = (objectPrefix == leadPrefix) 
            ? [SELECT Id,Name,Company, Title, Phone, Email, Status, LastModifiedDate,MobilePhone FROM Lead Where Id =:ObjectId]
            : null;
            return ldObj;
        }
    }
        
    /**
    * @description  If the specifed object id represents a Case then return the object id otherwise null.
    **/  
    public ID CaseId{
        get{
            return (objectPrefix == casePrefix) ? ObjectId : null;
        }
    }
    
    /**
    * @description  If the specifed object id represents a Case then return the Case object otherwise null.
    **/  
    public Case CaseObject{
        get{
            if(caseObj != null) return caseObj;
            caseObj = (objectPrefix == casePrefix) 
            ? [SELECT Id, Account.Phone,Contact.Phone,Contact.MobilePhone FROM Case Where Id=:ObjectId]
            : null;
            return caseObj;
        }
    }
    
     /**
    * @description  If the specifed object id represents an Event then return the object id otherwise null.
    **/  
    public ID EventId{
        get{
            return (objectPrefix == eventPrefix) ? ObjectId : null;
        }
    }
    
    /**
    * @description  If the specifed object id represents an Event then return the Event object otherwise null.
    **/  
    public Event EventObject{
        get{
            if(eventObj != null) return eventObj;
            eventObj = (objectPrefix == eventPrefix) 
            ? [SELECT Id, WhoId,WhatId FROM Event Where Id=:ObjectId]
            : null;
            return eventObj;
        }
    }
    
      /**
    * @description  If the specifed object id represents a Task then return the object id otherwise null.
    **/  
    public ID TaskId{
        get{
            return (objectPrefix == taskPrefix) ? ObjectId : null;
        }
    }
    
    /**
    * @description  If the specifed object id represents a Task then return the Task object otherwise null.
    **/  
    public Task TaskObject{
        get{
            if(taskObj != null) return taskObj;
            taskObj = (objectPrefix == taskPrefix) 
            ? [SELECT Id, WhoId,WhatId FROM Task Where Id=:ObjectId]
            : null;
            return taskObj;
        }
    }

    /**
    * @description  If the specifed object id represents a Case then return the object id otherwise null.
    **/  
    public ID OpportunityId{
        get{
            return (objectPrefix == opportunityPrefix) ? ObjectId : null;
        }
    }
    
    /**
    * @description  If the specifed object id represents a Case then return the Case object otherwise null.
    **/  
    public Opportunity OpportunityObject{
        get{
            if(oppObj != null) return oppObj;
            oppObj = (objectPrefix == opportunityPrefix) 
            ? AccountWrapper.PersonAccountsAvailable ? Database.query('SELECT Id, Account.Id, Account.Phone, Account.PersonMobilePhone FROM Opportunity Where Id= \'' + ObjectId + '\'') 
                : Database.query('SELECT Id, Account.Id, Account.Phone FROM Opportunity Where Id= \'' + ObjectId + '\'')
            : null;
            return oppObj;
        }
    }
    
    
    /**
    * @description  Retrieves the LiveText phone number object.
    **/  
    public LiveText_Number__c LiveTextPhoneNumber{
        get{
            return Util.GetLiveTextNumberObject(LiveTextNumber);
        }
    }
    
    @TestVisible
    private static string getToPhoneNumber(AccountWrapper acct){
    	 return !String.isBlank(acct.MobilePhone) ? acct.MobilePhone : acct.Phone;
    }
    
    @TestVisible
    private static string getToPhoneNumber(Case CaseObject){
   		string phoneNumber = (CaseObject.Contact == null) ? null : getPreferredPhoneNumberFromObject(CaseObject.Contact.Id);
   		if(String.isBlank(phoneNumber)){
   			return (CaseObject.Account == null) ? null : getToPhoneNumber(AccountWrapper.QueryAccount(CaseObject.Account.Id));
    	}
    	return phoneNumber;   
    }

    @TestVisible
    private static string getToPhoneNumber(Opportunity OpportunityObject){
        return (OpportunityObject.Account == null) ? null : getToPhoneNumber(AccountWrapper.QueryAccount(OpportunityObject.Account.Id)); 
    }
    
     /**
    * @description  Sets the "to" phone number based on the type of object triggered this send.
    **/ 
    public void SetPhoneNumberBasedOnObject(){
          
        if(AccountObject != null){
            ToPhoneNumber = getToPhoneNumber(AccountObject);
        }
        else if (CaseObject != null){
       		ToPhoneNumber = getToPhoneNumber(CaseObject);  	
        }
        else if (OpportunityObject != null){
            ToPhoneNumber = getToPhoneNumber(OpportunityObject);
        }
        else if ((EventObject != null && (EventObject.WhoId != null || EventObject.WhatId != null)) ||
        		 (TaskObject != null && (TaskObject.WhoId != null || TaskObject.WhatId != null))){
        	
        	Id whoId  = (EventObject != null) ? EventObject.WhoId : TaskObject.WhoId;
        	Id whatId = (EventObject != null) ? EventObject.WhatId : TaskObject.WhatId;
        	
        	if(whoId != null){ 
        		ToPhoneNumber = getOtherObjectPhoneNumber(whoId);
        	}
        	if(String.isBlank(ToPhoneNumber) && whatId != null){
        		ToPhoneNumber = getOtherObjectPhoneNumber(whatId);
        	}
        	if(String.isBlank(ToPhoneNumber)){
       			ToPhoneNumber = getOtherObjectPhoneNumber(objectId);
        	}
        }    
        else{
            //Calling OtherObjectPhoneNumber method to get phone number from other standard or custom object
            ToPhoneNumber = getOtherObjectPhoneNumber(objectId);
        }
        Boolean startsWithPlus = ToPhoneNumber == null ? false : ToPhoneNumber.startsWith('+');
        ToPhoneNumber = ToPhoneNumber == null ? '' : ToPhoneNumber.replaceAll('\\D', '');  //remove all non-numeric
        if(startsWithPlus){
            ToPhoneNumber = '+' + ToPhoneNumber;
        }else if(Util.IsNorthAmericanPhoneNumber(ToPhoneNumber)){
            if(ToPhoneNumber.startsWith('1')){
                ToPhoneNumber = '+' + ToPhoneNumber;
            }
            else{
                ToPhoneNumber = '+1' + ToPhoneNumber;
            }
        }
        system.debug('in schedule item, SetPhoneNumberBasedOnObject result: ' + ToPhoneNumber);
    }
    
     /**
     * @Description : Fetch the mobilephone/phone field value based on object type
     * @param       : Selected Object id to fetch the mobilephone/phone.
     *
     **/
     @TestVisible
     private static string getOtherObjectPhoneNumber(id selectedObjId){
     	String selectedObjectPrefix =  selectedObjId.getSObjectType().getDescribe().getKeyPrefix();	
		if (selectedObjectPrefix == accountPrefix) {
			return getToPhoneNumber(AccountWrapper.QueryAccount(selectedObjId));
		}
		
		if (selectedObjectPrefix == casePrefix) {
			Case caseObj =  [SELECT Id, Account.Phone,Contact.Phone,Contact.MobilePhone FROM Case Where Id=:selectedObjId];
			return getToPhoneNumber(caseObj);
		}
		   
   		return RetrievePreferredPhoneNumber.getToPhoneNumberFromObject(selectedObjId);
     }//End of Method
     
     @TestVisible
     private static string getPreferredPhoneNumberFromObject(id selectedObjId){
        
        string objName  = selectedObjId.getsObjectType().getDescribe().getName();         
        if(objName != null){
             schema.SObjectType objType = selectedObjId.getSobjectType().getDescribe().getSobjectType(); 
             list<String> fieldList = new list<String>{'id'};   
             
             //Getting all fields from specified object
             map<string, schema.SObjectField> objFieldMap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
             
             //Getting Fields with type phone
             map<string, schema.SObjectField> accessibleObjFieldMap = new  map<string, schema.SObjectField>();
             String phoneField = 'Phone';
             String mobilePhoneField = 'MobilePhone';
             for(String field : objFieldMap.keyset()){
             	schema.SObjectField objField = objFieldMap.get(field);
              	if(objField.getDescribe().isAccessible() && objField.getDescribe().getType() == Schema.displayType.PHONE){
                     fieldList.add(field);
                     accessibleObjFieldMap.put(field, objField);
                     if(field.equalsIgnoreCase(phoneField)) phoneField = field;
                     if(field.equalsIgnoreCase(mobilePhoneField)) mobilePhoneField = field;
             	}
             }  
             
             try{
                 //Constructing string with all fields and seperator as comma
                 string phoneFields= string.join(fieldList,', ');
                                 
                 sObject obj = database.query('select ' +phoneFields + ' From ' + objName + ' where id =\'' + String.escapeSingleQuotes(selectedObjId) + '\'' + 'LIMIT 1');
                 
                 //Checking whether the object is custom or standard and then append __c to the field accordingly
                 if(!Schema.getGlobalDescribe().get(objName).getDescribe().custom){
                 	if(accessibleObjFieldMap.get(mobilePhoneField) != null && !String.IsBlank((String)obj.get(mobilePhoneField))){
            			return (String)obj.get(mobilePhoneField);
                 	}
            		if(accessibleObjFieldMap.get(phoneField) != null && !String.IsBlank((String)obj.get(phoneField))){
            			return (String)obj.get(phoneField);
           			}
                 }  
                 else{           
                 	if(accessibleObjFieldMap.get(mobilePhoneField + '__c') != null && !String.IsBlank((String)obj.get(mobilePhoneField + '__c')))
            			return (String)obj.get(mobilePhoneField + '__c');
            		if(accessibleObjFieldMap.get(phoneField + '__c') != null && !String.IsBlank((String)obj.get(phoneField + '__c')))
            			return (String)obj.get(phoneField + '__c');
                 	
                 }                     
             }catch(Exception e){
                Util.insertException(selectedObjId, constant.priority_high, e.getMessage());

             }  
         }//End of If
         
         return null;
     }
    
 	public Boolean equals(Object obj){
 		
 		if(this.ToPhoneNumber == null) return false;
 		
		if(obj instanceOf ScheduleItem){
				ScheduleItem arObj = (ScheduleItem)obj;
				
				return (this.ToPhoneNumber.equals(arObj.ToPhoneNumber) && LiveTextPhoneNumber == arObj.LiveTextPhoneNumber);
		}
		return false;
	}
		
	//Implementing the equals method also needs hashCode implementation.
	public Integer hashCode(){
		return (ToPhoneNumber == null) ? ('' + LiveTextPhoneNumber).hashCode() : (ToPhoneNumber + LiveTextPhoneNumber).hashCode();
	}

}