/**
* @author
* @company       Heywire
* @date          01/01/2015
* @description   Test class for AccountWrapper class.
*
*/
@isTest
public with sharing class AccountWrapperTest {

    private static testmethod void Test_checkPersonAccountsEnabled() {
        Test.startTest();
        system.assert(AccountWrapper.checkPersonAccountsEnabled() == false);
        Test.stopTest();
    }
    
    private static testmethod void Test_IsPersonAccount() {
        Test.startTest();
          AccountWrapper testObject = new AccountWrapper(new Account());
          system.assert(testObject.IsPersonAccount() == false);
        Test.stopTest();
    }

    private static testmethod void Test_IsPersonContact() {
        Test.startTest();
        Contact testObject = new Contact();
        system.assert(AccountWrapper.IsPersonContact(testObject) == false);
        Test.stopTest();
    }

    private static testmethod void Test_QueryAccount() {
        Test.startTest();
        List<Account> acctList = [Select Id from Account limit 1];
        if(acctList.size() > 0) {
            Account acc = acctList.get(0);
            AccountWrapper acct = AccountWrapper.QueryAccount(acc.Id);
            system.assert(acct.IsPersonAccount == false);
        }
        Test.stopTest();
    }

    private static testmethod void Test_QueryAccounts() {
        Test.startTest();
        List<Account> acctList = [Select Id from Account limit 2];
        List<Id> ids = new List<Id>();
        for(Account acct : acctList) {
            ids.add(acct.Id);
        }
        List<AccountWrapper> accts = AccountWrapper.QueryAccounts(ids);
        Test.stopTest();
    }

    private static testmethod void Test_Attributes() {
        Test.startTest();
        AccountWrapper acct = new AccountWrapper(new Account());
        String phone = acct.Phone;
        String MobilePhone = acct.MobilePhone;
        String Name = acct.Name;
        String Columns = AccountWrapper.Columns;
        String InQuery = AccountWrapper.InQuery;
        String EqualsQuery = AccountWrapper.EqualsQuery;
        Boolean PersonAccountsAvailable = AccountWrapper.PersonAccountsAvailable;
        Boolean isPersonAccountsEnabled = AccountWrapper.isPersonAccountsEnabled;
        Test.stopTest();
    }

}
