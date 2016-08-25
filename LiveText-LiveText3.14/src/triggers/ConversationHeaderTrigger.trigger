trigger ConversationHeaderTrigger on Conversation_Header__c (after insert, after update, before insert, 
before update) {
	TriggerManager.invoke(ConversationHeaderTriggerHandler.class);
}