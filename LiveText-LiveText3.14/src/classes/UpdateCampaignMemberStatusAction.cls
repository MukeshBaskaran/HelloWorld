global class UpdateCampaignMemberStatusAction {
	@InvocableMethod(label='Update Campaign Member Status' description='Update Campaign Member base on Response Status')
	global static  void updateCampaignMemberStatus(List<CampaignMemberUpdateStatus> items) {
		/**
		* Change List of CampaignMemberUpdateStatus to the Map<CampaignMemberId, Status>
		*/
		Map<Id, String> campaignMemberResponseTypeMap = new Map<Id, String>();
		Map<Id, String> newCampaignMemberStatusMap = new Map<Id, String>();
		List<CampaignMember> updateCampaignMemberList = new List<CampaignMember>();
		for(CampaignMemberUpdateStatus item:items) 
		{
			if(item.responseType != NULL && item.campaignMemberId != NULL) 
			{
				campaignMemberResponseTypeMap.put(item.campaignMemberId, item.responseType);
			}
		}
		List<Campaign_Send_Member__c> campaignSendMemberList = new List<Campaign_Send_Member__c>();
		if(!campaignMemberResponseTypeMap.isEmpty()) 
		{
			campaignSendMemberList =	[	SELECT 	Id, CampaignSend__c, CampaignMemberId__c,
													CampaignSend__r.ErrorStatus__c, CampaignSend__r.OptoutStatus__c,
													CampaignSend__r.ResponseStatus__c, CampaignSend__r.SuccessStatus__c
											FROM 	Campaign_Send_Member__c
											WHERE 	Id IN :campaignMemberResponseTypeMap.keySet() AND CampaignSend__c != NULL
											LIMIT 	50000];
			if(campaignSendMemberList != NULL) 
			{
				for(Campaign_Send_Member__c item :campaignSendMemberList) 
				{
					if(item.CampaignMemberId__c != NULL) {
						String responseType = campaignMemberResponseTypeMap.get(item.Id);
						if(responseType == Label.CampaignResponseTypeResponded && !String.isBlank(item.CampaignSend__r.ResponseStatus__c)) 
						{
							newCampaignMemberStatusMap.put(item.CampaignMemberId__c, item.CampaignSend__r.ResponseStatus__c);
						}
						else if(responseType == Label.CampaignResponseTypeOptOut && !String.isBlank(item.CampaignSend__r.OptoutStatus__c)) 
						{
							newCampaignMemberStatusMap.put(item.CampaignMemberId__c, item.CampaignSend__r.OptoutStatus__c);
						}
					}
				}
			}
			if(!newCampaignMemberStatusMap.isEmpty()) 
			{
				for(CampaignMember item :	[	SELECT Id, Status
												FROM CampaignMember
												WHERE Id IN:newCampaignMemberStatusMap.keySet()]) 
				{
					String status =  newCampaignMemberStatusMap.get(item.Id);
					item.Status = newCampaignMemberStatusMap.get(item.Id);
					updateCampaignMemberList.add(item);
				}
			}
			if(!updateCampaignMemberList.isEmpty())
			{
				try 
				{
					AccessController.updateAsSystem(updateCampaignMemberList);
				} 
				catch(Exception ex) 
				{
                    Util.insertException('updateCMStatus', constant.priority_high, ex.getMessage());
                } 
			}
		}
		
		// Delete all recent campaign members that were just processed
		if(!campaignMemberResponseTypeMap.isEmpty())
		{
			List<Recent_Campaign_Send_Member__c> recentCampaignSendMemberList = [	SELECT 	Id
											FROM 	Recent_Campaign_Send_Member__c
											WHERE 	CampaignSendMember__r.Id IN :campaignMemberResponseTypeMap.keySet()
											LIMIT 	50000];
			if(!recentCampaignSendMemberList.isEmpty())
			{
				try 
				{
					AccessController.deleteAsSystem(recentCampaignSendMemberList);
				} 
				catch(Exception ex) 
				{
                    Util.insertException('updateCMStatus', constant.priority_high, ex.getMessage());
                } 
			}
		}
	}

}