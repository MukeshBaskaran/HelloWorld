@isTest
public with sharing class SemaphoreTest {

   static testMethod void sendMessages_Test(){
        Test.startTest();
        Semaphore.Create(constant.SEMAPHORE_SMS_TEXT_TRIGGER_HANDLER);
        Semaphore sem = new Semaphore(constant.SEMAPHORE_SMS_TEXT_TRIGGER_HANDLER);
        sem.Acquire();
        sem.Release();
        Test.stopTest();
    }
    
}