/**
 * @author         Ramesh Ale(rale@heywire.com)
 * @date           05.13.2015
 * @description    This is controller class for LivTextOptinStatus Page.
 */
public with sharing class LiveTextOptinStatusController {
	
    public List<Id> recordIds{get;set;}
	
	public String[] ltNumbers = new String[]{};
	
	public Boolean firstPart {get; set;}	// Boolean variable to help display the checkboxes paege block
	
	public Boolean secondPart {get; set;}	// Boolean variable to help display the confirmation page block
	
	public String returnURL{get;set;} 	//It holds the return URL to take back user once clicked on done button
										//and it is used only outside the console.
	
	public String recordType {get;set;}
	
	public String optinTypeString {get;set;}
	
	public Integer optinTypeInt {get;set;}
	
	public String buttonText {get;set;} // variable to display the confirm button for opt-in vs opt-out
	
	private String optTypePresentText {get;set;} // This variable holds the present-tense of opt-in vs opt-out
	
	private String optTypePastText {get;set;} // This variable holds the past-tense of opt-in vs opt-out 
	
	public String labelText {get;set;} //This is for the label text opt-in vs opt-out
	
	public String headerLabel {get;set;} //This variable holds the headerlabel to display opt-in vs opt-out
	
	/**
	 * @description This method converts the optinType parameter string to integer type
	 */
	@TestVisible
	private void convertOptinType(){
		if(optinTypeString.equals('0')){
			optinTypeInt = 0;			
		}else if(optinTypeString.equals('1')){
			optinTypeInt = 1;
		}
	}

	/**
	* @description This function gets all phones from objects for given Ids
	**/
	private List<String> getPhoneNumbersFromRecordIds(){
        List<String> retList = new List<String>();
        if(recordIds.isEmpty())
            return retList;
        Set<String> retSet = new Set<String>();
        String objName = (String) recordIds[0].getSobjectType().getDescribe().getName();
        List<String> phoneFields = Util.getPhoneNumberFilteredFields(objName, '');
        String query = 'SELECT ' + String.join(phoneFields, ',') + ' FROM ' + objName + ' WHERE Id IN :recordIds';
        List<SObject> records = Database.query(query);
        for(SObject record : records){
            for(String field : phoneFields){
                if(!'id'.equals(field)){
                    String phone = (String) record.get(field);
                    if(String.isNotBlank(phone))
                        retSet.add(phone);
                }
            }
        }
        retList.addAll(retSet);
        return retList;
	}
	
	/**
	 * @description This method executes once the user selects the LiveText phone number to opt-in or opt-out
	 */
    public PageReference Confirm() {		
		
		List<String> phoneNumbers = getPhoneNumbersFromRecordIds();
		List<OptInStatus__c> optInObjects = new List<OptInStatus__c>();

		convertOptinType();
		
		if(ltNumbers.size()>0){ // Condition to check if user selected livetext number or not
			for(String ltNumber : ltNumbers){
				for(String subPhone: phoneNumbers){
					OptInStatus__c obj = new OptInStatus__c(LiveTextNumber__c=ltNumber,Status__c=optinTypeInt,SubscriberPhoneNumber__c=Util.NormalizePhoneNumber(subPhone));
					optInObjects.add(obj);
				}
			}
			AccessController.insertAsSystem(optInObjects);
			this.firstPart = false; //disable the displaying of first part
			this.secondPart = true; // time to display the confirmation page block
	    	String messageText = recordIds.size() + ' record(s) have been ' + optTypePastText + ' for text messaging.';
	    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,messageText);
	        ApexPages.addMessage(myMsg);
	    	return null;
		}else{
			this.firstPart = true; // User did not select any live text number but clicked on confirm button so display the first part again.
			this.secondPart = false; 
			//set the error message asking user to select atleast one live text number.
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select at least one phone number.'));
			return null;
		}

    }
    
	/**
	 * Method to take the user back to the original page. This method is used only outside the console app. Inside console, 
	 * we just close the primary tab.
	 */
    public PageReference doneCustom(){
    	PageReference pageRef = new PageReference(returnURL);
		return pageRef;
    }
    
    public void setLtNumbers(String[] ids) {
        this.ltNumbers = ids;
    }    

    public String[] getLtNumbers() {
        return this.ltNumbers;
    }    
    
	/**
	 * Controller to retrieve the url parameters passed and set the necessary label and button text and other variables.
	 */
    public LiveTextOptinStatusController(ApexPages.StandardController stdController) {
    	this.firstPart = true;
    	this.secondPart = false;
    	String tempIds = ApexPages.currentPage().getParameters().get('records');
    	returnURL = ApexPages.currentPage().getParameters().get('retURL');
    	optinTypeString = ApexPages.currentPage().getParameters().get('optType'); // To determine opt-in vs opt-out
    	recordType = ApexPages.currentPage().getParameters().get('recordType');
    	
    	if(optinTypeString.equals('0')){
    		this.buttonText = 'Confirm Opt-out';
			optTypePastText = 'opted-out';
			optTypePresentText = 'opt-out';
			this.labelText = 'The phone number(s) to opt-out';
			this.headerLabel = 'Opt-out for Text Messaging ';
    	}else if(optinTypeString.equals('1')){
    		this.buttonText = 'Confirm Opt-in';
			optTypePastText = 'opted-in';
			optTypePresentText = 'opt-in';
			this.labelText = 'The phone number(s) to opt-in';
			this.headerLabel = 'Opt-in for Text Messaging ';
    	}
    	
    	recordIds= new List<Id>();
    	if(!String.isBlank(tempIds)){
    		recordIds = tempIds.split(',');
    	}
    }
    
	/**
	 * method which is executed for the initial page request before even page is loaded to the client
	 */
    public void init() {
    	String messageText = recordIds.size() + ' record(s) have been selected for '+ optTypePresentText;
    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,messageText);
        ApexPages.addMessage(myMsg);
    }
    
	/**
	 * This method is to retrieve the livetext numbers configured for the user
	 */
	public List<SelectOption> getNumbers() {
		List<SelectOption> options = new List<SelectOption>();
		
		String uid = UserInfo.getUserId(); 
		List<Id> ids = new List<Id>();
		List<Associated_Agents__c> agents = [SELECT LiveText_Number__c FROM Associated_Agents__c WHERE User__c=:uid];
		 		
		for(Associated_Agents__c a : agents){
			ids.add(a.LiveText_Number__c);
		}
		
		List<LiveText_Number__c> phoneNumbers = [SELECT Id, Name, Formatted_Support_Number__c FROM LiveText_Number__c WHERE Id IN :ids];
		for(LiveText_Number__c n : phoneNumbers)		{ 
			options.add(new SelectOption(String.valueOf(n.Id), n.Name));
		}
        return options;
     }
}