@isTest
private class CustomLookupControllerTest {

    @isTest static void CustomLookupController_Test() {
        PageReference dummy = Page.CustomLookup;
        dummy.getParameters().put('oldVal', '');
        dummy.getParameters().put('recType', 'Account');
        Test.startTest();
        insert UnitTestObjectBuilder.CreateAccount('');
        Test.setCurrentPage(dummy);
        CustomLookupController controller = new CustomLookupController();
        System.assertEquals(controller.oldselection, '');
        System.assertEquals(controller.objectRecordType ,'Account');
        System.assertEquals(controller.objectPluralLabel , 'Accounts');
        System.assertEquals(controller.parentIdToPassHiddenField ,'AccountId_hidden');
        System.assertEquals(controller.parentNameToPassHiddenField, 'AccountName_hidden');
        Test.stopTest();
    }
    
    @isTest static void doSearch_test() {
        PageReference dummy = Page.CustomLookup;
        dummy.getParameters().put('oldVal', '');
        dummy.getParameters().put('recType', 'Account');
        Test.startTest();
        insert UnitTestObjectBuilder.CreateAccount('');
        Test.setCurrentPage(dummy);
        CustomLookupController controller = new CustomLookupController();
        controller.viewRecenltyViwed = true;
        controller.doSearch();
        System.assertEquals(controller.viewRecenltyViwed, false);
        Test.stopTest();
    }

    @isTest static void doSearchLead_test() {
        PageReference dummy = Page.CustomLookup;
        dummy.getParameters().put('oldVal', '');
        dummy.getParameters().put('recType', 'Lead');
        Test.startTest();
        insert UnitTestObjectBuilder.CreateLead('');
        Test.setCurrentPage(dummy);
        CustomLookupController controller = new CustomLookupController();
        controller.viewRecenltyViwed = true;
        controller.doSearch();
        System.assertEquals(controller.viewRecenltyViwed, false);
        Test.stopTest();
    }

    @isTest static void doSearchOpportunity_test() {
        PageReference dummy = Page.CustomLookup;
        dummy.getParameters().put('oldVal', '');
        dummy.getParameters().put('recType', 'Opportunity');
        Test.startTest();
        Account acc = UnitTestObjectBuilder.CreateAccount('');
        insert acc;
        insert UnitTestObjectBuilder.CreateOpportunity(acc.id);
        Test.setCurrentPage(dummy);
        CustomLookupController controller = new CustomLookupController();
        controller.viewRecenltyViwed = true;
        controller.doSearch();
        System.assertEquals(controller.viewRecenltyViwed, false);
        Test.stopTest();
    }

    @isTest static void onChoose_test() {
        Test.startTest();
        Contact con = UnitTestObjectBuilder.CreateContactSimple('');
        insert con;
        PageReference dummy = Page.CustomLookup;
        dummy.getParameters().put('oldVal', '');
        dummy.getParameters().put('recType', 'Contact');
        Test.setCurrentPage(dummy);
        CustomLookupController controller = new CustomLookupController();
        controller.viewRecenltyViwed = false;
        controller.doSearch();
        System.assert(!controller.sobjectList.isEmpty());
        controller.sobjectIdToPass = con.id;
        controller.onChoose();
        System.assertEquals(controller.sobjectNameToPass, con.FirstName + ' ' + con.LastName);
        Test.stopTest();
    }

    @isTest static void clearSearch_test() {
        PageReference dummy = Page.CustomLookup;
        dummy.getParameters().put('oldVal', '');
        dummy.getParameters().put('recType', 'Case');
        Test.startTest();
        Account acc = UnitTestObjectBuilder.CreateAccount('');
        insert acc;
        Contact con = UnitTestObjectBuilder.CreateContactSimple('');
        insert con;
        insert UnitTestObjectBuilder.CreateCase(con.id, acc.id);
        Test.setCurrentPage(dummy);
        CustomLookupController controller = new CustomLookupController();
        controller.viewRecenltyViwed = false;
        controller.clearSearch();
        System.assertEquals(controller.viewRecenltyViwed, true);
        Test.stopTest();
    }   
}