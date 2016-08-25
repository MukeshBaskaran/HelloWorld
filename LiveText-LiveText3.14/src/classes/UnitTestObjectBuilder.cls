@isTest
public class UnitTestObjectBuilder {
    
    public static List<BusinessHours> businessHoursList;
    private static String[] alphaNumericCharacters = new String[]{'0','1','2','3','4','5','6','7','8','9'
            ,'a','b','c','d','e','f','g','h','i','j'
            ,'k','l','m','n','o','p','q','r','s','t'
            ,'u','v','w','x','y','z'};
    private static List<String> firstNames = new List<String> {'Lena','Doris','Louis','Michael','Ann','Carolyn','Faye','Peter',
            'Natasha','Roger','Joe','Fred','Dorothy','Irma','Shawn','Sheryl','Clara',
            'Frank','Jacquelyn','Louis','Jonathan','Ralph','Vincent','Emma','Bobby',
            'Gerald','Curtis','Phillip','Jeff','Paul','Linda','Candace','Juan','Genevieve',
            'Sandra','Lucille','Kirkland','Jacob','Patrick','Lawrence','Geraldine','Louis',
            'Sherri','Angie','Jeannette','Andrew','Cassandra','Claudia','Travis','Joanna',
            'Anthony','Aaron','Rodney','Chris','Todd','Vidal','Dolores','Debra','Joyce',
            'Hilda','Shelia','Christopher','Craig','Carl','Velma','David','Mike','Arthur',
            'Jeanette','Nellie','Manuel','Christina','Peter','David','Jimmy','Harry','Olga',
            'Carl','Molly','Richard','Bertha','Edward','Stephen','Janice','Harold','Ruby',
            'Eunice','Johnny','Edward','Sabrina','Hannah','Ruby','Todd','Bryan','Dolores',
            'Gregory','Samantha','Albert','Alan','Rachel','Eric','Bernice','Marvin','Justin',
            'Kenneth','Naomi','Donald','Raymond','Hannah','Andrew','Jo','Cassandra','William',
            'Joshua','David','Kenneth','Billy'};
    private static List<String> lastNames = new List<String> {'Mahaffey','Kinsella','Stanfield','Tsosie','Troxell','Shilling','Land',
        'Bigler','Kastner','Gwinn','Smalls','Burroughs','Broderick','Yingling','Feder','Ha',
        'New','Floyd','Lefler','Ivey','Cardinal','Tenney','Seger','Mcginn','Mendez','Matteson',
        'Mcmaster','Frisbie','Mcelroy','Ayotte','Everson','Lunsford','Ulrich','Kujawa','Eddins',
        'Palmer','Sines','Palomo','Denison','Babbitt','Santoro','Kellerman','Fortunato',
        'Blake','Salter','Carrington','Squires','Mares','Arbogast','Mcnew','Hairston','Dowden',
        'Hadden','Pack','Martindale','Ngo','Rao','Erdman','Baltazar','Byers','Deitz','Mayle',
        'Condon','Robertson','Wilborn','Ramsey','Mckoy','Corley','Snelling','Wilford','Nevins',
        'Whitacre','Pettiford','Henning','Bidwell','Chiles','Desjardins','Stanton','Kent',
        'Vanwinkle','Bartholomew','English','Farina','Zook','Hyman','Correll','Elson','Speaks',
        'Field','Kushner','Paulin','Driggers','Clanton','Paxton','Hinojosa','Healy','Woodall',
        'Busse','Kingery','Ching','Santacruz','Tyler','Chong','Galindo','Kingston','Pelton',
        'Kyser','Eakin','Fricke','Hillard','Rolfe','Rafferty','Grow','Smart','Held'};
    private static List<String> states = new List<String> {'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID',
        'IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO',
        'MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA',
        'RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'};
    private static List<String> cities = new List<String> {'Atlanta','Norcross', 'Mission Viejo', 'Portola Hills', 'Los Angeles'
            , 'Birmingham', 'Newnan', 'Moreland','West Clarkvale','Daytown','Campbury'
            ,'Hilridge','Bayview','Shakerchester','Hartvale','Huntshart','Stoneplain Estates'
            ,'Portburgh','Bridgewell','Cape Plumgate','Elmmill','Fairville','Glenshore'
            ,'Greater Millley','Hollyhurst','Lake Harborwell','Lower Countrywood'
            ,'Mapleside Terrace','Mount Oakbrook','New Whiteshore','North Riverridge'
            ,'Northmount Heights','Orchard Estates','Orchardgrove Bridge','Point Glenwell'
            ,'Point Lakebourne','Point Pleasanthill','Rosewood','Sheffield Farms','Sheffield Gate'
            ,'Silvervale Chase','South Elmridge','Whiteville','Ashmoss','Belmont Grange'
            ,'Cape Glenview','Devon Village','Downs Trails','Downstree Point','East Chase'
            ,'East Countrygrove','Greater Peachmill','Mist Square','Mount Westmill','North Crossing'
            ,'Northwood','Orchardbrook Manor','Orchardmill','Oxford Creek','Oxford Towers'
            ,'Point Fieldcrest','Radcliffe Chase','Sea Acres','Silver Downs','Spring Acres'
            ,'Westborough','Woodfair','Woodley Creek'};
    private static List<String> streets = new List<String> {'Elm', 'Main', 'Oak', 'Peachtree', 'Akins', 'Teasley', 'Techwood', 'Las Flores'};
    private static List<String> streetTypes = new List<String> {'Rd.', 'Dr.','St.', 'Lane', 'Ave', 'Circle', 'Trace', 'Trail', 'Blv'};

