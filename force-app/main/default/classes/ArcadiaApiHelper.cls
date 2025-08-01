public without sharing class ArcadiaApiHelper {
    
    private static ArcadiaApi arcadiaApi = new ArcadiaApi();
    
    @AuraEnabled
    public static void createAccount(Id solarEstimateAddressId) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        Solar_Estimate_Address__c solarEstimateAddress = (Solar_Estimate_Address__c) SObjectUtil.getSObjectDetailsById(solarEstimateAddressId, 'Lead__r.Account_Name__c');
        
        try {
            
            if(solarEstimateAddress.Failed_Solar_Estimate_Process__c) {
                return;
            }
            
            ArcadiaApiWrapper.Address address = new ArcadiaApiWrapper.Address();
            address.addressString = solarEstimateAddress.Address__c;
            
            ArcadiaApiWrapper.PropertyInput customerClass = new ArcadiaApiWrapper.PropertyInput();
            customerClass.keyName = 'customerClass';
            customerClass.dataValue = '1';
            
            ArcadiaApiWrapper.CreateAccountProperty property = new ArcadiaApiWrapper.CreateAccountProperty();
            property.customerClass = customerClass;
            
            ArcadiaApiWrapper.CreateAccountRequest wrapper = new ArcadiaApiWrapper.CreateAccountRequest();
            wrapper.providerAccountId = solarEstimateAddress.Provider_Account_Id__c;
            wrapper.accountName = String.isNotBlank(solarEstimateAddress.Lead__c) 
                ? solarEstimateAddress.Lead__r.Account_Name__c 
                : solarEstimateAddress.Provider_Account_Id__c;
            wrapper.address = address;
            wrapper.properties = property;
            
            request = arcadiaApi.accounts(JSON.serialize(wrapper, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"providerProfileId":"Test","tariffs":[{"masterTariffId":"Test","tariffName":"Test","tariffCode":"Test"}]}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                ArcadiaApiWrapper.CreateAccountResponse result = (ArcadiaApiWrapper.CreateAccountResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateAccountResponse.Class);
                
                if(result.status == 'Success') {
                    
                    solarEstimateAddress.Account_Id__c = result.results[0].accountId;
                    solarEstimateAddress.Master_Tariff_Id__c = result.results[0].tariffs[0].masterTariffId;
                    solarEstimateAddress.Tariff_Name__c = result.results[0].tariffs[0].tariffName;
                    solarEstimateAddress.Tariff_Code__c = result.results[0].tariffs[0].tariffCode;
                    solarEstimateAddress.Completed_Account_Process__c  = true;
                    
                    setProperties(solarEstimateAddress);
                    
                } else {
                    Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;              
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarEstimateAddress.Failed_Solar_Estimate_Process__c = true;
            
            update solarEstimateAddress; 
        }
        
        Logger.saveLog();      
    }
    
    public static void setProperties(Solar_Estimate_Address__c solarEstimateAddress) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            if(solarEstimateAddress.Failed_Solar_Estimate_Process__c) {
                return;
            }
            
            ArcadiaApiWrapper.SetPropertyRequest wrapper = new ArcadiaApiWrapper.SetPropertyRequest();
            wrapper.keyName = 'lseId';
            wrapper.dataValue = solarEstimateAddress.LSE_Id__c;
            wrapper.accuracy = 100;
            
            request = arcadiaApi.properties(solarEstimateAddress.Provider_Account_Id__c, JSON.serialize(wrapper, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success"}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                ArcadiaApiWrapper.SetPropertyResponse result = (ArcadiaApiWrapper.SetPropertyResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.SetPropertyResponse.Class);
                
                if(result.status == 'Success') {
                    
                    solarEstimateAddress.Completed_Properties_Process__c = true;
                    
                    calculateKwh(solarEstimateAddress);
                    
                } else {
                    Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarEstimateAddress.Failed_Solar_Estimate_Process__c = true;
            
            update solarEstimateAddress; 
        }
        
        Logger.saveLog();
    }
    
    public static void calculateKwh(Solar_Estimate_Address__c solarEstimateAddress) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            if(solarEstimateAddress.Failed_Solar_Estimate_Process__c) {
                return;
            }
            
            Date yesterDay = Date.today().addDays(-1);
            String fromDateTime = String.valueOf(yesterDay.addYears(-1));
            String toDateTime = String.valueOf(yesterDay);
            
            List<ArcadiaApiWrapper.PropertyInput> propertyInputs = new List<ArcadiaApiWrapper.PropertyInput>();
            
            ArcadiaApiWrapper.PropertyInput propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.keyName = 'total';
            propertyInput.dataValue = String.valueOf(solarEstimateAddress.Average_Monthly_Bill__c * 12);
            propertyInput.unit = 'cost';
            propertyInputs.add(propertyInput);
            
            ArcadiaApiWrapper.PropertyInput propertyInput2 = new ArcadiaApiWrapper.PropertyInput();
            propertyInput2.keyName = 'baselineType';
            propertyInput2.dataValue = 'typicalElectricity';
            propertyInputs.add(propertyInput2);
            
            ArcadiaApiWrapper.CalculateKwhRequest wrapper = new ArcadiaApiWrapper.CalculateKwhRequest();
            wrapper.fromDateTime = fromDateTime;
            wrapper.toDateTime = toDateTime;
            wrapper.billingPeriod = false;
            wrapper.groupBy = 'MONTH';
            wrapper.detailLevel = 'CHARGE_TYPE';
            wrapper.propertyInputs = propertyInputs;
            
            request = arcadiaApi.calculate(solarEstimateAddress.Provider_Account_Id__c, JSON.serialize(wrapper, true)); 
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"summary":{"kWh":100,"totalCost":100}}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                ArcadiaApiWrapper.CalculateKwhResponse result = (ArcadiaApiWrapper.CalculateKwhResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CalculateKwhResponse.Class);
                
                if(result.status == 'Success') {
                    
                    solarEstimateAddress.Annual_kWh_Arcadia__c = result.results[0].summary.kWh;
                    solarEstimateAddress.Annual_Bill__c = result.results[0].summary.totalCost;
                    solarEstimateAddress.Completed_kWh_Process__c = true;
                    
                    createElectricityProfile(solarEstimateAddress);
                    
                } else {
                    Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarEstimateAddress.Failed_Solar_Estimate_Process__c = true;
            
            update solarEstimateAddress; 
        }
        
        Logger.saveLog();
    }
    
    public static void createElectricityProfile(Solar_Estimate_Address__c solarEstimateAddress) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            if(solarEstimateAddress.Failed_Solar_Estimate_Process__c) {
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
            readingData.quantityValue = String.valueOf(solarEstimateAddress.Annual_kWh_Arcadia__c);
            
            ArcadiaApiWrapper.CreateElectricityProfileRequest wrapper = new ArcadiaApiWrapper.CreateElectricityProfileRequest();
            wrapper.providerAccountId = solarEstimateAddress.Provider_Account_Id__c;
            wrapper.providerProfileId = solarEstimateAddress.Provider_Account_Id__c + '-bills';
            wrapper.profileName = 'Electricity Bills';
            wrapper.isDefault = true;
            wrapper.serviceTypes = 'ELECTRICITY';
            wrapper.sourceId = 'ReadingEntry';
            wrapper.properties = property;
            wrapper.readingData = new List<ArcadiaApiWrapper.ReadingData>{readingData};
                
                request = arcadiaApi.profiles(JSON.serialize(wrapper, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success"}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                ArcadiaApiWrapper.CreateElectricityProfileResponse result = (ArcadiaApiWrapper.CreateElectricityProfileResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateElectricityProfileResponse.Class);
                
                if(result.status == 'Success') {
                    
                    solarEstimateAddress.Completed_Electricity_Profile_Process__c = true;
                    
                    update solarEstimateAddress; 
                    
                } else {
                    Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarEstimateAddress.Failed_Solar_Estimate_Process__c = true;
            
            update solarEstimateAddress; 
        }
        
        Logger.saveLog();
    }
    
    @AuraEnabled
    public static void createSolarProfiles(Id solarEstimateAddressId, String financeType) {
        
        Solar_Estimate_Address__c solarEstimateAddress = (Solar_Estimate_Address__c) SObjectUtil.getSObjectDetailsById(solarEstimateAddressId);
        String errorMessage;
        
        try {
            
            if(solarEstimateAddress.Failed_Solar_Estimate_Process__c) {
                return;
            }
            
            State__c state = (State__c) SObjectUtil.getSObjectDetailsById(solarEstimateAddress.State_Lookup__c, 'Cash_Panel__r.Production__c,'
                                                                            + 'Loan_Panel__r.Production__c,'
                                                                            + 'TPO_Panel__r.Production__c');
            
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
            
            if(productionPerPanel != null && productionPerPanel != 0) {
                
                if((financeType == 'Loan' || financeType == 'TPO') && productionPerPanel == state.Cash_Panel__r.Production__c) {
                    solarProviderProfileIds = solarEstimateAddress.Solar_Provider_Profile_Ids_Cash__c;
                    totalBaselineMeasures = solarEstimateAddress.Total_Baseline_Measures_Cash__c;
                    solarOffset = solarEstimateAddress.Solar_Offset_Cash__c;
                    
                } else if(financeType == 'TPO' && productionPerPanel == state.Loan_Panel__r.Production__c) {
                    solarProviderProfileIds = solarEstimateAddress.Solar_Provider_Profile_Ids_Loan__c;
                    totalBaselineMeasures = solarEstimateAddress.Total_Baseline_Measures_Loan__c;
                    solarOffset = solarEstimateAddress.Solar_Offset_Loan__c;
                    
                } else {
                    
                    GoogleApiWrapper.BuildingInsightsResponse buildingInsightsResponse;
                    
                    try {
                        buildingInsightsResponse = GoogleApiHelper.getBuildingInsights(solarEstimateAddress.Latitude__c, solarEstimateAddress.Longitude__c);
                        
                        solarEstimateAddress.Max_Panels_Count__c = 0;
                        
                        for(GoogleApiWrapper.SolarPanelConfig solarPanelConfig : buildingInsightsResponse.solarPotential.solarPanelConfigs) {
                            if(solarPanelConfig.panelsCount > solarEstimateAddress.Max_Panels_Count__c) {
                                solarEstimateAddress.Max_Panels_Count__c = solarPanelConfig.panelsCount;
                            }
                        }
                        
                    } catch(Exception ex) {
                        solarEstimateAddress.Failed_Google_Building_Insights__c = true;
                        solarEstimateAddress.Max_Panels_Count__c = 100;
                    }
                    
                    if(solarEstimateAddress.Panels_Count__c == null) {
                        solarEstimateAddress.Set_Best_Electrical_Offset__c = true;
                    }
                    
                    Integer panelsCount = solarEstimateAddress.Set_Best_Electrical_Offset__c ? 8 : Integer.valueOf(solarEstimateAddress.Panels_Count__c);
                    Map<String, Object> result = new Map<String, Object>();
                    List<GoogleApiWrapper.RoofSegmentSummary> roofSegmentSummaries = SolarEstimateProcessHelper.prepareRoofSegmentSummaries(solarEstimateAddress, buildingInsightsResponse, panelsCount);
                    
                    if(solarEstimateAddress.Set_Best_Electrical_Offset__c) {
                        
                        Boolean needToBreak = false;
                        Decimal electricalOffset = 0;
                        
                        while(!needToBreak) {
                            
                            if(electricalOffset != 0) {
                                
                                Integer panelsCountStepSize = 0;
                                
                                if(solarEstimateAddress.Ground_Mount__c == 'Standard Ground Mount' || solarEstimateAddress.Ground_Mount__c == 'Shade Structure Ground Mount') {
                                    panelsCountStepSize = 4;
                                } else {
                                    panelsCountStepSize = Integer.valueOf(Math.ceil(Decimal.valueOf(panelsCount) / electricalOffset)) - panelsCount;
                                }
                                
                                if(solarEstimateAddress.Ground_Mount__c != 'Standard Ground Mount' && solarEstimateAddress.Ground_Mount__c != 'Shade Structure Ground Mount') {
                                    if(panelsCount + panelsCountStepSize > solarEstimateAddress.Max_Panels_Count__c) {
                                        panelsCountStepSize = Integer.valueOf(solarEstimateAddress.Max_Panels_Count__c) - panelsCount;
                                    }
                                }
                                
                                if(panelsCount + panelsCountStepSize <= solarEstimateAddress.Max_Panels_Count__c) {
                                    panelsCount += panelsCountStepSize;
                                }
                                
                                roofSegmentSummaries = SolarEstimateProcessHelper.prepareRoofSegmentSummaries(solarEstimateAddress, buildingInsightsResponse, panelsCount);
                            }
                            
                            result = createSolarProfiles(solarEstimateAddress, productionPerPanel, roofSegmentSummaries);
                            
                            electricalOffset = ((Decimal) result.get('totalBaselineMeasures') / solarEstimateAddress.Annual_kWh_Arcadia__c);
                            
                            if(panelsCount == solarEstimateAddress.Max_Panels_Count__c) {
                                needToBreak = true;
                            }
                            
                            if(!needToBreak && electricalOffset > 1) {
                                
                                while(!needToBreak && electricalOffset > 1) {
                                    
                                    if(((solarEstimateAddress.Ground_Mount__c == 'Standard Ground Mount' 
                                         || solarEstimateAddress.Ground_Mount__c == 'Shade Structure Ground Mount') 
                                        && panelsCount - 4 < 8)
                                       || panelsCount - 1 < 8) 
                                    {
                                        needToBreak = true;
                                        
                                    } else {
                                        if(solarEstimateAddress.Ground_Mount__c == 'Standard Ground Mount' || solarEstimateAddress.Ground_Mount__c == 'Shade Structure Ground Mount') {
                                            panelsCount -= 4;
                                        } else {
                                            panelsCount --;
                                        }
                                        
                                        roofSegmentSummaries = SolarEstimateProcessHelper.prepareRoofSegmentSummaries(solarEstimateAddress, buildingInsightsResponse, panelsCount);
                                        
                                        result = createSolarProfiles(solarEstimateAddress, productionPerPanel, roofSegmentSummaries);
                                        
                                        electricalOffset = ((Decimal) result.get('totalBaselineMeasures') / solarEstimateAddress.Annual_kWh_Arcadia__c);
                                    }
                                }
                                
                                needToBreak = true;
                            }
                        }
                        
                        solarEstimateAddress.Set_Best_Electrical_Offset__c = false;
                        solarEstimateAddress.Best_Panels_Count__c = panelsCount;
                        solarEstimateAddress.Panels_Count__c = panelsCount;
                        
                    } else {
                        result = createSolarProfiles(solarEstimateAddress, productionPerPanel, roofSegmentSummaries);
                    }
                    
                    if(result.containsKey('solarProviderProfileIds')) {
                        solarProviderProfileIds = (String) result.get('solarProviderProfileIds');
                    }
                    
                    if(result.containsKey('totalBaselineMeasures')) {
                        totalBaselineMeasures = (Decimal) result.get('totalBaselineMeasures');
                        solarOffset = (totalBaselineMeasures / solarEstimateAddress.Annual_kWh_Arcadia__c) * 100;
                    }
                    
                    Decimal sumOfPitchDegrees = 0;
                    
                    for(GoogleApiWrapper.RoofSegmentSummary roofSegmentSummary : roofSegmentSummaries) {
                        if(roofSegmentSummary.pitchDegrees != null) {
                            sumOfPitchDegrees += roofSegmentSummary.pitchDegrees;
                        }
                    }
                    
                    solarEstimateAddress.Roof_Segment_Summaries__c = JSON.serialize(roofSegmentSummaries);
                    solarEstimateAddress.Average_Pitch_Degrees__c  = sumOfPitchDegrees / roofSegmentSummaries.size();
                }
            }
            
            if(financeType == 'Cash') {                
                solarEstimateAddress.Solar_Provider_Profile_Ids_Cash__c = solarProviderProfileIds;
                solarEstimateAddress.Total_Baseline_Measures_Cash__c = totalBaselineMeasures;
                solarEstimateAddress.Solar_Offset_Cash__c = solarOffset;
                solarEstimateAddress.Completed_Solar_Profiles_Process_Cash__c = true;
            }
            
            if(financeType == 'Loan') {
                solarEstimateAddress.Solar_Provider_Profile_Ids_Loan__c = solarProviderProfileIds;
                solarEstimateAddress.Total_Baseline_Measures_Loan__c = totalBaselineMeasures;
                solarEstimateAddress.Solar_Offset_Loan__c = solarOffset;
                solarEstimateAddress.Completed_Solar_Profiles_Process_Loan__c = true;
            }
            
            if(financeType == 'TPO') {
                solarEstimateAddress.Solar_Provider_Profile_Ids_TPO__c = solarProviderProfileIds;
                solarEstimateAddress.Total_Baseline_Measures_TPO__c = totalBaselineMeasures;
                solarEstimateAddress.Solar_Offset_TPO__c = solarOffset;
                solarEstimateAddress.Completed_Solar_Profiles_Process_TPO__c = true;
            }
            
            update solarEstimateAddress;
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarEstimateAddress.Failed_Solar_Estimate_Process__c = true;
            
            update solarEstimateAddress; 
        }
        
        Logger.saveLog();
    }    
    
    public static Map<String, Object> createSolarProfiles(Solar_Estimate_Address__c solarEstimateAddress, Decimal productionPerPanel, List<GoogleApiWrapper.RoofSegmentSummary> roofSegmentSummaries) { 
        
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
                
                ArcadiaApiWrapper.CreateSolarProfileRequest wrapper = new ArcadiaApiWrapper.CreateSolarProfileRequest();
                wrapper.providerAccountId = solarEstimateAddress.Provider_Account_Id__c;
                wrapper.providerProfileId = solarEstimateAddress.Provider_Account_Id__c + '-pvwatts-' + roofSegmentSummary.azimuthDegrees + '-' + productionPerPanel;
                wrapper.groupBy = 'YEAR';
                wrapper.serviceTypes = 'SOLAR_PV';
                wrapper.source = source;
                wrapper.properties = property;
                
                request = arcadiaApi.profiles(JSON.serialize(wrapper, true));
                
                Integer statusCode = 200;
                String responseBody = '{"status":"Success","results":[{"providerProfileId":"12345", "baselineMeasures":[{"i":1, "v":101}]}]}';
                
                if(!Test.isRunningTest()) {
                    response = new Http().send(request);
                    
                    statusCode = response.getStatusCode();
                    responseBody = response.getBody();
                }
                
                if(statusCode == 200 || statusCode == 201) {
                    ArcadiaApiWrapper.CreateSolarProfileResponse result = (ArcadiaApiWrapper.CreateSolarProfileResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateSolarProfileResponse.Class);
                    
                    if(result.status == 'Success') {   
                        
                        solarProviderProfileIds.add(result.results[0].providerProfileId);
                        
                        totalBaselineMeasures += result.results[0].baselineMeasures[0].v;
                        
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
            throw new GenericException(errorMessage);        
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
    public static void getAnalysis(Id solarEstimateAddressId) {
        
        Solar_Estimate_Address__c solarEstimateAddress = (Solar_Estimate_Address__c) SObjectUtil.getSObjectDetailsById(solarEstimateAddressId);
        String errorMessage;
        
        try {
            
            if(solarEstimateAddress.Failed_Solar_Estimate_Process__c) {
                return;
            }
            
            State__c state = (State__c) SObjectUtil.getSObjectDetailsById(solarEstimateAddress.State_Lookup__c, 'Cash_Panel__r.Production__c,'
                                                                            + 'Loan_Panel__r.Production__c,'
                                                                            + 'TPO_Panel__r.Production__c,'
                                                                            + 'Cash_Battery__r.Standard_Price__c,'
                                                                            + 'Loan_Battery__r.Standard_Price__c,'
                                                                            + 'TPO_Battery__r.Standard_Price__c,'
                                                                            + 'Cash_Preferred__r.Dealer_Fee__c,'
                                                                            + 'Loan_Preferred__r.Dealer_Fee__c,'
                                                                            + 'Cash_Preferred__r.Payment_Factor_1__c,'
                                                                            + 'Loan_Preferred__r.Payment_Factor_1__c,'
                                                                            + 'Loan_Preferred__r.APR__c,'
                                                                            + 'Loan_Competitor__r.Dealer_Fee__c,'
                                                                            + 'Loan_Competitor__r.Payment_Factor_1__c');
            
            solarEstimateAddress.Run_Typical_Analysis__c = solarEstimateAddress.City_Tier__c == null 
                || solarEstimateAddress.City_Tier__c < 1
                || solarEstimateAddress.City_Tier__c > 3
                || (!solarEstimateAddress.Finance_Type_Available_Cash__c
                    && !solarEstimateAddress.Finance_Type_Available_Loan__c
                    && !solarEstimateAddress.Finance_Type_Available_TPO__c);
            
            if(solarEstimateAddress.Run_Typical_Analysis__c || Test.isRunningTest()) {
                
                if(!Test.isRunningTest()) {
                    solarEstimateAddress.Roof_Segment_Summaries__c = null;
                    solarEstimateAddress.Average_Pitch_Degrees__c = null;
                    solarEstimateAddress.Max_Panels_Count__c = null;
                    solarEstimateAddress.Best_Panels_Count__c = null;
                    solarEstimateAddress.Panels_Count__c = null;
                    solarEstimateAddress.Finance_Type_Available_Cash__c = false;
                    solarEstimateAddress.Finance_Type_Available_Loan__c = false;
                    solarEstimateAddress.Finance_Type_Available_TPO__c = false;
                }
                
                Map<String, Decimal> result = getTypicalAnalysis(solarEstimateAddress);
                
                solarEstimateAddress.Monthly_Savings_Typical__c = result.get('monthlySavings');
                solarEstimateAddress.Yearly_Savings_Typical__c = result.get('yearlySavings');
                solarEstimateAddress.Old_Lifetime_Utility_Cost_Typical__c = result.get('oldLifetimeUtilityCost');
                solarEstimateAddress.New_Lifetime_Solar_Cost_Typical__c = result.get('newLifetimeSolarCost');
                solarEstimateAddress.Total_Lifetime_Savings_Typical__c = result.get('totalLifetimeSavings');
            } 
            
            if(!solarEstimateAddress.Run_Typical_Analysis__c) {
                
                if(state.Auto_Recommend_Battery__c 
                   && solarEstimateAddress.Last_Successful_Process_Run_Timestamp__c == null) 
                {
                    if(solarEstimateAddress.Batteries_Count_Cash__c == null) {
                        solarEstimateAddress.Batteries_Count_Cash__c = 1;
                    }
                    
                    if(solarEstimateAddress.Batteries_Count_Loan__c == null) {
                        solarEstimateAddress.Batteries_Count_Loan__c = 1;
                    }
                    
                    if(solarEstimateAddress.Batteries_Count_TPO__c == null) {
                        solarEstimateAddress.Batteries_Count_TPO__c = 1;
                    }
                }
                
                Decimal cityTierCost = SolarEstimateProcessHelper.getCityTierCost(solarEstimateAddress);
                Decimal pitchDegreesCost = SolarEstimateProcessHelper.getPitchDegreesCost(solarEstimateAddress);
                Decimal solarTaxFilingServiceCost = SolarEstimateProcessHelper.getSolarTaxFilingServiceCost(solarEstimateAddress);
                Map<String, List<Decimal>> backupBatteryPrices = SolarEstimateProcessHelper.getBackupBatteryPrices(state);
                
                SolarEstimateProcessHelper.doCashCalculation(solarEstimateAddress, state, backupBatteryPrices, 
                                                             cityTierCost, pitchDegreesCost, solarTaxFilingServiceCost);
                SolarEstimateProcessHelper.doLoanCalculation(solarEstimateAddress, state, backupBatteryPrices, 
                                                             cityTierCost, pitchDegreesCost, solarTaxFilingServiceCost);
                SolarEstimateProcessHelper.doTPOCalculation(solarEstimateAddress, state, backupBatteryPrices, 
                                                            cityTierCost, pitchDegreesCost, solarTaxFilingServiceCost);
                
                if(solarEstimateAddress.Finance_Type_Available_Cash__c) {
                    
                    if(solarEstimateAddress.Batteries_Available_Cash__c) {
                        createStorageProfile(solarEstimateAddress, state, 'Cash');
                    }
                    
                    Map<String, Decimal> result = getAnalysis(solarEstimateAddress, 'Cash');
                    
                    solarEstimateAddress.Monthly_Savings_Cash__c = result.get('monthlySavings');
                    solarEstimateAddress.Yearly_Savings_Cash__c = result.get('yearlySavings');
                    solarEstimateAddress.Old_Lifetime_Utility_Cost_Cash__c = result.get('oldLifetimeUtilityCost');
                    solarEstimateAddress.New_Lifetime_Solar_Cost_Cash__c = result.get('newLifetimeSolarCost');
                    solarEstimateAddress.Total_Lifetime_Savings_Cash__c = result.get('totalLifetimeSavings');
                }
                
                if(solarEstimateAddress.Finance_Type_Available_Loan__c) {
                    
                    if(solarEstimateAddress.Batteries_Available_Loan__c) {
                        createStorageProfile(solarEstimateAddress, state, 'Loan');
                    }
                    
                    Map<String, Decimal> result = getAnalysis(solarEstimateAddress, 'Loan');
                    
                    solarEstimateAddress.Monthly_Savings_Loan__c = result.get('monthlySavings');
                    solarEstimateAddress.Yearly_Savings_Loan__c = result.get('yearlySavings');
                    solarEstimateAddress.Old_Lifetime_Utility_Cost_Loan__c = result.get('oldLifetimeUtilityCost');
                    solarEstimateAddress.New_Lifetime_Solar_Cost_Loan__c = result.get('newLifetimeSolarCost');
                    solarEstimateAddress.Total_Lifetime_Savings_Loan__c = result.get('totalLifetimeSavings');
                }
                
                if(solarEstimateAddress.Finance_Type_Available_TPO__c) {
                    
                    if(solarEstimateAddress.Batteries_Available_TPO__c) {
                        createStorageProfile(solarEstimateAddress, state, 'TPO');
                    }
                    
                    Map<String, Decimal> result = getAnalysis(solarEstimateAddress, 'TPO');
                    
                    solarEstimateAddress.Monthly_Savings_TPO__c = result.get('monthlySavings');
                    solarEstimateAddress.Yearly_Savings_TPO__c = result.get('yearlySavings');
                    solarEstimateAddress.Old_Lifetime_Utility_Cost_TPO__c = result.get('oldLifetimeUtilityCost');
                    solarEstimateAddress.New_Lifetime_Solar_Cost_TPO__c = result.get('newLifetimeSolarCost');
                    solarEstimateAddress.Total_Lifetime_Savings_TPO__c = result.get('totalLifetimeSavings');
                }
            }
            
            solarEstimateAddress.Completed_Analysis_Process__c = true;
            
            update solarEstimateAddress;
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarEstimateAddress.Failed_Solar_Estimate_Process__c = true;
            
            update solarEstimateAddress; 
        }
        
        Logger.saveLog();
    }
    
    public static void createStorageProfile(Solar_Estimate_Address__c solarEstimateAddress, State__c state, String financeType) {
        
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
                
                if((financeType == 'Loan' || financeType == 'TPO') && productId == state.Cash_Battery__c) {
                    storageProviderProfileId = solarEstimateAddress.Storage_Profile_Id_Cash__c;
                    
                } else if(financeType == 'TPO' && productId == state.Loan_Battery__c) {
                    storageProviderProfileId = solarEstimateAddress.Storage_Profile_Id_Loan__c;
                    
                } else {
                    
                    String fromDateTime = String.valueOf(Date.today().toStartOfMonth().addMonths(-1));
                    
                    Product2 battery = [SELECT Id, Rated_Output_Power__c, Energy_Capacity__c, Min_SoC__c, Max_SoC__c, Initial_SoC__c, DC_Coupled__c, AC_to_DC_Efficiency__c, DC_to_AC_Efficiency__c,
                                        Input_Efficiency__c, Solar_DC_to_AC_Efficiency__c, Allow_Battery_to_Grid__c, Allow_Grid_to_Battery__c, Allow_Solar_to_Grid__c, Allow_Solar_to_Battery__c
                                        FROM Product2 
                                        WHERE Id = :productId];
                    
                    ArcadiaApiWrapper.Consumption consumption = new ArcadiaApiWrapper.Consumption();
                    consumption.providerProfileId = solarEstimateAddress.Provider_Account_Id__c + '-bills';
                    
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
                        solarProviderProfileIdsStr = solarEstimateAddress.Solar_Provider_Profile_Ids_Cash__c;
                    }
                    
                    if(financeType == 'Loan') {
                        solarProviderProfileIdsStr = solarEstimateAddress.Solar_Provider_Profile_Ids_Loan__c;
                    }
                    
                    if(financeType == 'TPO') {
                        solarProviderProfileIdsStr = solarEstimateAddress.Solar_Provider_Profile_Ids_TPO__c;
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
                    storage.mainTariffId = solarEstimateAddress.Master_Tariff_Id__c;
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
                    
                    ArcadiaApiWrapper.CreateStorageProfileRequest wrapper = new ArcadiaApiWrapper.CreateStorageProfileRequest();
                    wrapper.providerAccountId = solarEstimateAddress.Provider_Account_Id__c;
                    wrapper.providerProfileId = solarEstimateAddress.Provider_Account_Id__c + '-storage-' + String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
                    wrapper.fromDateTime = fromDateTime;
                    wrapper.consumption = consumption;
                    wrapper.solar = solars;
                    wrapper.storage = storage;
                    
                    request = arcadiaApi.profilesStorage(JSON.serialize(wrapper, true));
                    
                    Integer statusCode = 200;
                    String responseBody = '{"status":"Success","results":[{"usageProfile":{"providerProfileId":"Test"}}]}';
                    
                    if(!Test.isRunningTest()) {
                        response = new Http().send(request);
                        
                        statusCode = response.getStatusCode();
                        responseBody = response.getBody();
                    }
                    
                    if(statusCode == 200 || statusCode == 201) {
                        ArcadiaApiWrapper.CreateStorageProfileResponse result = (ArcadiaApiWrapper.CreateStorageProfileResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.CreateStorageProfileResponse.Class);
                        
                        if(result.status == 'Success') {
                            
                            storageProviderProfileId = result.results[0].usageProfile.providerProfileId;
                            
                        } else {
                            Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                            
                            errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                        }
                        
                    } else {
                        Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                        
                        errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                    }
                }
            }
            
            if(financeType == 'Cash') {
                solarEstimateAddress.Storage_Profile_Id_Cash__c = storageProviderProfileId;
            }
            
            if(financeType == 'Loan') {
                solarEstimateAddress.Storage_Profile_Id_Loan__c = storageProviderProfileId;
            }
            
            if(financeType == 'TPO') {
                solarEstimateAddress.Storage_Profile_Id_TPO__c = storageProviderProfileId;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        Logger.saveLog();
        
        if(String.isNotBlank(errorMessage)) {
            throw new GenericException(errorMessage);        
        }
    }
    
    public static Map<String, Decimal> getAnalysis(Solar_Estimate_Address__c solarEstimateAddress, String financeType) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            String fromDateTime = String.valueOf(Date.today());
            
            ArcadiaApiWrapper.RateBand rateBand = new ArcadiaApiWrapper.RateBand();
            
            if(financeType == 'Cash') {
                rateBand.rateAmount = solarEstimateAddress.Final_Price_Cash__c;
            }
            
            if(financeType == 'Loan') {
                rateBand.rateAmount = solarEstimateAddress.Final_Price_Loan__c;
            }
            
            if(financeType == 'TPO') {
                rateBand.rateAmount = solarEstimateAddress.Final_Price_TPO__c;
            }
            
            ArcadiaApiWrapper.RateInput rateInput = new ArcadiaApiWrapper.RateInput();
            rateInput.scenarios = 'solar';
            rateInput.chargeType = 'FIXED_PRICE';
            rateInput.rateBands = new List<ArcadiaApiWrapper.RateBand>{rateBand};
                
                List<ArcadiaApiWrapper.PropertyInput> propertyInputs = new List<ArcadiaApiWrapper.PropertyInput>();
            
            ArcadiaApiWrapper.PropertyInput propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'before';
            propertyInput.keyName = 'masterTariffId';
            propertyInput.dataValue = solarEstimateAddress.Master_Tariff_Id__c;
            
            propertyInputs.add(propertyInput);
            
            propertyInput = new ArcadiaApiWrapper.PropertyInput();
            propertyInput.scenarios = 'after';
            propertyInput.keyName = 'masterTariffId';
            propertyInput.dataValue = solarEstimateAddress.Master_Tariff_Id__c;
            
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
            propertyInput.dataValue = solarEstimateAddress.Provider_Account_Id__c + '-bills';
            
            propertyInputs.add(propertyInput);
            
            String solarProviderProfileIds;
            
            if(financeType == 'Cash') {
                solarProviderProfileIds = solarEstimateAddress.Solar_Provider_Profile_Ids_Cash__c;
            }
            
            if(financeType == 'Loan') {
                solarProviderProfileIds = solarEstimateAddress.Solar_Provider_Profile_Ids_Loan__c;
            }
            
            if(financeType == 'TPO') {
                solarProviderProfileIds = solarEstimateAddress.Solar_Provider_Profile_Ids_TPO__c;
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
                storageProviderProfileId = solarEstimateAddress.Storage_Profile_Id_Cash__c;
            }
            
            if(financeType == 'Loan') {
                storageProviderProfileId = solarEstimateAddress.Storage_Profile_Id_Loan__c;
            }
            
            if(financeType == 'TPO') {
                storageProviderProfileId = solarEstimateAddress.Storage_Profile_Id_TPO__c;
            }
            
            if(String.isNotBlank(storageProviderProfileId)) {
                propertyInput = new ArcadiaApiWrapper.PropertyInput();
                propertyInput.scenarios = 'after,solar';
                propertyInput.keyName = 'storageProfileId';
                propertyInput.dataValue = storageProviderProfileId;
                
                propertyInputs.add(propertyInput);
            }
            
            ArcadiaApiWrapper.AnalysisRequest wrapper = new ArcadiaApiWrapper.AnalysisRequest();
            wrapper.providerAccountId = solarEstimateAddress.Provider_Account_Id__c;
            wrapper.fromDateTime = fromDateTime;
            wrapper.autoBaseline = true;
            wrapper.useIntelligentBaselining = true;
            wrapper.tariffEffectiveOn = fromDateTime;
            wrapper.propertyInputs = propertyInputs;
            wrapper.rateInputs = new List<ArcadiaApiWrapper.RateInput>{rateInput};
                
                request = arcadiaApi.analysis(JSON.serialize(wrapper, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"summary":{"lifetimeWithoutCost":100,"lifetimeSolarCost":100,"preTotalCost":100,"postTotalCost":100}}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                ArcadiaApiWrapper.AnalysisResponse result = (ArcadiaApiWrapper.AnalysisResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.AnalysisResponse.Class);
                
                if(result.status == 'Success') {
                    
                    ArcadiaApiWrapper.AnalysisSummary summary = result.results[0].summary;
                    
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
                    Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            throw new GenericException(errorMessage); 
        }
        
        Logger.saveLog();
        
        return null;
    }
    
    public static Map<String, Decimal> getTypicalAnalysis(Solar_Estimate_Address__c solarEstimateAddress) {
        
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
            propertyInput.dataValue = solarEstimateAddress.Master_Tariff_Id__c;
            propertyInput.scenarios = 'before';
            
            propertyInputs.add(propertyInput);
            
            ArcadiaApiWrapper.AnalysisRequest wrapper = new ArcadiaApiWrapper.AnalysisRequest();
            wrapper.providerAccountId = solarEstimateAddress.Provider_Account_Id__c;
            wrapper.fromDateTime = fromDateTime;
            wrapper.propertyInputs = propertyInputs;
            wrapper.rateInputs = new List<ArcadiaApiWrapper.RateInput>{rateInput};
                
                request = arcadiaApi.analysis(JSON.serialize(wrapper, true));
            
            Integer statusCode = 200;
            String responseBody = '{"status":"Success","results":[{"summary":{"lifetimeWithoutCost":100,"lifetimeSolarCost":100,"preTotalCost":100,"postTotalCost":100}}]}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                
                ArcadiaApiWrapper.AnalysisResponse result = (ArcadiaApiWrapper.AnalysisResponse) JSON.deserialize(responseBody, ArcadiaApiWrapper.AnalysisResponse.Class);
                
                if(result.status == 'Success') {
                    
                    ArcadiaApiWrapper.AnalysisSummary summary = result.results[0].summary;
                    
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
                    Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                    
                    errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
                }
                
            } else {
                Logger.error('Bad Response From API', solarEstimateAddress.Id).setHttpRequestDetails(request).setHttpResponseDetails(response);
                
                errorMessage = 'Bad Response From API. Status Code: ' + statusCode + ', Response Body: ' + responseBody;
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex).setHttpRequestDetails(request).setHttpResponseDetails(response);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        Logger.saveLog();
        
        if(String.isNotBlank(errorMessage)) {
            throw new GenericException(errorMessage);        
        }
        
        return null;
    }
}