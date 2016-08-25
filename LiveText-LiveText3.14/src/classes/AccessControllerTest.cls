/**
* Copyright (c), 2014, Patron Holdings LLC
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
*   are permitted provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice,
*      this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice,
*      this list of conditions and the following disclaimer in the documentation
*      and/or other materials provided with the distribution.
* - Neither the name of the Patron Holdings nor the names of its contributors
*      may be used to endorse or promote products derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
*  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
*  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
*  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
*  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
*  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
*  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

@isTest 
private class AccessControllerTest { 
    
    private static Conversation_Header__c m_ConversationHeader = null;
    private static SMS_Text__c m_SMSText = null;
    private static LiveTextGlobalSettings__c m_LiveTextGlobalSettings = null;
    
    private static void SetUp() {
        m_LiveTextGlobalSettings = new LiveTextGlobalSettings__c();
        m_LiveTextGlobalSettings.GlobalTriggerExecutionEnabled__c = true;
        m_LiveTextGlobalSettings.Active_Status_Purge_Hours__c =0;
        insert m_LiveTextGlobalSettings;
        System.assertNotEquals(m_LiveTextGlobalSettings.Id, null); 
    }
     
    static testMethod void systemInsert() {
        SetUp();
        LiveText_Number__c LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber(); 
        User newUser = ensureRestrictedUser();
        System.runAs(newUser) {
            AccessController.insertAsSystem(new LiveText_Number__c[]{LiveTextNumber});
        } 
    }

    static testMethod void systemUpdate() {
        SetUp();
        LiveText_Number__c LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber(); 
        User newUser = ensureRestrictedUser();
        System.runAs(newUser) {
            AccessController.insertAsSystem(new LiveText_Number__c[]{LiveTextNumber});
        } 
        System.runAs(newUser) {
            LiveTextNumber.Name = 'New Name';
            AccessController.updateAsSystem(new LiveText_Number__c[]{LiveTextNumber});
            LiveText_Number__c LiveTextNumberReload = [SELECT Name FROM LiveText_Number__c WHERE Id = :LiveTextNumber.Id];
            System.assertEquals('New Name', LiveTextNumberReload.Name);
        }
    }
    
    static testMethod void systemUpsert() {
        SetUp();
        LiveText_Number__c LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
        insert LiveTextNumber;
        System.assertNotEquals(LiveTextNumber.Id, null); 
        LiveText_Number__c LiveTextNumberClone = new LiveText_Number__c(Id = LiveTextNumber.Id, Name= 'New Name');
        User newUser = ensureRestrictedUser();
        System.runAs(newUser) {
            AccessController.upsertAsSystem(new LiveText_Number__c[]{LiveTextNumberClone});
            LiveText_Number__c LiveTextNumberReload = [SELECT Name FROM LiveText_Number__c WHERE Id = :LiveTextNumber.Id];
            System.assertEquals('New Name', LiveTextNumberReload.Name);
        }
    }

    static testMethod void systemDelete() {
        SetUp();
        User newUser = ensureRestrictedUser();
        System.runAs(newUser) {
            LiveText_Number__c LiveTextNumber = UnitTestObjectBuilder.createLiveTextNumber();
            insert LiveTextNumber;
            System.assertNotEquals(LiveTextNumber.Id, null); 
            AccessController.deleteAsSystem(new LiveText_Number__c[]{LiveTextNumber});
        }
    }

    private static User ensureRestrictedUser() { 
        Profile p = [   SELECT Id 
                        FROM Profile 
                        WHERE Name='Read Only'
                    ]; 
        User newUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='crudmanageruser1@testorg.com');    
        insert newUser;
        System.assertNotEquals(newUser.Id, null);         
        return newUser;
    }
    
    private static void assignObjectPermission(User u, String objectType, Boolean create, Boolean edit, Boolean remove) {
        PermissionSet ps = new PermissionSet(Name = 'Enable' + objectType, Label = 'Enable ' + objectType);
        insert ps;                                                                      
        ObjectPermissions oPerm = new ObjectPermissions(ParentId = ps.Id,
        PermissionsRead = true,
        PermissionsCreate = create,
        PermissionsEdit = edit,
        PermissionsDelete = remove,
        SObjectType = objectType);   
        insert oPerm;                                   
        System.assertNotEquals(oPerm.Id, null);           
        PermissionSetAssignment assign = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);                       
        insert assign;  
        System.assertNotEquals(assign.Id, null);                                                
    }
}