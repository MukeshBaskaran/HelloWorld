/**
 * @author        Prudhvi Kanteti
 * @company       Comity Designs
 * @date          10.03.2014
 * @description   This class implements Schedulable class, Can be used to change ConversationHeader records status
*/
global class ConversationHeaderScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {       
        ConversationHeaderBatch chs = new ConversationHeaderBatch();
        Database.executeBatch(chs,1);       
    }
}