    public static Inbound_Connection_Status__c CreateConnectionStatus(){
        Inbound_Connection_Status__c connStatus = new Inbound_Connection_Status__c(
            Name = Constant.HEYWIRE_STATUS);
        insert connStatus;
        system.assertNotEquals(connStatus.Id,null);
        return connStatus;
    }

    public static ConfigurationSettings__c CreateConfigurationSettings(){
        ConfigurationSettings__c confSettings = new ConfigurationSettings__c(
            Name = Constant.HEYWIRE_CONFIG,
            Account_Id__c = GenerateAlphaNumericString(30),
            Auth_Token__c = GenerateAlphaNumericString(30),
            EndPoint_URL__c = Constant.HEYWIRE_PRODUCTION_URL,
            oAuth_URL__c = Constant.HEYWIRE_PRODUCTION_OAUTH_URL);
        insert confSettings;
         system.assertNotEquals(confSettings.Id,null);
        return confSettings;
    }
    
    public static LiveText_Number__c createLiveTextNumber(){
        LiveText_Number__c liveTextNumber = new LiveText_Number__c(
                                                Name='test support number',
                                                Number__c=GenerateValidFormattedPhoneNumber(),
                                                Chat_End_Message__c='End Chat Message',
                                                Initial_Message__c='Initial Message',
                                                Offline_Hours_Message__c='Offline Message',
                                                Validated__c=false);
        if(businessHoursList == null){
            businessHoursList = getAllBusinessHours();
        }
        liveTextNumber.Business_Hours__c = businessHoursList.get(0).Id;
        liveTextNumber.Show_New_Case_Tab__c = false;
		liveTextNumber.Show_New_Lead_Tab__c = false;
		liveTextNumber.Show_New_Contact_Tab__c = false;
		liveTextNumber.Show_New_Account_Tab__c = false;
		liveTextNumber.Show_New_Opportunity_Tab__c = false;
        
        return liveTextNumber;
    }
    
    private static List<BusinessHours> getAllBusinessHours(){
        return [Select Id, Name From BusinessHours Order By Name LIMIT 100];
    }
    
    public static string GenerateAlphaNumericString(Integer length){
        string AlphaNumericString = '';
        for (integer i = 0 ; i < length ; i++) {
            Integer index = RandomInt(alphaNumericCharacters.size());
            AlphaNumericString += alphaNumericCharacters[index];
        }
        return AlphaNumericString;
    }
    
    public static Integer RandomInt(Integer maxValue){
        Integer index = Math.Mod(Math.Round((Math.Random() * maxValue)),maxValue);
        return index;
    }
    
