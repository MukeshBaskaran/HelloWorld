/**
*
* @author         
* @Company        HeyWire
* @data           07/18/2015
* @description    LiveTextBulkSmsController class contains methods used by the Bulk SMS page
*                 in LiveText for Salesforce application.
*
*/
global with sharing class LiveTextBulkSmsController {

    /**
    *   Constructor with ApexPages.StandardController is required for extensions.
    */
    public LiveTextBulkSmsController(ApexPages.StandardController stdController) {
    }

    /**
    *   Return current user local.
    */
    public String getLocale(){
        return UserInfo.getLocale();
    }

    /**
    *   storageId - Storage__c record Id, used to delete Storage__c record
    *   Remote Action that delete Storage__c object using record Id.
    *   Method used when user interrupt process.
    */
    @RemoteAction
    public static void deleteStorageRecord(String storageId){
        if(String.isNotBlank(storageId)){
            delete [SELECT Id FROM Storage__c WHERE Id = :storageId];
        }
    }

    /**
    *   storageId - Storage__c record Id, used to delete Storage__c record at the end of process.
    *   activeSupportNumber - From Number. (Messages will be sent from this number).
    *   recordIdToPhoneNumber - list of recipients phone numbers.
    *   message - text message that will be sent to recipients.

    *   Remote Action that sends sms to list.
    *   Also creates events and tasks if messages were sent successfully.
    *   It accept next parameters:
    *   If process fails at any phase, system will log exception to exception object table.
    *   If process run without error system will return JSON with info message.
    */
    @RemoteAction
    public static String sendSMSToList(String storageId, String activeSupportNumber, Map<String, String> recordIdToPhoneNumber, String message){
        if(!String.isBlank(storageId) && !String.isBlank(activeSupportNumber) && !String.isBlank(message) && recordIdToPhoneNumber != NULL && !recordIdToPhoneNumber.isEmpty()){
            Map<String, String> validationResultMap = new Map<String, String>();
            try{
                delete [SELECT Id FROM Storage__c WHERE Id = :storageId];
                LiveText_Number__c liveTextNumber = Util.GetLiveTextNumberObjectById(activeSupportNumber);
                List<Event> eventList =  new List<Event>();
                List<Task> taskList = new List<Task>();
                if(liveTextNumber != null) {
                    String sResults = 'Results: ';
                    List<ActionResult> results = ScheduleMessageAction.scheduleMessages(liveTextNumber, recordIdToPhoneNumber, message, '12345',null);
                    for(ActionResult result : results){
                        sResults = sResults + result;
                        if(result.IsSuccess){
                            String id = (String) result.tag;
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
                        }else{
                            System.debug('Bulk SMS id: '+ result.Tag + ', error: '+ result.ErrorMessage);
                        }
                    }
                    if(!eventList.isEmpty())
                    AccessController.insertAsUser(eventList);
                    if(!taskList.isEmpty())
                    AccessController.insertAsUser(taskList);
                    validationResultMap.put('success',Label.BulkCongrats);
                }
            }catch(Exception ex) {
                Util.insertException('BulkSMS', constant.priority_high, 'Error in sending to list.');
                //validationResultMap.put('error','Something went wrong.');
            }
            if(!validationResultMap.isEmpty()){
                return JSON.serialize(validationResultMap);
            }
        }
        return NULL;
    }

  /**
  *   Remote Action that give us a list of phone numbers that we can use to send message.
  */
  @RemoteAction
  public static String getPhoneNumbers(){
      Map<Id, String> newPhoneNumbersMap = new Map<Id, String>();
      List<Id> phoneIds = new List<Id>();

      Id userId = UserInfo.getUserId();
      List<Id> associatedLiveTextNumberIds = new List<Id>();

      for(Associated_Agents__c a : [SELECT LiveText_Number__c FROM Associated_Agents__c WHERE User__c=:userId]) {
          associatedLiveTextNumberIds.add(a.LiveText_Number__c);
      }
      for(LiveText_Number__c n : [SELECT Id, Name, Formatted_Support_Number__c FROM LiveText_Number__c WHERE Id IN :associatedLiveTextNumberIds]) {
          newPhoneNumbersMap.put(n.Id, n.Name);
      }
      return JSON.serialize(newPhoneNumbersMap);
  }

  /**
  *   liveTextNumberIds - list of Ids (LiveTextNumber__c).
  *
  *   Remote Action that gives us If of dafault LiveTextNumber record.
  */
  @RemoteAction
  public static String getActiveLiveTextNumberId(List<String> liveTextNumberIds){
    if(liveTextNumberIds != NULL && !liveTextNumberIds.isEmpty()){
      List<Conversation_Header__c> newConversationHeaderList = [SELECT LastModifiedDate, Support_Number__r.Id
                                                                FROM Conversation_Header__c
                                                                WHERE Support_Number__r.Id IN :liveTextNumberIds
                                                                AND Support_Number__c != NULL
                                                                ORDER BY LastModifiedDate DESC LIMIT 1];
      if(newConversationHeaderList.isEmpty()){
        return liveTextNumberIds[0];
      }else{
        return newConversationHeaderList[0].Support_Number__r.Id;
      }
    }
    return NULL;
  }

  /**
  *   activeSupportNumberId - Select LiveTextNumber__c Id.
  *
  *   Remote Action that return limit of recipients for LiveTextNumber that we are using.
  */
  @RemoteAction
  public static Integer getRecordsNumberLimit(String activeSupportNumberId){
      if(String.isNotBlank(activeSupportNumberId)){
          LiveText_Number__c phoneNumber = [SELECT Number__c FROM LiveText_Number__c WHERE Id =:activeSupportNumberId];
          if(Util.IsShortCode(phoneNumber.Number__c)){
              return Util.BulkSmsShortcodeRecordLimit;
          }else{
              return Util.LongcodeRecordLimit;
          }
      }
      return NULL;
  }
  /**
  *   storageId - Id of the Storage__c record that store info about selected recipients.
  *
  *   Remote Action that return selected Recipients, information about this is taken from Storage__c record.
  */
  @RemoteAction
  public static String getRecipients(String storageId){
    List<Storage__c> storage = [SELECT StorageTextData__c FROM Storage__c WHERE Id = :storageId];
    if(!storage.isEmpty()){
      List<Id> recordArray = String.isBlank(storage[0].StorageTextData__c) ? new List<Id>() : storage[0].StorageTextData__c.split(',');
      //should we just return RetrievePreferredPhoneNumber.getToPhoneInformationFromObjects(recordArray)?
      Map<String, PhoneInformation> idToPhoneTypeAndPhone = (Map<String, PhoneInformation>) System.JSON.deserialize(RetrievePreferredPhoneNumber.getToPhoneInformationFromObjects(recordArray), Map<String, PhoneInformation>.class);
      if(!idToPhoneTypeAndPhone.isEmpty()){
        return JSON.serialize(idToPhoneTypeAndPhone);
      }
    }
    return NULL;
  }

  /**
  *   idToPhoneTypeAndPhone - map that contains info about recipient's phone number and phone type (mobile or land).
  *   Remote Action that return status for recipients number.
  *   For example if selected recipient does not have phone number we will no that there is 1 recipient without phone number.
  */
  @RemoteAction
  public static String getNumberStatuses(Map<String, PhoneInformation> idToPhoneTypeAndPhone){
      Map<String, Integer> resultMap = new Map<String, Integer>();
      Integer noMobileOrPhoneNumberRecordsNumber = 0;
      Integer noMobileNumberRecordsNumber = 0;
      Integer recordsNumber = 0;
      for(String key : idToPhoneTypeAndPhone.keySet()){
          PhoneInformation temp = idToPhoneTypeAndPhone.get(key);
          recordsNumber++;
          if(String.isBlank(temp.phone)){
              noMobileOrPhoneNumberRecordsNumber++;
          }else if(!'Mobile'.equals(temp.phoneType)){
              noMobileNumberRecordsNumber++;
          }
      }
      Integer recipientsNumber = recordsNumber - noMobileOrPhoneNumberRecordsNumber;
      resultMap.put('recipients', recipientsNumber);
      resultMap.put('noMobilePhone', noMobileNumberRecordsNumber);
      resultMap.put('noAnyPhone', noMobileOrPhoneNumberRecordsNumber);
      resultMap.put('records', recordsNumber);
      return JSON.serialize(resultMap);
  }

  /**
  *   userIds - list of Id (User).
  *
  *   Remote Action that return Map with locales for every user Id that were sent as userIds parameter.
  */
  @RemoteAction
  public static String getOwnersLocaleMap(List<String> userIds){
      Map<String, String> idToLocale = new Map<String, String>();
      for(User u : [SELECT id, localesidkey FROM User WHERe Id IN :userIds]){
          idToLocale.put(u.id, u.localesidkey);
      }
      return JSON.serialize(idToLocale);
  }

  /**
  *   recordsLimit - maximum recipients number for selecte LiveTextNumber.
  *   recipientsNumber - number of selected recipients.
  *   sms - message text.
  *
  *   Remote Action that validate sms before send.
  *   Method  accept three parameters.
  */
  @RemoteAction
  public static String smsTextValidation(Integer recordsLimit, Integer recipientsNumber, String sms){
    if(recordsLimit != NULL && recipientsNumber != NULL){
      Map<String, String> validationResultMap = new Map<String, String>();
       if(recordsLimit == 0){
         validationResultMap.put('error', Label.BulkNoPhoneAssignedError);
       }else if(String.isBlank(sms)){
         validationResultMap.put('error', Label.BulkNoSendTextError);
       }else if(recordsLimit < recipientsNumber){
         validationResultMap.put('error', Label.BulkRecordLimitPrefix + ' ' + recordsLimit + ' ' + Label.BulkRecordLimitSuffix);
       }else{
           if(recipientsNumber != 0){
               String recipientsNumberMessage = Label.BulkSendToPrefix + ' ';
               recipientsNumberMessage += recipientsNumber == 1
                                       ? recipientsNumber + ' ' + Label.BulkSendToSuffix
                                       : recipientsNumber + ' ' + Label.BulkSendToSuffixPlural;
               validationResultMap.put('info', recipientsNumberMessage);
           }
       }
       if(!validationResultMap.isEmpty()){
         return JSON.serialize(validationResultMap);
       }
     }
     return NULL;
  }

  /**
  *   recordsLimit - maximum recipients number for selecte LiveTextNumber.
  *   statusesMap - map that contains info about recipients. (For example: have many recipients do not have mobile phone. Or have many duplicates we have.)
  *
  *   Remote Action that used on page load.
  */
  @RemoteAction
  public static String loadingValidation(Integer recordsLimit, Map<String, Integer> statusesMap){
    if(recordsLimit != NULL && !statusesMap.isEmpty() && statusesMap != NULL){
      Map<String, List<String>> validationResultMap = new Map<String, List<String>>();
      if(recordsLimit < statusesMap.get('recipients')){
        String overLimitMessage = Label.BulkRecordLimitPrefix + ' ' + recordsLimit + ' ' + Label.BulkRecordLimitSuffix;
        validationResultMap.put('error', new List<String>{overLimitMessage});
      }else{
        if(statusesMap.get('recipients') != 0){
            String recipientsNumberMessage = statusesMap.get('recipients') == 1
                                    ? statusesMap.get('recipients') + ' ' + Label.BulkRecipientSelectedSuffix
                                    : statusesMap.get('recipients') + ' ' + Label.BulkRecipientsSelectedSuffix;
            validationResultMap.put('info', new List<String>{recipientsNumberMessage});
        }
        if(statusesMap.get('noMobilePhone') != 0){
            String noMobilePhoneMessage = statusesMap.get('noMobilePhone') == 1
                                            //Duplicated lines ahead
                                            ? statusesMap.get('noMobilePhone') + ' ' + Label.BulkNoMobilePhoneSuffix.remove('\\')
                                            : statusesMap.get('noMobilePhone') + ' ' + Label.BulkNoMobilePhoneSuffix.remove('\\');
            if(validationResultMap.containsKey('info')){
              List<String> tempList = validationResultMap.get('info');
              tempList.add(noMobilePhoneMessage);
              validationResultMap.put('info', tempList);
            }

        }
        if(statusesMap.get('noAnyPhone') != 0){
            String noPhoneMessage = statusesMap.get('noAnyPhone') == 1
                                    //Duplicated lines ahead
                                    ? statusesMap.get('noAnyPhone') + ' ' + Label.BulkNoPhoneSuffix.remove('\\')
                                    : statusesMap.get('noAnyPhone') + ' ' + Label.BulkNoPhoneSuffix.remove('\\');
            if(validationResultMap.containsKey('info')){
              List<String> tempList = validationResultMap.get('info');
              tempList.add(noPhoneMessage);
              validationResultMap.put('info', tempList);
            }
        }
      }
      if(!validationResultMap.isEmpty()){
        return JSON.serialize(validationResultMap);
      }
    }
    return NULL;
  }
}