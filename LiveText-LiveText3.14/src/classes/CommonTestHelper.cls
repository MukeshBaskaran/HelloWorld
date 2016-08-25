/*
* 
*   CommonTestHelper class provides help methods testing 
*   LiveText for Salesforce application
*
*   Author           |Author-Email                      |Date       |Comment
*   -----------------|----------------------------------|-----------|--------------------------------------------------
*   Santosh Gudge    |santosh@comitydesigns.com         |07.09.2014 |First draft
*
*/
 
public with sharing class CommonTestHelper {
    
    private static Account m_Account = null;  
    private static Contact m_Contact = null;  
    private static Case m_Case = null;  
    private static Lead m_Lead = null;
  
    /**
     * Retrieves the user with 'System Administrator' profile.
     * @return the User object with 'System Administrator' profile.
    */
    public static User GetTestRunAsUser() {    
        Profile p = [Select p.Name, p.Id From Profile p where p.Name =: Constant.system_administrator];
        User u = [select id, name from User where ProfileId = : p.id and IsActive = true][0]; 
        return u;
    }
    
    /** 
     * Comments 
     * Creates a Account.
     * @param Name - Name of Account
     * @return - New Account record that has or has not be saved the the database.
    */ 
    public static Account CreateAccount(String ActName) {
        Account objAccount = new Account();
        objAccount.Name = ActName;
        return objAccount;
    }
    
    /** 
     * Comments 
     *
     * Creates a lead.
     *
     * @param lastName - LastName of Contact
     * @param FirstName - FirstName of Contact
     * @return - New Contact record that has or has not be saved the the database.
    */
    public static Contact CreateContact(String Lastname, String FirstName) {
        Contact objContact = new Contact();
        objContact.Lastname = Lastname;
        objContact.FirstName = FirstName;
        return objContact;
    }
    
    /** 
     * Comments 
     * Creates a lead.
     * @param lastName - LastName of Lead
     * @param company - Company of Lead
     * @param status - Status of Lead
     * @return - New Lead record that has or has not be saved the the database.
    */
    public static Lead CreateLead(String lastName, String company, String status) {
        Lead objLead = new Lead();
        objLead.LastName = lastName;
        objLead.Company = company;
        objLead.Status = status;
        return objLead;
    }
  
    /*
     * Comments 
     * Creates a case.
     * @param status - Status of Case
     * @param origin - Origin of Case
     * @return - New Case record that has or has not be saved the the database.
    */
    public static Case CreateCase(String status, String origin) {
        Case objCase = new Case();
        objCase.Status = status;
        objCase.Origin = origin;
        return objCase;
    }
  
    /**
     * Retrieves the Conversation Header object. 
     *
     * @return the Conversation Header object without insert.
    */
    public static Conversation_Header__c CreateConversationHeader(String OriginatingNumber, String SupportNumber) {
        Conversation_Header__c conversationHeader = new Conversation_Header__c();
        m_Account = CreateAccount(Constant.accountName);
        insert m_Account;
        m_Case = CreateCase(Constant.stage_new,Constant.case_origin);
        insert m_Case;
        m_Lead = CreateLead(Constant.lastName, Constant.companyName, Constant.leadStatus);
        insert m_Lead;
        m_Contact = CreateContact(Constant.lastName, Constant.firstName);
        insert m_Contact;
        conversationHeader.Account__c = m_Account.Id;
        conversationHeader.Case__c = m_Case.Id;
        conversationHeader.Lead__c = m_Lead.Id;
        conversationHeader.Contact__c = m_Contact.Id;
        conversationHeader.Originating_Number__c = OriginatingNumber;
        conversationHeader.Support_Number__c = SupportNumber;
        conversationHeader.Status__c = Constant.stage_new;
        conversationHeader.ConversationType__c = Constant.ConversationType.Inbound.name();
        return conversationHeader;
    } 
    
    /**
     * Retrieves the SMS_Text__c object. 
     * @return the SMS_Text__c object without insert.
    */
    public static SMS_Text__c CreateSMSTextRecord (String OriginatingNumber, String SupportNumber, String conversationHeaderId) {
        SMS_Text__c SMSText = new SMS_Text__c();
        if (conversationHeaderId != null) {
            SMSText.Conversation_Header__c = conversationHeaderId;
        }
        SMSText.Originating_Number__c = OriginatingNumber;
        SMSText.Support_Number__c = SupportNumber;
        SMSText.Source__c = Constant.live_text;
        return SMSText;
    }
}