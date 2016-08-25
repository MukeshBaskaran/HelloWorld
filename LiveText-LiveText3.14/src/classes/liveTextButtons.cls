public with sharing class liveTextButtons {

    @AuraEnabled
    public static boolean isCase(Id recordId) {
        if(Schema.Case.SObjectType == recordId.getSobjectType()){
            return true;
        }
        return false;
    }
    
    @AuraEnabled
    public static string optIn(Id recordId) {
        if(recordId != null){
            string returnUrl = '/'+recordId;
            string recordType = '';
            if(Schema.Account.SObjectType == recordId.getSobjectType()){
                recordType = 'account';
            } else if(Schema.Contact.SObjectType == recordId.getSobjectType()){
                recordType = 'contact';
            } else if(Schema.Lead.SObjectType == recordId.getSobjectType()){
                recordType = 'lead';
            }   
            return '/apex/LiveText__LiveTextOptinStatusPage?recordType='+recordType+'&records='+recordId+'&retURL='+returnUrl+'&inConsole=no&optType=1';
        }
        return null;
    }
    
    @AuraEnabled
    public static string optOut(Id recordId) {
        if(recordId != null) {
            string returnUrl = '/'+recordId;
            string recordType = '';
            if(Schema.Account.SObjectType == recordId.getSobjectType()){
                recordType = 'account';
            } else if(Schema.Contact.SObjectType == recordId.getSobjectType()){
                recordType = 'contact';
            } else if(Schema.Lead.SObjectType == recordId.getSobjectType()){
                recordType = 'lead';
            }   
            return '/apex/LiveText__LiveTextOptinStatusPage?recordType='+recordType+'&records='+recordId+'&retURL='+returnUrl+'&inConsole=no&optType=0';
        }
        return null;
    }
    
    @AuraEnabled
    public static string getRecord(Id recordId) {
        if(recordId!= null) {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            string phoneNumber = '';
            string numberType = '';
            string objectPrefix = '';
            
            if(Schema.Contact.SObjectType == recordId.getSobjectType()) {
                Contact contactItem = new Contact();
                for(Contact item:[Select id, phone, mobilePhone, name From Contact Where Id =:recordId]) {
                    contactItem = item;
                }
                
                objectPrefix = string.valueOf(contactItem.id).subString(0,3);
                
                if(contactItem.mobilePhone != null && contactItem.mobilePhone != '') {
                    phoneNumber = contactItem.mobilePhone ;
                    numberType = 'mobile';
                } else {
                    phoneNumber = contactItem.phone;
                    numberType = 'phone';
                }
                //phoneNumber  = phoneNumber.replaceAll('(\\s+)', '');
                string params = '&phone='+phoneNumber +'&phonetype='+numberType +'&oid='+recordId+'&conversationtype=outbound&objectprefix='+objectPrefix;
                string conversationSessionPrefix = '/'+gd.get(string.valueOf(util.getNamespace()+'Conversation_Session__c').toLowerCase()).getDescribe().getKeyPrefix()+'/e?cvid=null'+params;
                
                for(AppMenuItem consoleItem:[ SELECT Id FROM AppMenuItem WHERE Name='LiveText_Console' ]) {
                    return '/console?tsid='+consoleItem.Id+'#'+conversationSessionPrefix;
                }  

            } else if(Schema.Account.SObjectType == recordId.getSobjectType()) {
                Account accountItem = new Account();
                try {
                    string query = 'Select id, phone, PersonMobilePhone, name From Account Where Id =:recordId';
                    for(Account item:database.query(query)) {
                        accountItem = item;
                    }
                    if(accountItem.get('personMobilePhone') != null && accountItem.get('personMobilePhone') != '') {
                        phoneNumber = (string)accountItem.get('personMobilePhone');
                        numberType = 'mobile';
                    } else if(accountItem.phone != null) {
                        phoneNumber = accountItem.phone;
                        numberType = 'phone';
                    }
                } catch(exception ex) {
                    for(Account item:[Select id, phone, name From Account Where Id =:recordId]) {
                        accountItem = item;
                    }
                    if(accountItem.phone != null) {
                        phoneNumber = accountItem.phone;
                        numberType = 'phone';
                    }
                }
                
                objectPrefix = string.valueOf(accountItem.id).subString(0,3);
                //change a0B 
                string params = '&phone='+phoneNumber+'&phonetype='+numberType+'&oid='+recordId+'&conversationtype=outbound&objectprefix='+objectPrefix;
                string conversationSessionPrefix = '/'+gd.get(string.valueOf(util.getNamespace()+'Conversation_Session__c').toLowerCase()).getDescribe().getKeyPrefix()+'/e?cvid=null'+params;
                
                for(AppMenuItem consoleItem:[SELECT Id FROM AppMenuItem WHERE Name='LiveText_Console']){
                    return '/console?tsid='+consoleItem.Id+'#'+conversationSessionPrefix;
                }
                
                
            } else if(Schema.Lead.SObjectType == recordId.getSobjectType()) {
                Lead leadItem = new Lead();
                for(Lead item:[Select id, phone, mobilePhone From Lead Where id=:recordId]) {
                    leadItem = item;
                }
                if(leadItem.mobilePhone != null && leadItem.mobilePhone.trim() != '') {
                    phoneNumber = leadItem.mobilePhone;
                    numberType = 'mobile';
                } else if(leadItem.phone != null) {
                    phoneNumber = leadItem.phone;
                    numberType = 'phone';
                }
                
                objectPrefix = string.valueOf(recordId).subString(0,3);
                //change a0B 
                string params = '&phone='+phoneNumber+'&phonetype='+numberType+'&oid='+recordId+'&conversationtype=outbound&objectprefix='+objectPrefix;
                string conversationSessionPrefix = '/'+gd.get(string.valueOf(util.getNamespace()+'Conversation_Session__c').toLowerCase()).getDescribe().getKeyPrefix()+'/e?cvid=null'+params;
                
                for(AppMenuItem consoleItem:[SELECT Id FROM AppMenuItem WHERE Name='LiveText_Console']){
                    return '/console?tsid='+consoleItem.Id+'#'+conversationSessionPrefix;
                }
                
            }else if(Schema.Case.SObjectType == recordId.getSobjectType()) {
                system.debug('p1');
                Case caseItem = new Case();
                for(Case item:[Select Id, ContactId, Contact.Phone, Contact.MobilePhone, Account.Id, Account.Phone from Case Where id =:recordId]){
                    caseItem = item;
                }
                system.debug('p2');
                if(caseItem.ContactId != null) {
                    system.debug('p3'); 
                    if(caseItem.Contact.MobilePhone != null && caseItem.Contact.Phone.trim() != '') {
                        phoneNumber = caseItem.Contact.MobilePhone;
                        numberType = 'mobile';
                    } else if(caseItem.Contact.Phone != null && caseItem.Contact.Phone.trim() != '') {
                        phoneNumber = caseItem.Contact.Phone;
                        numberType = 'phone';
                    }
                }
                system.debug('p4'); 
                system.debug('nt '+numberType+' cs '+caseItem.Account.Id);
                if(numberType == '' && caseItem.Account.Id != null) {
                    system.debug('p5');
                    try{
                        system.debug('p6');
                        string accountCaseQuery = 'Select id, name, PersonMobilePhone From Account Where id =:caseItem.Account.Id';
                        for(account item:database.query(accountCaseQuery)){
                            if((string)item.get('PersonMobilePhone') != null && (string)item.get('PersonMobilePhone') != '') {
                                phoneNumber = (string)item.get('PersonMobilePhone');
                                numberType = 'mobile';
                            }
                        }   
                    } catch(exception ex) {
                        system.debug('p7');
                        if(caseItem.Account.Phone != null) {
                            phoneNumber = caseItem.Account.Phone;
                            numberType = 'phone';
                        }
                    }
                    
                    system.debug('p8');
                    
                }
                objectPrefix = string.valueOf(recordId).subString(0,3);
                //change a0B 
                string params = '&phone='+phoneNumber+'&phonetype='+numberType+'&oid='+recordId+'&conversationtype=outbound&objectprefix='+objectPrefix;
                string conversationSessionPrefix = '/'+gd.get(string.valueOf(util.getNamespace()+'Conversation_Session__c').toLowerCase()).getDescribe().getKeyPrefix()+'/e?cvid=null'+params;
                        
                for(AppMenuItem consoleItem:[SELECT Id FROM AppMenuItem WHERE Name='LiveText_Console']) {
                    system.debug('p9');
                    return '/console?tsid='+consoleItem.Id+'#'+conversationSessionPrefix;
                }  
               
            }
        }
        return null;
    }

}