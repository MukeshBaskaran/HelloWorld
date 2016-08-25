@isTest
public with sharing class LiveTextBulkSmsControllerTest {

	@testSetup
	static void setUp(){
		User adminUser = UnitTestObjectBuilder.createAdminUser();
		insert adminUser;
		Contact conObj = new Contact(LastName='John',FirstName='John');
		conObj.mobilephone = UnitTestObjectBuilder.GenerateValidFormattedPhoneNumber();
		insert conObj;
		RetrievePreferredPhoneNumber.saveToStorage(conObj.Id);
		LiveText_Number__c ltNumberObj = UnitTestObjectBuilder.createLiveTextNumber();
		ltNumberObj.Number__c = Util.NormalizePhoneNumber(ltNumberObj.Number__c);
		insert ltNumberObj;
		Associated_Agents__c insertAssociatedUser = new Associated_Agents__c();
		insertAssociatedUser.User__c = adminUser.Id;
		insertAssociatedUser.LiveText_Number__c = ltNumberObj.Id;
		insert insertAssociatedUser;
	}

	@isTest
	public static void createLiveTextBulkSmsControllerInstance(){
		User adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
        System.runAs(adminUser){
			Conversation_Session__c newConvertsationSessionItem = new Conversation_Session__c();
			LiveTextBulkSmsController newInstanceBulkClass = new LiveTextBulkSmsController(new ApexPages.StandardController(newConvertsationSessionItem));
			System.assertEquals('en_US', newInstanceBulkClass.getLocale());
			System.assertNotEquals(NULL, newInstanceBulkClass);
		}
	}

	@isTest
	public static void getRecipients(){
		String storageId = [SELECT Id FROM Storage__c].get(0).Id;
		String jsonResult = LiveTextBulkSmsController.getRecipients(storageId);
		Map<String, PhoneInformation> newRecipientsResultMap = (Map<String, PhoneInformation>)JSON.deserialize(jsonResult, Map<String, PhoneInformation>.class);
		List<Contact> newContactList = new List<Contact>([SELECT Id, mobilephone FROM Contact]);

		System.assertEquals(1, newContactList.size());
		System.assertEquals(1, newRecipientsResultMap.size());
		System.assertEquals(TRUE, newRecipientsResultMap.containsKey(newContactList.get(0).Id));
		System.assertEquals('Mobile', newRecipientsResultMap.get(newContactList.get(0).Id).phoneType);
		System.assertEquals(newContactList.get(0).mobilephone, newRecipientsResultMap.get(newContactList.get(0).Id).phone);
	}

	@isTest
	public static void getRecipientsEmptyString(){
		System.assertEquals(NULL, LiveTextBulkSmsController.getRecipients(''));
	}

	@isTest
	public static void getRecipientsNull(){
		System.assertEquals(NULL, LiveTextBulkSmsController.getRecipients(NULL));
	}

	@isTest
	public static void getOwnersLocaleMap(){
		User adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
		System.assertEquals('{"'+adminUser.id + '":"en_US"}', LiveTextBulkSmsController.getOwnersLocaleMap(new List<String>{(String) adminUser.id}));
	}

	@isTest
	public static void getNumberStatuses(){
		String storageId = [SELECT Id FROM Storage__c].get(0).Id;
		String jsonResultRecipients = LiveTextBulkSmsController.getRecipients(storageId);
		Map<String, PhoneInformation> newRecipientsResultMap = (Map<String, PhoneInformation>)JSON.deserialize(jsonResultRecipients, Map<String, PhoneInformation>.class);
		String jsonResultPhoneNumberStatuses = LiveTextBulkSmsController.getNumberStatuses(newRecipientsResultMap);
		Map<String, Integer>  newPhoneNumberStatuseResultMap = (Map<String, Integer> )JSON.deserialize(jsonResultPhoneNumberStatuses, Map<String, Integer>.class);

		System.assertEquals(4, newPhoneNumberStatuseResultMap.size());
		System.assertEquals(1, newPhoneNumberStatuseResultMap.get('recipients'));
		System.assertEquals(1, newPhoneNumberStatuseResultMap.get('records'));
		System.assertEquals(0, newPhoneNumberStatuseResultMap.get('noAnyPhone'));
		System.assertEquals(0, newPhoneNumberStatuseResultMap.get('noMobilePhone'));
	}

	@isTest
	public static void getNumberStatusesWithNoMobilePhone(){
		List<Contact> newContactList = new List<Contact>([SELECT Id, mobilephone, phone FROM Contact]);
		newContactList.get(0).phone = newContactList.get(0).mobilephone;
		newContactList.get(0).mobilephone = NULL;
		update newContactList;
		String storageId = [SELECT Id FROM Storage__c].get(0).Id;
		String jsonResultRecipients = LiveTextBulkSmsController.getRecipients(storageId);
		Map<String, PhoneInformation> newRecipientsResultMap = (Map<String, PhoneInformation>)JSON.deserialize(jsonResultRecipients, Map<String, PhoneInformation>.class);
		String jsonResultPhoneNumberStatuses = LiveTextBulkSmsController.getNumberStatuses(newRecipientsResultMap);
		Map<String, Integer>  newPhoneNumberStatuseResultMap = (Map<String, Integer> )JSON.deserialize(jsonResultPhoneNumberStatuses, Map<String, Integer>.class);

		System.assertEquals(4, newPhoneNumberStatuseResultMap.size());
		System.assertEquals(1, newPhoneNumberStatuseResultMap.get('recipients'));
		System.assertEquals(1, newPhoneNumberStatuseResultMap.get('records'));
		System.assertEquals(0, newPhoneNumberStatuseResultMap.get('noAnyPhone'));
		System.assertEquals(1, newPhoneNumberStatuseResultMap.get('noMobilePhone'));
	}

	@isTest
	public static void getNumberStatusesWithNoAnyPhone(){
		List<Contact> newContactList = new List<Contact>([SELECT Id, mobilephone, phone FROM Contact]);
		newContactList.get(0).mobilephone = NULL;
		update newContactList;
		String storageId = [SELECT Id FROM Storage__c].get(0).Id;
		String jsonResultRecipients = LiveTextBulkSmsController.getRecipients(storageId);
		Map<String, PhoneInformation> newRecipientsResultMap = (Map<String, PhoneInformation>)JSON.deserialize(jsonResultRecipients, Map<String, PhoneInformation>.class);
		String jsonResultPhoneNumberStatuses = LiveTextBulkSmsController.getNumberStatuses(newRecipientsResultMap);
		Map<String, Integer>  newPhoneNumberStatuseResultMap = (Map<String, Integer> )JSON.deserialize(jsonResultPhoneNumberStatuses, Map<String, Integer>.class);

		System.assertEquals(4, newPhoneNumberStatuseResultMap.size());
		System.assertEquals(0, newPhoneNumberStatuseResultMap.get('recipients'));
		System.assertEquals(1, newPhoneNumberStatuseResultMap.get('records'));
		System.assertEquals(1, newPhoneNumberStatuseResultMap.get('noAnyPhone'));
		System.assertEquals(0, newPhoneNumberStatuseResultMap.get('noMobilePhone'));
	}

	@isTest
	public static void getPhoneNumbers(){
		User testUser = [SELECT id, name FROM User WHERE Alias = 'jdoe'];
		System.runAs(testUser) {
			Map<String, String> newPhoneNumbersMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.getPhoneNumbers(), Map<String, String>.class);

			System.assertEquals(1, newPhoneNumbersMap.size());
		}
	}

	@isTest
	public static void getActiveLiveTextNumberId(){
		User testUser = [SELECT id, name FROM User WHERE Alias = 'jdoe'];
		Id newLiveTextNumberId = [SELECT Id, Name, Formatted_Support_Number__c FROM LiveText_Number__c].get(0).Id;
		System.runAs(testUser) {
			Map<String, String> newPhoneNumbersMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.getPhoneNumbers(), Map<String, String>.class);
			Id resultId = LiveTextBulkSmsController.getActiveLiveTextNumberId(new List<String>(newPhoneNumbersMap.keySet()));

			System.assertEquals(new List<String>(newPhoneNumbersMap.keySet()).get(0), resultId);
			System.assertEquals(newLiveTextNumberId, resultId);
		}
	}

	@isTest
	public static void getActiveLiveTextNumberIdEmptyList(){
			System.assertEquals(NULL, LiveTextBulkSmsController.getActiveLiveTextNumberId(new List<String>()));
	}

	@isTest
	public static void getActiveLiveTextNumberIdNull(){
			System.assertEquals(NULL, LiveTextBulkSmsController.getActiveLiveTextNumberId(NULL));
	}

	@isTest
	public static void getActiveLiveTextNumberIdWithConversationHeader(){
		Id newLiveTextNumberId = [SELECT Id FROM LiveText_Number__c].get(0).Id;
		Conversation_Header__c newConversationHeaderItem = CommonTestHelper.CreateConversationHeader(Constant.OriginatingNumber, newLiveTextNumberId);
		insert newConversationHeaderItem;

		Id newSupportNumberId = [SELECT LastModifiedDate, Support_Number__r.Id
																															FROM Conversation_Header__c
																															WHERE Support_Number__c != NULL
																															ORDER BY LastModifiedDate DESC LIMIT 1].get(0).Support_Number__c;


		User testUser = [SELECT id, name FROM User WHERE Alias = 'jdoe'];
		System.runAs(testUser) {
			Map<String, String> newPhoneNumbersMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.getPhoneNumbers(), Map<String, String>.class);
			Id resultId = LiveTextBulkSmsController.getActiveLiveTextNumberId(new List<String>(newPhoneNumbersMap.keySet()));

			System.assertEquals(new List<String>(newPhoneNumbersMap.keySet()).get(0), resultId);
			System.assertEquals(newLiveTextNumberId, resultId);
			System.assertEquals(newSupportNumberId, resultId);
		}
	}

	@isTest
	public static void getRecordsNumberLimitLongCode(){
		User testUser = [SELECT id, name FROM User WHERE Alias = 'jdoe'];
		System.runAs(testUser) {
			Map<String, String> newPhoneNumbersMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.getPhoneNumbers(), Map<String, String>.class);
			Id resultId = LiveTextBulkSmsController.getActiveLiveTextNumberId(new List<String>(newPhoneNumbersMap.keySet()));

			System.assertNotEquals(NULL, LiveTextBulkSmsController.getRecordsNumberLimit(resultId));
		}
	}

	@isTest
	public static void getRecordsNumberLimitNull(){
			System.assertEquals(NULL, LiveTextBulkSmsController.getRecordsNumberLimit(NULL));
	}

	@isTest
	public static void getRecordsNumberLimitEmptyString(){
			System.assertEquals(NULL, LiveTextBulkSmsController.getRecordsNumberLimit(''));
	}

	@isTest
	public static void getRecordsNumberLimitShortCode(){
		LiveText_Number__c liveTextNumberShortCode = UnitTestObjectBuilder.createLiveTextNumber();
		liveTextNumberShortCode.Number__c = Util.NormalizePhoneNumber('77777');
		insert liveTextNumberShortCode;

		System.assertEquals(TRUE, Util.IsShortCode(liveTextNumberShortCode.Number__c));
		System.assertNotEquals(NULL, LiveTextBulkSmsController.getRecordsNumberLimit(liveTextNumberShortCode.Id));
	}

	@isTest
	public static void loadingValidationErrorNulls(){
		System.assertEquals(NULL, LiveTextBulkSmsController.loadingValidation(NULL, NULL));
	}

	@isTest
	public static void loadingValidationErrorEmptyMap(){
		System.assertEquals(NULL, LiveTextBulkSmsController.loadingValidation(0, new Map<String, Integer>()));
	}

	@isTest
	public static void loadingValidationError(){
		Map<String, Integer> statuesesMap = new Map<String, Integer>();
		statuesesMap.put('recipients', 100);
		statuesesMap.put('noMobilePhone', 0);
		statuesesMap.put('noAnyPhone', 0);
		statuesesMap.put('records', 100);
		Integer recordsLimit = 10;
		Map<String, List<String>> newValidationMap = (Map<String, List<String>>)JSON.deserialize(LiveTextBulkSmsController.loadingValidation(recordsLimit, statuesesMap), Map<String, List<String>>.class);

		System.assertEquals(TRUE, newValidationMap.containsKey('error'));
		System.assertEquals(1, newValidationMap.size());
		String overLimitMessage = Label.BulkRecordLimitPrefix + ' ' + recordsLimit + ' ' + Label.BulkRecordLimitSuffix;
		System.assertEquals(newValidationMap.values().get(0).get(0), overLimitMessage);
	}

	@isTest
	public static void loadingValidationInfo(){
		Map<String, Integer> statuesesMap = new Map<String, Integer>();
		statuesesMap.put('recipients', 100);
		statuesesMap.put('noMobilePhone', 10);
		statuesesMap.put('noAnyPhone', 10);
		statuesesMap.put('records', 100);
		Integer recordsLimit = 200;
		Map<String, List<String>> newValidationMap = (Map<String, List<String>>)JSON.deserialize(LiveTextBulkSmsController.loadingValidation(recordsLimit, statuesesMap), Map<String, List<String>>.class);

		System.assertEquals(FALSE, newValidationMap.containsKey('error'));
		System.assertEquals(TRUE, newValidationMap.containsKey('info'));
		System.assertEquals(1, newValidationMap.size());
		System.assertEquals(100+' '+Label.BulkRecipientsSelectedSuffix.remove('\\'), newValidationMap.get('info').get(0));
		System.assertEquals(10+' '+Label.BulkNoMobilePhoneSuffix.remove('\\'), newValidationMap.get('info').get(1));
		System.assertEquals(10+' '+Label.BulkNoPhoneSuffix.remove('\\'), newValidationMap.get('info').get(2));
	}
	@isTest
	public static void loadingValidationInfoSingle(){
		Map<String, Integer> statuesesMap = new Map<String, Integer>();
		statuesesMap.put('recipients', 1);
		statuesesMap.put('noMobilePhone', 1);
		statuesesMap.put('noAnyPhone', 1);
		statuesesMap.put('records', 1);
		Integer recordsLimit = 200;
		Map<String, List<String>> newValidationMap = (Map<String, List<String>>)JSON.deserialize(LiveTextBulkSmsController.loadingValidation(recordsLimit, statuesesMap), Map<String, List<String>>.class);

		System.assertEquals(FALSE, newValidationMap.containsKey('error'));
		System.assertEquals(TRUE, newValidationMap.containsKey('info'));
		System.assertEquals(1, newValidationMap.size());
		System.assertEquals(1+' '+Label.BulkRecipientSelectedSuffix.remove('\\'), newValidationMap.get('info').get(0));
		System.assertEquals(1+' '+Label.BulkNoMobilePhoneSuffix.remove('\\'), newValidationMap.get('info').get(1));
		System.assertEquals(1+' '+Label.BulkNoPhoneSuffix.remove('\\'), newValidationMap.get('info').get(2));
	}

	@isTest
	public static void smsTextValidation(){
		System.assertEquals(NULL, LiveTextBulkSmsController.smsTextValidation(NULL, NULL, NULL));
	}

	@isTest
	public static void smsTextValidationSmsNull(){
		Map<String, String> newValidationMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.smsTextValidation(1, 1, NULL), Map<String, String>.class);

		System.assertEquals(TRUE, newValidationMap.containsKey('error'));
		System.assertEquals(FALSE, newValidationMap.containsKey('info'));
		System.assertEquals(Label.BulkNoSendTextError, newValidationMap.get('error'));
	}

	@isTest
	public static void smsTextValidationSmsEmpty(){
		Map<String, String> newValidationMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.smsTextValidation(1, 1, NULL), Map<String, String>.class);

		System.assertEquals(TRUE, newValidationMap.containsKey('error'));
		System.assertEquals(FALSE, newValidationMap.containsKey('info'));
		System.assertEquals(Label.BulkNoSendTextError, newValidationMap.get('error'));
	}

	@isTest
	public static void smsTextValidationLimitError(){
		Integer recordLimit = 1;
		Map<String, String> newValidationMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.smsTextValidation(recordLimit, 10, 'sms'), Map<String, String>.class);

		System.assertEquals(TRUE, newValidationMap.containsKey('error'));
		System.assertEquals(FALSE, newValidationMap.containsKey('info'));
		System.assertEquals(Label.BulkRecordLimitPrefix + ' ' + recordLimit + ' ' + Label.BulkRecordLimitSuffix, newValidationMap.get('error'));
	}

	@isTest
	public static void smsTextValidationSmsNoRecordLimit(){
		Map<String, String> newValidationMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.smsTextValidation(0, 1, NULL), Map<String, String>.class);

		System.assertEquals(TRUE, newValidationMap.containsKey('error'));
		System.assertEquals(FALSE, newValidationMap.containsKey('info'));
		System.assertEquals(Label.BulkNoPhoneAssignedError, newValidationMap.get('error'));
	}

	@isTest
	public static void smsTextValidationInfoSingle(){
		Integer recordsNumber = 1;
		Map<String, String> newValidationMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.smsTextValidation(10, recordsNumber, 'SMS'), Map<String, String>.class);

		System.assertEquals(TRUE, newValidationMap.containsKey('info'));
		System.assertEquals(FALSE, newValidationMap.containsKey('error'));
		System.assertEquals(Label.BulkSendToPrefix+' '+recordsNumber+' '+Label.BulkSendToSuffix, newValidationMap.get('info'));
	}

	@isTest
	public static void smsTextValidationInfoBulk(){
		Integer recordsNumber = 5;
		Map<String, String> newValidationMap = (Map<String, String>)JSON.deserialize(LiveTextBulkSmsController.smsTextValidation(10, recordsNumber, 'SMS'), Map<String, String>.class);

		System.assertEquals(TRUE, newValidationMap.containsKey('info'));
		System.assertEquals(FALSE, newValidationMap.containsKey('error'));
		System.assertEquals(Label.BulkSendToPrefix+' '+recordsNumber+' '+Label.BulkSendToSuffixPlural, newValidationMap.get('info'));
	}

	@isTest
	public static void deleteStorageNull(){
		String oldStorageId = [SELECT Id FROM Storage__c].get(0).Id;
		LiveTextBulkSmsController.deleteStorageRecord(NULL);
		String newStorageId = [SELECT Id FROM Storage__c].get(0).Id;

		System.assertNotEquals(NULL, newStorageId);
		System.assertEquals(oldStorageId, newStorageId);
	}

	@isTest
	public static void deleteStorageEmptyString(){
		String oldStorageId = [SELECT Id FROM Storage__c].get(0).Id;
		LiveTextBulkSmsController.deleteStorageRecord('');
		String newStorageId = [SELECT Id FROM Storage__c].get(0).Id;

		System.assertNotEquals(NULL, newStorageId);
		System.assertEquals(oldStorageId, newStorageId);
	}

	@isTest
	public static void deleteStorage(){
		String storageId = [SELECT Id FROM Storage__c].get(0).Id;
		LiveTextBulkSmsController.deleteStorageRecord(storageId);
		List<Storage__c> newResultList = [SELECT Id FROM Storage__c WHERE Id =:storageId];
		System.assertEquals(TRUE, newResultList.isEmpty());
	}
	@isTest
	public static void sendSMSToListNulls(){
		System.assertEquals(NULL, LiveTextBulkSmsController.sendSMSToList(NULL, NULL, NULL, NULL));
	}

	@isTest
	public static void sendSMSToList(){
		String storageId = [SELECT Id FROM Storage__c].get(0).Id;
		LiveText_Number__c newLiveTextNumber = [SELECT Id, Name, Formatted_Support_Number__c, CreateEvent__c, CreateTask__c FROM LiveText_Number__c];
		newLiveTextNumber.CreateEvent__c = TRUE;
		newLiveTextNumber.CreateTask__c = TRUE;
		update newLiveTextNumber;

		String jsonResultRecipients = LiveTextBulkSmsController.getRecipients(storageId);
		Map<String, PhoneInformation> newRecipientsResultMap = (Map<String, PhoneInformation>)JSON.deserialize(jsonResultRecipients, Map<String, PhoneInformation>.class);
		Map<String, String> newIdtoPhoneResultMap = new Map<String,String>();
		for(String key : newRecipientsResultMap.keySet()){
			newIdtoPhoneResultMap.put(key, newRecipientsResultMap.get(key).phone);
		}
		Map<String, String> resultMap = (Map<String, String> )JSON.deserialize(LiveTextBulkSmsController.sendSMSToList(storageId, newLiveTextNumber.Id, newIdtoPhoneResultMap, 'sms'), Map<String, String>.class);
		System.assertEquals(1, resultMap.size());
		System.assertEquals(TRUE, resultMap.containsKey('info'));
		System.assertEquals(Label.BulkCongrats, resultMap.get('info'));
	}
}