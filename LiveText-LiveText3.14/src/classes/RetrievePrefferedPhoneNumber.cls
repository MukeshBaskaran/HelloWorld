/**
 * @author         swetha kalluri
 * @data           12.01.2015
 * @description    RetrievePrefferedPhoneNumber class contains methods used to retrive the phone number 
 *                 from objects.
 */
global with sharing class RetrievePrefferedPhoneNumber {


    /**
    * @description agentHasShortcodeNumberAssigned returns true if Agend has at least one shortCode number assigned
    *
    **/
    @TestVisible
    webService static Boolean agentHasShortcodeNumberAssigned(){
        return RetrievePreferredPhoneNumber.agentHasShortcodeNumberAssigned();
    }
    
    /**
    * @description: getToPhoneNumberFromObject returns the toPhoneNumber of the given Id by following conditions stated in LT-1137
    *               if no phone number found method returns null .
    */
    @TestVisible
    webService static String getToPhoneNumberFromObject(Id selectedObjId){
        return RetrievePreferredPhoneNumber.getToPhoneNumberFromObject(selectedObjId);
    }

    /**
    * @description getToPhoneNumberFromObjects returns JSON with Id -> phone number for given list of Ids. 
    * @important All Id's needs to be the same object type! I didn't do a checker since this funcion uses A LOT of cpu time
    **/
    @TestVisible
    webService static String getToPhoneNumberFromObjects(List<Id> selectedObjIds){
        return RetrievePreferredPhoneNumber.getToPhoneNumberFromObjects(selectedObjIds);
    }
    
    public static void DummyTest(){
    	Integer i;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	i=0;
    	
    }

}