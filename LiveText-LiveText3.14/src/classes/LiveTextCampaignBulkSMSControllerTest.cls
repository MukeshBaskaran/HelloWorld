@isTest
private class LiveTextCampaignBulkSMSControllerTest {
    static User adminUser;
    static Contact conObj;
    static LiveText_Number__c ltNumberObj;
    //setup methods
    static void createAdminUser(){
        adminUser = UnitTestObjectBuilder.createAdminUser();
        insert adminUser;
    }
    static CampaignMemberStatus createStatus(String campId, String label, Boolean isDefault, Boolean responded, Integer i){
        CampaignMemberStatus cs = new CampaignMemberStatus();
        cs.CampaignId = campId;
        cs.Label = label;
        cs.IsDefault = isDefault;
        cs.HasResponded = responded;
        cs.SortOrder = i;
        return cs;
    }


    static testmethod void campaignMethods_Test(){
        createAdminUser();
        system.runAs(adminUser){
            ltNumberObj = UnitTestObjectBuilder.createLiveTextNumber();
            insert ltNumberObj;
            Associated_Agents__c a = UnitTestObjectBuilder.createAssociatedAgent(ltNumberObj.Id, adminUser.Id);
            insert a;
            Account acc = UnitTestObjectBuilder.CreateAccount('122233334444');
            insert acc;
            List<Lead> leadToAdd = new List<lead>();
            List<Contact> contactsToAdd = new List<Contact>();
            for(Integer i=0; i<=20; i++){
                Lead temp = UnitTestObjectBuilder.CreateLead('1111111' + i);
                leadToAdd.add(temp);
                Contact temp2 = UnitTestObjectBuilder.CreateContactMobile(acc.id, '12342235677');
                contactsToAdd.add(temp2);
            }
            leadToAdd.add(UnitTestObjectBuilder.CreateLead(''));
            insert leadToAdd;
            insert contactsToAdd;
            Campaign camp = new Campaign();
            camp.Name = 'test';
            camp.IsActive = false;
            insert camp;
            List<CampaignMemberStatus> campStatuses = new List<CampaignMemberStatus>();
            campStatuses.add(createStatus(camp.id, 'TestNew', true, false, 3));
            campStatuses.add(createStatus(camp.id, 'TestSent', false, false, 4));
            campStatuses.add(createStatus(camp.id, 'TestResponded', false, true, 5));
            campStatuses.add(createStatus(camp.id, 'TestDuplicate', false, false, 6));
            campStatuses.add(createStatus(camp.id, 'TestOptout', false, true, 7));
            insert campStatuses;
            List<CampaignMember> campMems = new List<CampaignMember>();
            for(Lead l : leadToAdd){
                CampaignMember temp = new CampaignMember();
                temp.LeadId = l.Id;
                temp.CampaignId = camp.Id;
                temp.Status = 'TestNew';
                campMems.add(temp);
            }
            for(Contact c : contactsToAdd){
                CampaignMember temp = new CampaignMember();
                temp.ContactId = c.Id;
                temp.CampaignId = camp.Id;
                temp.Status = 'TestNew';
                campMems.add(temp);
            }
            insert campMems;

            String storageId = RetrievePreferredPhoneNumber.saveToStorage(camp.id);
            PageReference pageRef = new PageReference(Page.LiveTextCampaignBulkSMS+'?storageId='+storageId+'&recordType=Campaign');
            Test.setCurrentPage(pageRef);
            LiveTextCampaignBulkSMSController controller = new LiveTextCampaignBulkSMSController(null);
            controller.init();
            System.assertEquals(controller.storageId, storageId);
            List<String> sendTostatus = New List<String>();
            sendTostatus.add('TestNew');
            System.assertEquals(LiveTextCampaignBulkSMSController.countCampaignMembers(camp.Id, sendTostatus), campMems.size());
            System.assertNotEquals(controller.getCampaignAvailableStatuses(), null);
            System.assertNotEquals(controller.getCampaignRespondedStatuses(), null);
            System.assertNotEquals(controller.getNumbers(), null);
            System.assertEquals(controller.getCampaignShortcodeRecordLimit(), Util.CampaignShortcodeRecordLimit);
            System.assertEquals(controller.getLongcodeRecordLimit(), Util.LongcodeRecordLimit);

            System.assertEquals(LiveTextCampaignBulkSMSController.getCampaignRecordLimitForPhone(ltNumberObj.Id), Util.LongcodeRecordLimit);

            ltNumberObj.Number__c = '51515';
            update ltNumberObj;
            System.assertEquals(LiveTextCampaignBulkSMSController.getCampaignRecordLimitForPhone(ltNumberObj.Id), Util.CampaignShortcodeRecordLimit);

            LiveTextCampaignBulkSMSController.sendSMSToCampaignMembers(ltNumberObj.Id, 'msg', camp.Id, sendTostatus, 'TestSent', 'TestDuplicate', 'TestResponded', 'TestOptout', storageId);
            System.assertNotEquals(LiveTextCampaignBulkSMSController.getInprogressOutBoundBatchCount(), null);
            System.assertEquals(LiveTextCampaignBulkSMSController.getCampaignRecordLimitForPhone(''), 0);
            LiveTextCampaignBulkSMSController.deleteStorageRecord(storageId);
        }
    }
}