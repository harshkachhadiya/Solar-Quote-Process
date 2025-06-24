@IsTest
public with sharing class VitlApiTest {
    
    @IsTest
    static void getCitiesFromZipTest() {
        
        TestMockCallouts callouts = new TestMockCallouts();
        
        TestMockCallouts.ResponseMock callout = new TestMockCallouts.ResponseMock(
            'https://vitl-api.onrender.com/projects/lightspeed/getCitiesFromZip',
            200,
            '{"cities":[{"label":"Test","tier":1}]}'
        );
        
        callout.setEndpointStartsWithEnabled(true);
        
        callouts.add(callout);
        
        try {
            VitlApiWrapper.CitiesResponse result = VitlApiHelper.getCitiesFromZip(null);
            
        } catch(Exception ex) {
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        
        Test.setMock(HttpCalloutMock.class, callouts);
        
        Test.startTest();
        
        VitlApiWrapper.CitiesResponse result = VitlApiHelper.getCitiesFromZip('111111');
        
        Test.stopTest();
        
        System.assert(!result.cities.isEmpty());
        System.assertEquals('Test', result.cities[0].label);
        System.assertEquals(1, result.cities[0].tier);
    }
}