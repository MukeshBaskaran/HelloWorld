/**
* @author         Patrick Kwete
* @data           02.04.2015
* @description    LiveTextBulkSmsController class contains methods used by the Bulk SMS page
*                 in LiveText for Salesforce application.
**/

global with sharing class LiveTextCampaignBulkSMSController {
    // an instance varaible for the standard controller
    @TestVisible
    private ApexPages.StandardController controller {get;set;}
    public String storageId {get; set;}
    public String campaignId {get;set;}
    public String campaignName {get;set;}

    public Integer getCampaignShortcodeRecordLimit(){
        return Util.CampaignShortcodeRecordLimit;
    }

    public Integer getLongcodeRecordLimit(){
        return Util.LongcodeRecordLimit;
    }

    public List<SelectOption> getCampaignAvailableStatuses(){
        List<SelectOption> options = new List<SelectOption>();
        for(CampaignMemberStatus cs : [Select Label FROM CampaignMemberStatus WHERE CampaignId =:campaignId]){
            options.add(new SelectOption(cs.Label, cs.Label));
        }
        return options;
    }

    public List<SelectOption> getCampaignRespondedStatuses(){
        List<SelectOption> options = new List<SelectOption>();
        for(CampaignMemberStatus cs : [Select Label FROM CampaignMemberStatus WHERE CampaignId =:campaignId AND HasResponded = true]){
            options.add(new SelectOption(cs.Label, cs.Label));
        }
        return options;
    }

    public List<SelectOption> getNumbers() {
        List<SelectOption> options = new List<SelectOption>();

        String uid = UserInfo.getUserId();
        List<Id> ids = new List<Id>();

        for(Associated_Agents__c a : [SELECT LiveText_Number__c FROM Associated_Agents__c WHERE User__c=:uid]) {
            ids.add(a.LiveText_Number__c);
        }
        for(LiveText_Number__c n : [SELECT Id, Name, Formatted_Support_Number__c FROM LiveText_Number__c WHERE Id IN :ids]) {
            options.add(new SelectOption(n.Id, n.Name));
        }
        return options;
    }

    /**
    * @description: Controller constructor method, used to intialize the collections,
    *               variables and load the static data(like object prefixes) for the LiveText page.
    **/

    public LiveTextCampaignBulkSMSController(ApexPages.StandardController stdController) {
        this.controller = controller;
    }

    /**
	*
    * @description: init method called when page loads to set campaign data.
	*
    **/

    public void init() {
        String record = '';
        storageId = ApexPages.currentPage().getParameters().get('storageId');
        if(!String.isBlank(storageId)){
            List<Storage__c> storage = [SELECT StorageTextData__c FROM Storage__c WHERE Id = :storageId];
            if(!storage.isEmpty()){
                record = storage[0].StorageTextData__c;
            }
        }
        if(!String.isEmpty(record)){
            Id tempId = (Id) record;
            String selectedObjectPrefix = tempId.getSObjectType().getDescribe().getKeyPrefix();
            if('701'.equals(selectedObjectPrefix)){
                this.campaignId = record;
                this.campaignName = [SELECT Name FROM Campaign WHERE Id =:campaignId LIMIT 1].Name;
            }
        }
    }

    @RemoteAction
    public static void deleteStorageRecord(String storageId){
        if(String.isNotBlank(storageId)){
            delete [SELECT Id FROM Storage__c WHERE Id = :storageId];
        }
    }

    @RemoteAction
    public static void sendSMSToCampaignMembers(String liveTextNumberId, String message, String campaignId, List<String> sendToStatuses, String statusAfterSend, String duplicatesStatus, String statusAfterResponse, String statusAfterOptOut, String storageId){
        Id batchId = Database.executeBatch(new SendSMSToCampaignBatch(liveTextNumberId, message, campaignId, sendToStatuses, statusAfterSend, duplicatesStatus, statusAfterResponse, statusAfterOptOut, storageId), 100);
        //We can return this Id back to the page, and create batch progress bar there.
    }

    @RemoteAction
    @readOnly
    public static Integer countCampaignMembers(String campaignId, List<String> sendToStatuses){
        return [SELECT count() FROM CampaignMember WHERE CampaignId =: campaignId AND Status IN :sendToStatuses];
    }

    @RemoteAction
    @readOnly
    public static Integer getInprogressOutBoundBatchCount(){
        List<String> campaignSendBatchIdList = new List<String>();
        Integer count = 0;
        List<String> statusList = new List<String>{Label.BulkCampaignBatchStatusAborted,Label.BulkCampaignBatchStatusFailed,Label.BulkCampaignBatchStatusFinish};
        for(Campaign_Send__c cs : [SELECT Id,BatchId__c FROM Campaign_Send__c WHERE BatchId__c != null LIMIT 50000 ]){
            campaignSendBatchIdList.add(cs.BatchId__c);
        }
        if(campaignSendBatchIdList != null){
            count = [Select count()
                     FROM AsyncApexJob
                     WHERE Id  IN: campaignSendBatchIdList 
                        AND Status NOT IN: statusList ];
        }
        return count;
    }

    @RemoteAction
    public static Integer getCampaignRecordLimitForPhone(String ltnId){
        if(String.isNotBlank(ltnId)){
            LiveText_Number__c phoneNumber = [SELECT Number__c FROM LiveText_Number__c WHERE Id =:ltnId];
            if(Util.IsShortCode(phoneNumber.Number__c)){
                return Util.CampaignShortcodeRecordLimit;
            }else{
                return Util.LongcodeRecordLimit;
            }
        }
        return 0;
    }
}