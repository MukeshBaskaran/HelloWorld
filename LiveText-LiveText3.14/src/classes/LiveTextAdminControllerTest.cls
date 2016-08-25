@isTest
private class LiveTextAdminControllerTest {
    
    static Inbound_Connection_Status__c connStatus;
    static ConfigurationSettings__c confSettings;
    static String testAuthToken;
    static String testEmail;
    static List<LiveText_Number__c> ltNumberList;
    static User restrictedUser;
    static User adminUser;
    static String testPhoneNumber;
    static String businessHourId;
    static final String TOO_LONG_STRING = '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'+
    										'1234567890123456789012345678901234567890123456789012345678901234567890';

    static {
        confSettings = UnitTestObjectBuilder.CreateConfigurationSettings();
        connStatus = UnitTestObjectBuilder.CreateConnectionStatus();
    }
    
    static void createAdminUser() {
    	adminUser = UnitTestObjectBuilder.createAdminUser();
    	insert adminUser;
    }
    
    static void initTestData() {
        testAuthToken = UnitTestObjectBuilder.GenerateAlphaNumericString(30);
        testEmail = UnitTestObjectBuilder.GenerateAlphaNumericString(30);
        ltNumberList = new List<LiveText_Number__c>();
        for(Integer i = 0; i < 5; i++) {
            ltNumberList.add(UnitTestObjectBuilder.createLiveTextNumber());
        }
        insert ltNumberList;
        List<User> userList = new List<User>();
        for(Integer i=0; i<2; i++) {
            userList.add(UnitTestObjectBuilder.createAdminUser());
        }
        insert userList;
        UnitTestObjectBuilder.assignPermissionSetToUsers(userList);
        List<Associated_Agents__c> associatedAgentList = new List<Associated_Agents__c>();
        for(User usr : userList) {
        	associatedAgentList.add(UnitTestObjectBuilder.createAssociatedAgent(ltNumberList.get(0).Id, usr.Id));
        }
        insert associatedAgentList;
        restrictedUser = UnitTestObjectBuilder.createRestrictedUser();
        insert restrictedUser;
        testPhoneNumber = UnitTestObjectBuilder.GenerateValidPhoneNumber();
        if (UnitTestObjectBuilder.businessHoursList != null && !UnitTestObjectBuilder.businessHoursList.isEmpty()) {
            businessHourId = UnitTestObjectBuilder.businessHoursList.get(0).Id;
        }
    }
    
