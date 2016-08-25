@isTest
public with sharing class LiveTextOptinStatusControllerTest {

	private static PageReference pageRef = null;
	private static OptInStatus__c obj = null;
	private static LiveTextOptinStatusController controller = null;
    private static SObject ltnObject = null;
    private static User randomUser = null;
    private static Contact conObj = null;
	
	static testmethod void setup(){
		pageRef = Page.LiveTextOptinStatusPage;
		Test.setCurrentPage(pageRef);
        String phoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        String formattedPhNumber = UnitTestObjectBuilder.PhoneFormatter(phoneNumber);
		conObj = UnitTestObjectBuilder.CreateContactSimple(formattedPhNumber);
		insert conObj;
		conObj.mobilephone = formattedPhNumber;
		update conObj;
		System.debug('conobj is '+ conObj);
		ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
		insert ltnObject;
		randomUser = UnitTestObjectBuilder.createRestrictedUser();
		insert randomUser;
		Associated_Agents__c assAgent = UnitTestObjectBuilder.createAssociatedAgent(ltnObject.Id, randomUser.Id);
		insert assAgent;
		obj = new OptinStatus__c(LiveTextNumber__c=String.valueOf(ltnObject.id),Status__c=0,SubscriberPhoneNumber__c=formattedPhNumber);
		insert obj;
	}

	
	static testmethod void setup_optIn(){
		setup();
		ApexPages.currentPage().getParameters().put('optType','1');
		ApexPages.currentPage().getParameters().put('records',String.valueOf(conObj.id));
		ApexPages.currentPage().getParameters().put('retURL','/'+ String.valueOf(conObj.id));
		controller = new LiveTextOptinStatusController(new ApexPages.StandardController(obj));		
	}
	
	static testmethod void setup_optOut(){
		setup();
		ApexPages.currentPage().getParameters().put('optType','0');
		ApexPages.currentPage().getParameters().put('records',String.valueOf(conObj.id));
		ApexPages.currentPage().getParameters().put('retURL','/'+ String.valueOf(conObj.id));		
		controller = new LiveTextOptinStatusController(new ApexPages.StandardController(obj));		
	}
	
	static testmethod void convertOptinType_optin_Test(){
		Test.startTest();
		setup_optIn();
		controller.convertOptinType();
		System.assert(controller.optinTypeInt == 1);
		Test.stopTest();		
	}
	

	static testmethod void getNumbers_Test(){
		Test.startTest();
		setup_optIn();
		System.runAs(randomUser){
			System.assert(!controller.getNumbers().isEmpty());			
		}
		Test.stopTest();		
	}
	
	
	static testmethod void convertOptinType_optout_Test(){
		Test.startTest();
		setup_optOut();
		controller.convertOptinType();
		System.assert(controller.optinTypeInt == 0);
		Test.stopTest();		
	}
	
	static testmethod void init_Test(){
		Test.startTest();
		setup_optIn();
		controller.init();
		List<ApexPages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(ApexPages.Message msg: msgs){
			if(msg.getDetail().contains('1 record(s) have been selected for opt-in'))
				b=true;
		}
		System.assert(b);
		Test.stopTest();
	}
	
	static testmethod void confirm_optin_positive_Test(){
		Test.startTest();
		setup_optIn();
		List<SelectOption> options;
		System.runAs(randomUser){
			options = controller.getNumbers();
		}
		
		PageReference pageObj = controller.doneCustom();
		
		System.debug(pageObj!=null);
		
		String[] numbers = new String[]{};
		
		for(SelectOption option: options){
			numbers.add(option.getValue());
		}
		controller.setLtNumbers(numbers);
		
		System.debug(!controller.getLtNumbers().isEmpty());
		
		controller.Confirm();
		List<ApexPages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(ApexPages.Message msg: msgs){
			if(msg.getDetail().contains('1 record(s) have been opted-in for text messaging.'))
				b=true;
		}
		System.assert(b);
		Test.stopTest();
	}
	
	static testmethod void confirm_optin_negative_Test(){
		Test.startTest();
		setup_optIn();
		List<SelectOption> options;
		System.runAs(randomUser){
			options = controller.getNumbers();
		}
		
		String[] numbers = new String[]{};
		
		for(SelectOption option: options){
			numbers.add(option.getValue());
		}
		controller.Confirm();
		List<ApexPages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(ApexPages.Message msg: msgs){
			if(msg.getDetail().contains('Please select at least one phone number.'))
				b=true;
		}
		System.assert(b);
		Test.stopTest();
	}

	
}