public without sharing class GoogleApiWrapper {
    
    public class GeocodeResponse {
        @AuraEnabled public List<GeocodeResponseResult> results {get; set;}
    }
    
    public class GeocodeResponseResult {
        @AuraEnabled public Geometry geometry {get; set;}
    }
    
    public class Geometry {
        @AuraEnabled public Location location {get; set;}
    }
    
    public class Location {
        @AuraEnabled public Decimal lat {get; set;}
        @AuraEnabled public Decimal lng {get; set;}
    }
    
    public class BuildingInsightsResponse {
        @AuraEnabled public SolarPotential solarPotential {get; set;}
    }
    
    public class SolarPotential {
        @AuraEnabled public List<SolarPanelConfig> solarPanelConfigs {get; set;}
        @AuraEnabled public Decimal maxSunshineHoursPerYear { get; set; }
        @AuraEnabled public Decimal maxArrayPanelsCount { get; set; }
        @AuraEnabled public Decimal carbonOffsetFactorKgPerMwh { get; set; }
        @AuraEnabled public Decimal maxArrayAreaMeters2 { get; set;}
    }
    
    public class SolarPanelConfig {
        @AuraEnabled public Integer panelsCount {get; set;}
        @AuraEnabled public Decimal yearlyEnergyDcKwh {get; set;}
        @AuraEnabled public List<RoofSegmentSummary> roofSegmentSummaries {get; set;}
    }
    
    public class RoofSegmentSummary {
        @AuraEnabled public Integer panelsCount {get; set;}
        @AuraEnabled public Decimal pitchDegrees {get; set;}
        @AuraEnabled public Decimal azimuthDegrees {get; set;}
    }
}