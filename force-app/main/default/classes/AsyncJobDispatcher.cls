public without sharing class AsyncJobDispatcher implements Callable {
    
    public Object call(String identifier, Map<String, Object> arguments) {
        
        switch on identifier {            
            when 'SolarEstimateProcessHelper.startGeneralProcess' {
                SolarEstimateProcessHelper.startGeneralProcess(
                    (Id) arguments.get('solarEstimateAddressId')
                );                
            }
            
            when 'ArcadiaApiHelper.createAccount' {
                ArcadiaApiHelper.createAccount(
                    (Id) arguments.get('solarEstimateAddressId')
                );                
            }
            
            when 'ArcadiaApiHelper.createSolarProfiles' {
                ArcadiaApiHelper.createSolarProfiles(
                    (Id) arguments.get('solarEstimateAddressId'),
                    (String) arguments.get('financeType')
                );                
            }
            
            when 'ArcadiaApiHelper.getAnalysis' {
                ArcadiaApiHelper.getAnalysis(
                    (Id) arguments.get('solarEstimateAddressId')
                );                
            }
        }
        
        return null;
    }
}