public class CustomLookupController {
    public String searchByName { get; set; }
    public String objectLabel { get; set; }
    public String objectPluralLabel { get; set; }
    public String objectRecordType { get; set; }
    public String sobjectIdToPass { get; set; }
    public String sobjectNameToPass { get; set; }
    public String parentIdToPassHiddenField { get; set; }
    public String parentNameToPassHiddenField { get; set; }
    public Boolean viewRecenltyViwed { get; set; }
    public List<SearchObjWrapper> sobjectList { get; set; }
    public Set<String> headers { get; set; }
    public SObject choosenObj { get; set; }
    public String keyPrefix{ get; set; }
    public String objName{ get; set; }

    @TestVisible
    private String oldselection { get; set; }
     
    public CustomLookupController() {
        oldselection = ApexPages.CurrentPage().getParameters().get('oldVal');
        objectRecordType = ApexPages.CurrentPage().getParameters().get('recType');
        List<Schema.DescribeSobjectResult> tempSchema = Schema.describeSObjects(new List<String>{objectRecordType});
        if(!tempSchema.isEmpty()) {
            objectLabel = Schema.describeSObjects(new List<String>{objectRecordType})[0].getLabel();
            objectPluralLabel = Schema.describeSObjects(new List<String>{objectRecordType})[0].getLabelPlural();
        }
        searchByName = oldselection != null ? oldselection : '';
        sobjectList = new List<SearchObjWrapper>();
        headers = new Set<String>();
        doSearch(true);
        parentIdToPassHiddenField = objectRecordType + 'Id_hidden';
        parentNameToPassHiddenField = objectRecordType + 'Name_hidden';
    }

    public void onChoose() {
        Id tempId = (Id) sobjectIdToPass;
        keyPrefix = tempId.getSobjectType().getDescribe().getKeyPrefix();
        objName = tempId.getSobjectType().getDescribe().getName();
        for(SearchObjWrapper temp : sobjectList) {
            if(temp.Id.equals(sobjectIdToPass)) {
                //sobjectNameToPass = keyPrefix.equals('500') ? (String) temp.obj.get('CaseNumber') : (String) temp.obj.get('Name');
                if(objName == Constant.CASE_OBJECT) {
                    sobjectNameToPass = (String) temp.obj.get('CaseNumber');
                }else if(objName == Constant.CONTRACT_OBJECT) {
                    sobjectNameToPass = (String) temp.obj.get('ContractNumber');
                }else if(objName == Constant.ORDER_OBJECT) {
                    sobjectNameToPass = (String) temp.obj.get('OrderNumber');   
                }else {
                    sobjectNameToPass =  (String) temp.obj.get('Name');
                }
                break;
            }
        }
    }

    public PageReference doSearch() {
        return doSearch(false);
    }

    public PageReference clearSearch() {
        return doSearch(true);
    }
    
    public PageReference doSearch(Boolean showRecentlyViewedOnly) {
        viewRecenltyViwed = showRecentlyViewedOnly;
        searchByName = searchByName.replace('*', '%');
        String byName = '%'+String.escapeSingleQuotes(searchByName) + '%';
        //String nameField = objectRecordType.equals(Constant.CASE_OBJECT) ? 'CaseNumber' : 'Name';
        String nameField = 'Name';
        headers.clear();
        List<String> fields = new List<String>();
        if(objectRecordType.equals(Constant.CASE_OBJECT)) {
            fields.add('CaseNumber');
            fields.add('Subject');
            fields.add('Account.Name');
            fields.add('Status');
            headers.add('Case Number');
            headers.add('Subject');
            headers.add('Account Name');
            headers.add('Status');
            nameField = 'CaseNumber';
        } else if(objectRecordType.equals(Constant.ACCOUNT_OBJECT)) {
            fields.add('Name');
            fields.add('Site');
            fields.add('Owner.Alias');
            fields.add('Type');
            headers.add('Name');
            headers.add('Site');
            headers.add('Owner Alias');
            headers.add('Type');
        } else if(objectRecordType.equals(Constant.CONTACT_OBJECT)) {
            fields.add('Name');
            fields.add('Account.Name');
            fields.add('Account.Site');
            headers.add('Name');
            headers.add('Account Name');
            headers.add('Account Site');
        } else if(objectRecordType.equals(Constant.LEAD_OBJECT)) {
            fields.add('Name');
            fields.add('Company');
            headers.add('Name');
            headers.add('Company');
        } else if(objectRecordType.equals(Constant.OPPORTUNITY_OBJECT)) {
            fields.add('Name');
            fields.add('Account.Name');
            fields.add('Account.Site');
            headers.add('Name');
            headers.add('Account Name');
            headers.add('Account Site');
        } else if(objectRecordType.equals(Constant.CONTRACT_OBJECT)) {
            fields.add('ContractNumber');
            fields.add('Owner.Alias');
            headers.add('Contract Number');
            headers.add('Contract Owner Alias');
            nameField = 'ContractNumber';
        } else if(objectRecordType.equals(Constant.ORDER_OBJECT)) {
            fields.add('OrderNumber');
            headers.add('Order Number');
            nameField = 'OrderNumber';
        }
        else {
            fields.add('Name');
            headers.add('Name');
        }
        try{
            Set<Id> keyset;
            if(showRecentlyViewedOnly) {
                keyset = new Map<Id, RecentlyViewed>(   [   SELECT Id 
                                                            FROM RecentlyViewed 
                                                            WHERE Type = :objectRecordType ORDER BY LastViewedDate DESC LIMIT 15
                                                        ]).keySet();
            }
            sobjectList.clear();
            String query = 'SELECT Id, ';
            for(String field : fields){
                query += field + ', ';
            }
            query = query.removeEnd(', ');
            query += ' FROM ' + objectRecordType + ' WHERE ' + nameField + ' LIKE \'' + byName + '\'';
            query += showRecentlyViewedOnly ? ' AND Id IN :keySet ORDER BY LastViewedDate DESC LIMIT 15' : ' ORDER BY LastViewedDate DESC LIMIT 15';
            for(SObject obj : Database.query(query)){
                sobjectList.add(new SearchObjWrapper(obj, fields));
            }
        }catch(Exception ex){
            apexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Illegal Search parameter!'));
        }   
        return null;
    }
    
    public class SearchObjWrapper {
        public SObject obj { get; set; }
        public Id id { get; set; }
        public List<String> columnValues { get; set; }

        public SearchObjWrapper(SObject obj, List<String> fields) {
            this.obj = obj;
            this.id = ((Id) obj.get('Id'));
            columnValues = new List<String>();
            String temp = '';
            for(String field : fields) {
                if(field.contains('.')) {
                    SObject tempSObject = obj.getSObject(field.split('\\.')[0]); 
                    temp = tempSObject != null ? (String) tempSObject.get(field.split('\\.')[1]) : '';
                }
                else {
                    temp = (String) obj.get(field);
                }
                columnValues.add(String.isEmpty(temp) ? '' : temp);
            }
        }
    }
}