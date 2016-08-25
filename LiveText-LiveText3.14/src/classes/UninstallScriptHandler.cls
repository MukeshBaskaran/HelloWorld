/**
 * @author        Santosh Gudge (santosh@comitydesigns.com)
 * @company       ComityDesigns
 * @date          08/07/2014
 * @description   UninstallScriptHandler class is executed when package is being uninstalled.
 */
global class UninstallScriptHandler implements UninstallHandler {
  global void onUninstall(UninstallContext ctx) {
    try {
        List < PushTopic >pushTopicList = [SELECT Id, Name FROM PushTopic WHERE Name =: constant.conversation_header_push_topic];
        if (!pushTopicList.isEmpty()) {
            PushTopic pt = new PushTopic(Id=pushTopicList[0].Id, IsActive = false, 
                                         name= (((String.valueof(system.now())).replace('-','')).replace(':','')).replace(' ',''));
            update(pt);
        }
        
         List < PushTopic >pushTopicList2 = [SELECT Id, Name FROM PushTopic WHERE Name =: constant.sms_text_push_topic];
        if (!pushTopicList2.isEmpty()) {
            PushTopic pt2 = new PushTopic(Id=pushTopicList2[0].Id, IsActive = false, 
                                         name= (((String.valueof(system.now().addSeconds(60))).replace('-','')).replace(':','')).replace(' ',''));
            update(pt2);
        }
        
    } catch(exception ex) {
        Messaging.SingleEmailMessage emailTobeSent = new Messaging.SingleEmailMessage();
            list<String> listEmailMembers = new list<String>();
            //remove below code after testing
            listEmailMembers.add(Label.TXT_AdminEmail);
            emailTobeSent.setToAddresses(listEmailMembers);
            emailTobeSent.setSubject('Uninstall exception');
            emailTobeSent.setHtmlBody('Message : ' + ex.getMessage() + 'Line no : ' + ex.getLineNumber() + ' getStackTraceString ' + ex.getStackTraceString() + '' + ex.getCause());
            Messaging.SendEmailResult [] r1 = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailTobeSent});
        
    }
  }
}