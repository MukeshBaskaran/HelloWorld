/**
 * @author         Santosh Gudge(santosh@comitydesigns.com)
 * @data           08.08.2014
 * @description    LiveTextPicController class contains methods used by the LiveText Chat Panel
 *                 in LiveText for Salesforce application.
 */
global with sharing class LiveTextPicController { 	
    public String imageUrl {get;set;}
 
   /**
    * @description: Controller constructor method, used to intialize the collections, 
    *               variables and load the static data(like object prefixes) for the LiveText page.
    */ 
    public LiveTextPicController(ApexPages.StandardController stdController) {
    }

    /**
     * @description: init method called when page loads to get initial message for auto response.
     */
    public void init() {
    	this.imageUrl = ApexPages.currentPage().getParameters().get('imageurl');
    }
                   
}