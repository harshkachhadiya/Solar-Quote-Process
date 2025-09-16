public without sharing class AsyncJobDispatcher implements Callable {
    
    public Object call(String identifier, Map<String, Object> arguments) {
        
        switch on identifier {            
            when 'SolarQuoteProcessHelper.startGeneralProcess' {
                SolarQuoteProcessHelper.startGeneralProcess(
                    (Id) arguments.get('solarQuoteId')
                );                
            }
            
            when 'ArcadiaApiHelper.createAccount' {
                ArcadiaApiHelper.createAccount(
                    (Id) arguments.get('solarQuoteId')
                );                
            }
            
            when 'ArcadiaApiHelper.createSolarProfiles' {
                ArcadiaApiHelper.createSolarProfiles(
                    (Id) arguments.get('solarQuoteId'),
                    (String) arguments.get('financeType')
                );                
            }
            
            when 'ArcadiaApiHelper.getAnalysis' {
                ArcadiaApiHelper.getAnalysis(
                    (Id) arguments.get('solarQuoteId')
                );                
            }
        }
        
        return null;
    }
}