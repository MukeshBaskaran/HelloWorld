/**
*
* @author         Maciej Miłosz
* @Company        HeyWire
* @data           07/10/2015
* @description    SendSMSToCampaignBatch class is used to mass text to campaign
*                 in LiveText for Salesforce application.
*
*/

global class SendSMSToCampaignBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    private String campaignId;
    private String liveTextNumberId;
    private String message;
    private List<String> sendToStatuses;
    private String statusAfterSend;
    private String duplicatesStatus;
    private String statusAfterResponse;
    private String statusAfterOptOut;
    private String storageId;

    private LiveText_Number__c liveTextNumber;
    private Integer recordsWithoutPhone;
    private Integer recordsWithoutMobile;
    private List<ActionResult> sendSMSResults;
    private Set<String> phonesFromPreviousBatches;
    private Boolean isShortcode;

    private Campaign_Send__c campaignSend;
    
    global SendSMSToCampaignBatch(String liveTextNumberId, String message, String campaignId, List<String> sendToStatuses, String statusAfterSend, String duplicatesStatus, String statusAfterResponse, String statusAfterOptOut, String storageId) {
        this.campaignId = campaignId;
        this.liveTextNumberId = liveTextNumberId;
        this.message = message;
        this.sendToStatuses = sendToStatuses;
        this.statusAfterResponse = statusAfterResponse;
        this.statusAfterSend = statusAfterSend;
        this.duplicatesStatus = duplicatesStatus;
        this.statusAfterOptOut = statusAfterOptOut;
        this.storageId = storageId;
        this.recordsWithoutMobile = 0;
        this.recordsWithoutPhone = 0;
        this.sendSMSResults = new List<ActionResult>();
        this.phonesFromPreviousBatches = new Set<String>();
        this.liveTextNumber = Util.GetLiveTextNumberObjectById(liveTextNumberId);
        this.isShortcode = Util.IsShortCode(liveTextNumber.Number__c);
        List<Campaign_Send__c> campaignSendList = new List<Campaign_Send__c>();
        campaignSend = new Campaign_Send__c();
        if(campaignId != null){
            campaignSend.Campaign__c = campaignId;
        }
        if(liveTextNumberId != null){
            campaignSend.SupportNumber__c = liveTextNumberId;
        }
        campaignSend.SuccessStatus__c = statusAfterSend;
        campaignSend.ResponseStatus__c = 'doNotChange'.equals(statusAfterResponse) ? null : statusAfterResponse;
        campaignSend.OptoutStatus__c = 'doNotChange'.equals(statusAfterOptOut) ? null : statusAfterOptOut;
        campaignSend.StartTime__c = DateTime.now();
        campaignSendList.add(campaignSend);
        if(campaignSendList != null) {
             AccessController.insertAsUser(campaignSendList);
        }

    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        if(BC.getJobId() != null) {
            campaignSend.BatchId__c = BC.getJobId();
            AccessController.updateAsUser(new List<Campaign_Send__c>{campaignSend});
        }
        String query = 'SELECT Id, ContactId, LeadId FROM CampaignMember WHERE CampaignId = :campaignId AND Status IN :sendToStatuses ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Id> contactIds = new List<Id>();
        List<Id> leadIds = new List<Id>();
        List<Id> ids = new List<Id>();
        Set<String> campaignMembersIdsToAfterStatusUpdate = new Set<String>();
        Set<String> campaignMembersIdsToDuplicateStatusUpdate = new Set<String>();
        Map<String, String> contactOrLeadIdtoCampaignMemberId = new Map<String, String>();
        Map<String, Set<String>> statusesToCampaignMemberIds = new Map<String, Set<String>>();
     
        for(sObject cm : scope){
            if(cm.get('ContactId') != null){
                Id contactId = (Id) cm.get('ContactId');
                contactIds.add(contactId);
                ids.add(contactId);
                contactOrLeadIdtoCampaignMemberId.put(contactId, (String) cm.get('Id'));
            }else if(cm.get('LeadId') != null){
                Id leadId = (Id) cm.get('LeadId');
                leadIds.add(leadId);
                ids.add(leadId);
                contactOrLeadIdtoCampaignMemberId.put(leadId, (String) cm.get('Id'));
            }
        }
        
        Map<String, PhoneInformation> idToPhonesWithType = new Map<String, PhoneInformation>();
        
        // Get contact(s) phone numbers
        if(!contactIds.isEmpty()){
        	Map<String, PhoneInformation> contactIdToPhonesWithType =  (Map<String, PhoneInformation>)System.JSON.deserialize(RetrievePreferredPhoneNumber.getToPhoneInformationFromObjects(contactIds), Map<String, PhoneInformation>.class);
        	if(!contactIdToPhonesWithType.isEmpty()){
        		idToPhonesWithType.putAll(contactIdToPhonesWithType);
        	}
        } 
        
        // Get leads(s) phone numbers    
        if(!leadIds.isEmpty()){
        	Map<String, PhoneInformation> leadIdToPhonesWithType =  (Map<String, PhoneInformation>)System.JSON.deserialize(RetrievePreferredPhoneNumber.getToPhoneInformationFromObjects(leadIds), Map<String, PhoneInformation>.class);
        	if(!leadIdToPhonesWithType.isEmpty()){
        		idToPhonesWithType.putAll(leadIdToPhonesWithType);
        	}
        }        
        
        if(!ids.isEmpty() && !idToPhonesWithType.isEmpty()){
            Set<String> tempAfterSendIds = new Set<String>();
            Set<String> tempDuplicatesIds = new Set<String>();
            Map<String, Set<String>> tempMap = sendSMSToObjects(contactOrLeadIdtoCampaignMemberId, idToPhonesWithType);
            if(tempMap.containsKey('afterSend'))
                tempAfterSendIds.addAll(tempMap.get('afterSend'));
            if(tempMap.containsKey('duplicate'))
                tempDuplicatesIds.addAll(tempMap.get('duplicate'));
            statusesToCampaignMemberIds.put('duplicate', tempDuplicatesIds);
            statusesToCampaignMemberIds.put('afterSend', tempAfterSendIds);
        }
    
        if(statusesToCampaignMemberIds.containsKey('afterSend'))
            campaignMembersIdsToAfterStatusUpdate = statusesToCampaignMemberIds.get('afterSend');
        if(statusesToCampaignMemberIds.containsKey('duplicate'))
            campaignMembersIdsToDuplicateStatusUpdate = statusesToCampaignMemberIds.get('duplicate');

        for(sObject cm : scope){
            if(!'doNotChange'.equals(statusAfterSend)){
                if(campaignMembersIdsToAfterStatusUpdate.contains((String) cm.get('Id')))
                    cm.put('Status', statusAfterSend);
            }
            if(!'doNotChange'.equals(duplicatesStatus)){
                if(campaignMembersIdsToDuplicateStatusUpdate.contains((String) cm.get('Id')))
                    cm.put('Status', duplicatesStatus);   
            }
        }
        update scope;
    }
    
    global void finish(Database.BatchableContext BC) {
        campaignSend.BatchId__c = null;
        campaignSend.EndTime__c = DateTime.Now();
        AccessController.updateAsUser(new List<Campaign_Send__c>{campaignSend});

    }

    /**
    *   @description: sendSMSToObjects contains logic to send sms to proper phone numbers
    *
    *   @param  Map<String, String> contactOrLeadIdtoCampaignMemberId - contact/Lead Id to CampaignMember Id
    *           Map<String, PhoneInformation> idToPhonesWithType - contact/lead Id to PhoneInformation
    **/

    private Map<String, Set<String>> sendSMSToObjects(Map<String, String> contactOrLeadIdtoCampaignMemberId, Map<String, PhoneInformation> idToPhonesWithType){
        Map<String, Set<String>> statusTypeToCampaignMembersIds = new Map<String, Set<String>>();
        Map<String, Set<String>> phoneNumberToCampaignMemberIds = new Map<String, Set<String>>();
        try{
            Map<String, Campaign_Send_Member__c> campaignMemberIdToCampaignSendMembers = new Map<String, Campaign_Send_Member__c>();
            Integer noMobile = 0;
            Integer noPhone = 0;
            String cmId = '';
            Set<String> currentBatchPhoneNumbers = new Set<String>();
            Set<String> idsForActivities = new Set<String>();
            Map<String,String> recordIdToPhoneNumber = new Map<String,String>();
            for(String key : idToPhonesWithType.keySet()){      	
                String phone = idToPhonesWithType.get(key).phone;
                 
                cmId = contactOrLeadIdtoCampaignMemberId.get(key);
                if(!String.isBlank(phone)){
                    phone = CountryCodeUtil.preparePhoneForBulk(phone);
      	           	Set<String> cids = new Set<String>();
      	           	if(phoneNumberToCampaignMemberIds.containsKey(phone)){
      	           		cids = phoneNumberToCampaignMemberIds.get(phone);
      	           	}
      	           	cids.add(cmId);
      	           	phoneNumberToCampaignMemberIds.put(phone, cids);
                }
                
                if(String.isBlank(phone)){
                    // if no phone is found we do not update CM or create any records
                    noPhone++;
                }else if('Mobile'.equals(idToPhonesWithType.get(key).phoneType)){
                    if(phonesFromPreviousBatches.contains(phone)){
                        //adding CM that have the same phone number as ones from previous batches - for status update
                        Set<String> tempIds = new Set<String>();
                        if(statusTypeToCampaignMembersIds.containsKey('duplicate')){
                            tempIds = statusTypeToCampaignMembersIds.get('duplicate');
                        }
                        tempIds.add(cmId);
                        statusTypeToCampaignMembersIds.put('duplicate', tempIds);
                    }else{
                        //checking locale only for shortcodes
                        if(CountryCodeUtil.isPhoneFromLocale(phone, liveTextNumber.ISOCountryCode__c) || !isShortcode){
                            recordIdToPhoneNumber.put(key, phone);
                            phonesFromPreviousBatches.add(phone);

                            Campaign_Send_Member__c csm = new Campaign_Send_Member__c();
                            csm.CampaignSend__c = campaignSend.Id;
                            csm.Phone__c = Util.NormalizePhoneNumber(phone);
                            csm.CampaignMemberId__c = cmId;

                            campaignMemberIdToCampaignSendMembers.put(cmId, csm);
                            idsForActivities.add(key);
                        }
                    }
                    currentBatchPhoneNumbers.add(phone);
                }else{
                    noMobile++;
                    if(phonesFromPreviousBatches.contains(phone)){
                        //adding CM that have the same phone number as ones from previous batches - for status update
                        Set<String> tempIds = new Set<String>();
                        if(statusTypeToCampaignMembersIds.containsKey('duplicate')){
                            tempIds = statusTypeToCampaignMembersIds.get('duplicate');
                        }
                        tempIds.add(cmId);
                        statusTypeToCampaignMembersIds.put('duplicate', tempIds);
                    }else{
                        //checking locale only for shortcodes
                        if(CountryCodeUtil.isPhoneFromLocale(phone, liveTextNumber.ISOCountryCode__c) || !isShortcode){
                            recordIdToPhoneNumber.put(key, phone);
                            phonesFromPreviousBatches.add(phone);

                            Campaign_Send_Member__c csm = new Campaign_Send_Member__c();
                            csm.CampaignSend__c = campaignSend.Id;
                            csm.Phone__c = Util.NormalizePhoneNumber(phone);
                            csm.CampaignMemberId__c = cmId;

                            campaignMemberIdToCampaignSendMembers.put(cmId, csm);
                            idsForActivities.add(key);
                        }
                    }
                    currentBatchPhoneNumbers.add(phone);
                }
            }

            recordsWithoutPhone += noPhone;
            recordsWithoutMobile += noMobile;
            
            List<ActionResult> results = ScheduleMessageAction.scheduleMessagesForBatch(liveTextNumber, recordIdToPhoneNumber, message, '12345',null);
            sendSMSResults.addAll(results);
            for(ActionResult result : results){
                //if a number is opted-out do not change CM status and do not create activity record
                if(!result.IsSuccess && Label.ActionResultPhoneNotOptedIn.equals(result.ErrorMessage)){
                    cmId = contactOrLeadIdtoCampaignMemberId.get(result.Tag);
                    campaignMemberIdToCampaignSendMembers.remove(cmId);
                    idsForActivities.remove(result.Tag);
 
                    // remove opted out phone number from duplicates                   
                    String phone = recordIdToPhoneNumber.get(result.Tag);
                    if(!String.IsBlank(phone) && statusTypeToCampaignMembersIds.containsKey('duplicate') && phoneNumberToCampaignMemberIds.containsKey(phone)){
      	           		Set<String> cids = phoneNumberToCampaignMemberIds.get(phone);
                        Set<String> tempIds = statusTypeToCampaignMembersIds.get('duplicate');
                        tempIds.removeAll(cids);
                        statusTypeToCampaignMembersIds.put('duplicate', tempIds);
                   	}               
                }
            }
                        
            //adding all CM for after send status update
            statusTypeToCampaignMembersIds.put('afterSend', campaignMemberIdToCampaignSendMembers.keySet());

            AccessController.insertAsUser(campaignMemberIdToCampaignSendMembers.values());

            Map<String, Recent_Campaign_Send_Member__c> phoneToRecentCampaignSendMember = new Map<String, Recent_Campaign_Send_Member__c>();
            Date today = System.today();
            for(Recent_Campaign_Send_Member__c rcsm : [SELECT Id, CampaignSendMember__r.Phone__c, CampaignSendMember__c FROM Recent_Campaign_Send_Member__c 
                                                                WHERE CampaignSendMember__r.Phone__c IN :currentBatchPhoneNumbers
                                                                AND CampaignSendMember__r.FromNumber__c = :liveTextNumber.Number__c]){
                phoneToRecentCampaignSendMember.put(rcsm.CampaignSendMember__r.Phone__c, rcsm);
            }

            List<Recent_Campaign_Send_Member__c> recentCampaignSendMembersToUpsert = new List<Recent_Campaign_Send_Member__c>();
            for(Campaign_Send_Member__c csm : campaignMemberIdToCampaignSendMembers.values()){
                //this if is for creating olny one Recent_Campaign_Send_Member__c per phone/LTNumber
                Recent_Campaign_Send_Member__c temp = new Recent_Campaign_Send_Member__c();
                if(phoneToRecentCampaignSendMember.containsKey(csm.Phone__c)){
                    temp = phoneToRecentCampaignSendMember.get(csm.Phone__c);
                }
                temp.CampaignSendMember__c = csm.Id;
                recentCampaignSendMembersToUpsert.add(temp);
            }
            if(!recentCampaignSendMembersToUpsert.isEmpty())
                upsert recentCampaignSendMembersToUpsert;

            //Activities 
            List<Event> eventList =  new List<Event>();
            List<Task> taskList = new List<Task>();
            for(String id : new List<String>(idsForActivities)) {
                String myIdPrefix = String.valueOf(id).substring(0,3);
                if(liveTextNumber.CreateEvent__c) {
                    Event e = new Event();
                    e.OwnerId = UserInfo.getUserId(); 
                    e.Subject = Label.OutboundMessageTitle;
                    e.IsReminderSet = false; 
                    e.StartDateTime = DateTime.now();
                    e.EndDateTime = DateTime.now();
                    if(myIdPrefix == '003' || myIdPrefix == '00Q') {        
                        e.WhoId = id;
                    } else {
                        e.WhatId = id;
                    }
                    e.Description =  Util.createOutboundMessageTranscript(message);             
                    eventList.add(e);
                }
                if(liveTextNumber.CreateTask__c) {
                    Task t = new Task();
                    t.OwnerId = UserInfo.getUserId();
                    t.Subject = Label.OutboundMessageTitle;
                    t.IsReminderSet = false;
                    if(myIdPrefix == '003' || myIdPrefix == '00Q') {        
                        t.WhoId = id;
                    } else {
                        t.WhatId = id;
                    }
                    DateTime d = DateTime.Now();
                    t.ActivityDate = Date.newinstance(d.year(), d.month(), d.day());
                    t.Status = 'Completed';//required
                    t.Priority = 'Normal';//required
                    t.Description = Util.createOutboundMessageTranscript(message);
                    taskList.add(t);
                }
            }

            if(!eventList.isEmpty())
                AccessController.insertAsUser(eventList);
            if(!taskList.isEmpty())
                AccessController.insertAsUser(taskList);
        } catch(Exception ex) {
            Util.insertException('sendBulk', constant.priority_high, ex.getMessage());
        }
        return statusTypeToCampaignMembersIds;
    }
    
}