    static testMethod void Test_Connect_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_LOOKUP_ACCOUNT, new String[]{'9999999999'});
	        createHtttMockRequest(endPoint, 200, 'OK');
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        System.assertEquals(true, Util.isHeyWireConnected());
	        ltaController.configSettingsObj = confSettings;
	   
	        //call the method to be tested
	        PageReference pageRef = ltaController.connect();
	        ConfigurationSettings__c expectedConfSettings = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
	        System.assertEquals(expectedConfSettings.Account_Id__c, confSettings.Account_Id__c);
	        System.assertEquals(expectedConfSettings.Auth_Token__c, confSettings.Auth_Token__c);
	        System.assertEquals(expectedConfSettings.Endpoint_URL__c, confSettings.Endpoint_URL__c);
	        System.assertEquals(expectedConfSettings.oAuth_URL__c, confSettings.oAuth_URL__c);
	        System.assertEquals(ltaController.oAuthUrl, confSettings.oAuth_URL__c);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_Connect_InvalidCredentials() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        confSettings.Account_Id__c = '';
	        confSettings.Auth_Token__c = '';
	        ltaController.configSettingsObj = confSettings;
	   
	        //call the method to be tested for empty values.
	        PageReference pageRef = ltaController.connect();
	        
	        //call the method to be tested for non-alphanumeric characters.
	        confSettings.Account_Id__c = '!@#5dsfadssfdsadf';
	        pageRef = ltaController.connect();
	        ConfigurationSettings__c expectedConfSettings = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
	        System.assert(expectedConfSettings.Auth_Token__c != testAuthToken);
	        System.assert(expectedConfSettings.Account_Id__c != testEmail);
	        System.assert(expectedConfSettings.Endpoint_URL__c != null);
	        System.AssertEquals(ApexPages.getMessages()[0].getSummary(), System.Label.HeyWireCredentialsRequiredMsg);
	        System.AssertEquals(ApexPages.getMessages()[0].getSeverity(), ApexPages.Severity.ERROR);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_Connect_InvalidHeyWireCredentials() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_LOOKUP_ACCOUNT, new String[]{'9999999999'});
	        createHtttMockRequest(endPoint, 401, 'OK');
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.configSettingsObj = confSettings;
	   
	        //call the method to be tested
	        PageReference pageRef = ltaController.connect();
	        ConfigurationSettings__c expectedConfSettings = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
	        System.assertEquals(expectedConfSettings.Account_Id__c, confSettings.Account_Id__c);
	        System.assertEquals(expectedConfSettings.Auth_Token__c, confSettings.Auth_Token__c);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_Connect_CredentailsLengthLimit() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPoint = confSettings.EndPoint_URL__c + String.format(Constant.HEYWIRE_API_LOOKUP_ACCOUNT, new String[]{'9999999999'});
	        createHtttMockRequest(endPoint, 200, 'OK');
	        confSettings.Account_Id__c = UnitTestObjectBuilder.GenerateAlphaNumericString(255);
	        confSettings.Auth_Token__c = testAuthToken;
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        System.assertEquals(true, Util.isHeyWireConnected());
	        ltaController.configSettingsObj = confSettings;
	   
	        //call the method to be tested
	        PageReference pageRef = ltaController.connect();
	        ConfigurationSettings__c expectedConfSettings = ConfigurationSettings__c.getInstance(Constant.HEYWIRE_CONFIG);
	        System.assert(expectedConfSettings.Account_Id__c != testEmail);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_AddSupportNumber_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        PageReference pageRef = ltaController.addSupportNumber();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayComponent, true);
	        system.assert(ltaController.ltnObject != null);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_EditSupportNumber_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.selectedLtnId = ltNumberList.get(0).Id;
	        PageReference pageRef = ltaController.editSupportNumber();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayComponent, true);
	        system.assert(ltaController.ltnObject != null);
	        system.assertEquals(ltaController.ltnObject.Id, ltaController.selectedLtnId);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_DeleteSupportNumber_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.selectedLtnId = ltNumberList.get(0).Id;
	        PageReference pageRef = ltaController.deleteSupportNumber();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayMessagesOnTop, false);
	        system.assert(ltaController.ltnObject != null);
	        system.assertEquals(ltaController.ltnObject.Id, ltaController.selectedLtnId);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_DeleteSupportNumber_Negative() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.selectedLtnId = ltNumberList.get(0).Id;
	        system.runAs(restrictedUser) {
	            try {
                    PageReference pageRef = ltaController.deleteSupportNumber();
                    system.assertEquals(pageRef, null);
	                system.assertEquals(ltaController.displayMessagesOnTop, false);
	                system.assert(ltaController.ltnObject != null);
	                system.assertEquals(ltaController.ltnObject.Id, ltaController.selectedLtnId);
	                LiveText_Number__c selectedLtnObj = [Select Id From LiveText_Number__c Where Id=:ltaController.selectedLtnId];
	                system.assert(selectedLtnObj != null);
                } catch (Exception ex) {
                    system.assertEquals(ex.getTypeName(), AccessController.CRUDException.class.getName());
                }
	        }
	        Test.stopTest();
    	}
    }
   
   /* static testMethod void Test_SaveSupportNumber_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPointNumber = '1' + testPhoneNumber;
	        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + endPointNumber;
	        createHtttMockRequest(endPoint, 200, 'OK');
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.addSupportNumber();
	        ltaController.ltnObject.put('Number__c', testPhoneNumber);
	        ltaController.ltnObject.put('Name', 'Save Unit Test');
	        ltaController.ltnObject.put('Chat_End_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Initial_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Offline_Hours_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Validated__c', false);
	        ltaController.ltnObject.put('Show_New_Account_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Case_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Contact_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Lead_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Opportunity_Tab__c', false);    
	        ltaController.ltnObject.put('Screen_Pop_Default_Record_Type__c', 'Lead');
	        ltaController.ltnObject.put('Prepend_Country_Code__c', false);
	        ltaController.ltnObject.put('CreateEvent__c', false);
	        ltaController.ltnObject.put('CreateTask__c', true);
	        ltaController.ltnObject.put('Critical_Alert_Time__c', 30);
	        
	        ltaController.criticalAlertTime = '30';
	        	            
	        ltaController.selectedBusinessHour = 'None';
	        ltaController.selectedMembers.add(new SelectOption(restrictedUser.Id, restrictedUser.FirstName));
	        if(String.isNotBlank(businessHourId)) {
	            ltaController.ltnObject.put('Business_Hours__c', businessHourId);
	        }
	        PageReference pageRef = ltaController.save();
	        system.assertEquals(pageRef, null);
	        //system.assertEquals(ltaController.displayComponent, false);
	        //system.assertEquals(ltaController.ltnObject.Id != null, true);
	        
	        Test.stopTest();
    	}
    }
    */
    static testMethod void Test_SaveSupportNumber_InvalidPhoneAndLabel() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.addSupportNumber();
	        ltaController.selectedBusinessHour = businessHourId;
	        PageReference pageRef = ltaController.save();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayComponent, true);
	        system.assertEquals(ltaController.ltnObject.Id == null, true);
	        Test.stopTest();
    	}
    }
    
