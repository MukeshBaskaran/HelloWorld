/**
 * @author         Santosh Gudge(santosh@comitydesigns.com)
 * @data           07.03.2014
 * @description    ConsoleIntegrationController class contains methods used by the ConsoleIntegrationPage
 *                 in LiveText for Salesforce application.
*/
global with sharing class ConsoleIntegrationController { 

    private final Conversation_Header__c conversationHeader;
    /*property to store objct prefix*/
    @TestVisible
    private String keyPrefix { get; set; }
    public String formattedOriginatingNumber{ get; set; }
    public String openPrimaryTabName { get; set; }
    /*Integer used to show user the total Live Text Records*/
    public integer totalSize { get; set; }
    /*property to store conversationHeaderId*/
    public String conversationHeaderId { get; set; }
    /*string returns package namespace*/
    public String nameSpace {
        get {
            return util.getNamespace();
        }
        set;
    }
    /*string returns initial auto response message*/
    public String autoResponseMessage { get; set; }
    /*string returns conversation Header List*/
    public String currentConversationHeader {
        get {
            return JSON.serialize(conversationHeaderList);
        }
        set;
    }
    /*string returns keyPrefix*/
    public String conversationSessionPrefix {
        get {
            return getConversationSessionPrefix();
        }
    }
    /*list to hold current ConversationHeader*/
    public List < Conversation_Header__c > conversationHeaderList { get; set; }      
    public String status {
        get {
            if(String.isBlank(status)) {
                status = getCurrentUserStatus();
            }
            return status;
        }
        set;
    }

    /**
        * @description:  List of my phone numbers
        * @return status options.
    */
    public String MyPhoneNumbers {
        get {
           return JSON.serialize(phoneNumbers);
        }
        set;
    }    

    public String getUserLocale(){
        return UserInfo.getLocale();
    }  

    public Integer getSessionRefreshTimeInMiliseconds() {
      AuthSession session = [   SELECT NumSecondsValid 
                                FROM AuthSession 
                                WHERE UsersId=:UserInfo.getUserId() 
                                AND SessionType = 'Visualforce' LIMIT 1
                            ];
      return (Integer) (session.NumSecondsValid/3)*1000;
    }
    
    /* Map of phone number labels to phone numbers */
    public List<LiveText_Number__c> phoneNumbers;
    public String LeadSource{get;set;}

    public Boolean disconnectSound { get; set; }

    /*Constructor*/
    public ConsoleIntegrationController(ApexPages.StandardController stdController) {
        this.conversationHeader = (Conversation_Header__c) stdController.getRecord();
        getConversationHeaderList();  
        phoneNumbers = Util.GetMyPhoneNumbers();
        this.LeadSource = '';
        Set<String> pickValSet = new Set<String>();      
        for(Schema.picklistEntry entry : Lead.LeadSource.getDescribe().getPicklistValues()) {
            pickValSet.add(String.valueOf(entry.getValue()));
        }
        if(!pickValSet.isEmpty()) {
            LeadSource = pickValSet.contains(Label.Text_Session_Label) ? Label.Text_Session_Label
                             : pickValSet.contains(Label.Other_Label) ? Label.Other_Label : '';
        }

        List<ConfigurationSettings__c> conf = new List<ConfigurationSettings__c>();
        conf = [    SELECT Id,Disconnect_Sound_Enabled__c
                    FROM ConfigurationSettings__c LIMIT 1
                ];
        this.disconnectSound = conf.size() > 0 ? conf[0].Disconnect_Sound_Enabled__c : true;

    }
    
    @RemoteAction
    public static List<String> getCustomLogo( String onLineLogo, String offLineLogo) {   
        List<String> logoUrls = new List<String>();
        logoUrls.add(Util.GetResourceURL(onLineLogo));
        logoUrls.add(Util.GetResourceURL(offLineLogo));
        return logoUrls;
    }

    @RemoteAction
    public static Boolean checkTshPrefixListView(String url){
        if(String.isBlank(url)){
            return false;
        }else{
            String urlPrefix = '/' +Schema.getGlobalDescribe().get(Util.namespace + 'Conversation_Header__c').getDescribe().getKeyPrefix();
            return url.startsWith(urlPrefix);
        }
    }

    /**
     * @description: SelectOption for Livetext status
     * @return status options.
     */
    public List < SelectOption > getItems() {
        List < SelectOption > options = new List < SelectOption > ();
        options.add(new SelectOption(constant.status_avaialble, constant.status_avaialble));
        options.add(new SelectOption(constant.status_offline, constant.status_offline));
        return options;
    }
    
    /**
     * @description: assigns conversationHeader records to currentConversationHeader
     * @return  List of Conversation Header
     */
    public PageReference getConversationHeaderRecords() {
        List < Conversation_Header__c > chList = getConversationHeaderList();
        this.currentConversationHeader = JSON.serialize(conversationHeaderList);
        return null;
    }

    /**
     * @description: gets list of Conversation Header
     * @return  List of Conversation Header
     */
    public List < Conversation_Header__c > getConversationHeaderList() {
        this.totalSize = 0;
        this.conversationHeaderList = [SELECT Transcript_Summary_1__c, Transcript_Summary_2__c, Support_Number__c, TimeDifference__c, 
                                        Status__c, OwnerId, Originating_Number__c, Lead__c, ElapsedTime__c,SessionReopenedTime__c, Conversation_Identifier__c, 
                                        Contact__c, Case__c, Formatted_Originating_Number__c, LiveText_Number__c, CreatedDate,
                                        Account__c, Opportunity__c, ConversationType__c From Conversation_Header__c WHERE Status__c = : Constant.stage_new Order By CreatedDate ASC];

        if (conversationHeaderList.size() > 0) {
            totalSize = conversationHeaderList.size();
        }
        return conversationHeaderList;
    }  
    
   @RemoteAction
    public static ConversationInfo AcceptRemote (String conversationHeaderId) {
        try {
            if (conversationHeaderId != null && conversationHeaderId.length() != 0) {
                List<Conversation_Header__c> chReadable =  Util.getCurrentConversationHeaderList(conversationHeaderId);
                List<Conversation_Header__c> chList =  Util.getCurrentConversationHeaderListForUpdate(conversationHeaderId);
                if (!chList.isEmpty()) {
                    Conversation_Header__c c = chList.get(0);
                    if(c.Status__c == Constant.stage_new) { 
                        c.Status__c = Constant.stage_active;
                        c.isAccepted__c = True;
                        c.AcceptedBy__c = UserInfo.getUserId();
                        AccessController.updateAsUser(new List<sObject>{c});                             
                    }
                    chList =  Util.getCurrentConversationHeaderList(conversationHeaderId);
                    return new ConversationInfo(chReadable[0], c);
                }
            }
        } 
        catch (Exception ex) {
            Util.addMessageOnError(ex.getMessage());
            Util.insertException(constant.conversation_header_obj, constant.priority_high, ex.getMessage());
        }
        return null;
    }    


    
    @RemoteAction
    global static String getPhoneNumberAccounts(String phoneNumber) {
        // deprecated  
        return null; 
    }
    
    
    @RemoteAction
    global static String getPhoneNumberContacts(String phoneNumber) {
        // deprecated  
        return null;    
    }
 
  
    @RemoteAction
    global static String getPhoneNumberLeads(String phoneNumber) {
        // deprecated  
        return null; 
    }
    
    @RemoteAction
    global static Boolean isConversationHeaderActive(String conversationRecordId) {
        // deprecated
        return false;
     }
     
     @RemoteAction
     public static Id isNewConversationHeader(String conversationRecordId){
        try{
            Id convertedConversationHeaderID = conversationRecordId;
            List <Conversation_Header__c> chList = [Select Id FROM Conversation_Header__c 
                                                    WHERE Id = : conversationRecordId 
                                                    AND Status__c =: Constant.stage_new];
            if(!chList.isEmpty()){
                return convertedConversationHeaderID;
            }
        }
        catch(Exception ex){
        }
        return null;
     }
          
     @RemoteAction
     public static AcceptedConversationInfo GetRelatedObjectsAndAutoLink(Conversation_Header__c mainObject, String phoneNumber, List<SObjectWrapper> records){
        List<LiveText_Number__c> ltnList = [SELECT Id, New_Custom_Objects_Tabs__c, Screen_Pop_Default_Record_Type__c FROM LiveText_Number__c WHERE Id = : mainObject.Support_Number__c];
        if(ltnList.size() == 0) 
            return null;
        LiveText_Number__c ltn = ltnList.get(0);
        AcceptedConversationInfo aci = new AcceptedConversationInfo(ltn);       
        PhoneNumberRelatedObjects objs = new PhoneNumberRelatedObjects(mainObject ,ltn.Id, phoneNumber, records);
        if(!mainObject.ConversationReopened__c)
            objs.AutoLink(mainObject);
        objs.setOnlySelectedRecords();
        aci.RelatedObjects = JSON.serialize(objs);      
        return aci;
     }
        
    /**
     *  @description Get's total LiveText Record size.
     *  @return Null.
    */
    public void getLiveTextRecordSize() {
        this.totalSize = 0;
        Integer listSize = [SELECT count() FROM Conversation_Header__c WHERE Status__c = : constant.stage_new];
        if(listSize > 0) {
            this.totalSize = listSize;
        }
    }

        
    /**
     * @description: Updates the currently logged in Agent's status to Offline/Available. If Agent Status object does not exists,
     *               then creates the new Agent Status object.
    */
    public PageReference updateAgentStatus() {
        try {
            if(String.isNotBlank(this.status)) {
                List<Agent_Status__c> agentStatus = [
                                                        SELECT Id, Status__c 
                                                        FROM Agent_Status__c 
                                                        WHERE User__c=:UserInfo.getUserId()
                                                    ];
                if(agentStatus.isEmpty()) {
                    Agent_Status__c newAgentStatus = new Agent_Status__c(); 
                    newAgentStatus.User__c = UserInfo.getUserId();
                    newAgentStatus.Status__c = this.status;
                    AccessController.insertAsUser(newAgentStatus);
                } else {
                    agentStatus.get(0).Status__c = this.status;
                    AccessController.updateAsUser(agentStatus);
                }
            }
        }
        catch(Exception ex) {
            Util.insertException('updateAgentStatus', Constant.PRIORITY_HIGH, ex.getMessage());
        }
        return null;
    }
     
    /*
     * Get SMS Text messages associated to the conversation header
    */
    @RemoteAction
    global static List<SMS_Text__c> getSMSMessages(String conversationHeaderId) {
        Set<Id> conversationHeaders = new Set<Id> {conversationHeaderId};
        List<SMS_Text__c> smsList = [   SELECT id, Conversation_Header__c, Message__c 
                                        FROM SMS_Text__c 
                                        WHERE Conversation_Header__c IN:conversationHeaders 
                                        AND Source__c !=:Constant.salesforce_auto_response AND Source__c !=:Constant.salesforce AND Source__c !=:Constant.salesforce_linking 
                                        ORDER BY CreatedDate DESC LIMIT 1
                                    ];
        return smsList;
    }
     
    /**
     * @description: Checks if new chat request is routed to current user or not. Finds the Associated Agent object
     *               for the given LiveText number and current user in context.
     * @param: liveTextNumberId, LiveText Number Id.
     * @return true, if new chat request is routed to current user.
    */
    @RemoteAction
    global static Boolean isRoutedToCurrentUser(String liveTextNumberId) {
        Boolean routedToCurrentUser = false;
        if(String.isNotBlank(liveTextNumberId)) {
            List<Associated_Agents__c> associatedAgents =   [   SELECT Id 
                                                                FROM Associated_Agents__c 
                                                                WHERE LiveText_Number__c=:liveTextNumberId 
                                                                AND User__c=:UserInfo.getUserId()
                                                            ];
            if(!associatedAgents.isEmpty()) {
                routedToCurrentUser = true;
            }
        }
        return routedToCurrentUser;
    }

    /**
     * @description: Checks if new chat request is routed to current user or not and also checks if there is any active conversation between given orginating number and support number .
     * Finds the Associated Agent object for the given LiveText number and current user in context .
     * @param: orginatingNumber,supportNumberId
     * @return true, if new chat request is routed to current user.
    */
    @RemoteAction
    public static Boolean isConversationRoutedToCurrentUser(String orginatingNumber,String supportNumberId) {
        Boolean routedToCurrentUser = false;
        List<Conversation_Header__c>  chHeaderStatusActiveList = new List<Conversation_Header__c>();
        List<String> pnoVariations = Util.getPhoneNumberVariations(orginatingNumber);
        chHeaderStatusActiveList = [    SELECT Id 
                                        FROM Conversation_Header__c
                                        WHERE Status__c =: Constant.stage_active AND Originating_Number__c 
                                        IN :pnoVariations AND Support_Number__c =: supportNumberId
                                    ];
        if(String.isNotBlank(supportNumberId)){
            List<Associated_Agents__c> associatedAgents =   [   SELECT Id 
                                                                FROM Associated_Agents__c 
                                                                WHERE LiveText_Number__c=:supportNumberId 
                                                                AND User__c=:UserInfo.getUserId()
                                                            ];
            if(!associatedAgents.isEmpty() && chHeaderStatusActiveList.isEmpty()) {
                routedToCurrentUser = true;
            }
        }
        return routedToCurrentUser;
    }

    @RemoteAction
    public static Boolean setInternationalFormattedPhone(String conversationId, String formattedOriginatingNumber){
        if(String.isBlank(conversationId))
            return false;
        Semaphore sem = new Semaphore(constant.SEMAPHORE_INBOUND_PHONE_FORMAT);
        if(sem.Acquire()){
            List<Conversation_Header__c> tsh = [SELECT Formatted_Originating_Number_To_Display__c
                                            FROM Conversation_Header__c 
                                            WHERE Id = :conversationId];
            if(tsh == null || tsh.isEmpty())
            {
            	sem.Release();
                return false;
            }
            tsh[0].Formatted_Originating_Number_To_Display__c = formattedOriginatingNumber;
            AccessController.updateAsSystem(tsh);
            
            sem.Release();
            return true;
           
        }
        return false;
    }


    @RemoteAction
    public static  void dummyRemoteAction() {
        Boolean isDeleteRequired = false;
        List<LiveTextGlobalSettings__c> dummySetting = [SELECT id FROM LiveTextGlobalSettings__c];
        if(dummySetting.isEmpty()) {
            dummySetting.add(new LiveTextGlobalSettings__c());
            isDeleteRequired = true;
        }
        try {
            if (isDeleteRequired) {
                insert dummySetting;
                delete dummySetting;
            } else {
                update dummySetting;
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
     
    @TestVisible
    private String getCurrentUserStatus() {
        String status = null;
        List<Agent_Status__c> agentStatus   =   [   SELECT Id, Status__c, LastModifiedDate 
                                                    FROM Agent_Status__c 
                                                    WHERE User__c=:UserInfo.getUserId()
                                                ];
        if(!agentStatus.isEmpty()){
            List<User> userList =   [   SELECT Id, LastLoginDate 
                                        FROM User 
                                        WHERE Id=:UserInfo.getUserId() ];
            if(!userList.isEmpty() && userList.get(0).LastLoginDate < agentStatus.get(0).LastModifiedDate) {
                status = agentStatus.get(0).Status__c;
            } else {
                status = Constant.STATUS_OFFLINE;
                agentStatus.get(0).Status__c = Constant.STATUS_OFFLINE;
                AccessController.upsertAsUser(agentStatus);
            }
        } else {
            status = Constant.STATUS_OFFLINE;
        }
        return status;
    }

    /**
     * @description: returns custom url by getting object prefix
     * @return  custom partial url for Conversation Session
    */
    @TestVisible
    private String getConversationSessionPrefix() {
        Schema.DescribeSObjectResult DescribeObjectResult = Conversation_Session__c.sObjectType.getDescribe();
        keyPrefix = buildUrl(String.valueOf(DescribeObjectResult.getKeyPrefix()).subString(0, 3));
        return keyPrefix;
    }

    /**
     * @description: returns custom format url for object prefix passed
     * @param object prefix
     * @return  custom partial url (/a05/e?retURL=/a05/o format)
    */
     @TestVisible
    private String buildUrl(String Prefix) {
        String url = '/' + Prefix + '/e?';
        return url;
    }
    
    /**
     * @description: Action method for End Text Session button on the page. Performs below operation for end chat,
     *               1. Retrieves the initial message for the conversation header.
     *               2. Makes API callout to send the initial message to customer.
     *               3. Inserts the initial message to the database.
     *               4. Creates the transcript and set it to Text session header.
     *               5. Delete all the SMSes associated to Text session.
     *               6. Updates the status of Text session header to Ended.
     * @returns PageReference object.
    */ 
     @RemoteAction
     global static void endChat(String conversationRecordId) {      
        List<Conversation_Header__c> chl = [    SELECT Id 
                                                FROM Conversation_Header__c 
                                                WHERE Id=:conversationRecordId 
                                            ];
        if(!chl.isEmpty()){   
            Util.endChat(conversationRecordId);
        }
    }
    
    @RemoteAction
    global static string findLeadSourceVal() {
        String leadSource; 
        set<String> pickValSet = new set<String>();
        for(Schema.picklistEntry entry : Lead.LeadSource.getDescribe().getPicklistValues()) {
            pickValSet.add(String.valueOf(entry.getValue()));
        }
        if(!pickValSet.isEmpty()) {
            LeadSource =    pickValSet.contains(Label.Text_Session_Label) ? Label.Text_Session_Label
                            : pickValSet.contains(Label.Other_Label) ? Label.Other_Label : '';
        }
        return leadSource;     
    }
 }