public without sharing class VitlApiHelper {
    
    private static VitlApi vitlApi = new VitlApi();
    
    public static VitlApiWrapper.CitiesResponse getCitiesFromZip(String postalCode) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            request = vitlApi.getCitiesFromZip(postalCode);
            
            Integer statusCode = 200;
            String responseBody = String.isNotBlank(postalCode) ? '{"cities":[{"label":"Test","tier":1}]}' : null;
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                
                VitlApiWrapper.CitiesResponse result = (VitlApiWrapper.CitiesResponse) JSON.deserialize(responseBody, VitlApiWrapper.CitiesResponse.Class);
                
                return result;
                
            } else {
                Logger.error('Bad Response From API').setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        Logger.saveLog();
        
        if(String.isNotBlank(errorMessage)) {
            throw new GenericException(errorMessage);        
        }
        
        return null;
    }
}