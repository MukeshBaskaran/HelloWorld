public with sharing class PrepObjectCache {
	public PrepObjectCache(){
		String dummyId = 'a0WF000000RACm9MAH';
		List<Account> accts = [Select Id from Account where Id=:dummyId Limit 1];
		List<Contact> contacts = [Select Id from Contact  where Id=:dummyId Limit 1];
		List<Lead> leads = [Select Id from Lead where Id=:dummyId Limit 1];
		List<Opportunity> opps = [Select Id from Opportunity where Id=:dummyId Limit 1];
		List<Case> cases = [Select Id from Case where Id=:dummyId Limit 1];
	}
}