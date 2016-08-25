/**
* @author
* @company       Heywire
* @date          01/01/2015
* @description   Test class for AcceptedConversationInfo class.
*
*/
@isTest
public with sharing class AcceptedConversationInfoTest {

    static LiveText_Number__c ltnObject;

    /**
    *   Method create LiveText_Number__c record for Unit Testing.
    *   New LiveText_Number__c record should be created and Id should not be NULL.
    */
    static void initTestData() {
        ltnObject = UnitTestObjectBuilder.createLiveTextNumber();
        insert ltnObject;
        system.assertNotEquals(ltnObject.id, NULL);
    }

    /**
    *   Method tests if Person Account enabled.
    */
    private static testmethod void Test_checkPersonAccountsEnabled() {
        Test.startTest();
        initTestData();
          AcceptedConversationInfo info = new AcceptedConversationInfo(ltnObject);
          AcceptedConversationInfo.customObjectWrapper infoWrapper = new AcceptedConversationInfo.customObjectWrapper('Contact');
        Test.stopTest();
    }
}
