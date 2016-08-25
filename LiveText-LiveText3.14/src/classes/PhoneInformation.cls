public with sharing class PhoneInformation {
    public String phone {get;set;}
    public String locale {get;set;}
    public String phoneType {get;set;}
    public String ownerId{get;set;}

	public PhoneInformation(String phone, String locale, String phoneType, String ownerId){
        this.phone = phone;
        this.locale = locale;
        this.phoneType = phoneType;
        this.ownerId = ownerId;
	}
    public PhoneInformation(){}
}