public with sharing class ConversationInfo {
    public Conversation_Header__c ReadableConversation;
    public Conversation_Header__c WriteableConversation;
    
    public ConversationInfo(Conversation_Header__c readableConvo, Conversation_Header__c writeableConvo) {
        this.ReadableConversation = readableConvo;
        this.WriteableConversation = writeableConvo;
    }
}