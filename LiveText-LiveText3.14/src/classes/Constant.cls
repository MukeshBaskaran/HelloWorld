/**
* @author         Santosh Gudge(santosh@comitydesigns.com)
* @date           07.03.2014
* @description    Constant class contains global static variables used by the apex classes
*                 in LiveText for Salesforce application
*/
public class Constant {
    //End point URL for making API calls to Heywire
    public static final String HEYWIRE_PRODUCTION_URL = 'https://app.hwlivetext.com/';
    public static final String HEYWIRE_EU_PRODUCTION_URL = 'https://euapp.hwlivetext.com/';
    public static final String HEYWIRE_SANDBOX_URL = 'https://livetext.dev.mediafriendsinc.com/';
    public static final String HEYWIRE_DEV_URL = 'https://livetext.dev.mediafriendsinc.com/';
    
    // URL for directing user to oAUTH flow on Heywire side
    public static final String HEYWIRE_PRODUCTION_OAUTH_URL = 'https://app.hwlivetext.com/oauth';
    public static final String HEYWIRE_EU_PRODUCTION_OAUTH_URL = 'https://euapp.hwlivetext.com/oauth';
    public static final String HEYWIRE_SANDBOX_OAUTH_URL = 'https://livetext.dev.mediafriendsinc.com/oauth_sandbox';
        
    public static final String HEYWIRE_CONFIG = UserInfo.getOrganizationId();
    public static final String HEYWIRE_STATUS = 'OAuth Established';
    public static final List<String> LT_PERMISSION_SETS = new List<String>{'LiveText_Admin', 'LiveText_Manager', 'LiveText_Agent'};
    
    public static final String LIVE_TEXT_NUMBER_SOBJECT_NAME = Util.getObjectName('LiveText_Number__c');
    public static final String ASSOCIATED_AGENTS_SOBJECT_NAME = Util.getObjectName('Associated_Agents__c');
    public static final String CONVERSATION_HEADER_SOBJECT_NAME = Util.getObjectName('Conversation_Header__c');
    
    public static final Integer ALLOWED_GREETING_MSG_LENGTH_LIMIT = 160;
    
    public static final String HEYWIRE_API = 'api/4.4';
    public static final String HEYWIRE_API_GET_PHONE_NUMBER = HEYWIRE_API + '/phonenumber/';
    public static final String HEYWIRE_API_SEND_SMS = HEYWIRE_API + '/account/{0}/message';
    public static final String HEYWIRE_API_LOOKUP_ACCOUNT = HEYWIRE_API + '/account/{0}';
    public static final String HEYWIRE_API_SEND_PICTURE_REQUEST = HEYWIRE_API + '/account/{0}/message/attachmentReplyUrl';
    
    public static final String ACCOUNT_OBJECT = 'Account';
    public static final String CASE_OBJECT = 'Case';
    public static final String CONTACT_OBJECT = 'Contact';
    public static final String LEAD_OBJECT = 'Lead';
    public static final String OPPORTUNITY_OBJECT = 'Opportunity';  
    public static final String TASK_OBJECT = 'Task';
    public static final String EVENT_OBJECT = 'Event';
    public static final String USER_OBJECT = 'User';
    public static final String CONTRACT_OBJECT = 'Contract';  
    public static final String ORDER_OBJECT = 'Order';  

    public static final String REGEX_VALID_PHONE_NO = '^[0-9-()+ ]*$';
    public static final String REGEX_REMOVE_UNWANTED_CH = '[^0-9]';
  
    
    public static final Map<String, String> PROFILE_NAMES = new Map<String, String>{'Agent Profile'=>'LiveText Agent', 
                                  'Manager Profile'=>'LiveText Manager', 
                                  'Admin Profile'=>'LiveText Admin'};
    
    public enum ConversationType {Inbound, Outbound, Multiple}
    
    /*Trigger Flags to Avoid recursive running of triggers*/
    public static Boolean on_after_insert_smstext_trg = true; 
    public static Boolean on_before_insert_smstext_trg = true;
 
