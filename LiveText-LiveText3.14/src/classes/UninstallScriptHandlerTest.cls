//All the test methods in this class have access to all data in the organization.
@isTest(SeeAllData=true)
private class UninstallScriptHandlerTest {
 
    static testMethod void UninstallScriptHandler_Test() {
        test.StartTest();
        UninstallScriptHandler uninstall = new UninstallScriptHandler();
        Test.testUninstall(uninstall);
        test.StopTest();
    }
}