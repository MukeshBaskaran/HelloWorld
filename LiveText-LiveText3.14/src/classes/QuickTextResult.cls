public with sharing class QuickTextResult {
	
	public String Name{get;set;}
	public String Message{get;set;}
	
	public QuickTextResult(String name, String message){
		this.Name = name;
		this.Message = message;
	}
}