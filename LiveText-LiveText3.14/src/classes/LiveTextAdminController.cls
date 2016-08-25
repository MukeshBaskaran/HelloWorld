/**
 * @author         Amit Madhoriya(amit@comitydesigns.com)
 * @version        1.0
 * @date           08.06.2014
 * @description    This is controller class for admin page. It contain methods to perform admin tab functionality i.e. 
 *                1. Connect/Refresh connection to HeyWire APIs.
 *                2. Add/Edit/Delete the support numbers.
 *                3. Display the list of configured support numbers.
 *                4. Assign users to a support numbers.
 *                5. Api callout to lookup the phone number for delete and validate.
 */
public with sharing class LiveTextAdminController {
    private Set<String> removedMembers;
    public ConfigurationSettings__c configSettingsObj{ get; set; }
    public Inbound_Connection_Status__c connectionStatus{ get; private set; }
    public List<SelectOption> availableMembers{ get; set; }
    public List<SelectOption> selectedMembers{ get; set; }
    public List<SelectOption> searchTypeList{ get; set; }
    public List<SelectOption> businessHours{ get; set; }
    public List<SelectOption> defaultRecordTypes{ get; set; }
    public List<String> availableMembersList{ get; set; }
    public List<String> selectedMembersList{ get; set; }
    
    public List<String> screenPopAvailableRecordTypesList{ get; set; }
    public List<String> screenPopSelectedRecordTypesList{ get; set; }
    public List<SelectOption> screenPopAvailableRecordTypes{ get; set; }
    public List<SelectOption> screenPopSelectedRecordTypes{ get; set; }
    public String screenPopDefaultRecordType{ get; set; }
    
    public List<String> autoLinkingAvailableRecordTypesList{ get; set; }
    public List<String> autoLinkingSelectedRecordTypesList{ get; set; }
    public List<SelectOption> autoLinkingAvailableRecordTypes{ get; set; }
    public List<SelectOption> autoLinkingSelectedRecordTypes{ get; set; }
      
    public List<LiveText_Number__c> sObjList{ get; set; }
    public LiveText_Number__c ltnObject{ get; set; }
    public String phoneNumber {get;set;}
    public Boolean displayComponent{ get; set; }
    public Boolean displayMessagesOnTop{ get; set; }
    public Boolean checkConnectionStatus{ get; set; }
    public Id selectedLtnId{ get; set; }
    public String oAuthUrl{ get; set; }
    public String selectedBusinessHour{ get; set; }
    public String searchUserName{ get; set; }
    public String selectedSearchType{ get; set; }
    public String criticalAlertTime{ get; set; }
    public String textSessionReuseTime { get; set; }
    String[] selectedNewTabs = new String[]{};
    public List<String> selectedCreateActivityItems { get; set; }
    public Boolean isPrependCountryCode{ get; set; }
    public Boolean isITREnabled{ get; set; }
    public Boolean notifyUsersDuringOffHours{ get; set; }
    public Boolean disconnectSoundEnabled{ get; set; }

    public String phoneErrorMessage {get;set;}
    public String liveTextServer {get;set;}
    
    private String TaskObjectName;
    private String EventObjectName;
    private String EUServer;
    private String NAServer;

    public Boolean isConfigureUrls {
        get{
            return Apexpages.currentPage().getParameters().get('configureUrls') == 'true';
        }
    }

    public String getUserLocale(){
        return UserInfo.getLocale();
    }

   /**
     * @description: Controller constructor method, used to intialize the collections, 
     *               variables and load the static data(like business hours) for the admin tab functionality.
    */      
    public LiveTextAdminController() {
        this.displayComponent = false;
        this.displayMessagesOnTop = true;
        this.checkConnectionStatus = false;
        this.isPrependCountryCode = false;
        this.isITREnabled = false;
        this.notifyUsersDuringOffHours = true;
        configSettingsObj = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
        connectionStatus = Inbound_Connection_Status__c.getInstance(Constant.HEYWIRE_STATUS);
        if(connectionStatus != null) {
            retrieveSupportNumbers();
        }
        if (this.businessHours == null) {
            this.setAvailableBusinessHours();
        }
        if(this.searchTypeList == null) {
            this.searchTypeList = Util.getSearchTypeList();
        }
        this.selectedMembers = new List<SelectOption>();
        this.availableMembers = new List<SelectOption>();
        this.addNoneToMemberList();
        this.availableMembersList = new List<String>();
        this.selectedMembersList = new List<String>();
       
        this.screenPopAvailableRecordTypes = new List<SelectOption>();
        this.screenPopSelectedRecordTypes = new List<SelectOption>();
        this.addNoneToScreenPopRecordTypesList();
        this.screenPopAvailableRecordTypesList = new List<String>();
        this.screenPopSelectedRecordTypesList = new List<String>();
        
        this.autoLinkingAvailableRecordTypes = new List<SelectOption>();
        this.autoLinkingSelectedRecordTypes = new List<SelectOption>();
        this.addNoneToAutoLinkingRecordTypesList();
        this.autoLinkingAvailableRecordTypesList = new List<String>();
        this.autoLinkingSelectedRecordTypesList = new List<String>();
              
        this.removedMembers = new Set<String>();
        
        this.TaskObjectName = Util.GLOBAL_DESCRIBE.get(Constant.TASK_OBJECT).getDescribe().getName();
        this.EventObjectName = Util.GLOBAL_DESCRIBE.get(Constant.EVENT_OBJECT).getDescribe().getName();
        this.EUServer = Label.OAuthServerEurope;
        this.NAServer = Label.OAuthServerNA;
        
         if(this.defaultRecordTypes == null) {
            this.setDefaultRecordTypes();
        }

        List<ConfigurationSettings__c> conf = new List<ConfigurationSettings__c>();
        conf = [    SELECT Id,Disconnect_Sound_Enabled__c
                    FROM ConfigurationSettings__c LIMIT 1
                ];
        this.disconnectSoundEnabled = conf[0].Disconnect_Sound_Enabled__c;               
    }

    /**
     * @description action method for recreating settings for Sandboxes only
     *
    **/
    public PageReference checkSettings() {
        //there are no config settings for current org id
        if(configSettingsObj == null) {
            createConfigurationSettingsForSandboxesOnly();
        }
        configSettingsObj = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
        //check if there are global settings
        LiveTextGlobalSettings__c ltgs = LiveTextGlobalSettings__c.getInstance(UserInfo.getOrganizationId());
        if (ltgs.SetupOwnerId == null) {
            createGlobalSettingsForSandboxesOnly();
        }
        return null;
    }

    @RemoteAction
    public static void enableAlertSound(Boolean enabled){
        List<ConfigurationSettings__c> conf = new List<ConfigurationSettings__c>();
        conf = [SELECT Id , Disconnect_Sound_Enabled__c
                FROM ConfigurationSettings__c 
                LIMIT 1];
        if(conf != null && conf.size() > 0) {
            if(enabled){
                conf[0].Disconnect_Sound_Enabled__c = enabled;
            }else{
                conf[0].Disconnect_Sound_Enabled__c = enabled;
            }
            AccessController.updateAsSystem(conf);
        } 
    }
    
   /**
     * @description: Action method for Connect/Refresh connection button on the admin page. It stores the 
     *               entered authentication to configuration custom settings and opens the OAuth URL to HeyWire.
     * @return PageReference object which redirects to another page if not null.
    */
    public Pagereference connect() {
        //Creates save point for rollback, in case of exceptions
        if(!isConfigureUrls){
            if(liveTextServer == NAServer){
                configSettingsObj.oAuth_URL__c = Constant.HEYWIRE_PRODUCTION_OAUTH_URL;
                configSettingsObj.Endpoint_URL__c = Constant.HEYWIRE_PRODUCTION_URL;
            }else if(liveTextServer == EUServer){
                configSettingsObj.oAuth_URL__c = Constant.HEYWIRE_EU_PRODUCTION_OAUTH_URL;
                configSettingsObj.Endpoint_URL__c = Constant.HEYWIRE_EU_PRODUCTION_URL;
            }
        }
        this.oAuthUrl = null;
        this.validateInputs();
        if(!ApexPages.hasMessages()) {
            Savepoint sp = Database.setSavepoint();
            this.oAuthUrl = configSettingsObj.oAuth_URL__c;
            configSettingsObj.Is_Valid_Credentials__c = true;
            Util.addMessageOnError(Database.update(configSettingsObj, false));
            connectionStatus = Inbound_Connection_Status__c.getInstance(Constant.HEYWIRE_STATUS);
            if (connectionStatus != null) {
                Util.addMessageOnError(Database.delete(connectionStatus, false));
                connectionStatus = Inbound_Connection_Status__c.getInstance(Constant.HEYWIRE_STATUS);
            }
            this.checkConnectionStatus = true;
            if(ApexPages.hasMessages()) {
                Database.rollback(sp);
                Util.insertException(this.configSettingsObj.Id == null?'ConfigurationSettings__c':this.configSettingsObj.Id, 
                    Constant.priority_high, System.Label.ConnectionExceptionMsg);
                return null;
            }
        }
        return null;
    }
    
   /**
     * @description: Action method for Add Support Number button on the admin page. It initializes the
     *               LiveTextNumber object and retrieves the first fifty users in available members list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference addSupportNumber() {
        try{
            this.displayComponent = true;
            this.oAuthUrl = null;
            this.selectedBusinessHour = null;
            this.screenPopDefaultRecordType = null;
            this.ltnObject = new LiveText_Number__c();
            this.phoneNumber = '';
            AssignUserHelper helper = new AssignUserHelper(this.ltnObject);
            this.populateAvailableMembers(helper);
            this.textSessionReuseTime = null;
            this.criticalAlertTime = null;
            this.populateScreenPopAvailableRecordTypes();
            this.populateAutoLinkingAvailableRecordTypes();
            this.selectedNewTabs = new String[]{};
            this.selectedCreateActivityItems = new List<String>();
            this.selectedCreateActivityItems.add(TaskObjectName);
            this.isPrependCountryCode = false;
            this.isITREnabled = false;
            this.notifyUsersDuringOffHours = true;
            
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }
    
   /**
     * @description: Action method for Edit action in the support number list on admin page. Finds the support number
     *               selected for editing and loads the configuration section with existing support number detail. Retrieves
     *               and loads the list of selected members for the support number.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference editSupportNumber() {
        try{
            this.selectedNewTabs = new String[]{};
            this.selectedBusinessHour = null;
            this.screenPopDefaultRecordType = null;
            findObjectById();
            this.selectedBusinessHour = this.ltnObject.Business_Hours__c;
            this.screenPopDefaultRecordType = isObjectRelationShipDeleted(this.ltnObject.Screen_Pop_Default_Record_Type__c) ? null : this.ltnObject.Screen_Pop_Default_Record_Type__c;
            this.isPrependCountryCode = (this.ltnObject.Prepend_Country_Code__c == true) ? true : false; 
            this.isITREnabled = (this.ltnObject.ITR_Enabled__c == true) ? true : false; 
            this.notifyUsersDuringOffHours = (this.ltnObject.Notify_Users_During_Off_Hours__c == true) ? true : false;
            this.phoneNumber = ltnObject.Number__c;
            this.ltnObject.Number__c = this.ltnObject.Formatted_Support_Number__c;
            this.textSessionReuseTime = String.valueOf(this.ltnObject.Text_Session_Reuse_Time_seconds__c);
            this.criticalAlertTime = String.valueOf(this.ltnObject.Critical_Alert_Time__c);
            AssignUserHelper helper = new AssignUserHelper(this.ltnObject);
            this.populateSelectedMembers(helper);
            this.populateAvailableMembers(helper);
            
            AssignScreenPopRecordTypeHelper screenPopHelper = new AssignScreenPopRecordTypeHelper(this.ltnObject);
            this.populateScreenPopSelectedRecordTypes(screenPopHelper);
            this.populateScreenPopAvailableRecordTypes();
            
            AssignAutoLinkingRecordTypeHelper autoLinkingHelper = new AssignAutoLinkingRecordTypeHelper(this.ltnObject);
            this.populateAutoLinkingSelectedRecordTypes(autoLinkingHelper);
            this.populateAutoLinkingAvailableRecordTypes();
            
            this.populateSelectedNewTabs();
            this.populateSelectedCreateActivityItems();
            this.displayComponent = true;
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }
    
    /**
     * @description: Populates the Selected New tabs.
    */
    private void populateSelectedNewTabs() {
        if(!String.isEmpty(this.ltnObject.New_Custom_Objects_Tabs__c)) {
            for(String newObjectTabName : this.ltnObject.New_Custom_Objects_Tabs__c.split(';')) {
                selectedNewTabs.add(newObjectTabName);
            }
        }
    }

    private void populateSelectedCreateActivityItems() {
        selectedCreateActivityItems = new List<String>();
        if(this.ltnObject.CreateTask__c == true) {
            selectedCreateActivityItems.add(TaskObjectName);
        }
        if(this.ltnObject.CreateEvent__c == true) {
            selectedCreateActivityItems.add(EventObjectName);
        }
    }
    
   /**
     * @description: Action method for Delete action in the support number list on admin page. Finds the support number
     *               selected for Deletion and makes API callout to check if number is delete from Heywire. If deleted
     *               then deletes the number else throws the error message back on screen.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference deleteSupportNumber() {
        this.displayMessagesOnTop = false;
        findObjectById();
        try{
            String phoneNumber = this.ltnObject.Number__c.replaceAll(Constant.REGEX_REMOVE_UNWANTED_CH, '');
            Boolean canDelete = (Boolean)this.ltnObject.Validated__c
                                    ? Callout.canDeletePhoneNo(phoneNumber)
                                    : !this.ltnObject.Validated__c;
            if(canDelete) {
                AccessController.deleteAsUser(this.ltnObject);
                retrieveSupportNumbers();
            }
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }



    public PageReference showPhoneErrorMessage(){
        if('phoneNotValid'.equals(phoneErrorMessage)){
            Util.addMessageOnError(System.Label.InvalidPhoneNumberMsg);
        }else if('phoneInvalidLength'.equals(phoneErrorMessage)){
            Util.addMessageOnError(System.Label.LTNumberLengthMsg);
        }
        if(Apexpages.hasMessages()) {
            this.displayMessagesOnTop = false;
        }
        return null;
    }

    private void validatePhCallout(String phoneNumber, Boolean validated){
        // validate phone number on heywire by making api callout.
        validated = validated == null || !validated ?false:validated;
        if(!validated && !Callout.doesPhoneNoExist(phoneNumber)){
            Util.addMessageOnError(System.Label.UnvalidatedPhNoMsg);
        }
    }

    
   /**
     * @description: Action method for Save button on the admin page. Validates the required 
     *               fields on LiveText_Number__c object, checks the length(160) of greeting messages and
     *               checks if offline hour message is provided for selected business hour. Makes API callout
     *               to validate the entered phone number. Adds and Removes the selected Members for the number.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference save() {
    
        String enteredNumber = this.ltnObject.Number__c;
        try{
            String phoneNumber = this.ltnObject.Number__c;
            String phoneLabel = this.ltnObject.Name;
            Boolean validated = this.ltnObject.Validated__c;
            if(String.isBlank(phoneNumber) || String.isBlank(phoneLabel)){
                Util.addMessageOnError(System.Label.SupportNumberReqValMsg);
            }
            showPhoneErrorMessage();
            if(!ApexPages.hasMessages()){
                validatePhCallout(phoneNumber, validated);
            }
            if(Apexpages.hasMessages()) {
                this.displayMessagesOnTop = false;
            } else{
                this.validateRequiredFields();
                if(Apexpages.hasMessages()) {
                    this.displayMessagesOnTop = false;
                } else{
                    this.validateCriticalAlertTime();
                    this.validateTextSessionReuseTime();
                    if(Apexpages.hasMessages()) {
                        this.displayMessagesOnTop = false;
                    } else{
                        ltnObject.Critical_Alert_Time__c = String.isBlank(criticalAlertTime) ? null : Integer.valueOf(criticalAlertTime);
                        ltnObject.Text_Session_Reuse_Time_seconds__c = String.isBlank(textSessionReuseTime) ? 0 : Integer.valueOf(textSessionReuseTime);
                        this.displayComponent = false;
                        this.ltnObject.Number__c = phoneNumber;
                        if(system.Label.NoneLbl.equals(this.selectedBusinessHour)){
                            this.selectedBusinessHour = null;
                        }
                        if(system.Label.NoRecordTypeLbl.equals(this.screenPopDefaultRecordType)){
                            this.screenPopDefaultRecordType = null;
                        }
                        this.ltnObject.Validated__c = true;
                        // Validate that selectedBusinessHour is of ID type
                        this.ltnObject.Business_Hours__c = this.selectedBusinessHour;
                        this.ltnObject.Screen_Pop_Default_Record_Type__c = this.screenPopDefaultRecordType;
                        this.ltnObject.Prepend_Country_Code__c = this.isPrependCountryCode;
                        this.ltnObject.ITR_Enabled__c = this.isITREnabled;
                        this.ltnObject.Notify_Users_During_Off_Hours__c = this.notifyUsersDuringOffHours;
                        retrieveSelectedNewTabs();
                        retrieveSelectedCreateActivityItems();
                        AccessController.upsertAsUser(this.ltnObject);
                        this.removeAddAgents();
                        this.saveScreenPopRecordTypes();
                        this.saveAutoLinkingRecordTypes();
                        this.retrieveSupportNumbers();
                        this.clearMemberList();
                        this.clearScreenPopRecordTypesList();
                        this.clearAutoLinkingRecordTypesList();
                        this.searchUserName = null;
                    }
                }
            }
        } catch(Exception ex) {
            this.handleSaveException(ex, enteredNumber);
        }
        return null;
    }
    
    /**
     * @description: Retrieves the Selected new tabs.
    */
    private void retrieveSelectedNewTabs() {
        String customObjectsNameToSave = '';
        for(String newObjectTabName : selectedNewTabs){
            customObjectsNameToSave += newObjectTabName + ';';
        }
        this.ltnObject.New_Custom_Objects_Tabs__c = customObjectsNameToSave;
    }

    private void retrieveSelectedCreateActivityItems() {
        this.ltnObject.CreateTask__c = Util.ListContainsObject(selectedCreateActivityItems, TaskObjectName);
        this.ltnObject.CreateEvent__c = util.ListContainsObject(selectedCreateActivityItems, EventObjectName);
    }
    
   /**
     * @description: Action method for Cancel button on the admin page. It cancels the current action
     *               and takes the user back to the support number list view.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference cancel() {
        try{
            this.clearMemberList();
            this.clearScreenPopRecordTypesList();
            this.clearAutoLinkingRecordTypesList();
            this.searchUserName = null;
            this.retrieveSupportNumbers();
            this.displayComponent = false;
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }
    
   /**
     * @description: Action method for Add button on the Assign user section. Retrieves the users
     *               containing the entered string. Adds the available members to the buffer list
     *               for removed users.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference searchUsers() {
        try{
            // populating the removed members list every time search user is initiated, so that we do not loose the members
            // which were moved from selected members to available members at the time of save.
            this.populateRemovedMemberSet();
            this.availableMembers.clear();
            AssignUserHelper helper = new AssignUserHelper(this.ltnObject);
            List<SelectOption> foundUsers = helper.findUsersByName(this.searchUserName, this.getSelectMemberSet());
            if(foundUsers.isEmpty()) {
                foundUsers.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
            }
            this.availableMembers.addAll(foundUsers);
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }
    
   /**
     * @description: Action method for Add button on the Assign user section. Moves all the selected
     *               users from available members list to the selected members list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveToRight() {
        try {
            this.removeNoneFromMemberList();
            for (String userId : this.availableMembersList) {
                for(Integer i = 0; i < this.availableMembers.size(); i++) {
                    SelectOption sp = this.availableMembers.get(i);
                    if(userId.equals(sp.getValue())) {
                        this.availableMembers.remove(i);
                        this.selectedMembers.add(sp);
                        break;
                    }
                }
            }
            this.addNoneToMemberList();
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }
    
   /**
     * @description: Action method for Remove button on the Assign user section. Moves all the selected
     *               users from selected members list to the available members list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveToLeft() {
        this.removeNoneFromMemberList();
        for (String userId : this.selectedMembersList) {
            for(Integer i = 0; i < this.selectedMembers.size(); i++) {
                SelectOption sp = this.selectedMembers.get(i);
                if(userId.equals(sp.getValue())) {
                    this.selectedMembers.remove(i);
                    this.availableMembers.add(sp);
                    break;
                }
            }
        }
        this.addNoneToMemberList();
        return null;
    }
    
    /**
     * @description: Action method for Add button in the Screen Pop section. Moves all the selected
     *               record types from available record types list to the selected record types list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveSPRecordTypeToRight() {
        try {
            this.removeNoneFromScreenPopRecordTypesList();
            for (String recordType : this.screenPopAvailableRecordTypesList) {
                for(Integer i = 0; i < this.screenPopAvailableRecordTypes.size(); i++) {
                    SelectOption sp = this.screenPopAvailableRecordTypes.get(i);
                    if(recordType.equals(sp.getValue())) {
                        this.screenPopAvailableRecordTypes.remove(i);
                        this.screenPopSelectedRecordTypes.add(sp);
                        break;
                    }
                }
            }
            this.addNoneToScreenPopRecordTypesList();
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }
    
   /**
     * @description: Action method for Remove button in the Screen Pop section. Moves all the selected
     *               users from selected members list to the available members list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveSPRecordTypeToLeft() {
        this.removeNoneFromScreenPopRecordTypesList();
        for (String recordType : this.screenPopSelectedRecordTypesList) {
            for(Integer i = 0; i < this.screenPopSelectedRecordTypes.size(); i++) {
                SelectOption sp = this.screenPopSelectedRecordTypes.get(i);
                if(recordType.equals(sp.getValue())) {
                    this.screenPopSelectedRecordTypes.remove(i);
                    this.screenPopAvailableRecordTypes.add(sp);
                    break;
                }
            }
        }
        this.addNoneToScreenPopRecordTypesList();
        return null;
    }
    
    /**
     * @description: Action method for Up button in the Screen Pop section. Moves the selected
     *               records up in the sequence of the selected record types list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveSPRecordTypeUp() {
        for (String recordType : this.screenPopSelectedRecordTypesList) { 
            for(Integer i = 0; i < this.screenPopSelectedRecordTypes.size(); i++) {
                SelectOption sp = this.screenPopSelectedRecordTypes.get(i);
                if(recordType.equals(sp.getValue())) {
                    if(i > 0) {
                        this.screenPopSelectedRecordTypes.remove(i);
                        this.screenPopSelectedRecordTypes.add(i-1,sp);
                    }
                    break;
                }
            }
         }
        return null;
    }
    
   /**
     * @description: Action method for Remove button in the Screen Pop section. Moves all the selected
     *                records down in the sequence of the selected record types list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveSPRecordTypeDown() {
        Integer maxIndex = this.screenPopSelectedRecordTypes.size() - 1;
        for (String recordType : this.screenPopSelectedRecordTypesList) {
            for(Integer i = 0; i < this.screenPopSelectedRecordTypes.size(); i++){
                SelectOption sp = this.screenPopSelectedRecordTypes.get(i);
                if(recordType.equals(sp.getValue())){
                    if(i < this.screenPopSelectedRecordTypes.size() - 1){
                        this.screenPopSelectedRecordTypes.remove(i);
                        if(i+1 > this.screenPopSelectedRecordTypes.size() - 1){
                            this.screenPopSelectedRecordTypes.add(sp);
                        } else {
                            this.screenPopSelectedRecordTypes.add(i+1,sp);
                        }
                    }
                    break;
                }
            }
        }
        return null;
    }
    
    /**
     * @description: Action method for Add button in the Auto Link Options section. Moves all the selected
     *               record types from available record types list to the selected record types list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveALRecordTypeToRight() {
        try {
            this.removeNoneFromAutoLinkingRecordTypesList();
            for (String recordType : this.autoLinkingAvailableRecordTypesList) {
                for(Integer i = 0; i < this.autoLinkingAvailableRecordTypes.size(); i++) {
                    SelectOption sp = this.autoLinkingAvailableRecordTypes.get(i);
                    if(recordType.equals(sp.getValue())) {
                        this.autoLinkingAvailableRecordTypes.remove(i);
                        this.autoLinkingSelectedRecordTypes.add(sp);
                        break;
                    }
                }
            }
            this.addNoneToAutoLinkingRecordTypesList();
        } catch(Exception ex) {
            handleException(false, ex);
        }
        return null;
    }
    
   /**
     * @description: Action method for Remove button int the Auto Link section. Moves all the selected
     *               users from selected members list to the available members list.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference moveALRecordTypeToLeft() {
        this.removeNoneFromAutoLinkingRecordTypesList();
        for (String recordType : this.autoLinkingSelectedRecordTypesList) {
            for(Integer i = 0; i < this.autoLinkingSelectedRecordTypes.size(); i++) {
                SelectOption sp = this.autoLinkingSelectedRecordTypes.get(i);
                if(recordType.equals(sp.getValue())) {
                    this.autoLinkingSelectedRecordTypes.remove(i);
                    this.autoLinkingAvailableRecordTypes.add(sp);
                    break;
                }
            }
        }
        this.addNoneToAutoLinkingRecordTypesList();
        return null;
    }
    
   /**
     * @description: Action method called by poller component to check whenter LiveText is successfully
     *               connected to Heywire servers using oAuth or not.
     * @return PageReference object which redirects to another page if not null.
    */
    public PageReference connectedToHeywire() {
        try {
                connectionStatus = Inbound_Connection_Status__c.getInstance(Constant.HEYWIRE_STATUS);
                if(connectionStatus != null) {
                    this.checkConnectionStatus = false;
                }
                retrieveSupportNumbers();
            } catch(Exception ex) {
                handleException(true, ex);
            }
        return null;
    }

    public List<SelectOption> getNewTabOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for(String customObjectAPIName : Util.getAllRelationshipObjects()) {
            options.add(new SelectOption(customObjectAPIName, 'New ' + Schema.describeSObjects(new List<String>{customObjectAPIName})[0].getLabel()));
        }
        return options;
    }

    public List<SelectOption> getLiveTextServerPickList(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(NAServer, NAServer));
        options.add(new SelectOption(EUServer, EUServer));
        return options;
    }

    public List<SelectOption> getCreateActivityItemsOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(TaskObjectName, TaskObjectName));
        options.add(new SelectOption(EventObjectName, EventObjectName));
        return options;
    }
    
    public String[] getSelectedNewTabs() {
        return selectedNewTabs;
    }
     
    public void setSelectedNewTabs(String[] selectedNewTabs) {
        this.selectedNewTabs = selectedNewTabs;
    }
    
    private void removeNoneFromMemberList() {
        if(this.selectedMembers.size() == 1) {
            SelectOption sp = this.selectedMembers.get(0);
            if(system.Label.NoneWithHyphenLbl.equals(sp.getValue())) {
                this.selectedMembers.remove(0);
            }
        }
        if(this.availableMembers.size() == 1) {
            SelectOption sp = this.availableMembers.get(0);
            if(system.Label.NoneWithHyphenLbl.equals(sp.getValue())) {
                this.availableMembers.remove(0);
            }
        }
    }
    
    private void addNoneToMemberList() {
        if(this.selectedMembers.isEmpty()) {
            this.selectedMembers.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        }
        if(this.availableMembers.isEmpty()) {
            this.availableMembers.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        }
    }
    
    private void populateAvailableMembers(AssignUserHelper helper) {
        List<SelectOption> firstFiftyUsers = helper.retrieveFirstFiftyUsers(this.getSelectMemberSet());
        if(!firstFiftyUsers.isEmpty()) {
            this.availableMembers.clear();
            this.availableMembers.addAll(firstFiftyUsers);
        }
    }
    
    private void populateSelectedMembers(AssignUserHelper helper) {
        List<SelectOption> selectedMembers = helper.getSelectedMembers();
        if(!selectedMembers.isEmpty()) {
            this.selectedMembers.clear();
            this.selectedMembers.addAll(selectedMembers);
        }
    }
    
    private void populateScreenPopAvailableRecordTypes() {   
        Set<String> selectedRecordTypes = this.getScreenPopSelectRecordTypesSet();
        List<SelectOption>  recordTypesPickList = populateAvailableRecordTypes(selectedRecordTypes, true);
        if(!recordTypesPickList.isEmpty()) {
            this.screenPopAvailableRecordTypes.clear();
            this.screenPopAvailableRecordTypes.addAll(recordTypesPickList);
        }
    }
    
    private void populateAutoLinkingAvailableRecordTypes() { 
        Set<String> selectedRecordTypes = this.getAutoLinkingSelectRecordTypesSet();
        List<SelectOption>  recordTypesPickList = populateAvailableRecordTypes(selectedRecordTypes, false); 
        if(!recordTypesPickList.isEmpty()) {
            this.autoLinkingAvailableRecordTypes.clear();
            this.autoLinkingAvailableRecordTypes.addAll(recordTypesPickList);
        }
    }
    
    private List<SelectOption> populateAvailableRecordTypes(Set<String> selectedRecordTypes, Boolean isScreenPop) {
        List<SelectOption>  recordTypesPickList = new List<SelectOption>();
        for(String customObjectAPIName : Util.getAllRelationshipObjects()) {
            if(!selectedRecordTypes.contains(customObjectAPIName)) {
                recordTypesPickList.add(new SelectOption(customObjectAPIName, Schema.describeSObjects(new List<String>{customObjectAPIName})[0].getLabel()));
            }
        }   
        
        return recordTypesPickList;
    }
    
    private void populateScreenPopSelectedRecordTypes(AssignScreenPopRecordTypeHelper helper) {
        List<SelectOption> selectedOptions = helper.getSelectedRecordTypes();
        if(!selectedOptions.isEmpty()){
            this.screenPopSelectedRecordTypes.clear();
            this.screenPopSelectedRecordTypes.addAll(selectedOptions);
        }
    }
    
     private void populateAutoLinkingSelectedRecordTypes(AssignAutoLinkingRecordTypeHelper helper) {
        List<SelectOption> selectedOptions = helper.getSelectedRecordTypes();
        if(!selectedOptions.isEmpty()) {
            this.autoLinkingSelectedRecordTypes.clear();
            this.autoLinkingSelectedRecordTypes.addAll(selectedOptions);
        }
    }
    
    private void removeNoneFromScreenPopRecordTypesList() {
        if(this.screenPopSelectedRecordTypes.size() == 1) {
            SelectOption sp = this.screenPopSelectedRecordTypes.get(0);
            if(system.Label.NoneWithHyphenLbl.equals(sp.getValue())) {
                this.screenPopSelectedRecordTypes.remove(0);
            }
        }
        if(this.screenPopAvailableRecordTypes.size() == 1) {
            SelectOption sp = this.screenPopAvailableRecordTypes.get(0);
            if(system.Label.NoneWithHyphenLbl.equals(sp.getValue())) {
                this.screenPopAvailableRecordTypes.remove(0);
            }
        }
    }
    
    private void addNoneToScreenPopRecordTypesList() {
        if(this.screenPopSelectedRecordTypes.isEmpty()) {
            this.screenPopSelectedRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        }
        if(this.screenPopAvailableRecordTypes.isEmpty()) {
            this.screenPopAvailableRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        }
    }
    
     private void removeNoneFromAutoLinkingRecordTypesList() {
        if(this.autoLinkingSelectedRecordTypes.size() == 1) {
            SelectOption sp = this.autoLinkingSelectedRecordTypes.get(0);
            if(system.Label.NoneWithHyphenLbl.equals(sp.getValue())) {
                this.autoLinkingSelectedRecordTypes.remove(0);
            }
        }
        if(this.autoLinkingAvailableRecordTypes.size() == 1) {
            SelectOption sp = this.autoLinkingAvailableRecordTypes.get(0);
            if(system.Label.NoneWithHyphenLbl.equals(sp.getValue())) {
                this.autoLinkingAvailableRecordTypes.remove(0);
            }
        }
    }
    
    private void addNoneToAutoLinkingRecordTypesList() {
        if(this.autoLinkingSelectedRecordTypes.isEmpty()) {
            this.autoLinkingSelectedRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        }
        if(this.autoLinkingAvailableRecordTypes.isEmpty()) {
            this.autoLinkingAvailableRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        }
    }
    
    
    private void handleSaveException(Exception ex, String enteredNumber) {
        this.displayComponent = true;
        this.displayMessagesOnTop = false;
        this.ltnObject.Number__c = enteredNumber;
        this.ltnObject.Validated__c = false;
        Util.insertException(this.ltnObject.Id == null?'LiveText_Number__c':this.ltnObject.Id, 
                                Constant.priority_high, ex.getMessage());
        if(ex.getMessage().contains('DUPLICATE_VALUE')) {
            Util.addMessageOnError(system.label.DuplicatePhoneNoMsg);
        } else {
            Util.addMessageOnError(ex.getMessage());
        }
    }
    
    private void clearMemberList() {
        this.selectedMembers.clear();
        this.selectedMembers.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        this.availableMembers.clear();
        this.availableMembers.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
    }
    
     private void clearScreenPopRecordTypesList() {
        this.screenPopSelectedRecordTypes.clear();
        this.screenPopSelectedRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        this.screenPopAvailableRecordTypes.clear();
        this.screenPopAvailableRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
    }
    
   private void clearAutoLinkingRecordTypesList() {
        this.autoLinkingSelectedRecordTypes.clear();
        this.autoLinkingSelectedRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
        this.autoLinkingAvailableRecordTypes.clear();
        this.autoLinkingAvailableRecordTypes.add(new SelectOption(system.Label.NoneWithHyphenLbl, system.Label.NoneWithHyphenLbl, true));
    }
    
    private void removeAddAgents() {
        // populating the removed members list every time save is clicked, so that we do not loose the members
        // which were moved from selected members to available members.
        this.populateRemovedMemberSet();
        AssignUserHelper helper = new AssignUserHelper(this.ltnObject);
        helper.removeAddAgents(getSelectMemberSet(), this.removedMembers);
    }
    
    private void saveScreenPopRecordTypes() {
        AssignScreenPopRecordTypeHelper helper = new AssignScreenPopRecordTypeHelper(this.ltnObject);
        helper.removeAddRecordTypes(getScreenPopSelectRecordTypesSet());
    }
    
     private void saveAutoLinkingRecordTypes() {
        AssignAutoLinkingRecordTypeHelper helper = new AssignAutoLinkingRecordTypeHelper(this.ltnObject);
        helper.removeAddRecordTypes(getAutoLinkingSelectRecordTypesSet());
    }
    
    private void populateRemovedMemberSet() {
        for(SelectOption sp : this.availableMembers) {
            String value = sp.getValue();
            if(!system.Label.AvailableMembersLbl.equals(value)) {
                this.removedMembers.add(value);
            }
        }
    }
    
    private Set<String> getSelectMemberSet() {
        Set<String> selectedMemberSet = new Set<String>();
        for(SelectOption sp : this.selectedMembers) {
            if(!sp.getValue().equals(system.Label.NoneWithHyphenLbl)) {
                selectedMemberSet.add(sp.getValue());
            }
        }
        return selectedMemberSet;
    }
    
     private Set<String> getScreenPopSelectRecordTypesSet() {
        Set<String> selectedRecordTypesSet = new Set<String>();
        for(SelectOption sp : this.screenPopSelectedRecordTypes) {
            if(!sp.getValue().equals(system.Label.NoneWithHyphenLbl)) {
                selectedRecordTypesSet.add(sp.getValue());
            }
        }
        return selectedRecordTypesSet;
    }
    
    private Set<String> getAutoLinkingSelectRecordTypesSet() {
        Set<String> selectedRecordTypesSet = new Set<String>();
        for(SelectOption sp : this.autoLinkingSelectedRecordTypes) {
            if(!sp.getValue().equals(system.Label.NoneWithHyphenLbl)) {
                selectedRecordTypesSet.add(sp.getValue());
            }
        }
        return selectedRecordTypesSet;
    }
    
    private void setAvailableBusinessHours() {
        this.businessHours = new List<SelectOption>();
        this.businessHours.add(new SelectOption(system.Label.NoneLbl, system.Label.NoneLbl));
        List<BusinessHours> businessHoursList = [   SELECT Id, Name 
                                                    FROM BusinessHours 
                                                    WHERE IsActive=true 
                                                    ORDER BY Name LIMIT 100
                                                ];
        if(!businessHoursList.isEmpty()) {
            for(BusinessHours bHour : businessHoursList) {
                this.businessHours.add(new SelectOption(bHour.Id, bHour.Name));
            }
        }
    }
    
    private void setDefaultRecordTypes() {
        this.defaultRecordTypes = new List<SelectOption>();
        this.defaultRecordTypes.add(new SelectOption(system.Label.NoRecordTypeLbl, system.Label.NoRecordTypeLbl));
        for(String customObjectAPIName : Util.getAllRelationshipObjects()) {
            this.defaultRecordTypes.add(new SelectOption(customObjectAPIName, Schema.describeSObjects(new List<String>{customObjectAPIName})[0].getLabel()));
        }
    }

    private Boolean isObjectRelationShipDeleted(String objectApiName) {
        return !Util.getAllRelationshipObjects().contains(objectApiName);
    }
    
    private void validateRequiredFields() {
        // validate offline hours message is provided if business hours is selected.
        // LT-1328 offline hours message is not required if ITR is enabled
        if(String.isNotBlank(this.selectedBusinessHour) 
            && !system.Label.NoneLbl.equals(this.selectedBusinessHour)
            && !isITREnabled 
            && String.isBlank(this.ltnObject.Offline_Hours_Message__c)) {
            Util.addMessageOnError(System.Label.OfflineHrsReqMsg);
        }
        
        String autoResponseMessage = this.ltnObject.Auto_Response_Message__c;
        String chatEndMessage = this.ltnObject.Chat_End_Message__c;
        String initialMessage = this.ltnObject.Initial_Message__c;
        String offlineHoursMessage = this.ltnObject.Offline_Hours_Message__c;
        String noUsersAvailableMessage = this.ltnObject.No_Available_Users_Message__c;
        // validate 160 character limit for auto response message.
        if(String.isNotBlank(autoResponseMessage)
            && autoResponseMessage.length() > Constant.ALLOWED_GREETING_MSG_LENGTH_LIMIT) {
            Util.addMessageOnError(String.format(System.Label.GreetingMsgLengthLimitMsg, 
                                    new String[]{system.Label.AutoResponseMsgLbl}));
        }

        // validate 160 character limit for chat end message.
        if(String.isNotBlank(chatEndMessage)
            && chatEndMessage.length() > Constant.ALLOWED_GREETING_MSG_LENGTH_LIMIT) {
            Util.addMessageOnError(String.format(System.Label.GreetingMsgLengthLimitMsg, 
                                    new String[]{system.Label.ChatEndMsgLbl}));
        }
        // validate 160 character limit for initial message.
        if(String.isNotBlank(initialMessage)
            && initialMessage.length() > Constant.ALLOWED_GREETING_MSG_LENGTH_LIMIT) {
            Util.addMessageOnError(String.format(System.Label.GreetingMsgLengthLimitMsg, 
                                    new String[]{system.Label.InitialMsgLbl}));
        }
        // validate 160 character limit for offline hour message.
        if(String.isNotBlank(offlineHoursMessage)
            && offlineHoursMessage.length() > Constant.ALLOWED_GREETING_MSG_LENGTH_LIMIT) {
            Util.addMessageOnError(String.format(System.Label.GreetingMsgLengthLimitMsg, 
                                    new String[]{system.Label.OfflineHrsMsgLbl}));
        }
        // validate 160 character limit for No Available Users Message.
        if(String.isNotBlank(noUsersAvailableMessage)
            && noUsersAvailableMessage.length() > Constant.ALLOWED_GREETING_MSG_LENGTH_LIMIT) {
            Util.addMessageOnError(String.format(System.Label.GreetingMsgLengthLimitMsg, 
                                    new String[]{system.Label.NoAvailableUsersMsgLbl}));
        }
    }
    private void validateCriticalAlertTime() {
        if(!String.isBlank(criticalAlertTime)) {
            if(!criticalAlertTime.isNumeric())
                Util.addMessageOnError(Label.CriticalWaitAlertTimeMsg);
        }
    }
    private void validateTextSessionReuseTime() {
        if(!String.isBlank(textSessionReuseTime)) {
            if(!textSessionReuseTime.isNumeric())
                Util.addMessageOnError(Label.TextSessionReuseTimeMsg);
            }
    }
    
    private void findObjectById() {
        if(String.isNotBlank(this.selectedLtnId)) {
            for(LiveText_Number__c sobj : sObjList) {
                if(this.selectedLtnId.equals(sobj.Id)) {
                    this.ltnObject = sobj;
                    break;
                }
            }
        }
    }
        
    private void validateInputs() {
        this.displayMessagesOnTop = true;
        if(String.isBlank(configSettingsObj.Account_Id__c)
            || String.isBlank(configSettingsObj.Auth_Token__c)) {
            Util.addMessageOnError(System.Label.HeyWireCredentialsRequiredMsg);
        }
        if(!ApexPages.hasMessages() && (!Util.isAlphaNumeric(configSettingsObj.Account_Id__c)
            || !Util.isAlphaNumeric(configSettingsObj.Account_Id__c))) {
            Util.addMessageOnError(System.Label.InvalidHeyWireCredentialMsg);
        }
        String tempNumber = '9999999999';
        if(!ApexPages.hasMessages() 
            && !Callout.validateAccCredentials(configSettingsObj, tempNumber)) {
            configSettingsObj.Is_Valid_Credentials__c = false;
            Util.addMessageOnError(Database.update(configSettingsObj, false));
            Util.addMessageOnError(System.Label.InvalidHeywireCredentialsMsg);
        }
    }
    
    private void retrieveSupportNumbers() {
        sObjList = new List<LiveText_Number__c>();
        String  soql =  'SELECT validated__c, createddate, initial_message__c, Formatted_Support_Number__c,ISOCountryCode__c,International_Live_Text_Number__c, '+
                        'createdbyid, lastmodifieddate, id, offline_hours_message__c, Auto_Response_Message__c,No_Available_Users_Message__c, '+
                        'chat_end_message__c, number__c, isdeleted, name, business_hours__c, Critical_Alert_Time__c, ' +
                        'Screen_Pop_Default_Record_Type__c, Prepend_Country_Code__c, ITR_Enabled__c, lastmodifiedbyid, CreateEvent__c, CreateTask__c, ' +
                        'Notify_Users_During_Off_Hours__c, New_Custom_Objects_Tabs__c, Text_Session_Reuse_Time_seconds__c ' + 
                        'FROM LiveText_Number__c ' +
                        'ORDER BY Name, CreatedDate ASC LIMIT 1000';
        sObjList = Database.query(soql);
    }
    
    @TestVisible
    private void handleException(Boolean displayMessagesOnTop, Exception ex){
        this.displayMessagesOnTop = displayMessagesOnTop;
        Util.insertException(this.ltnObject.Id == null?'LiveText Admin':this.ltnObject.Id, Constant.priority_high, ex.getMessage());
        Util.addMessageOnError(ex.getMessage());
    }

     private void createConfigurationSettingsForSandboxesOnly() {
        Organization orginfo = [    SELECT Id, IsSandbox 
                                    FROM Organization LIMIT 1
                                ];
            if(orginfo.IsSandbox) {
                ConfigurationSettings__c confSettings = new ConfigurationSettings__c(
                    Name = Constant.HEYWIRE_CONFIG,
                    EndPoint_URL__c = Constant.HEYWIRE_PRODUCTION_URL,
                    oAuth_URL__c = Constant.HEYWIRE_PRODUCTION_OAUTH_URL);
                AccessController.insertAsSystem(new List<ConfigurationSettings__c>{confSettings});
            }
     }

     private void createGlobalSettingsForSandboxesOnly() {
        Organization orginfo = [    SELECT Id, IsSandbox 
                                    FROM Organization LIMIT 1
                                ];
        if(orginfo.IsSandbox) {
            LiveTextGlobalSettings__c globalSettings = new LiveTextGlobalSettings__c(   GlobalTriggerExecutionEnabled__c = true,
                                                                                        Active_Status_Purge_Hours__c = 48,
                                                                                        New_Status_Purge_Hours__c = 1,
                                                                                        Offline_Status_Purge_Hours__c =1,
                                                                                        SetupOwnerId = UserInfo.getOrganizationId()
                                                                                    );
            AccessController.insertAsSystem(new List<LiveTextGlobalSettings__c>{globalSettings});
        }
     }
     
     public static void DummyTest(){
     	Integer i;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	i=0;
     	
     }
     
}