    public static string GetRandomFirstName(){
        Integer index = Math.Mod(RandomInt(firstNames.size()), firstNames.size());
        return firstNames[index];
    }
    
    public static string GetRandomLastName(){
        Integer index = Math.Mod(RandomInt(lastNames.size()), lastNames.size());
        return lastNames[index];
    }

    public static String GetRandomEmailAddress(){
        String addr = GetRandomFirstName() + '.' + GetRandomLastName() + '@test.com';
        return addr;
    }
    
    public static User createRestrictedUser(){ 
        Profile p = [SELECT Id FROM Profile WHERE Name='Read Only']; 
        //assignObjectPermission(newUser,'Opportunity',true,true,false);
        return CreateUser(p.Id);
    }
    
    public static User createAdminUser(){ 
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        return CreateUser(p.Id);
    }
    
    public static List<PermissionSet> getLTPermissionSets(){
    	List<PermissionSet> PermissionSetList;
    	PermissionSetList =[Select Id, Name, Label From PermissionSet Where Name IN:Constant.LT_PERMISSION_SETS];
    	system.assertNotEquals(PermissionSetList.isEmpty(),false);
    	return PermissionSetList;
    }
    
    public static void assignPermissionSetToUsers(List<User> userList){
    	List<PermissionSet> permissionSetList = [Select Id, Name, Label From PermissionSet Where Name IN:Constant.LT_PERMISSION_SETS];
    	if(!permissionSetList.isEmpty()){
    		List<PermissionSetAssignment> pAssignmentList = new List<PermissionSetAssignment>();
	    	Integer i = 0;
	    	for(User user : userList){
	    		PermissionSetAssignment pAssignment = new PermissionSetAssignment();
	    		pAssignment.AssigneeId = user.Id;
	    		pAssignment.PermissionSetId = permissionSetList.get(i).Id;
	    		i = i>=2?0:i+1;
	    		pAssignmentList.add(pAssignment);
	    	}
	    	insert pAssignmentList;
    	}
    }
    
    public static User CreateUser(Id profileId){
        User u = new User(
            FirstName = GetRandomFirstName()
            , LastName = GetRandomLastName()
            , Username = GetRandomEmailAddress()
            , Email = GetRandomEmailAddress()
            , IsActive = true
            , Alias = 'jdoe'
            , TimeZoneSidKey = 'GMT'
            , LocaleSidKey = 'en_US'
            , EmailEncodingKey = 'ISO-8859-1'
            , LanguageLocaleKey = 'en_US'
            , ProfileId = profileId);
            return u;
    }
    
    public static Associated_Agents__c createAssociatedAgent(Id ltnObjectId, Id userId){
        Associated_Agents__c associatedAgent = new Associated_Agents__c(LiveText_Number__c=ltnObjectId, User__c=userId);
        return associatedAgent;
    }
    
