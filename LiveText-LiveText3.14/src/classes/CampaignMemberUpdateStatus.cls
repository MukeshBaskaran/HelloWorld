global class CampaignMemberUpdateStatus {
	@InvocableVariable(label='Campaign Member Id' description='Campaign Member	to Update' required=true)
	global Id campaignMemberId;

	@InvocableVariable(label='Response' description='Response Type' required=true)
	global String responseType;
}