    public static Boolean on_after_insert_conversationheader_trg = true;
    public static Boolean on_after_update_conversationheader_trg = true;
    public static Boolean on_before_insert_conversationheader_trg = true;
 
    /*Custom Object API Name without Namespace*/
    public static String sms_text_obj = 'SMS_Text__c';
    public static String conversation_header_obj = 'Conversation_Header__c';
  
    /*Exception__c object constants*/
    public static String after_insert = 'After Insert';
    public static String before_insert = 'Before Insert';
    public static final String PRIORITY_HIGH = 'High';
    public static final String PRIORITY_LOW = 'Low';
  
    /*Conversation_Header__c object constants*/
    public static String stage_new = 'New';
    public static String stage_active = 'Active';
    public static String stage_ended = 'Ended';
    public static String stage_offline = 'Offline';
    public static String rec_Id = 'Id'; 
    public static String support_number = 'Support_Number__c';
    public static String stage ='Stage__c';
    public static String originating_number = 'Originating_Number__c';
    public static String conversation_header_push_topic = 'NewConversationHeader';
    public static String conversation_header_push_topic_Test = 'NewConversationHeaderTest';
    public static String sms_text_push_topic = 'NewSMSText';
    public static String sms_text_push_topic_Test = 'NewSMSTextTest';
 
     
    /*SMS_Text constants*/
    public static String source_field = 'Source__c';    
           
    /*LiveText_Number__c Constant*/
    public static String initial_Message = 'Initial_Message__c';
    public static String offline_Hours_Message = 'Offline_Hours_Message__c';
    public static String chat_End_Message = 'Chat_End_Message__c';
    public static String liveText_Number = 'LiveText_Number__c';
    
    /* pickList Constant*/
    public static String status_avaialble = 'Available';
    public static String status_offline = 'Offline';
    public static String status_away = 'Away';
    
    /*SMS text source */
    public static String itr  = 'ITR';   
    public static String live_text = 'LiveText';
    public static String salesforce = 'Salesforce';
    public static String permission_marketing = 'PermissionMarketing';
    public static String salesforce_linking = 'Salesforce Linking';
    public static String salesforce_welcome = 'Salesforce Welcome';
    public static String salesforce_goodbye = 'Salesforce Goodbye';
    public static String salesforce_offline = 'Salesforce Offline';
    public static String salesforce_auto_response = 'Salesforce Auto Response';         
    
   
    /*Case constants*/
    public static String case_origin = 'Web';
    
    /*class constants*/
    public static String cls_TriggerManager = 'TriggerManager';
   
    /*profile constants*/
    public static final String system_administrator = 'System Administrator';
      
    /*Test Class data constants*/
    public static final String firstName = 'Mark';
    public static final String lastName = 'Anderson';
    public static final String companyName = 'AppInc';
    public static final String leadStatus = 'Open - Not Contacted';
    public static final String accountName = 'Aircell';
    public static final String OriginatingNumber = '1-888-835-5311';
    public static final String SupportNumber = '1-888-835-5399';
  
    /*Enum constants for Access Controller*/
    public static final String op_insert = 'OP_INSERT';
    public static final String op_update = 'OP_UPDATE';
    public static final String op_delete = 'OP_DELETE';
    public static final String op_upsert = 'OP_UPSERT';
  
    /* Semaphores */
    public static final String SEMAPHORE_SMS_TEXT_TRIGGER_HANDLER = 'SMSTextTrigger';
    public static final String SEMAPHORE_INBOUND_PHONE_FORMAT = 'InboundPhoneFormat';

    /* Set of excluded objects from Util.getCustomObjectsRelationships and ConversationDetailController.retrieveAndAssociateOriginatingObjectLinkedRecords; lowerCase only*/
    public static final Set<String> excludeObjectTypes = new Set<String>{'user', 'group', 'businesshours', 'recordtype', Util.namespace.toLowerCase() + 'livetext_number__c', Util.namespace.toLowerCase() +'conversation_header__c'};
  
}