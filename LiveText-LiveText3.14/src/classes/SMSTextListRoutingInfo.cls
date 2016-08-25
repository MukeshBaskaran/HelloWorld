public with sharing class SMSTextListRoutingInfo {

	private Map<Id, Boolean> smsToIsItrEnabledMap = new Map<Id, Boolean>();
	private Map<Id, Boolean> smsToIsOkToRouteMap = new Map<Id, Boolean>();
		 
	public SMSTextListRoutingInfo(List<SMS_Text__c> smsList){
	  	if(smsList != null && smsList.size() > 0){
         	smsToIsItrEnabledMap = Util.isITREnabled(smsList);
	     	for(SMS_Text__c sms : smsList){
	        	Boolean itrEnabled = smsToIsItrEnabledMap.get(sms.Id);
	        	Boolean okToRoute = false;
	          	if(!itrEnabled){
	          		okToRoute = true;
	          	} 
	         	smsToIsOkToRouteMap.put(sms.Id, okToRoute);
	     	}
    	} 	
	 }	
	 
	 public Boolean isItrEnabled(SMS_Text__c sms){
	 	return smsToIsItrEnabledMap.get(sms.Id);
	 }
	 
	 public Boolean isOkToRoute(SMS_Text__c sms){
	 	return smsToIsOkToRouteMap.get(sms.Id);
	 }
}