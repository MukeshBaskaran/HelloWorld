public with sharing class SObjectWrapper {
	
	public String ObjectType{get;set;}
	public Long LastModifiedTime{get;set;}
	public String Id{get;set;}
	public String ObjectPrefix{get{return Id.left(3);}} 
	public String ObjectLabel{get;set;}
	public String ObjectName{get;set;}
	
	public SObjectWrapper(SObject obj){
		this.ObjectType = obj.getSObjectType().getDescribe().getName();
		this.LastModifiedTime = ((Datetime)obj.get('LastModifiedDate')).getTime();
        this.Id = (String)obj.get('Id');
        this.ObjectLabel = obj.getSObjectType().getDescribe().getLabel();
        string objectNameField = '500'.equals(ObjectPrefix) 
            ? 'CaseNumber' 
            : '801'.equals(ObjectPrefix) 
            ? 'OrderNumber' 
            : '800'.equals(ObjectPrefix) 
            ? 'ContractNumber' 
            : 'Name';   
        this.ObjectName = (String)obj.get(objectNameField);         
	}
}