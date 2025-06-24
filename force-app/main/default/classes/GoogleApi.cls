public without sharing class GoogleApi {
    
    private static Google_Api_Configuration__mdt configuration = Google_Api_Configuration__mdt.getAll().values()[0];
    
    public HttpRequest geocode(String address) {
        return call('GET', 'https://maps.googleapis.com/maps/api/geocode/json?address=' + EncodingUtil.urlEncode(address, 'UTF-8'), null);
    }
    
    public HttpRequest buildingInsights(Decimal latitude, Decimal longitude) {
        return call('GET', 'https://solar.googleapis.com/v1/buildingInsights:findClosest'
                    + '?requiredQuality=HIGH'
                    + '&location.latitude=' + latitude
                    + '&location.longitude=' + longitude, null);
    }
    
    public static HttpRequest call(String method, String endpoint, String payload) {
        
        HttpRequest request = new HttpRequest();
        
        request.setMethod(method);
        request.setEndpoint(endpoint + '&key=' + configuration.Api_Key__c);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        
        if((method == 'PUT' || method == 'POST' || method == 'PATCH') && String.isNotBlank(payload)) {
            request.setBody(payload);
        }
        
        return request;
    }
}