public without sharing class VitlApi {
    
    private static String baseEndpoint = 'https://vitl-api.onrender.com';
    private static String accessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjIiLCJuYW1lIjoiRGFuaWVsIEZlcm9saW5vIiwiZW1haWwiOiJkZmVyb2xpbm9Adml0bHBvd2VyLmNvbSIsImlhdCI6MTcxMTE1MDI5MSwiZXhwIjoxODY4OTM4MjkxfQ.INM7d91gyzBUErfkl32jGaQtpSat3-yMqu9iu9EmkDc';
    
    public HttpRequest getCitiesFromZip(String postalCode) {
        return call('GET', '/projects/lightspeed/getCitiesFromZip?zip=' + EncodingUtil.urlEncode(postalCode, 'UTF-8'), null);
    }
    
    public static HttpRequest call(String method, String relativeEndpoint, String payload) {
        
        HttpRequest request = new HttpRequest();
        
        request.setMethod(method);
        request.setEndpoint(baseEndpoint + relativeEndpoint);
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        
        if((method == 'PUT' || method == 'POST' || method == 'PATCH') && String.isNotBlank(payload)) {
            request.setBody(payload);
        }
        
        return request;
    }
}