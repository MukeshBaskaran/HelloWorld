@isTest
private class CountryCodeUtilTest {
	
	@isTest 
    static void getCountryCodeForLocale_test() {
		Test.startTest();
        System.assertEquals(null, CountryCodeUtil.getCountryCodeForLocale(''));
        System.assertEquals(null, CountryCodeUtil.getCountryCodeForLocale('abcs'));
        System.assertEquals('+1', CountryCodeUtil.getCountryCodeForLocale('US'));
        System.assertEquals('+1809', CountryCodeUtil.getCountryCodeForLocale('DO'));
        Test.stopTest();
	}
	
	@isTest 
    static void getLocaleForCountryCode_test() {
		Test.startTest();
        System.assertEquals(null, CountryCodeUtil.getLocaleForCountryCode(''));
        System.assertEquals(null, CountryCodeUtil.getLocaleForCountryCode('+878786'));
        System.assertEquals('GB', CountryCodeUtil.getLocaleForCountryCode('+44'));
        System.assertEquals('PR', CountryCodeUtil.getLocaleForCountryCode('1939'));
        Test.stopTest();
	}

    @isTest 
    static void isPhoneFromLocale_test() {
        Test.startTest();
        System.assertEquals(null, CountryCodeUtil.isPhoneFromLocale('', ''));
        System.assertEquals(true, CountryCodeUtil.isPhoneFromLocale('+16176666666', 'US'));
        System.assertEquals(false, CountryCodeUtil.isPhoneFromLocale('+56763764736', 'US'));
        Test.stopTest();
    }

    @isTest 
    static void preparePhoneForBulk_test() {
        Test.startTest();
        System.assertEquals(null, CountryCodeUtil.preparePhoneForBulk(''));
        System.assertEquals('+1656565656', CountryCodeUtil.preparePhoneForBulk('+1 (656) 565-656'));
        System.assertEquals('+16176666666', CountryCodeUtil.preparePhoneForBulk('16176666666'));
        System.assertEquals('+16176666666', CountryCodeUtil.preparePhoneForBulk('(617) 666-6666'));
        System.assertEquals('617', CountryCodeUtil.preparePhoneForBulk('(617)'));
        Test.stopTest();
    }
	
}