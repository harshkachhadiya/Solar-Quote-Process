public without sharing class ArcadiaApi {
    
    private static Arcadia_Api_Configuration__mdt configuration = Arcadia_Api_Configuration__mdt.getAll().values()[0];
    
    public HttpRequest publicLses(String urlParameters) {
        return call('GET', ('public/lses?' + urlParameters).replace(' ', '%20'), null);
    }
    
    public HttpRequest accounts(String payload) {
        return call('PUT', 'v1/accounts', payload);
    }
    
    public HttpRequest properties(String providerAccountId, String payload) {
        return call('PUT', 'v1/accounts/pid/' + providerAccountId + '/properties', payload);
    }
    
    public HttpRequest profiles(String payload) {
        return call('PUT', 'v1/profiles', payload);
    }
    
    public HttpRequest profilesStorage(String payload) {
        return call('POST', 'v1/profiles/storage', payload);
    }
    
    public HttpRequest typicalBaselines(String urlParameters) {
        return call('GET', ('v1/typicals/baselines/best?' + urlParameters).replace(' ', '%20'), null);
    }
    
    public HttpRequest calculate(String providerAccountId, String payload) {
        return call('POST', 'v1/accounts/pid/' + providerAccountId + '/calculate', payload);
    }
    
    public HttpRequest analysis(String payload) {
        return call('POST', 'v1/accounts/analysis', payload);
    }
    
    public static HttpRequest call(String method, String relativeEndpoint, String payload) {
        
        HttpRequest request = new HttpRequest();
        
        request.setMethod(method);
        request.setEndpoint(configuration.Base_Endpoint__c + relativeEndpoint);
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(configuration.Username__c + ':' + configuration.Password__c)));
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        
        if((method == 'PUT' 
            || method == 'POST' 
            || method == 'PATCH') 
           && String.isNotBlank(payload)) 
        {
            request.setBody(payload);
        }
        
        return request;
    }
}