/*    static testMethod void Test_SaveSupportNumber_InvalidBusinessHoursMsg() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPointNumber = '1' + testPhoneNumber;
	        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + endPointNumber;
	        createHtttMockRequest(endPoint, 200, 'OK');
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.addSupportNumber();
	        ltaController.ltnObject.put('Number__c', testPhoneNumber);
	        ltaController.ltnObject.put('Name', 'Save Unit Test');
	        ltaController.selectedBusinessHour = businessHourId;
	        PageReference pageRef = ltaController.save();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayComponent, true);
	        system.assertEquals(ltaController.ltnObject.Id == null, true);
	        Test.stopTest();
    	}
    }

    static testMethod void Test_SaveSupportNumber_InvalidCriticalAlertTimeMsg() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPointNumber = '1' + testPhoneNumber;
	        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + endPointNumber;
	        createHtttMockRequest(endPoint, 200, 'OK');
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.addSupportNumber();
	        ltaController.ltnObject.put('Number__c', testPhoneNumber);
	        ltaController.ltnObject.put('Name', 'Save Unit Test');
	        ltaController.ltnObject.put('Chat_End_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Initial_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Offline_Hours_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Validated__c', false);
	        ltaController.ltnObject.put('Show_New_Account_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Case_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Contact_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Lead_Tab__c', false);
	        ltaController.ltnObject.put('Show_New_Opportunity_Tab__c', false);    
	        ltaController.ltnObject.put('Screen_Pop_Default_Record_Type__c', 'Lead');
	        ltaController.ltnObject.put('Prepend_Country_Code__c', false);
	        ltaController.ltnObject.put('CreateEvent__c', false);
	        ltaController.ltnObject.put('CreateTask__c', true);
	        ltaController.selectedBusinessHour = 'None';
	        ltaController.selectedMembers.add(new SelectOption(restrictedUser.Id, restrictedUser.FirstName));
	        if(String.isNotBlank(businessHourId)) {
	            ltaController.ltnObject.put('Business_Hours__c', businessHourId);
	        }

	        ltaController.criticalAlertTime = 'NaN';

	        PageReference pageRef = ltaController.save();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayComponent, true);
	        system.assertEquals(ltaController.ltnObject.Id == null, true);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_SaveSupportNumber_AutoResponseMsgLength() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPointNumber = '1' + testPhoneNumber;
	        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + endPointNumber;
	        createHtttMockRequest(endPoint, 200, 'OK');
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.addSupportNumber();
	        ltaController.ltnObject.put('Number__c', testPhoneNumber);
	        ltaController.ltnObject.put('Name', 'Save Unit Test');
	        ltaController.ltnObject.put('Chat_End_Message__c', TOO_LONG_STRING);
	        ltaController.ltnObject.put('Initial_Message__c', TOO_LONG_STRING);
	        ltaController.ltnObject.put('Offline_Hours_Message__c', TOO_LONG_STRING);
	        PageReference pageRef = ltaController.save();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayComponent, true);
	        system.assertEquals(ltaController.ltnObject.Id == null, true);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_SaveSupportNumber_Negative() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        initTestData();
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        String endPointNumber = '1' + testPhoneNumber;
	        String endPoint = confSettings.EndPoint_URL__c + Constant.HEYWIRE_API_GET_PHONE_NUMBER + endPointNumber;
	        createHtttMockRequest(endPoint, 200, 'OK');
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.addSupportNumber();
	        ltaController.ltnObject.put('Number__c', testPhoneNumber);
	        ltaController.ltnObject.put('Name', 'Save Unit Test');
	        ltaController.ltnObject.put('Chat_End_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Initial_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Offline_Hours_Message__c', 'Save Unit Test');
	        ltaController.ltnObject.put('Validated__c', false);
	        if(String.isNotBlank(businessHourId)) {
	            ltaController.ltnObject.put('Business_Hours__c', businessHourId);
	        }
	        system.runAs(restrictedUser) {
	            try {
                    PageReference pageRef = ltaController.save();
                    system.assertEquals(pageRef, null);
	                system.assertEquals(ltaController.displayComponent, true);
	                system.assertEquals(ltaController.ltnObject.Id == null, true);
                } catch (Exception ex) {
                    system.assertEquals(ex.getTypeName(), AccessController.CRUDException.class.getName());
                }
	        }
	        Test.stopTest();
    	}
    }
    */
    
    static testMethod void Test_Cancel_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        PageReference pageRef = ltaController.cancel();
	        system.assertEquals(pageRef, null);
	        system.assertEquals(ltaController.displayComponent, false);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_SearchUsers_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.ltnObject = ltNumberList.get(0);
	        ltaController.searchUserName = restrictedUser.FirstName;
	        ltaController.availableMembers.add(new SelectOption(restrictedUser.Id, restrictedUser.FirstName));
	        PageReference pageRef = ltaController.searchUsers();
	        system.assertEquals(pageRef, null);
	        system.assert(ltaController.selectedMembers.size() == 1);
	        //system.assert(ltaController.availableMembers.size() > 1);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_MoveToRight_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        List<User> userList = new List<User>();
	        for(Integer i=0; i<5; i++) {
	            userList.add(UnitTestObjectBuilder.createAdminUser());
	        }
	        insert userList;
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        List<SelectOption> availableMembers = new List<SelectOption>();
	        for(User user : userList) {
	            availableMembers.add(new SelectOption(user.Id, user.FirstName));
	            ltaController.availableMembersList.add(user.Id);
	        }
	        ltaController.availableMembers = availableMembers;
	        PageReference pageRef =  ltaController.moveToRight();
	        system.assertEquals(pageRef, null);
	        system.assert(ltaController.selectedMembers.size() > 1);
	        system.assert(ltaController.availableMembers.size() == 1);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_MoveToLeft_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        List<User> userList = new List<User>();
	        for(Integer i=0; i<5; i++) {
	            userList.add(UnitTestObjectBuilder.createAdminUser());
	        }
	        insert userList;
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        List<SelectOption> selectedMembers = new List<SelectOption>();
	        for(User user : userList) {
	            selectedMembers.add(new SelectOption(user.Id, user.FirstName));
	            ltaController.selectedMembersList.add(user.Id);
	        }
	        ltaController.selectedMembers = selectedMembers;
	        PageReference pageRef = ltaController.moveToLeft();
	        system.assertEquals(pageRef, null);
	        system.assert(ltaController.selectedMembers.size() == 1);
	        system.assert(ltaController.availableMembers.size() > 1);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_ConnectedToHeywire_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        initTestData();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        PageReference pageRef = ltaController.connectedToHeywire();
	        system.assertEquals(pageRef, null);
	        system.assert(ltaController.sObjList != null);
	        system.assert(ltaController.sObjList.size() > 1);
	        Test.stopTest();
    	}
    }
    
    static testMethod void Test_HandleException_Positive() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        PageReference pageRef = ltaController.addSupportNumber();
	        AccessController.CRUDException ex = new AccessController.CRUDException(LiveText_Number__c.getSObjectType(), AccessController.Operation.OP_INSERT);
	        system.assertEquals(pageRef, null);
	        ltaController.handleException(true, ex);
	        system.assert(ltaController.displayMessagesOnTop);
	        Test.stopTest();
    	}
    }

    static testMethod void Test_MovingRecords() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        system.assertEquals(ltaController.moveSPRecordTypeToRight(), null);
	        system.assertEquals(ltaController.moveSPRecordTypeToLeft(), null);
	        system.assertEquals(ltaController.moveSPRecordTypeUp(), null);
	        system.assertEquals(ltaController.moveSPRecordTypeDown(), null);
	        system.assertEquals(ltaController.moveALRecordTypeToRight(), null);
	        system.assertEquals(ltaController.moveALRecordTypeToLeft(), null);
	        Test.stopTest();
    	}
    }

    static testMethod void Test_SelectedNewTabs() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        ltaController.setSelectedNewTabs(new List<String>{'a','b','c'});
	        List<String> temp = ltaController.getSelectedNewTabs();
	        system.assertEquals(temp[0], 'a');
	        system.assertEquals(temp[1], 'b');
	        system.assertEquals(temp[2], 'c');
	        Test.stopTest();
    	}
    }

    static testMethod void Test_CreateActivityItemsOptions() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        PageReference pageRefVF = Page.LiveTextAdmin;
	        Test.setCurrentPageReference(pageRefVF);
	        LiveTextAdminController ltaController = new LiveTextAdminController();
	        List<SelectOption> so = ltaController.getCreateActivityItemsOptions();
	        system.assertEquals(so[0].getValue(), Util.GLOBAL_DESCRIBE.get(Constant.TASK_OBJECT).getDescribe().getName());
	        system.assertEquals(so[1].getValue(), Util.GLOBAL_DESCRIBE.get(Constant.EVENT_OBJECT).getDescribe().getName());
	        Test.stopTest();
    	}
    }
    
      static testMethod void Test_Dummy() {
    	createAdminUser();
    	system.runAs(adminUser) {
	        Test.startTest();
	        LiveTextAdminController.DummyTest();
	        Test.stopTest();
    	}
    }
    
    static void createHtttMockRequest(String endPoint, Integer code, String status) {
    	HTTPRequestMockTest fakePhNoExistResp = new HTTPRequestMockTest(code, status, null, null);
		Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
		endpoint2TestResp.put(endPoint, fakePhNoExistResp);
		HttpCalloutMock httpRequestCalloutMock = new HTTPRequestMockTest(endpoint2TestResp);
		Test.setMock(HttpCalloutMock.class, httpRequestCalloutMock);
    }
    
}