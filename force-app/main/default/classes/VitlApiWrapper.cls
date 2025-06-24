public with sharing class VitlApiWrapper {
    
    public class CitiesResponse {
        @AuraEnabled public List<CityDetail> cities {get; set;}
    }
    
    public class CityDetail {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public Integer tier {get; set;}
    }
}