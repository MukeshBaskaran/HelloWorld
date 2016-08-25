/**
* @author
* @company       Heywire
* @date          01/01/2015
* @description   Wrapper class for Account that can be used to avoid problems with Person Accounts.
*
*/
public with sharing class AccountWrapper {
    @TestVisible
    private static final Boolean isPersonAccountsEnabled = checkPersonAccountsEnabled();
    private Account acct;
    private String personMobilePhone = null;
    public AccountWrapper(Account acct) {
        this.acct = acct;
    }
    public String Phone {
        get {
            return acct.Phone;
        }
    }

    public String MobilePhone {
        get {
            if(!PersonAccountsAvailable) return null;
            if(personMobilePhone != null) return personMobilePhone;
            personMobilePhone = (String)acct.get('PersonMobilePhone');
            return personMobilePhone;
        }
    }

    public String Name {
        get {
            return acct.Name;
        }
    }

    @TestVisible
    private static String Columns {
        get {
            return  PersonAccountsAvailable ? 'Id, Phone,PersonMobilePhone,Name' : 'Id, Phone,Name';
        }
    }

    @TestVisible
    private static String InQuery {
        get {
            return  'SELECT ' + Columns + ' FROM Account Where Id IN:recordIds';
        }
    }

    @TestVisible
    private static String EqualsQuery {
        get {
            return  'SELECT ' + Columns + ' FROM Account Where Id =:acctId';
        }
    }

    public static List<AccountWrapper> QueryAccounts(List<Id> recordIds) {
        List<Account> accountObjects = Database.query(InQuery);
        List<AccountWrapper> wrappers = new List<AccountWrapper>();
        for(Account acct : accountObjects) {
            wrappers.add(new AccountWrapper(acct));
        }
        return wrappers;
    }

    public static AccountWrapper QueryAccount(Id acctId) {
        List<Account> accountObjects = Database.query(EqualsQuery);
        if(accountObjects.size() > 0){
            return new AccountWrapper(accountObjects.get(0));
        }
        return null;
    }

    public Boolean IsPersonAccount {
        get{
            return PersonAccountsAvailable && (Boolean)acct.get('IsPersonAccount');
        }
    }

    /**
    * @description Checks to see if Person Accounts are available in current org.
    *
    * @Return      True/False
    **/
     @TestVisible
    private static Boolean checkPersonAccountsEnabled() {
        try {
            // Try to use the isPersonAccount field.
            Account testObject = new Account();
            testObject.get( 'isPersonAccount' );
            // If we got here without an exception, return true.
            return true;
        } catch(Exception ex) {
            // An exception was generated trying to access the isPersonAccount field
            // so person accounts aren't enabled; return false.
            return false;
        }
    }

    /**
    * @description Returns whether or not person accounts are availabe in current org.
    *
    * @Return      True/False
    **/
    public static Boolean PersonAccountsAvailable {
        get {
            return isPersonAccountsEnabled;
        }
    }

    /**
    * @description Returns whether or not given account is a person account.
    *
    * @Return      True/False
    **/
    public Boolean IsPersonAccount() {

        if(!isPersonAccountsEnabled) return false;
        Id accountId = acct.Id;
        List <Account> ipcs =  Database.query('Select IsPersonAccount From Account Where Id =:accountId');
        if(ipcs.size() > 0) {
            Account accountSObj = (Account)ipcs[0];
            if(accountSObj == null) return false;
            Object pa = accountSObj.get('IsPersonAccount');
            if(pa == null) return false;
            return (Boolean)pa == true;
        }
        return false;
    }

    /**
    * @description Returns whether or not given account is a person account.
    *
    * @Return      True/False
    **/
    public static Boolean IsPersonContact(Contact contact) {
        if(!isPersonAccountsEnabled) return false;
        Id contactId = contact.Id;
        List <Contact> ipcs =  Database.query('Select IsPersonAccount From Contact Where Id =:contactId');
        if(ipcs.size() > 0) {
            Contact contactSObj = (Contact)ipcs[0];
            if(contactSObj == null) return false;
            Object pa = contactSObj.get('IsPersonAccount');
            if(pa == null) return false;
            return (Boolean)pa == true;
        }
        return false;
    }
}
