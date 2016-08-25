/**
* @author
* @company       Heywire
* @date          01/01/2015
* @description   Test class for ActionResult class.
*
*/
@isTest
public with sharing class ActionResultTest {
    static testmethod void setError_Test() {
        Contact conObj = CommonTestHelper.CreateContact('John','John');
        insert conObj;
        ActionResult obj = new ActionResult(conObj.id);
        System.assert(obj.IsSuccess);
        System.debug(String.valueOf(conObj.id));
        System.debug(String.valueOf(obj.Tag));
        System.assert(String.valueOf(conObj.id).equals(String.valueOf(obj.Tag)));
        obj.SetError('test');
        System.assert(!obj.IsSuccess);
        System.assert(obj.ErrorMessage.equals('test'));
    }
}
