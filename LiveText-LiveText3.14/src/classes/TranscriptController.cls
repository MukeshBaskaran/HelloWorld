/**
 * @author         Amit Madhoriya(amit@comitydesigns.com)
 * @version        1.0
 * @date           08.19.2014
 * @description   Controller class for the Transcript section displayed below the associated record section in conversation page.. 
 */
public with sharing class TranscriptController {
	
	public String recordId{get;set;}
	public String transcript;
	public List<Conversation_Header__c> convHeaderList;
	public String transcriptLabel{get;set;}
	
   /*returns Conversation Header list*/
    public String ConversationHeaderList {
        get {
        	return JSON.serialize(convHeaderList);
        }
        set;
    }
    
    /*string returns package namespace*/
    public String nameSpace {
        get{
            return util.getNamespace();
        }
        set;
    }
    
	/**
     * @description: Retrieves the conversation header record for the given record id(Account/Contact/Lead/CustomObject). Generates the 
     *				 transcript string in the descending order(Most recent to Oldest) and send it back to page for display.
     * @return List of conversation header records.
     */
	public List<Conversation_Header__c> getConvHeaderList(){
		
		String temprecordId = recordId.replace('\'',''); //LT-834
		convHeaderList = new List<Conversation_Header__c>();
		if(!String.isBlank(temprecordId)){ //LT-835
			List<String> listrecordId = temprecordId.split(',');
			Map<String, String> relationshipMap = Util.getRelationshipMapForConversationHeader();// to change if we start support multi object linking
			String query = 'SELECT Id, Transcript_Summary_1__c, Transcript_Summary_2__c FROM Conversation_Header__c';
			if(Util.getAllRelationshipObjects().size()>0){
				query += ' WHERE ';
				for(String apiName : Util.getAllRelationshipObjects()){
					if(relationshipMap.containsKey(apiName))
					{
						query += relationshipMap.get(apiName)+ ' IN :listrecordId OR ';
					}
				}
				query = query.removeEnd(' OR ');
			}
			query += ' ORDER BY LastModifiedDate DESC LIMIT 1000'; //to prevent apex:repeat having more than 1k records
			convHeaderList = Database.query(query);
		}
		return convHeaderList;
	}
		
}