    private static void assignObjectPermission(User u, String objectType, Boolean create, Boolean edit, Boolean remove){
        PermissionSet ps = new PermissionSet(Name = 'Enable' + objectType, Label = 'Enable ' + objectType);
        insert ps;   
        system.assertNotEquals(ps.Id,null);                               
                                            
        ObjectPermissions oPerm = new ObjectPermissions(ParentId = ps.Id,
            PermissionsRead = true,
            PermissionsCreate = create,
            PermissionsEdit = edit,
            PermissionsDelete = remove,
            SObjectType = objectType);
            
        insert oPerm;                                   
         system.assertNotEquals(oPerm.Id,null);           
        PermissionSetAssignment assign = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);                       
        insert assign; 
         system.assertNotEquals(assign.Id,null);                                                  
    }
    
    public static string GenerateValidPhoneNumber(){ 
        String PhoneNumber = '';
        for (integer i = 0 ; i < 10 ; i++) {
            Integer digit = RandomInt(9);

            // Phone numbers cannot begin with a 0 or 1
            if (i == 0 && (digit <= 1)){
                i--;
            } else {
                PhoneNumber += '' + digit;
            }
        }
        return PhoneNumber;
    }
    
    public static string GenerateValidFormattedPhoneNumber(){
        //return '7384204923';
        return PhoneFormatter(GenerateValidPhoneNumber());
    }
    
    public static SMS_Text__c CreateSMSTextRecord(SObject ltnObject, String conversationHeaderId) {
        SMS_Text__c SMSText = new SMS_Text__c();
        if (String.isNotBlank(conversationHeaderId)) {
            SMSText.Conversation_Header__c = conversationHeaderId;
        }
        SMSText.Originating_Number__c = GenerateValidFormattedPhoneNumber();
        SMSText.Support_Number__c = ltnObject.Id;
        
        return SMSText;
    }
    
    public static Conversation_Header__c CreateConversationHeader(String OriginatingNumber, Id liveTextNumberId) {
        Conversation_Header__c conversationHeader = new Conversation_Header__c();
        String phoneNumber = OriginatingNumber.replaceAll('\\D', '');
        phoneNumber = (phoneNumber.startsWith('1')) ? '+' + phoneNumber : '+1' + phoneNumber;
        conversationHeader.Originating_Number__c = phoneNumber;
        conversationHeader.Support_Number__c = liveTextNumberId;
        conversationHeader.Status__c = 'New';
        conversationHeader.ConversationType__c = Constant.ConversationType.Inbound.name();
        return conversationHeader;
    }
    
    public static Conversation_Header__c CreateOutboundConversationHeader(String destinationNumber, Id liveTextNumberId) {
        Conversation_Header__c conversationHeader = new Conversation_Header__c();
        conversationHeader.Originating_Number__c = destinationNumber;
        conversationHeader.Support_Number__c = liveTextNumberId;
        conversationHeader.Status__c = Constant.stage_active;
        conversationHeader.ConversationType__c = Constant.ConversationType.Outbound.name();
        return conversationHeader;
    }
    
    public static Account CreateAccount(String phoneNumber){
        Account testAccount = new Account(
            Phone = phoneNumber
            , Name = GetRandomCompanyName()+String.valueOf(System.Now())
            , BillingStreet = GenerateRandomStreetAddress()
            , BillingCity = GetRandomCity()
            , BillingState = GenerateValidStateCode()
            , BillingPostalCode = GenerateRandomZipCode()
            , ShippingStreet = GenerateRandomStreetAddress()
            , ShippingCity = GetRandomCity()
            , ShippingState = GenerateValidStateCode()
            , ShippingPostalCode = GenerateRandomZipCode()
            );

        return testAccount;
    }
    
    public static string GenerateRandomZipCode(){
        String zip = '';
        for (integer i = 0 ; i < 5 ; i++) {
            Integer digit = RandomInt(9);
            zip += '' + digit;
        }

        return zip;
    }
    
    public static string GenerateValidStateCode() {
        Integer index = RandomInt(states.size());
        return states[index];
    }

    public static string GetRandomCity() {
        Integer index = RandomInt(cities.size());
        return cities[index];
    }
    
    public static string GenerateRandomStreetAddress() {
        integer streetNumber = RandomInt(10000) + 1;

        return '' + streetNumber + ' ' + GetRandomStreetName() + ' ' + GetRandomStreetType();
    }
    
    private static string GetRandomStreetName() {

        Integer index = RandomInt(streets.size());
        return streets[index];
    }

    private static string GetRandomStreetType() {

        Integer index = RandomInt(streetTypes.size());
        return streetTypes[index];
    }
    
    public static Contact CreateContact(Id accountId, String phoneNumber){
        Contact c = new Contact(
            AccountId = accountId
            , Phone = phoneNumber
            , Email = GetRandomEmailAddress()
            , FirstName = GetRandomFirstName()
            , LastName = GetRandomLastName()
            , MailingStreet = GenerateRandomStreetAddress()
            , MailingCity = GetRandomCity()
            , MailingState = GenerateValidStateCode()
            , MailingPostalCode = GenerateRandomZipCode()
            );
        return c;
    }

    public static Contact CreateContactMobile(Id accountId, String phoneNumber){
        Contact c = new Contact(
            AccountId = accountId
            , MobilePhone = phoneNumber
            , Email = GetRandomEmailAddress()
            , FirstName = GetRandomFirstName()
            , LastName = GetRandomLastName()
            , MailingStreet = GenerateRandomStreetAddress()
            , MailingCity = GetRandomCity()
            , MailingState = GenerateValidStateCode()
            , MailingPostalCode = GenerateRandomZipCode()
            );
        return c;
    }
    
    public static Contact CreateContactSimple(String phoneNumber){
        Contact c = new Contact(
              Phone = phoneNumber
            , Email = GetRandomEmailAddress()
            , FirstName = GetRandomFirstName()
            , LastName = GetRandomLastName()
            , MailingStreet = GenerateRandomStreetAddress()
            , MailingCity = GetRandomCity()
            , MailingState = GenerateValidStateCode()
            , MailingPostalCode = GenerateRandomZipCode()
            );
        return c;
    }

    
    
    public static Opportunity CreateOpportunity(Id accId){
    	Opportunity op = new Opportunity(
									 	Name= 'Opportunity'+String.valueOf(System.now()),
										CloseDate = System.today().addDays(5),
										StageName = 'Qualification',
										AccountId = accId);
	    return op;
    }
    
    public static Case CreateCase(Id conId,Id accId){
    	Case caseObj = new Case(
    	ContactId = conID,
    	AccountId = accId,
    	Status = 'Working',
    	Origin = 'Phone'
    	);
		return caseObj;    	
    }
    
    
    public static Lead CreateLead(String phoneNumber) {
        Lead objLead = new Lead();
        objLead.LastName = GetRandomLastName();
        objLead.Company = GetRandomCompanyName()+String.valueOf(System.Now());
        objLead.Status = 'Open - Not Contacted';
        objLead.Phone = phoneNumber;
        return objLead;
    }
    
    public static string GetRandomCompanyName() {
        string company = '';
        integer format = RandomInt(7);
        if (format == 0) {
            company = GetRandomLastName() + ' Limited';
        } else if (format == 1) {
            company = GetRandomCity() + ' Corporate';
        } else if (format == 2) {
            company = 'House of ' + GetRandomCity();
        } else if (format == 3) {
            company = GetRandomLastName() + ' and ' + GetRandomLastName() + ' Brothers';
        } else if (format == 4) {
            company = GetRandomCity() + ' Best';
        } else if (format == 5) {
            company = GetRandomLastName() + ' Estate';
        } else if (format == 6) {
            company = GetRandomCity() + ' Properties';
        } else if (format == 7) {
            company = GetRandomFirstName() + ' ' + GetRandomLastName() + ' Rentals';
        }
        return company;
    }
    
    public static string PhoneFormatter(string phoneNumber){
        if (phoneNumber == null) return null;
        string formatted = '';
        string digitsOnly = '';
        for (integer i = 0 ; i < phoneNumber.length() ; i++){
            string current = phoneNumber.substring(i, i+1);
            if (Pattern.matches('\\d',current)) {
                digitsOnly += current;
            }
        }

        if (digitsOnly.length() != 10) return phoneNumber;

        // We aren't checking the length because it's being checked in the validation rule.
        // This is just to format unformatted phone numbers.
        formatted = '(' + digitsOnly.substring(0,3) + ') ' + digitsOnly.substring(3,6) +  '-' + digitsOnly.substring(6);
        return formatted;
    }
    
  	public static Auto_Linking__c createAutoLinkRecordType(Id ltnObjectId, String recordType)
  	{
  		Auto_Linking__c auto = new Auto_Linking__c(LiveText_Number__c=ltnObjectId, Record_Type__c=recordType);
        return auto;
    }
    
    public static ScreenPopSequence__c createScreenPopSequence(Id ltnObjectId, String recordType, Integer sequence){
    	ScreenPopSequence__c seq = new ScreenPopSequence__c(LiveText_Number__c=ltnObjectId, Record_Type__c=recordType, Sequence__c=sequence);
        return seq;
    }
}