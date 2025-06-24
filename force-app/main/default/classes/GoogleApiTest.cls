@IsTest
public with sharing class GoogleApiTest {
    
    @IsTest
    static void getGeocodeTest() {
        
        TestMockCallouts callouts = new TestMockCallouts();
        
        TestMockCallouts.ResponseMock callout = new TestMockCallouts.ResponseMock(
            'https://maps.googleapis.com/maps/api/geocode/json',
            200, 
            '{"results":[{"geometry":{"location":{"lat":1,"lng":1}}}]}'
        );
        
        callout.setEndpointStartsWithEnabled(true);
        
        callouts.add(callout);
        
        try {
            GoogleApiWrapper.Location result = GoogleApiHelper.getGeocode('Test');
            
        } catch(Exception ex) {
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        
        Test.setMock(HttpCalloutMock.class, callouts);
        
        Test.startTest();
        
        GoogleApiWrapper.Location result = GoogleApiHelper.getGeocode('Test');
        
        Test.stopTest();
        
        System.assert(result != null);
    }
    
    @IsTest
    static void buildingInsightsTest() {
        
        TestMockCallouts callouts = new TestMockCallouts();
        
        TestMockCallouts.ResponseMock callout = new TestMockCallouts.ResponseMock(
            'https://solar.googleapis.com/v1/buildingInsights:findClosest',
            200, 
            '{"solarPotential":{"maxSunshineHoursPerYear":10,"maxArrayPanelsCount":10,"carbonOffsetFactorKgPerMwh":10,"maxArrayAreaMeters2":10, "solarPanelConfigs":[{"panelsCount":10,"yearlyEnergyDcKwh":10,"roofSegmentSummaries":[{"panelsCount":10,"pitchDegrees":10,"azimuthDegrees":10}]}]}}'
        );
        
        callout.setEndpointStartsWithEnabled(true);
        
        callouts.add(callout);
        
        try {
            GoogleApiWrapper.BuildingInsightsResponse result = GoogleApiHelper.getBuildingInsights(1, 2);
            
        } catch(Exception ex) {
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        
        Test.setMock(HttpCalloutMock.class, callouts);
        
        Test.startTest();              
        
        GoogleApiWrapper.BuildingInsightsResponse result = GoogleApiHelper.getBuildingInsights(1, 2);
        
        Test.stopTest();
        
        System.assert(result != null);
        System.assert(!result.solarPotential.solarPanelConfigs.isEmpty());
        System.assertEquals(10, result.solarPotential.maxSunshineHoursPerYear);
        System.assertEquals(10, result.solarPotential.maxArrayPanelsCount);
        System.assertEquals(10, result.solarPotential.carbonOffsetFactorKgPerMwh);
        System.assertEquals(10, result.solarPotential.maxArrayAreaMeters2);
        System.assert(!result.solarPotential.solarPanelConfigs[0].roofSegmentSummaries.isEmpty());
        System.assertEquals(10, result.solarPotential.solarPanelConfigs[0].panelsCount);
        System.assertEquals(10, result.solarPotential.solarPanelConfigs[0].yearlyEnergyDcKwh);
        System.assertEquals(10, result.solarPotential.solarPanelConfigs[0].roofSegmentSummaries[0].panelsCount);
        System.assertEquals(10, result.solarPotential.solarPanelConfigs[0].roofSegmentSummaries[0].pitchDegrees);
        System.assertEquals(10, result.solarPotential.solarPanelConfigs[0].roofSegmentSummaries[0].azimuthDegrees);
    }
}