public without sharing class Semaphore {
	
	private String name;
	private Semaphore__c sem;
	
	public Semaphore(String name){
		this.name = name;
	}
	
	
	public static Semaphore__c Create(String name){
		List<Semaphore__c> sems = [Select Name from Semaphore__c where Name =: name];
		if(sems.size() > 0){
			return sems.get(0);
		}
			
		Semaphore__c sem = new Semaphore__c();
	   	sem.Name = name;
	   	AccessController.insertAsUser(new list < Semaphore__c > {sem});
	   	return sem;
	}	
	
	public Boolean Acquire(){
		
		if(sem != null) return true;
		
		try{
			List<Semaphore__c> sems = [Select Name from Semaphore__c where Name =: this.name For Update];
			if(sems.size() > 0){
				sem = sems.get(0);
			}
			
			//sem = new Semaphore__c();
	       //	sem.Name = name;
	       // AccessController.insertAsUser(new list < Semaphore__c > {sem});
	        return true;
		}
		catch(Exception e){
			 Util.insertException('SEMAPHORE', Constant.priority_high, e.getMessage());		
		}
		
		return false;
	}
		
	public void Release(){
		if(sem != null) {
			AccessController.updateAsUser(new list < Semaphore__c > {sem});
			sem = null;
			//AccessController.deleteAsUser(new list < Semaphore__c > {sem});
		}
	}
	
}