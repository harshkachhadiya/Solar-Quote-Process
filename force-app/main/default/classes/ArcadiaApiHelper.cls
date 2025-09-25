public without sharing class ArcadiaApiHelper {
    
    private static ArcadiaApi arcadiaApi = new ArcadiaApi();
    
    @AuraEnabled
    public static void createAccount(Id solarQuoteId) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;

        Solar_Quote__c solarQuote = (Solar_Quote__c) SObjectUtil.getSObjectDetailsById(solarQuoteId);
        
        try {
            
            if(solarQuote.Failed_Solar_Quote_Process__c) {
                return;
            }
            
            ArcadiaApiWrapper.Address address = new ArcadiaApiWrapper.Address();
            address.addressString = solarQuote.Address__c;
            
            ArcadiaApiWrapper.PropertyInput customerClass = new ArcadiaApiWrapper.PropertyInput();
            customerClass.keyName = 'customerClass';
            customerClass.dataValue = '1';
            
            ArcadiaApiWrapper.CreateAccountProperty property = new ArcadiaApiWrapper.CreateAccountProperty();
            property.customerClass = customerClass;
            
            ArcadiaApiWrapper.CreateAccountRequest apiPayload = new ArcadiaApiWrapper.CreateAccountRequest();
            apiPayload.providerAccountId = solarQuote.Provider_Account_Id__c;
            apiPayload.accountName = solarQuote.Provider_Account_Id__c;
            apiPayload.address = address;
            apiPayload.properties = property;
            
            request = arcadiaApi.accounts(JSON.serialize(apiPayload, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"providerProfileId":"Test","tariffs":[{"masterTariffId":"Test","tariffName":"Test","tariffCode":"Test"}]}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 
               || statusCode == 201) 
            {
                ArcadiaApiWrapper.CreateAccountResponse apiResponse = (ArcadiaApiWrapper.CreateAccountResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateAccountResponse.Class);
                
                if(apiResponse.status == 'Success') {
                    
                    solarQuote.Account_Id__c = apiResponse.results[0].accountId;
                    solarQuote.Master_Tariff_Id__c = apiResponse.results[0].tariffs[0].masterTariffId;
                    solarQuote.Tariff_Name__c = apiResponse.results[0].tariffs[0].tariffName;
                    solarQuote.Tariff_Code__c = apiResponse.results[0].tariffs[0].tariffCode;
                    solarQuote.Completed_Account_Process__c  = true;
                    
                    setProperties(solarQuote);
                    
                } else {
                    Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;              
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarQuote.Failed_Solar_Quote_Process__c = true;
            
            update solarQuote; 
        }
        
        Logger.saveLog();      
    }
    
    public static void setProperties(Solar_Quote__c solarQuote) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            if(solarQuote.Failed_Solar_Quote_Process__c) {
                return;
            }
            
            ArcadiaApiWrapper.SetPropertyRequest apiPayload = new ArcadiaApiWrapper.SetPropertyRequest();
            apiPayload.keyName = 'lseId';
            apiPayload.dataValue = solarQuote.LSE_Id__c;
            apiPayload.accuracy = 100;
            
            request = arcadiaApi.properties(solarQuote.Provider_Account_Id__c, JSON.serialize(apiPayload, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success"}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 
               || statusCode == 201) 
            {
                ArcadiaApiWrapper.SetPropertyResponse apiResponse = (ArcadiaApiWrapper.SetPropertyResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.SetPropertyResponse.Class);
                
                if(apiResponse.status == 'Success') {
                    
                    solarQuote.Completed_Properties_Process__c = true;
                    
                    calculateKwh(solarQuote);
                    
                } else {
                    Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarQuote.Failed_Solar_Quote_Process__c = true;
            
            update solarQuote; 
        }
        
        Logger.saveLog();
    }
    
    public static void calculateKwh(Solar_Quote__c solarQuote) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            if(solarQuote.Failed_Solar_Quote_Process__c) {
                return;
            }
            
            Date yesterDay = Date.today().addDays(-1);
            String fromDateTime = String.valueOf(yesterDay.addYears(-1));
            String toDateTime = String.valueOf(yesterDay);
            
            List<ArcadiaApiWrapper.PropertyInput> propertyInputs = new List<ArcadiaApiWrapper.PropertyInput>();
            
            ArcadiaApiWrapper.PropertyInput propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'total';
            propertyInput.dataValue = String.valueOf(solarQuote.Average_Monthly_Bill__c * 12);
            propertyInput.unit = 'cost';
            propertyInputs.add(propertyInput);
            
            ArcadiaApiWrapper.PropertyInput propertyInput2 = new ArcadiaApiWrapper.PropertyInput();
            propertyInput2.keyName = 'baselineType';
            propertyInput2.dataValue = 'typicalElectricity';
            propertyInputs.add(propertyInput2);
            
            ArcadiaApiWrapper.CalculateKwhRequest apiPayload = new ArcadiaApiWrapper.CalculateKwhRequest();
            apiPayload.fromDateTime = fromDateTime;
            apiPayload.toDateTime = toDateTime;
            apiPayload.billingPeriod = false;
            apiPayload.groupBy = 'MONTH';
            apiPayload.detailLevel = 'CHARGE_TYPE';
            apiPayload.propertyInputs = propertyInputs;
            
            request = arcadiaApi.calculate(solarQuote.Provider_Account_Id__c, JSON.serialize(apiPayload, true)); 
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"summary":{"kWh":100,"totalCost":100}}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 
               || statusCode == 201) 
            {
                ArcadiaApiWrapper.CalculateKwhResponse apiResponse = (ArcadiaApiWrapper.CalculateKwhResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CalculateKwhResponse.Class);
                
                if(apiResponse.status == 'Success') {
                    
                    solarQuote.Annual_kWh_Arcadia__c = apiResponse.results[0].summary.kWh;
                    solarQuote.Annual_Bill__c = apiResponse.results[0].summary.totalCost;
                    solarQuote.Completed_kWh_Process__c = true;
                    
                    createElectricityProfile(solarQuote);
                    
                } else {
                    Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarQuote.Failed_Solar_Quote_Process__c = true;
            
            update solarQuote; 
        }
        
        Logger.saveLog();
    }
    
    public static void createElectricityProfile(Solar_Quote__c solarQuote) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            if(solarQuote.Failed_Solar_Quote_Process__c) {
                return;
            }
            
            Date yesterDay = Date.today().addDays(-1);
            String fromDateTime = String.valueOf(yesterDay.addYears(-1));
            String toDateTime = String.valueOf(yesterDay);
            
            ArcadiaApiWrapper.PropertyInput baselineType = new ArcadiaApiWrapper.PropertyInput();
            baselineType.keyName = 'baselineType';
            baselineType.dataValue = 'typicalElectricity';
            
            ArcadiaApiWrapper.CreateElectricityProfileProperty property = new ArcadiaApiWrapper.CreateElectricityProfileProperty();
            property.baselineType = baselineType;
            
            ArcadiaApiWrapper.ReadingData readingData = new ArcadiaApiWrapper.ReadingData();
            readingData.fromDateTime = fromDateTime;
            readingData.toDateTime = toDateTime;
            readingData.quantityUnit = 'kWh';
            readingData.quantityValue = String.valueOf(solarQuote.Annual_kWh_Arcadia__c);
            
            ArcadiaApiWrapper.CreateElectricityProfileRequest apiPayload = new ArcadiaApiWrapper.CreateElectricityProfileRequest();
            apiPayload.providerAccountId = solarQuote.Provider_Account_Id__c;
            apiPayload.providerProfileId = solarQuote.Provider_Account_Id__c + '-bills';
            apiPayload.profileName = 'Electricity Bills';
            apiPayload.isDefault = true;
            apiPayload.serviceTypes = 'ELECTRICITY';
            apiPayload.sourceId = 'ReadingEntry';
            apiPayload.properties = property;
            apiPayload.readingData = new List<ArcadiaApiWrapper.ReadingData>{readingData};
                
                request = arcadiaApi.profiles(JSON.serialize(apiPayload, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success"}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 
               || statusCode == 201) 
            {
                ArcadiaApiWrapper.CreateElectricityProfileResponse apiResponse = (ArcadiaApiWrapper.CreateElectricityProfileResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateElectricityProfileResponse.Class);
                
                if(apiResponse.status == 'Success') {
                    
                    solarQuote.Completed_Electricity_Profile_Process__c = true;
                    
                    update solarQuote; 
                    
                } else {
                    Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarQuote.Failed_Solar_Quote_Process__c = true;
            
            update solarQuote; 
        }
        
        Logger.saveLog();
    }
    
    @AuraEnabled
    public static void createSolarProfiles(Id solarQuoteId, String financeType) {
        
        Solar_Quote__c solarQuote = (Solar_Quote__c) SObjectUtil.getSObjectDetailsById(solarQuoteId);
        String errorMessage;
        
        try {
            
            if(solarQuote.Failed_Solar_Quote_Process__c) {
                return;
            }
            
            List<String> additionalFields = new List<String>{
                'Cash_Panel__r.Production__c', 
                'Loan_Panel__r.Production__c', 
                'TPO_Panel__r.Production__c'
            };
            State__c state = (State__c) SObjectUtil.getSObjectDetailsById(solarQuote.State_Lookup__c, additionalFields);
            
            Decimal productionPerPanel = financeType == 'Cash' 
                ? state.Cash_Panel__r.Production__c
                : financeType == 'Loan' 
                    ? state.Loan_Panel__r.Production__c
                    : financeType == 'TPO' 
                        ? state.TPO_Panel__r.Production__c
                        : 0;
            
            String solarProviderProfileIds;
            Decimal totalBaselineMeasures;
            Decimal solarOffset;
            
            if(productionPerPanel != null 
               && productionPerPanel != 0) 
            {
                if((financeType == 'Loan' 
                    || financeType == 'TPO') 
                   && productionPerPanel == state.Cash_Panel__r.Production__c) 
                {
                    solarProviderProfileIds = solarQuote.Solar_Provider_Profile_Ids_Cash__c;
                    totalBaselineMeasures = solarQuote.Total_Baseline_Measures_Cash__c;
                    solarOffset = solarQuote.Solar_Offset_Cash__c;
                    
                } else if(financeType == 'TPO' 
                          && productionPerPanel == state.Loan_Panel__r.Production__c) 
                {
                    solarProviderProfileIds = solarQuote.Solar_Provider_Profile_Ids_Loan__c;
                    totalBaselineMeasures = solarQuote.Total_Baseline_Measures_Loan__c;
                    solarOffset = solarQuote.Solar_Offset_Loan__c;
                    
                } else {
                    
                    GoogleApiWrapper.BuildingInsightsResponse buildingInsightsResponse;
                    
                    try {
                        buildingInsightsResponse = GoogleApiHelper.getBuildingInsights(solarQuote.Latitude__c, solarQuote.Longitude__c);
                        
                        solarQuote.Max_Panels_Count__c = 0;
                        
                        for(GoogleApiWrapper.SolarPanelConfig solarPanelConfig : buildingInsightsResponse.solarPotential.solarPanelConfigs) {
                            if(solarPanelConfig.panelsCount > solarQuote.Max_Panels_Count__c) {
                                solarQuote.Max_Panels_Count__c = solarPanelConfig.panelsCount;
                            }
                        }
                        
                    } catch(Exception ex) {
                        solarQuote.Failed_Google_Building_Insights__c = true;
                        solarQuote.Max_Panels_Count__c = 100;
                    }
                    
                    if(solarQuote.Panels_Count__c == null) {
                        solarQuote.Set_Best_Electrical_Offset__c = true;
                    }
                    
                    Integer panelsCount = solarQuote.Set_Best_Electrical_Offset__c 
                        ? 8 
                        : Integer.valueOf(solarQuote.Panels_Count__c);
                    Map<String, Object> result = new Map<String, Object>();
                    List<GoogleApiWrapper.RoofSegmentSummary> roofSegmentSummaries = SolarQuoteProcessHelper.prepareRoofSegmentSummaries(solarQuote, buildingInsightsResponse, panelsCount);
                    
                    if(solarQuote.Set_Best_Electrical_Offset__c) {
                        
                        Boolean needToBreak = false;
                        Decimal electricalOffset = 0;
                        
                        while(!needToBreak) {
                            
                            if(electricalOffset != 0) {
                                
                                Integer panelsCountStepSize = 0;
                                
                                if(solarQuote.Ground_Mount__c == 'Standard Ground Mount' 
                                   || solarQuote.Ground_Mount__c == 'Shade Structure Ground Mount') 
                                {
                                    panelsCountStepSize = 4;
                                    
                                } else {
                                    panelsCountStepSize = Integer.valueOf(Math.ceil(Decimal.valueOf(panelsCount) / electricalOffset)) - panelsCount;
                                }
                                
                                if(solarQuote.Ground_Mount__c != 'Standard Ground Mount' 
                                   && solarQuote.Ground_Mount__c != 'Shade Structure Ground Mount') 
                                {
                                    if(panelsCount + panelsCountStepSize > solarQuote.Max_Panels_Count__c) {
                                        panelsCountStepSize = Integer.valueOf(solarQuote.Max_Panels_Count__c) - panelsCount;
                                    }
                                }
                                
                                if(panelsCount + panelsCountStepSize <= solarQuote.Max_Panels_Count__c) {
                                    panelsCount += panelsCountStepSize;
                                }
                                
                                roofSegmentSummaries = SolarQuoteProcessHelper.prepareRoofSegmentSummaries(solarQuote, buildingInsightsResponse, panelsCount);
                            }
                            
                            result = createSolarProfiles(solarQuote, productionPerPanel, roofSegmentSummaries);
                            
                            electricalOffset = ((Decimal) result.get('totalBaselineMeasures') / solarQuote.Annual_kWh_Arcadia__c);
                            
                            if(panelsCount == solarQuote.Max_Panels_Count__c) {
                                needToBreak = true;
                            }
                            
                            if(!needToBreak 
                               && electricalOffset > 1) 
                            {
                                while(!needToBreak 
                                      && electricalOffset > 1) 
                                {
                                    if(((solarQuote.Ground_Mount__c == 'Standard Ground Mount' 
                                         || solarQuote.Ground_Mount__c == 'Shade Structure Ground Mount') 
                                        && panelsCount - 4 < 8)
                                       || panelsCount - 1 < 8) 
                                    {
                                        needToBreak = true;
                                        
                                    } else {
                                        if(solarQuote.Ground_Mount__c == 'Standard Ground Mount' 
                                           || solarQuote.Ground_Mount__c == 'Shade Structure Ground Mount') 
                                        {
                                            panelsCount -= 4;
                                            
                                        } else {
                                            panelsCount --;
                                        }
                                        
                                        roofSegmentSummaries = SolarQuoteProcessHelper.prepareRoofSegmentSummaries(solarQuote, buildingInsightsResponse, panelsCount);
                                        
                                        result = createSolarProfiles(solarQuote, productionPerPanel, roofSegmentSummaries);
                                        
                                        electricalOffset = ((Decimal) result.get('totalBaselineMeasures') / solarQuote.Annual_kWh_Arcadia__c);
                                    }
                                }
                                
                                needToBreak = true;
                            }
                        }
                        
                        solarQuote.Set_Best_Electrical_Offset__c = false;
                        solarQuote.Best_Panels_Count__c = panelsCount;
                        solarQuote.Panels_Count__c = panelsCount;
                        
                    } else {
                        result = createSolarProfiles(solarQuote, productionPerPanel, roofSegmentSummaries);
                    }
                    
                    if(result.containsKey('solarProviderProfileIds')) {
                        solarProviderProfileIds = (String) result.get('solarProviderProfileIds');
                    }
                    
                    if(result.containsKey('totalBaselineMeasures')) {
                        totalBaselineMeasures = (Decimal) result.get('totalBaselineMeasures');
                        solarOffset = (totalBaselineMeasures / solarQuote.Annual_kWh_Arcadia__c) * 100;
                    }
                    
                    Decimal sumOfPitchDegrees = 0;
                    
                    for(GoogleApiWrapper.RoofSegmentSummary roofSegmentSummary : roofSegmentSummaries) {
                        if(roofSegmentSummary.pitchDegrees != null) {
                            sumOfPitchDegrees += roofSegmentSummary.pitchDegrees;
                        }
                    }
                    
                    solarQuote.Roof_Segment_Summaries__c = JSON.serialize(roofSegmentSummaries);
                    solarQuote.Average_Pitch_Degrees__c  = sumOfPitchDegrees / roofSegmentSummaries.size();
                }
            }
            
            if(financeType == 'Cash') {                
                solarQuote.Solar_Provider_Profile_Ids_Cash__c = solarProviderProfileIds;
                solarQuote.Total_Baseline_Measures_Cash__c = totalBaselineMeasures;
                solarQuote.Solar_Offset_Cash__c = solarOffset;
                solarQuote.Completed_Solar_Profiles_Process_Cash__c = true;
            }
            
            if(financeType == 'Loan') {
                solarQuote.Solar_Provider_Profile_Ids_Loan__c = solarProviderProfileIds;
                solarQuote.Total_Baseline_Measures_Loan__c = totalBaselineMeasures;
                solarQuote.Solar_Offset_Loan__c = solarOffset;
                solarQuote.Completed_Solar_Profiles_Process_Loan__c = true;
            }
            
            if(financeType == 'TPO') {
                solarQuote.Solar_Provider_Profile_Ids_TPO__c = solarProviderProfileIds;
                solarQuote.Total_Baseline_Measures_TPO__c = totalBaselineMeasures;
                solarQuote.Solar_Offset_TPO__c = solarOffset;
                solarQuote.Completed_Solar_Profiles_Process_TPO__c = true;
            }
            
            update solarQuote;
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarQuote.Failed_Solar_Quote_Process__c = true;
            
            update solarQuote; 
        }
        
        Logger.saveLog();
    }    
    
    public static Map<String, Object> createSolarProfiles(Solar_Quote__c solarQuote, Decimal productionPerPanel, List<GoogleApiWrapper.RoofSegmentSummary> roofSegmentSummaries) { 
        
        String errorMessage;
        List<String> solarProviderProfileIds = new List<String>();
        Decimal totalBaselineMeasures = 0;
        
        for(GoogleApiWrapper.RoofSegmentSummary roofSegmentSummary : roofSegmentSummaries) {
            
            HttpRequest request;
            HttpResponse response;
            
            try {
                
                ArcadiaApiWrapper.Source source = new ArcadiaApiWrapper.Source();
                source.sourceId = 'PVWatts';
                source.sourceVersion = '8';
                
                ArcadiaApiWrapper.PropertyInput systemSizeWrapper = new ArcadiaApiWrapper.PropertyInput();
                systemSizeWrapper.keyName = 'systemSize';
                systemSizeWrapper.dataValue = String.valueOf((productionPerPanel * roofSegmentSummary.panelsCount) / 1000);
                
                ArcadiaApiWrapper.PropertyInput azimuthWrapper = new ArcadiaApiWrapper.PropertyInput();
                azimuthWrapper.keyName = 'azimuth';
                azimuthWrapper.dataValue = String.valueOf(roofSegmentSummary.azimuthDegrees);
                
                ArcadiaApiWrapper.PropertyInput losses = new ArcadiaApiWrapper.PropertyInput();
                losses.keyName = 'losses';
                losses.dataValue = '0';
                
                ArcadiaApiWrapper.PropertyInput inverterEfficiency = new ArcadiaApiWrapper.PropertyInput();
                inverterEfficiency.keyName = 'inverterEfficiency';
                inverterEfficiency.dataValue = '99.5';
                
                ArcadiaApiWrapper.PropertyInput tiltWrapper = new ArcadiaApiWrapper.PropertyInput();
                tiltWrapper.keyName = 'tilt';
                tiltWrapper.dataValue = String.valueOf(roofSegmentSummary.pitchDegrees);
                
                ArcadiaApiWrapper.PropertyInput bifaciality = new ArcadiaApiWrapper.PropertyInput();
                bifaciality.keyName = 'bifaciality';
                bifaciality.dataValue = '0.5';
                
                ArcadiaApiWrapper.PropertyInput albedo = new ArcadiaApiWrapper.PropertyInput();
                albedo.keyName = 'albedo';
                albedo.dataValue = '0.5';
                
                ArcadiaApiWrapper.PropertyInput useWeatherFileAlbedo = new ArcadiaApiWrapper.PropertyInput();
                useWeatherFileAlbedo.keyName = 'useWeatherFileAlbedo';
                useWeatherFileAlbedo.dataValue = '0';
                
                ArcadiaApiWrapper.PropertyInput soiling = new ArcadiaApiWrapper.PropertyInput();
                soiling.keyName = 'soiling';
                soiling.dataValue = '12.0, 4.0, 45.0, 23.0, 9.0, 99.0, 67.0, 12.54, 54.0, 9.0, 0.0, 7.6';
                
                ArcadiaApiWrapper.CreateSolarProfileProperty property = new ArcadiaApiWrapper.CreateSolarProfileProperty();
                property.systemSize = systemSizeWrapper;
                property.azimuth = azimuthWrapper;
                property.losses = losses;
                property.inverterEfficiency = inverterEfficiency;
                property.tilt = tiltWrapper;
                property.bifaciality = bifaciality;
                property.albedo = albedo;
                property.useWeatherFileAlbedo = useWeatherFileAlbedo;
                property.soiling = soiling;
                
                ArcadiaApiWrapper.CreateSolarProfileRequest apiPayload = new ArcadiaApiWrapper.CreateSolarProfileRequest();
                apiPayload.providerAccountId = solarQuote.Provider_Account_Id__c;
                apiPayload.providerProfileId = solarQuote.Provider_Account_Id__c + '-pvwatts-' + roofSegmentSummary.azimuthDegrees + '-' + productionPerPanel;
                apiPayload.groupBy = 'YEAR';
                apiPayload.serviceTypes = 'SOLAR_PV';
                apiPayload.source = source;
                apiPayload.properties = property;
                
                request = arcadiaApi.profiles(JSON.serialize(apiPayload, true));
                
                Integer statusCode = 200;
                String responseBody = '{"status":"Success","results":[{"providerProfileId":"12345", "baselineMeasures":[{"i":1, "v":101}]}]}';
                
                if(!Test.isRunningTest()) {
                    response = new Http().send(request);
                    
                    statusCode = response.getStatusCode();
                    responseBody = response.getBody();
                }
                
                if(statusCode == 200 || statusCode == 201) {
                    ArcadiaApiWrapper.CreateSolarProfileResponse apiResponse = (ArcadiaApiWrapper.CreateSolarProfileResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateSolarProfileResponse.Class);
                    
                    if(apiResponse.status == 'Success') {   
                        
                        solarProviderProfileIds.add(apiResponse.results[0].providerProfileId);
                        
                        totalBaselineMeasures += apiResponse.results[0].baselineMeasures[0].v;
                        
                    } else {
                        Logger.error('Bad Response From API').setHttpRequestDetails(request).setHttpResponseDetails(response);
                        
                        errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                    }
                    
                } else {
                    Logger.error('Bad Response From API').setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } catch(Exception ex) {
                Logger.error('Exception', ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Exception: ' + ex.getMessage();
            }   
        }
        
        Logger.saveLog();
        
        if(String.isNotBlank(errorMessage)) {
            throw new ApplicationException(errorMessage);        
        }
        
        Map<String, Object> result = new Map<String, Object>();
        
        if(!solarProviderProfileIds.isEmpty()) {
            result.put('solarProviderProfileIds', String.join(solarProviderProfileIds, ','));
        }
        
        if(totalBaselineMeasures != null) {
            result.put('totalBaselineMeasures', totalBaselineMeasures);
        }
        
        return result;
    }
    
    @AuraEnabled
    public static void getAnalysis(Id solarQuoteId) {
        
        Solar_Quote__c solarQuote = (Solar_Quote__c) SObjectUtil.getSObjectDetailsById(solarQuoteId);
        String errorMessage;
        
        try {
            
            if(solarQuote.Failed_Solar_Quote_Process__c) {
                return;
            }

            List<String> additionalFields = new List<String>{
                'Cash_Panel__r.Production__c', 
                'Loan_Panel__r.Production__c', 
                'TPO_Panel__r.Production__c',
                'Cash_Battery__r.Standard_Price__c',
                'Loan_Battery__r.Standard_Price__c',
                'TPO_Battery__r.Standard_Price__c',
                'Cash_Preferred__r.Dealer_Fee__c',
                'Loan_Preferred__r.Dealer_Fee__c',
                'Cash_Preferred__r.Payment_Factor__c',
                'Loan_Preferred__r.Payment_Factor__c',
                'Loan_Preferred__r.APR__c',
                'Loan_Competitor__r.Dealer_Fee__c',
                'Loan_Competitor__r.Payment_Factor__c'
            };
            
            State__c state = (State__c) SObjectUtil.getSObjectDetailsById(solarQuote.State_Lookup__c, additionalFields);
            
            solarQuote.Run_Typical_Analysis__c = solarQuote.City_Tier__c == null 
                || solarQuote.City_Tier__c < 1
                || solarQuote.City_Tier__c > 3;
            
            if(!solarQuote.Run_Typical_Analysis__c) {
                
                if(state.Auto_Recommend_Battery__c 
                   && solarQuote.Last_Successful_Process_Run_Timestamp__c == null) 
                {
                    if(solarQuote.Batteries_Count_Cash__c == null) {
                        solarQuote.Batteries_Count_Cash__c = 1;
                    }
                    
                    if(solarQuote.Batteries_Count_Loan__c == null) {
                        solarQuote.Batteries_Count_Loan__c = 1;
                    }
                    
                    if(solarQuote.Batteries_Count_TPO__c == null) {
                        solarQuote.Batteries_Count_TPO__c = 1;
                    }
                }
                
                Decimal cityTierCost = SolarQuoteProcessHelper.getCityTierCost(solarQuote);
                Decimal pitchDegreesCost = SolarQuoteProcessHelper.getPitchDegreesCost(solarQuote);
                Decimal solarTaxFilingServiceCost = SolarQuoteProcessHelper.getSolarTaxFilingServiceCost(solarQuote);
                Map<String, List<Decimal>> backupBatteryPrices = SolarQuoteProcessHelper.getBackupBatteryPrices(state);
                
                SolarQuoteProcessHelper.doCashCalculation(solarQuote, state, backupBatteryPrices, 
                                                             cityTierCost, pitchDegreesCost, solarTaxFilingServiceCost);
                SolarQuoteProcessHelper.doLoanCalculation(solarQuote, state, backupBatteryPrices, 
                                                             cityTierCost, pitchDegreesCost, solarTaxFilingServiceCost);
                SolarQuoteProcessHelper.doTPOCalculation(solarQuote, state, backupBatteryPrices, 
                                                            cityTierCost, pitchDegreesCost, solarTaxFilingServiceCost);
                
                if(solarQuote.Finance_Type_Available_Cash__c) {
                    
                    if(solarQuote.Batteries_Available_Cash__c) {
                        createStorageProfile(solarQuote, state, 'Cash');
                    }
                    
                    Map<String, Decimal> result = getAnalysis(solarQuote, 'Cash');
                    
                    solarQuote.Monthly_Savings_Cash__c = result.get('monthlySavings');
                    solarQuote.Yearly_Savings_Cash__c = result.get('yearlySavings');
                    solarQuote.Old_Lifetime_Utility_Cost_Cash__c = result.get('oldLifetimeUtilityCost');
                    solarQuote.New_Lifetime_Solar_Cost_Cash__c = result.get('newLifetimeSolarCost');
                    solarQuote.Total_Lifetime_Savings_Cash__c = result.get('totalLifetimeSavings');
                }
                
                if(solarQuote.Finance_Type_Available_Loan__c) {
                    
                    if(solarQuote.Batteries_Available_Loan__c) {
                        createStorageProfile(solarQuote, state, 'Loan');
                    }
                    
                    Map<String, Decimal> result = getAnalysis(solarQuote, 'Loan');
                    
                    solarQuote.Monthly_Savings_Loan__c = result.get('monthlySavings');
                    solarQuote.Yearly_Savings_Loan__c = result.get('yearlySavings');
                    solarQuote.Old_Lifetime_Utility_Cost_Loan__c = result.get('oldLifetimeUtilityCost');
                    solarQuote.New_Lifetime_Solar_Cost_Loan__c = result.get('newLifetimeSolarCost');
                    solarQuote.Total_Lifetime_Savings_Loan__c = result.get('totalLifetimeSavings');
                }
                
                if(solarQuote.Finance_Type_Available_TPO__c) {
                    
                    if(solarQuote.Batteries_Available_TPO__c) {
                        createStorageProfile(solarQuote, state, 'TPO');
                    }
                    
                    Map<String, Decimal> result = getAnalysis(solarQuote, 'TPO');
                    
                    solarQuote.Monthly_Savings_TPO__c = result.get('monthlySavings');
                    solarQuote.Yearly_Savings_TPO__c = result.get('yearlySavings');
                    solarQuote.Old_Lifetime_Utility_Cost_TPO__c = result.get('oldLifetimeUtilityCost');
                    solarQuote.New_Lifetime_Solar_Cost_TPO__c = result.get('newLifetimeSolarCost');
                    solarQuote.Total_Lifetime_Savings_TPO__c = result.get('totalLifetimeSavings');
                }
            }
            
            if(!solarQuote.Run_Typical_Analysis__c
               && !solarQuote.Finance_Type_Available_Cash__c
               && !solarQuote.Finance_Type_Available_Loan__c
               && !solarQuote.Finance_Type_Available_TPO__c) 
            {
                solarQuote.Run_Typical_Analysis__c = true;
            }
            
            if(solarQuote.Run_Typical_Analysis__c 
               || Test.isRunningTest()) 
            {
                solarQuote.Roof_Segment_Summaries__c = null;
                solarQuote.Average_Pitch_Degrees__c = null;
                solarQuote.Max_Panels_Count__c = null;
                solarQuote.Best_Panels_Count__c = null;
                solarQuote.Panels_Count__c = null;
                solarQuote.Finance_Type_Available_Cash__c = false;
                solarQuote.Finance_Type_Available_Loan__c = false;
                solarQuote.Finance_Type_Available_TPO__c = false;
                
                Map<String, Decimal> result = getTypicalAnalysis(solarQuote);
                
                solarQuote.Monthly_Savings_Typical__c = result.get('monthlySavings');
                solarQuote.Yearly_Savings_Typical__c = result.get('yearlySavings');
                solarQuote.Old_Lifetime_Utility_Cost_Typical__c = result.get('oldLifetimeUtilityCost');
                solarQuote.New_Lifetime_Solar_Cost_Typical__c = result.get('newLifetimeSolarCost');
                solarQuote.Total_Lifetime_Savings_Typical__c = result.get('totalLifetimeSavings');
            } 
            
            solarQuote.Completed_Analysis_Process__c = true;
            
            update solarQuote;
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarQuote.Failed_Solar_Quote_Process__c = true;
            
            update solarQuote; 
        }
        
        Logger.saveLog();
    }
    
    public static void createStorageProfile(Solar_Quote__c solarQuote, State__c state, String financeType) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            String productId = financeType == 'Cash'
                ? state.Cash_Battery__c
                : financeType == 'Loan'
                    ? state.Loan_Battery__c
                    : financeType == 'TPO'
                        ? state.TPO_Battery__c
                        : null;
            
            String storageProviderProfileId;
            
            if(String.isNotBlank(productId)) {
                
                if((financeType == 'Loan' 
                    || financeType == 'TPO') 
                   && productId == state.Cash_Battery__c) 
                {
                    storageProviderProfileId = solarQuote.Storage_Profile_Id_Cash__c;
                    
                } else if(financeType == 'TPO' 
                          && productId == state.Loan_Battery__c) 
                {
                    storageProviderProfileId = solarQuote.Storage_Profile_Id_Loan__c;
                    
                } else {
                    
                    String fromDateTime = String.valueOf(Date.today().toStartOfMonth().addMonths(-1));
                    
                    Product2 battery = [SELECT Id, Rated_Output_Power__c, Energy_Capacity__c, Min_SoC__c, Max_SoC__c, Initial_SoC__c, DC_Coupled__c, AC_to_DC_Efficiency__c, DC_to_AC_Efficiency__c,
                                        Input_Efficiency__c, Solar_DC_to_AC_Efficiency__c, Allow_Battery_to_Grid__c, Allow_Grid_to_Battery__c, Allow_Solar_to_Grid__c, Allow_Solar_to_Battery__c
                                        FROM Product2 
                                        WHERE Id = :productId];
                    
                    ArcadiaApiWrapper.Consumption consumption = new ArcadiaApiWrapper.Consumption();
                    consumption.providerProfileId = solarQuote.Provider_Account_Id__c + '-bills';
                    
                    ArcadiaApiWrapper.DispatchStrategy dispatchStrategy = new ArcadiaApiWrapper.DispatchStrategy();
                    dispatchStrategy.optimize = true;
                    
                    List<ArcadiaApiWrapper.PropertyInput> propertyInputs = new List<ArcadiaApiWrapper.PropertyInput>();
                    
                    ArcadiaApiWrapper.PropertyInput propertyInput = new ArcadiaApiWrapper.PropertyInput();
                    propertyInput.keyName = 'accPlusAdderCustomerType';
                    propertyInput.dataValue = 'nonLowIncome';
                    propertyInputs.add(propertyInput);
                    
                    propertyInput = new ArcadiaApiWrapper.PropertyInput();
                    propertyInput.keyName = 'hasCareDiscount';
                    propertyInput.dataValue = 'false';
                    propertyInputs.add(propertyInput);
                    
                    List<ArcadiaApiWrapper.Solar> solars = new List<ArcadiaApiWrapper.Solar>();
                    
                    String solarProviderProfileIdsStr;
                    
                    if(financeType == 'Cash') {
                        solarProviderProfileIdsStr = solarQuote.Solar_Provider_Profile_Ids_Cash__c;
                    }
                    
                    if(financeType == 'Loan') {
                        solarProviderProfileIdsStr = solarQuote.Solar_Provider_Profile_Ids_Loan__c;
                    }
                    
                    if(financeType == 'TPO') {
                        solarProviderProfileIdsStr = solarQuote.Solar_Provider_Profile_Ids_TPO__c;
                    }
                    
                    if(String.isNotBlank(solarProviderProfileIdsStr)) {
                        
                        List<String> solarProviderProfileIds = solarProviderProfileIdsStr.split(',');
                        
                        for(Integer i = 0; i < solarProviderProfileIds.size(); i++) {
                            ArcadiaApiWrapper.Solar solar = new ArcadiaApiWrapper.Solar();
                            solar.providerProfileId = solarProviderProfileIds[i];
                            
                            if(i == 0) {
                                solar.dataFactor = 1.5;
                            }
                            
                            solars.add(solar);
                        } 
                    }
                    
                    ArcadiaApiWrapper.Storage storage = new ArcadiaApiWrapper.Storage();
                    storage.mainTariffId = solarQuote.Master_Tariff_Id__c;
                    storage.dispatchStrategy = dispatchStrategy;
                    storage.batteryNameplatePower = Decimal.valueOf(battery.Rated_Output_Power__c);
                    storage.batteryNameplateCapacity = Decimal.valueOf(battery.Energy_Capacity__c);
                    storage.batteryMinSoc = battery.Min_SoC__c / 100;
                    storage.batteryMaxSoc = battery.Max_SoC__c / 100;
                    storage.batteryInitialSoc = battery.Initial_SoC__c / 100;
                    storage.batteryDcCoupled = battery.DC_Coupled__c;
                    storage.batteryAcToDcEfficiency = battery.AC_to_DC_Efficiency__c / 100;
                    storage.batteryDcToAcEfficiency = battery.DC_to_AC_Efficiency__c / 100;
                    storage.batteryInputEfficiency = battery.Input_Efficiency__c / 100;
                    storage.batteryDegradationCost = 0;
                    storage.solarDcToAcEfficiency = battery.Solar_DC_to_AC_Efficiency__c / 100;
                    storage.allowBatteryToGrid = battery.Allow_Battery_to_Grid__c;
                    storage.allowGridToBattery = battery.Allow_Grid_to_Battery__c;
                    storage.allowSolarToGrid = battery.Allow_Solar_to_Grid__c;
                    storage.allowSolarToBattery = battery.Allow_Solar_to_Battery__c;
                    storage.tariffPropertyInputs = propertyInputs;
                    
                    ArcadiaApiWrapper.CreateStorageProfileRequest apiPayload = new ArcadiaApiWrapper.CreateStorageProfileRequest();
                    apiPayload.providerAccountId = solarQuote.Provider_Account_Id__c;
                    apiPayload.providerProfileId = solarQuote.Provider_Account_Id__c + '-storage-' + String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
                    apiPayload.fromDateTime = fromDateTime;
                    apiPayload.consumption = consumption;
                    apiPayload.solar = solars;
                    apiPayload.storage = storage;
                    
                    request = arcadiaApi.profilesStorage(JSON.serialize(apiPayload, true));
                    
                    Integer statusCode = 200;
                    String responseBody = '{"status":"Success","results":[{"usageProfile":{"providerProfileId":"Test"}}]}';
                    
                    if(!Test.isRunningTest()) {
                        response = new Http().send(request);
                        
                        statusCode = response.getStatusCode();
                        responseBody = response.getBody();
                    }
                    
                    if(statusCode == 200 
                       || statusCode == 201) 
                    {
                        ArcadiaApiWrapper.CreateStorageProfileResponse apiResponse = (ArcadiaApiWrapper.CreateStorageProfileResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateStorageProfileResponse.Class);
                        
                        if(apiResponse.status == 'Success') {
                            
                            storageProviderProfileId = apiResponse.results[0].usageProfile.providerProfileId;
                            
                        } else {
                            Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                            
                            errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                        }
                        
                    } else {
                        Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                        
                        errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                    }
                }
            }
            
            if(financeType == 'Cash') {
                solarQuote.Storage_Profile_Id_Cash__c = storageProviderProfileId;
            }
            
            if(financeType == 'Loan') {
                solarQuote.Storage_Profile_Id_Loan__c = storageProviderProfileId;
            }
            
            if(financeType == 'TPO') {
                solarQuote.Storage_Profile_Id_TPO__c = storageProviderProfileId;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        Logger.saveLog();
        
        if(String.isNotBlank(errorMessage)) {
            throw new ApplicationException(errorMessage);        
        }
    }
    
    public static Map<String, Decimal> getAnalysis(Solar_Quote__c solarQuote, String financeType) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            String fromDateTime = String.valueOf(Date.today());
            
            ArcadiaApiWrapper.RateBand rateBand = new ArcadiaApiWrapper.RateBand();
            
            if(financeType == 'Cash') {
                rateBand.rateAmount = solarQuote.Final_Price_Cash__c;
            }
            
            if(financeType == 'Loan') {
                rateBand.rateAmount = solarQuote.Final_Price_Loan__c;
            }
            
            if(financeType == 'TPO') {
                rateBand.rateAmount = solarQuote.Final_Price_TPO__c;
            }
            
            ArcadiaApiWrapper.RateInput rateInput = new ArcadiaApiWrapper.RateInput();
            rateInput.scenarios = 'solar';
            rateInput.chargeType = 'FIXED_PRICE';
            rateInput.rateBands = new List<ArcadiaApiWrapper.RateBand>{rateBand};
                
                List<ArcadiaApiWrapper.PropertyInput> propertyInputs = new List<ArcadiaApiWrapper.PropertyInput>();
            
            ArcadiaApiWrapper.PropertyInput propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'before';
            propertyInput.keyName = 'masterTariffId';
            propertyInput.dataValue = solarQuote.Master_Tariff_Id__c;
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'after';
            propertyInput.keyName = 'masterTariffId';
            propertyInput.dataValue = solarQuote.Master_Tariff_Id__c;
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'before,after';
            propertyInput.keyName = 'rateInflation';
            propertyInput.dataValue = '3.5';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'solar';
            propertyInput.keyName = 'rateInflation';
            propertyInput.dataValue = '0';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'after,solar';
            propertyInput.keyName = 'solarDegradation';
            propertyInput.dataValue = '0.5';
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'before,after';
            propertyInput.keyName = 'providerProfileId';
            propertyInput.dataValue = solarQuote.Provider_Account_Id__c + '-bills';
            
            propertyInputs.add(propertyInput);
            
            String solarProviderProfileIds;
            
            if(financeType == 'Cash') {
                solarProviderProfileIds = solarQuote.Solar_Provider_Profile_Ids_Cash__c;
            }
            
            if(financeType == 'Loan') {
                solarProviderProfileIds = solarQuote.Solar_Provider_Profile_Ids_Loan__c;
            }
            
            if(financeType == 'TPO') {
                solarProviderProfileIds = solarQuote.Solar_Provider_Profile_Ids_TPO__c;
            }
            
            for(String solarProviderProfileId : solarProviderProfileIds.split(',')) {
                propertyInput = new ArcadiaApiWrapper.PropertyInput();
                propertyInput.scenarios = 'after,solar';
                propertyInput.keyName = 'providerProfileId';
                propertyInput.dataValue = solarProviderProfileId;
                
                propertyInputs.add(propertyInput);
            }
            
            String storageProviderProfileId;
            
            if(financeType == 'Cash') {
                storageProviderProfileId = solarQuote.Storage_Profile_Id_Cash__c;
            }
            
            if(financeType == 'Loan') {
                storageProviderProfileId = solarQuote.Storage_Profile_Id_Loan__c;
            }
            
            if(financeType == 'TPO') {
                storageProviderProfileId = solarQuote.Storage_Profile_Id_TPO__c;
            }
            
            if(String.isNotBlank(storageProviderProfileId)) {
                propertyInput = new ArcadiaApiWrapper.PropertyInput();
                propertyInput.scenarios = 'after,solar';
                propertyInput.keyName = 'storageProfileId';
                propertyInput.dataValue = storageProviderProfileId;
                
                propertyInputs.add(propertyInput);
            }
            
            ArcadiaApiWrapper.AnalysisRequest apiPayload = new ArcadiaApiWrapper.AnalysisRequest();
            apiPayload.providerAccountId = solarQuote.Provider_Account_Id__c;
            apiPayload.fromDateTime = fromDateTime;
            apiPayload.autoBaseline = true;
            apiPayload.useIntelligentBaselining = true;
            apiPayload.tariffEffectiveOn = fromDateTime;
            apiPayload.propertyInputs = propertyInputs;
            apiPayload.rateInputs = new List<ArcadiaApiWrapper.RateInput>{rateInput};
                
                request = arcadiaApi.analysis(JSON.serialize(apiPayload, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"summary":{"lifetimeWithoutCost":100,"lifetimeSolarCost":100,"preTotalCost":100,"postTotalCost":100}}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                ArcadiaApiWrapper.AnalysisResponse apiResponse = (ArcadiaApiWrapper.AnalysisResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.AnalysisResponse.Class);
                
                if(apiResponse.status == 'Success') {
                    
                    ArcadiaApiWrapper.AnalysisSummary summary = apiResponse.results[0].summary;
                    
                    Decimal oldLifetimeUtilityCost = summary.lifetimeWithoutCost;
                    Decimal newLifetimeSolarCost = summary.lifetimeSolarCost;
                    Decimal totalLifetimeSavings = Math.abs(oldLifetimeUtilityCost - newLifetimeSolarCost);
                    Decimal yearlySavings = summary.preTotalCost - summary.postTotalCost;
                    Decimal monthlySavings = yearlySavings / 12;
                    
                    Map<String, Decimal> analysisResult = new Map<String, Decimal>();
                    analysisResult.put('oldLifetimeUtilityCost', oldLifetimeUtilityCost);
                    analysisResult.put('newLifetimeSolarCost', newLifetimeSolarCost);
                    analysisResult.put('totalLifetimeSavings', totalLifetimeSavings);
                    analysisResult.put('yearlySavings', yearlySavings);
                    analysisResult.put('monthlySavings', monthlySavings);  
                    
                    return analysisResult;
                    
                } else {
                    Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            throw new ApplicationException(errorMessage); 
        }
        
        Logger.saveLog();
        
        return null;
    }
    
    public static Map<String, Decimal> getTypicalAnalysis(Solar_Quote__c solarQuote) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            String fromDateTime = String.valueOf(Date.today());
            
            ArcadiaApiWrapper.RateBand rateBand = new ArcadiaApiWrapper.RateBand();
            rateBand.tariffRateBandId = null;
            rateBand.tariffRateId = null;
            rateBand.rateSequenceNumber = null;
            rateBand.hasConsumptionLimit = null;
            rateBand.hasDemandLimit = null;
            rateBand.hasPropertyLimit = false;
            rateBand.rateAmount = 0.15;
            rateBand.rateUnit = null;
            rateBand.isCredit = null;
            rateBand.prevUpperLimit = null;
            
            ArcadiaApiWrapper.RateInput rateInput = new ArcadiaApiWrapper.RateInput();
            rateInput.masterTariffRateId = null;
            rateInput.tariffBookSequenceNumber = null;
            rateInput.tariffBookRateGroupName = null;
            rateInput.tariffBookRateName = null;
            rateInput.fromDateTime = fromDateTime;
            rateInput.toDateTime = null;
            rateInput.chargeType = 'CONSUMPTION_BASED';
            rateInput.chargePeriod = 'MONTHLY';
            rateInput.transactionType = 'BUY';
            rateInput.rateBands = new List<ArcadiaApiWrapper.RateBand>{rateBand};
                rateInput.scenarios = 'solar';
            
            List<ArcadiaApiWrapper.PropertyInput> propertyInputs = new List<ArcadiaApiWrapper.PropertyInput>();
            
            ArcadiaApiWrapper.PropertyInput propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'projectDuration';
            propertyInput.dataType = 'INTEGER';
            propertyInput.dataValue = '20';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'baselineType';
            propertyInput.dataType = 'STRING';
            propertyInput.dataValue = 'typicalElectricity';
            propertyInput.scenarios = 'before,after';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'baselineType';
            propertyInput.dataType = 'STRING';
            propertyInput.dataValue = 'typicalSolarPv';
            propertyInput.scenarios = 'after,solar';
            propertyInput.operator = '-';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'solarPvLoadOffset';
            propertyInput.unit = '%';
            propertyInput.dataValue = '80';
            propertyInput.scenarios = 'after,solar';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'rateInflation';
            propertyInput.dataType = 'DECIMAL';
            propertyInput.dataValue = '1.9';
            propertyInput.scenarios = 'solar';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'rateInflation';
            propertyInput.dataType = 'DECIMAL';
            propertyInput.dataValue = '3';
            propertyInput.scenarios = 'before,after';
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'masterTariffId';
            propertyInput.dataType = 'INTEGER';
            propertyInput.dataValue = solarQuote.Master_Tariff_Id__c;
            propertyInput.scenarios = 'before';
            
            propertyInputs.add(propertyInput);
            
            ArcadiaApiWrapper.AnalysisRequest apiPayload = new ArcadiaApiWrapper.AnalysisRequest();
            apiPayload.providerAccountId = solarQuote.Provider_Account_Id__c;
            apiPayload.fromDateTime = fromDateTime;
            apiPayload.propertyInputs = propertyInputs;
            apiPayload.rateInputs = new List<ArcadiaApiWrapper.RateInput>{rateInput};
                
                request = arcadiaApi.analysis(JSON.serialize(apiPayload, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"summary":{"lifetimeWithoutCost":100,"lifetimeSolarCost":100,"preTotalCost":100,"postTotalCost":100}}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 
               || statusCode == 201) 
            {
                ArcadiaApiWrapper.AnalysisResponse apiResponse = (ArcadiaApiWrapper.AnalysisResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.AnalysisResponse.Class);
                
                if(apiResponse.status == 'Success') {
                    
                    ArcadiaApiWrapper.AnalysisSummary summary = apiResponse.results[0].summary;
                    
                    Decimal oldLifetimeUtilityCost = summary.lifetimeWithoutCost;
                    Decimal newLifetimeSolarCost = summary.lifetimeSolarCost;
                    Decimal totalLifetimeSavings = Math.abs(oldLifetimeUtilityCost - newLifetimeSolarCost);
                    Decimal yearlySavings = summary.preTotalCost - summary.postTotalCost;
                    Decimal monthlySavings = yearlySavings / 12;
                    
                    Map<String, Decimal> analysisResult = new Map<String, Decimal>();
                    analysisResult.put('oldLifetimeUtilityCost', oldLifetimeUtilityCost);
                    analysisResult.put('newLifetimeSolarCost', newLifetimeSolarCost);
                    analysisResult.put('totalLifetimeSavings', totalLifetimeSavings);
                    analysisResult.put('yearlySavings', yearlySavings);
                    analysisResult.put('monthlySavings', monthlySavings);
                    
                    return analysisResult;
                    
                } else {
                    Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarQuote.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarQuote.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        Logger.saveLog();
        
        if(String.isNotBlank(errorMessage)) {
            throw new ApplicationException(errorMessage);        
        }
        
        return null;
    }
}