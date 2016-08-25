@isTest
private class UpdateCampaignMemberStatusActionTest
{

	static CampaignMemberStatus createStatus(String campId, String label, Boolean isDefault, Boolean responded, Integer i){
        CampaignMemberStatus cs = new CampaignMemberStatus();
        cs.CampaignId = campId;
        cs.Label = label;
        cs.IsDefault = isDefault;
        cs.HasResponded = responded;
        cs.SortOrder = i;
        return cs;
  }

	@testSetup
	static void baseTestSetup()
	{
		/*
		* Creat Account
		*/
		Account newAccount = new Account();
		newAccount.Name = 'MyAccount';
		insert newAccount;
		/*
		* Creat Contacts
		*/
		List<Contact> insertNewContactsList = new List<Contact>();
		for(integer i = 0; i < 10; i++)
		{
			Contact newContact = new Contact();
			newContact.FirstName = 'MyContact'+i;
			newContact.LastName = 'MyContact'+i;
			insertNewContactsList.add(newContact);
		}
		insert insertNewContactsList;
		/*
		* Create Campaign
		*/
		Campaign newCampaign = new Campaign();
		newCampaign.Description = '123';
		newCampaign.Name = 'myCamp';
		insert newCampaign;
		/*
		* Creat CampaignMemberStatus
		*/
		CampaignMemberStatus insertResponedStatus = UpdateCampaignMemberStatusActionTest.createStatus(newCampaign.Id, Label.CampaignResponseTypeResponding, TRUE, TRUE, 11);
		CampaignMemberStatus insertOptOutStatus = UpdateCampaignMemberStatusActionTest.createStatus(newCampaign.Id, Label.CampaignResponseTypeOptOut, FALSE, TRUE, 10);
		List<CampaignMemberStatus> insertStatusList = new List<CampaignMemberStatus>();
		insertStatusList.add(insertResponedStatus);
		insertStatusList.add(insertOptOutStatus);
		insert insertStatusList;
		/*
		* Add Campaign Members to Campaign
		*/
		List<CampaignMember> insertNewCampaignMembersList = new List<CampaignMember>();
		for(Contact item:insertNewContactsList)
		{
			CampaignMember newCampaignMember = new CampaignMember();
			newCampaignMember.ContactId = item.Id;
			newCampaignMember.CampaignId = newCampaign.Id;
			insertNewCampaignMembersList.add(newCampaignMember);
		}
		insert insertNewCampaignMembersList;
		/*
		* Fet Default BusinessHours
		*/
		BusinessHours defaultBussinesHours = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
		/*
		* Create Live Text Number
		*/
		LiveText_Number__c newLiveTextNumber = new LiveText_Number__c();
		newLiveTextNumber.Name = 'Short Code 5 Digits Test';
		newLiveTextNumber.Number__c = '71717';
		newLiveTextNumber.Validated__c = TRUE;
		newLiveTextNumber.Business_Hours__c = defaultBussinesHours.Id;
		insert newLiveTextNumber;
		/*
		* Create Campaign Send
		*/
		Campaign_Send__c newCampaignSend = new Campaign_Send__c();
		newCampaignSend.Campaign__c = newCampaign.Id;
		newCampaignSend.SupportNumber__c = newLiveTextNumber.Id;
		newCampaignSend.ResponseStatus__c =  Label.CampaignResponseTypeResponding;
		newCampaignSend.OptoutStatus__c = Label.CampaignResponseTypeOptOut;
		insert newCampaignSend;
		/*
		* Create Campaign Send Members
		*/
		List<Campaign_Send_Member__c> insertCampaignSendMembersList = new List<Campaign_Send_Member__c>();
		for(CampaignMember item:insertNewCampaignMembersList)
		{
			Campaign_Send_Member__c newCampaignSendMember = new Campaign_Send_Member__c();
			newCampaignSendMember.CampaignMemberId__c = (String)item.Id;
			newCampaignSendMember.CampaignSend__c = newCampaignSend.Id;
			newCampaignSendMember.Phone__c = '73737';
			insertCampaignSendMembersList.add(newCampaignSendMember);
		}
		insert insertCampaignSendMembersList;
	}

	@isTest
	static void itShouldUpdateCampaignMemberStatus()
	{
		List<CampaignMemberUpdateStatus> newCampaignMemberStatusList = new List<CampaignMemberUpdateStatus>();
		for(Campaign_Send_Member__c item:[SELECT Id, CampaignMemberId__c FROM Campaign_Send_Member__c])
		{
			CampaignMemberUpdateStatus newCampaignMemberItem = new CampaignMemberUpdateStatus();
			newCampaignMemberItem.campaignMemberId = item.Id;
			newCampaignMemberItem.responseType = Label.CampaignResponseTypeResponding;
			newCampaignMemberStatusList.add(newCampaignMemberItem);
		}
		newCampaignMemberStatusList[0].responseType = Label.CampaignResponseTypeOptOut;
		Test.startTest();
		UpdateCampaignMemberStatusAction.updateCampaignMemberStatus(newCampaignMemberStatusList);
		Test.stopTest();
		List<CampaignMember> checkCampaignMembersList = new List<CampaignMember>([SELECT Id, Status FROM CampaignMember WHERE Status =:Label.CampaignResponseTypeOptOut]);
		System.AssertEquals(Label.CampaignResponseTypeOptOut, checkCampaignMembersList.get(0).Status);
		checkCampaignMembersList = new List<CampaignMember>([SELECT Id, Status FROM CampaignMember WHERE Status =:Label.CampaignResponseTypeResponding]);
		System.AssertEquals(Label.CampaignResponseTypeResponding, checkCampaignMembersList.get(0).Status);
	}
}