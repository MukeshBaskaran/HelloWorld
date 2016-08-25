@isTest
public with sharing class QuickTextControllerTest {

	static testmethod void setUp(){
    }
    static testMethod void QuickText_Test(){
        setUp();
        Test.startTest();
        QuickTextController qtObj = new QuickTextController();
        qtObj.setSearchText('Help Text');
        System.assertEquals('Help Text',  qtObj.getSearchText());      
        qtObj.getResults();
        Test.stopTest();
    }
}