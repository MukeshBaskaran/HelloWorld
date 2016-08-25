/**
 * @author         Amit Madhoriya(amit@comitydesigns.com)
 * @version        1.0
 * @date           08.06.2014
 * @description    This is helper class for Assign user functionality on the admin page. It contain methods to perform followin functionalities, 
 *                 1. Retrieves the already associated agents with the LiveText Number.
 *                 2. Finds the user containing the provided string and not in selected members list.
 *                 3. Removes the agents provided in available members list.
 *                 4. Adds the agents provided in selected members list.
 *                 5. Retrieves the list of first fifty active users with LiveText profiles.
*/
public with sharing class AssignUserHelper {
    private SObject ltnObject;   

    /**
     * @description: Constructor method, used to intialize the LiveText Number Object, object name. 
     * @param: LiveText Number Object.
    */  
    public AssignUserHelper(SObject ltnObject) {
            this.ltnObject = ltnObject;
    }

    /**
     * @description: Retrieves the list of agents already associated to a given LiveText Number object.
     * @return List of SelectOption object, which is displayed in selected member list.
    */
    public List<SelectOption> getSelectedMembers() {
        List<SelectOption> selectedMembers = new List<SelectOption>();
        if(ltnObject != null && ltnObject.Id != null) {
            List<Associated_Agents__c> associcatedAgentList = retrieveAssociatedAgents();
            if(associcatedAgentList != null && !associcatedAgentList.isEmpty()) {
                for(Associated_Agents__c assAgent : associcatedAgentList) {
                    String userName = assAgent.User__r.Name;
                    String userId = assAgent.User__c;
                    selectedMembers.add(new SelectOption(userId, userName));
                }
            }
        }
        return selectedMembers;
    }
    
    /**
     * @description: Searches the user containing the given string but not in selected member list.
     * @param: searchText, user entered string to search the user.
     * @param: selectedMembers, set of already selected member ids.
     * @return List of SelectOption object, which is displayed in available member list.
    */
    public List<SelectOption> findUsersByName(String searchText, Set<String> selectedMembers) {
        List<SelectOption> foundUsers = new List<SelectOption>();
        if(String.isBlank(searchText)) {
            foundUsers = retrieveFirstFiftyUsers(selectedMembers);
        } else {
            List<User> foundUserList = searchUserByName(searchText, selectedMembers);
            for(User foundUser : foundUserList) {
                if(!selectedMembers.contains(foundUser.Id)) {
                    foundUsers.add(new SelectOption(foundUser.Id, foundUser.Name));
                }
            }   
        }
        return foundUsers;
    }
    
    /**
     * @description: Removes the agents given in the selected member list and adds the agents given in the available list.
     * @param: selecteMembersList, set of selected member ids needs to be removed.
     * @param: selecteMembersList, set of available member ids needs to be added.
    */
    public void removeAddAgents(Set<String> selecteMembersList, Set<String> availableMembersList) {
        removeAgents(availableMembersList);
        addAgents(selecteMembersList);
    }
    
    /**
     * @description: Retrieves the list of first fifty active users to be populated in the available member picklist.
     *               with LiveText profiles.
     * @param: selecteMembersList, set of already selected member ids.
    */
    public List<SelectOption> retrieveFirstFiftyUsers(Set<String> selectedMembers) {
        List<SelectOption> userPickList = new List<SelectOption>();
        List<User> userList =   [   SELECT Id, Name 
                                    FROM User 
                                    WHERE IsActive=true 
                                    AND Id IN(
                                                SELECT AssigneeId 
                                                FROM PermissionSetAssignment 
                                                WHERE PermissionSet.Name IN:Constant.LT_PERMISSION_SETS
                                            )
                                    ORDER BY Name LIMIT 50
                                ];
        for(User user : userList) {
            if(!selectedMembers.contains(user.Id)) {
                userPickList.add(new SelectOption(user.Id, user.Name));
            }
        }
        return userPickList;
    }
    
    private List<Associated_Agents__c> retrieveAssociatedAgents() { 
        return [    SELECT Id, Name, User__c, User__r.Name 
                    FROM Associated_Agents__c 
                    WHERE LiveText_Number__c=:this.ltnObject.Id 
                    ORDER BY User__r.Name LIMIT 1000
                ];
    }
    
    private void removeAgents(Set<String> avaiableMembersList) {
        List<Associated_Agents__c> associcatedAgentList = retrieveAssociatedAgents();
        if(associcatedAgentList != null && !associcatedAgentList.isEmpty()) {
            List<Associated_Agents__c> deleteAgentList = new List<SObject>();
            for(Associated_Agents__c assAgent : associcatedAgentList) {
                if(avaiableMembersList.contains(assAgent.User__c)) {
                    deleteAgentList.add(assAgent);
                }
            }
            if(!deleteAgentList.isEmpty()) {
                AccessController.deleteAsUser(deleteAgentList);
            }
        }
    }
    
    private void addAgents(Set<String> selectedMembersList) {
        List<Associated_Agents__c> associcatedAgentList = retrieveAssociatedAgents();
        List<Associated_Agents__c> addAgentList = new List<Associated_Agents__c>();
        if(associcatedAgentList != null && !associcatedAgentList.isEmpty()) {
            Set<Id> existingAgents = new Set<Id>();
            for(Associated_Agents__c assAgent : associcatedAgentList) {
                existingAgents.add(assAgent.User__c);
            }
            for(String userId : selectedMembersList) {
                if(!existingAgents.contains(userId)) {
                    addAgentList.add(createAssociatedAgent(userId));
                }
            }
        } else {
            for(String userId : selectedMembersList) {
                addAgentList.add(createAssociatedAgent(userId));
            }
        }
        
        if(!addAgentList.isEmpty()) {
            AccessController.insertAsUser(addAgentList);
        }
    }
    
    private Associated_Agents__c createAssociatedAgent(String userId) {
        Associated_Agents__c associatedAgent = new Associated_Agents__c();
        associatedAgent.LiveText_Number__c = this.ltnObject.Id;
        associatedAgent.User__c = userId;
        return associatedAgent;
    }
    
    private List<User> searchUserByName(String searchText, Set<String> selectedMembers) {
        searchText = '%' + searchText + '%';
        return [    SELECT Id, Name 
                    FROM User 
                    WHERE IsActive=true 
                    AND Name LIKE:searchText 
                    AND Id IN(
                                SELECT AssigneeId 
                                FROM PermissionSetAssignment 
                                WHERE PermissionSet.Name 
                                IN:Constant.LT_PERMISSION_SETS
                            )
                    ORDER BY Name LIMIT 1000
                ];
    }
}