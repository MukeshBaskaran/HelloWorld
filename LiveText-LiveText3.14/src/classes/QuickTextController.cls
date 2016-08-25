public class QuickTextController {

   String searchText;
   List<QuickTextResult> results;
      
   public String getSearchText() {
      return searchText;
   }

   public void setSearchText(String s) {
      searchText = s;
   }

    public QuickTextController(){
      results = new List<QuickTextResult>();
      
      try{
      String liveTextChannelName = 'LiveText';

         String query = 'SELECT Name,Message,Channel FROM QuickText WHERE Channel includes(:liveTextChannelName) ORDER BY LastModifiedDate';
        List<sObject> objs = Database.query(query);
        for(sObject obj : objs){
          String name = (String)obj.get('Name');
          String message = (String)obj.get('Message');
          results.add(new QuickTextResult(name, message));
        } 
      }
      catch(Exception ex){
        
      }
    }

    public List<QuickTextResult> getResults() {
      return results;
   }

}