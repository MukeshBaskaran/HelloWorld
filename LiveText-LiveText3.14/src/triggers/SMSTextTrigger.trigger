trigger SMSTextTrigger on SMS_Text__c (after insert, after update, before insert, before update) {
	TriggerManager.invoke(SMSTextTriggerHandler.class);
}