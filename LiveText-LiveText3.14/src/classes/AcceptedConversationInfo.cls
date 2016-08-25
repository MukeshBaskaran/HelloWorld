/**
* @author
* @company       Heywire
* @date          01/01/2015
* @description   It is helper class that are used in ConsoleIntegrationController (GetRelatedObjectsAndAutoLink method).
*                This method create JSON with info about tabs that should be opened (for existing and new objects).
*
*/
public with sharing class AcceptedConversationInfo {

    public Id LiveTextNumberId;
    public String RelatedObjects;
    public String ShowNewObjectsTabsAPINames;
    public String ObjectsTabsAPINames;
    public String DefaultScreenPop;

    /**
    *   liveTextNumber - LiveText_Number__c record.
    *   Constructor method.
    *   This method gets data from liveTextNumber and create JSON for ConsoleIntegrationPage.
    */
    public AcceptedConversationInfo(LiveText_Number__c liveTextNumber) {
        LiveTextNumberId = liveTextNumber.Id;
        DefaultScreenPop = '';

        List<customObjectWrapper> customObjectWrapperList = new List<customObjectWrapper>();
        if(liveTextNumber.New_Custom_Objects_Tabs__c != null) {
            for (String apiName : liveTextNumber.New_Custom_Objects_Tabs__c.split(';')) {
            	customObjectWrapperList.add(new customObjectWrapper(apiName));
            }
        }
        ShowNewObjectsTabsAPINames = JSON.serialize(customObjectWrapperList);
        if(liveTextNumber.Screen_Pop_Default_Record_Type__c != null) {
       		DefaultScreenPop = JSON.serialize(new customObjectWrapper(liveTextNumber.Screen_Pop_Default_Record_Type__c));
      	}
        customObjectWrapperList = new List<customObjectWrapper>();
        for(String apiName : Util.getAllRelationshipObjects()) {
           customObjectWrapperList.add(new customObjectWrapper(apiName));
        }
        ObjectsTabsAPINames = JSON.serialize(customObjectWrapperList);
    }

    /**
    *   Wrapper Class for custom objects.
    *   Wrapper used to standardize object's model.
    */
    public class customObjectWrapper {

        public String   apiName;
        public String   label;
        public String   url;
        public String   iconUrl;
        public Boolean  isCreateable;

        /**
        *   apiName - object api name.
        *   Wrapper Constructor method.
        *   This method populates wrapper class varibles.
        */
        public customObjectWrapper(String apiName) {
          this.apiName = apiName;
          Schema.DescribeSObjectResult dsor = Schema.describeSObjects(new List<String>{apiName})[0];
          this.label = dsor.getLabel();
          this.isCreateable = dsor.isCreateable();
          this.url = new PageReference('/' + dsor.getKeyPrefix() + '/e').getUrl();

          List<Schema.DescribeTabSetResult> tabSetPerApp = Schema.describeTabs();
          Set<Schema.DescribeTabResult> allTabs = new Set<Schema.DescribeTabResult>();

          for(Schema.DescribeTabSetResult tabSet : tabSetPerApp) {
            allTabs.addAll(tabSet.getTabs());
          }

          for(Schema.DescribeTabResult tab : allTabs) {
            if(tab.getSobjectName().equals(apiName)) {
              iconUrl = tab.getMiniIconUrl();
              break;
            }
          }
        }
    }
}
