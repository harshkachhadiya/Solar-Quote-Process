public without sharing class ArcadiaApi {
    
    private static Arcadia_Api_Configuration__mdt configuration;
    
    public ArcadiaApi() {
        if (configuration == null) {
            Map<String, Arcadia_Api_Configuration__mdt> configurations = Arcadia_Api_Configuration__mdt.getAll();
            
            if (configurations.isEmpty()) {
                throw new ApplicationException('No Arcadia Api configuration found. Please create an Arcadia_Api_Configuration__mdt record.');
            }

            configuration = configurations.values()[0];
        }
    }

    public HttpRequest publicLses(String urlParameters) {
        return buildRequest('GET', 'public/lses?' + EncodingUtil.urlEncode(urlParameters, 'UTF-8'), null);
    }
    
    public HttpRequest accounts(String payload) {
        return buildRequest('PUT', 'v1/accounts', payload);
    }
    
    public HttpRequest properties(String providerAccountId, String payload) {
        return buildRequest('PUT', 'v1/accounts/pid/' + providerAccountId + '/properties', payload);
    }
    
    public HttpRequest profiles(String payload) {
        return buildRequest('PUT', 'v1/profiles', payload);
    }
    
    public HttpRequest profilesStorage(String payload) {
        return buildRequest('POST', 'v1/profiles/storage', payload);
    }
    
    public HttpRequest typicalBaselines(String urlParameters) {
        return buildRequest('GET', 'v1/typicals/baselines/best?' + EncodingUtil.urlEncode(urlParameters, 'UTF-8'), null);
    }
    
    public HttpRequest calculate(String providerAccountId, String payload) {
        return buildRequest('POST', 'v1/accounts/pid/' + providerAccountId + '/calculate', payload);
    }
    
    public HttpRequest analysis(String payload) {
        return buildRequest('POST', 'v1/accounts/analysis', payload);
    }
    
    public static HttpRequest buildRequest(String method, String relativeEndpoint, String payload) {
        
        HttpRequest request = new HttpRequest();
        
        request.setMethod(method);
        request.setEndpoint(configuration.Base_Endpoint__c + relativeEndpoint);
        request.setTimeout(120000);
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(configuration.Username__c + ':' + configuration.Password__c)));
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