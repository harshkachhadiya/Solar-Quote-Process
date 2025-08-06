public without sharing class SolarEstimateProcessHelper {
    
    private static Integer maxBatteriesCount = 3;
    
    @AuraEnabled
    public static Map<String, String> getDefaultValuesForSolarEstimate() {
        
        Map<String, String> result = new Map<String, String>();
        
        for(Product2 product : [SELECT Name, Product_Image_URL__c, Learn_More__c 
                                FROM Product2 
                                WHERE Name IN ('Ground Mount',
                                               'Shade Structure Ground Mount',
                                               'SafeStreets / Google Smart Home: Basics Package',
                                               'SafeStreets / Google Smart Home: Essentials Package',
                                               'SafeStreets / Google Smart Home: Premium Package',
                                               'Solar Tax Filing Service')]) 
        {
            if(product.Name == 'Ground Mount') {
                result.put('groundMountImageUrl', '/resource/' + product.Product_Image_URL__c);
                result.put('groundMountDescription', product.Learn_More__c);
            }
            
            if(product.Name == 'Shade Structure Ground Mount') {
                result.put('shadeStructureGroundMountImageUrl', '/resource/' + product.Product_Image_URL__c);
                result.put('shadeStructureGroundMountDescription', product.Learn_More__c);
            }
            
            if(product.Name == 'SafeStreets / Google Smart Home: Basics Package') {
                result.put('safeStreetsBasicsPackageImageUrl', '/resource/' + product.Product_Image_URL__c);
                result.put('safeStreetsBasicsPackageDescription', product.Learn_More__c);
            }
            
            if(product.Name == 'SafeStreets / Google Smart Home: Essentials Package') {
                result.put('safeStreetsEssentialsPackageImageUrl', '/resource/' + product.Product_Image_URL__c);
                result.put('safeStreetsEssentialsPackageDescription', product.Learn_More__c);
            }
            
            if(product.Name == 'SafeStreets / Google Smart Home: Premium Package') {
                result.put('safeStreetsPremiumPackageImageUrl', '/resource/' + product.Product_Image_URL__c);
                result.put('safeStreetsPremiumPackageDescription', product.Learn_More__c);
            }  
            
            if(product.Name == 'Solar Tax Filing Service') {
                result.put('solarTaxFilingServiceImageUrl', '/resource/' + product.Product_Image_URL__c);
                result.put('solarTaxFilingServiceDescription', product.Learn_More__c);
            }  
        }
        
        return result;
    }
    
    @AuraEnabled
    public static Solar_Estimate_Address__c upsertSolarEstimateAddress(Id recordId) {
        
        String sObjectApiName = SObjectUtil.getSObjectApiNameById(recordId);
        
        if(sObjectApiName == 'Lead') {
            
            Lead ld = (Lead) SObjectUtil.getSObjectDetailsById(recordId);
            
            Solar_Estimate_Address__c solarEstimateAddress = new Solar_Estimate_Address__c();
            solarEstimateAddress.Id = ld.Solar_Estimate_Address__c;
            solarEstimateAddress.Lead__c = ld.Id;
            solarEstimateAddress.Address__c = ld.Address_Formula__c;
            
            if(ld.Latitude != null
               && ld.Longitude!= null) 
            {
                solarEstimateAddress.Latitude__c = ld.Latitude;
                solarEstimateAddress.Longitude__c = ld.Longitude;
            }
            
            solarEstimateAddress.State__c = ld.State;
            solarEstimateAddress.Postal_Code__c = ld.PostalCode;
            solarEstimateAddress.LSE_Id__c = ld.Lse_Id__c;
            solarEstimateAddress.Average_Monthly_Bill__c = ld.Average_Monthly_Bill__c;
            solarEstimateAddress.Preferred_Finance_Type__c = 'TPO';
            upsert solarEstimateAddress;
            
            return solarEstimateAddress;
        }
        
        return null;
    }
    
    @AuraEnabled
    public static void startGeneralProcess(Id solarEstimateAddressId) { 
        
        Solar_Estimate_Address__c solarEstimateAddress = (Solar_Estimate_Address__c) SObjectUtil.getSObjectDetailsById(solarEstimateAddressId);
        String errorMessage;
        
        try {
            
            List<Genability_Provider_Account_Id__c> genabilityProviderAccountIds = new List<Genability_Provider_Account_Id__c>();
            
            if(String.isNotBlank(solarEstimateAddress.Genability_Provider_Account_Id__c)) {
                
                genabilityProviderAccountIds = [SELECT Id, Provider_Account_Id__c, First_Used_Date_Time__c 
                                                FROM Genability_Provider_Account_Id__c 
                                                WHERE Id = :solarEstimateAddress.Genability_Provider_Account_Id__c
                                                LIMIT 1];
            } 
            
            if(genabilityProviderAccountIds.isEmpty()) { 
                
                State__c state = (State__c) SObjectUtil.getSObjectDetailsById(solarEstimateAddress.State_Lookup__c);
                
                if(state.Auto_Recommend_Battery__c) {
                    genabilityProviderAccountIds = [SELECT Id, Provider_Account_Id__c, First_Used_Date_Time__c 
                                                    FROM Genability_Provider_Account_Id__c 
                                                    WHERE Genability_Monthly_Limit__r.Is_Active__c = true
                                                    AND Storage_Account__c = true
                                                    ORDER by Last_Used_Date_Time__c ASC NULLS FIRST
                                                    LIMIT 1];
                    
                } else {
                    genabilityProviderAccountIds = [SELECT Id, Provider_Account_Id__c, First_Used_Date_Time__c 
                                                    FROM Genability_Provider_Account_Id__c 
                                                    WHERE Genability_Monthly_Limit__r.Is_Active__c = true
                                                    AND Storage_Account__c = false
                                                    ORDER by Last_Used_Date_Time__c ASC NULLS FIRST
                                                    LIMIT 1];
                }
            }
            
            if(!genabilityProviderAccountIds.isEmpty()) {
                
                DateTime currentDateTime = DateTime.now();
                
                if(genabilityProviderAccountIds[0].First_Used_Date_Time__c == null) {
                    genabilityProviderAccountIds[0].First_Used_Date_Time__c = currentDateTime;
                }
                
                genabilityProviderAccountIds[0].Last_Used_Date_Time__c = currentDateTime;    
                
                solarEstimateAddress.Genability_Provider_Account_Id__c = genabilityProviderAccountIds[0].Id;
                
                if(solarEstimateAddress.City_Tier__c == null) {
                    solarEstimateAddress.City_Tier__c = VitlApiHelper.getCitiesFromZip(solarEstimateAddress.Postal_Code__c).cities[0].tier;
                }
                
                if(solarEstimateAddress.Latitude__c == null 
                   || solarEstimateAddress.Longitude__c == null)
                {
                    GoogleApiWrapper.Location location = GoogleApiHelper.getGeocode(solarEstimateAddress.Address__c);
                    
                    if(location != null) {
                        solarEstimateAddress.Latitude__c = location.lat;
                        solarEstimateAddress.Longitude__c = location.lng;
                    }
                }
                
                solarEstimateAddress.Completed_General_Process__c = true;
                
                update genabilityProviderAccountIds[0];
                
                update solarEstimateAddress;
                
            } else {
                Logger.error('Error: No matching ProviderAccountId found.', solarEstimateAddress.Id);
                
                Logger.saveLog();
                
                throw new GenericException('Error: No matching ProviderAccountId found.');
            }
            
        } catch(Exception ex) {
            Logger.error('Exception', solarEstimateAddress.Id, ex);
            
            errorMessage = 'Exception: ' + ex.getMessage();
        }
        
        if(String.isNotBlank(errorMessage)) {
            solarEstimateAddress.Failed_Solar_Estimate_Process__c = true;
            
            update solarEstimateAddress; 
        }
    }
    
    public static List<GoogleApiWrapper.RoofSegmentSummary> prepareRoofSegmentSummaries(Solar_Estimate_Address__c solarEstimateAddress, GoogleApiWrapper.BuildingInsightsResponse buildingInsightsResponse, Integer panelsCount) {
        
        List<GoogleApiWrapper.RoofSegmentSummary> roofSegmentSummaries = new List<GoogleApiWrapper.RoofSegmentSummary>();
        
        if(solarEstimateAddress.Ground_Mount__c == 'Standard Ground Mount') {
            GoogleApiWrapper.RoofSegmentSummary roofSegmentSummary = new GoogleApiWrapper.RoofSegmentSummary();
            roofSegmentSummary.azimuthDegrees = 180;
            roofSegmentSummary.pitchDegrees = 20;
            roofSegmentSummary.panelsCount = panelsCount;
            
            roofSegmentSummaries.add(roofSegmentSummary);
            
        } else if(solarEstimateAddress.Ground_Mount__c == 'Shade Structure Ground Mount') {
            GoogleApiWrapper.RoofSegmentSummary roofSegmentSummary = new GoogleApiWrapper.RoofSegmentSummary();
            roofSegmentSummary.azimuthDegrees = 180;
            roofSegmentSummary.pitchDegrees = 0;
            roofSegmentSummary.panelsCount = panelsCount;
            
            roofSegmentSummaries.add(roofSegmentSummary);
            
        } else if(solarEstimateAddress.Failed_Google_Building_Insights__c) {
            
            Integer baseCount = panelsCount / 3;
            Integer remainder = panelsCount - (3 * baseCount);
            
            List<Decimal> azimuthValues = new List<Decimal>{90, 180, 270};
                
                for (Integer i = 0; i < 3; i++) {
                    GoogleApiWrapper.RoofSegmentSummary roofSegmentSummary = new GoogleApiWrapper.RoofSegmentSummary();
                    roofSegmentSummary.pitchDegrees = 25;
                    roofSegmentSummary.azimuthDegrees = azimuthValues[i];
                    
                    roofSegmentSummary.panelsCount = baseCount + ((i < remainder) ? 1 : 0);
                    
                    roofSegmentSummaries.add(roofSegmentSummary);
                }
            
        } else {
            
            for(GoogleApiWrapper.SolarPanelConfig solarPanelConfig : buildingInsightsResponse.solarPotential.solarPanelConfigs) {
                if(solarPanelConfig.panelsCount == panelsCount) {
                    roofSegmentSummaries = solarPanelConfig.roofSegmentSummaries;
                }
            }
        }
        
        return roofSegmentSummaries;
    }
    
    public static void doCashCalculation(Solar_Estimate_Address__c solarEstimateAddress, State__c state, Map<String, List<Decimal>> backupBatteryPrices,
                                         Decimal cityTierCost, Decimal pitchDegreesCost, Decimal solarTaxFilingServiceCost)
    {
        solarEstimateAddress.Finance_Type_Available_Cash__c = String.isNotBlank(state.Cash_Panel__c) 
            && state.Cash_Panel__r.Production__c > 0
            && state.Cash_PPW__c > 0
            && state.Cash_Preferred__r.Dealer_Fee__c > 0 
            && state.Cash_Preferred__r.Dealer_Fee__c != 100;
        
        if(solarEstimateAddress.Finance_Type_Available_Cash__c) {
            solarEstimateAddress.Batteries_Available_Cash__c =  backupBatteryPrices.containsKey('Cash');
            
            solarEstimateAddress.System_Size_kW_Cash__c = (solarEstimateAddress.Panels_Count__c * state.Cash_Panel__r.Production__c) / 1000;
            solarEstimateAddress.Additional_Cost_Cash__c = SolarEstimateProcessHelper.doAdditionalCostCalculation(solarEstimateAddress, backupBatteryPrices, 'Cash');
            solarEstimateAddress.Base_System_Cost_Cash__c = solarEstimateAddress.System_Size_kW_Cash__c * state.Cash_PPW__c * 1000;
            solarEstimateAddress.Total_System_Cost_Cash__c = solarEstimateAddress.Base_System_Cost_Cash__c + solarEstimateAddress.Additional_Cost_Cash__c + cityTierCost + pitchDegreesCost + solarTaxFilingServiceCost;
            solarEstimateAddress.Gross_System_Cost_Cash__c = solarEstimateAddress.Total_System_Cost_Cash__c / (1 - (state.Cash_Preferred__r.Dealer_Fee__c / 100));
            solarEstimateAddress.Federal_ITC_Cash__c = solarEstimateAddress.Gross_System_Cost_Cash__c * 0.3;
            solarEstimateAddress.Domestic_Content_Credit_Cash__c = solarEstimateAddress.Gross_System_Cost_Cash__c * 0.1;
            solarEstimateAddress.Depreciation_Cash__c = solarEstimateAddress.Solar_Tax_Filing_Service__c
                ? getDepreciation(solarEstimateAddress, state, 'Cash')
                : 0;
            solarEstimateAddress.Incentives_Cash__c = solarEstimateAddress.Federal_ITC_Cash__c + solarEstimateAddress.Domestic_Content_Credit_Cash__c + solarEstimateAddress.Depreciation_Cash__c;
            solarEstimateAddress.Final_Price_Cash__c = solarEstimateAddress.Gross_System_Cost_Cash__c - solarEstimateAddress.Incentives_Cash__c;
            
            Decimal competitorBaseSystemCostCash = solarEstimateAddress.System_Size_kW_Cash__c * state.Competitor_Cash_PPW__c * 1000;
            Decimal competitorSystemCostCash = competitorBaseSystemCostCash + solarEstimateAddress.Additional_Cost_Cash__c + cityTierCost + pitchDegreesCost + solarTaxFilingServiceCost;
            Decimal competitorGrossSystemCostCash = competitorSystemCostCash / (1 - (state.Cash_Preferred__r.Dealer_Fee__c / 100));
            Decimal competitorFederalITCCash = competitorGrossSystemCostCash * 0.3;
            Decimal competitorIncentivesCash = competitorFederalITCCash;
            
            solarEstimateAddress.Competitor_Incentives_Cash__c = competitorIncentivesCash;
            solarEstimateAddress.Competitor_Final_Price_Cash__c = competitorGrossSystemCostCash - competitorIncentivesCash;
        }
    }
    
    public static void doLoanCalculation(Solar_Estimate_Address__c solarEstimateAddress, State__c state, Map<String, List<Decimal>> backupBatteryPrices,
                                         Decimal cityTierCost, Decimal pitchDegreesCost, Decimal solarTaxFilingServiceCost) 
    {
        solarEstimateAddress.Finance_Type_Available_Loan__c = String.isNotBlank(state.Loan_Panel__c) 
            && state.Loan_Panel__r.Production__c > 0
            && state.Loan_PPW__c > 0
            && String.isNotBlank(state.Loan_Panel__c) 
            && state.Loan_Preferred__r.Dealer_Fee__c > 0 
            && state.Loan_Preferred__r.Dealer_Fee__c != 100
            && state.Loan_Preferred__r.Payment_Factor_1__c > 0;
        
        if(solarEstimateAddress.Finance_Type_Available_Loan__c) {
            solarEstimateAddress.Batteries_Available_Loan__c =  backupBatteryPrices.containsKey('Loan');
            
            solarEstimateAddress.System_Size_kW_Loan__c = (solarEstimateAddress.Panels_Count__c * state.Loan_Panel__r.Production__c) / 1000;
            solarEstimateAddress.Additional_Cost_Loan__c = SolarEstimateProcessHelper.doAdditionalCostCalculation(solarEstimateAddress, backupBatteryPrices, 'Loan');
            solarEstimateAddress.Base_System_Cost_Loan__c = solarEstimateAddress.System_Size_kW_Loan__c * state.Loan_PPW__c * 1000;
            solarEstimateAddress.Total_System_Cost_Loan__c = solarEstimateAddress.Base_System_Cost_Loan__c + solarEstimateAddress.Additional_Cost_Loan__c + cityTierCost + pitchDegreesCost + solarTaxFilingServiceCost;
            solarEstimateAddress.Gross_System_Cost_Loan__c = solarEstimateAddress.Total_System_Cost_Loan__c / (1 - (state.Loan_Preferred__r.Dealer_Fee__c / 100));
            solarEstimateAddress.Federal_ITC_Loan__c = solarEstimateAddress.Gross_System_Cost_Loan__c * 0.3;
            solarEstimateAddress.Domestic_Content_Credit_Loan__c = solarEstimateAddress.Gross_System_Cost_Loan__c * 0.1;
            solarEstimateAddress.Depreciation_Loan__c = solarEstimateAddress.Solar_Tax_Filing_Service__c
                ? getDepreciation(solarEstimateAddress, state, 'Loan')
                : 0;
            solarEstimateAddress.Incentives_Loan__c = solarEstimateAddress.Federal_ITC_Loan__c + solarEstimateAddress.Domestic_Content_Credit_Loan__c + solarEstimateAddress.Depreciation_Loan__c;
            solarEstimateAddress.Final_Price_Loan__c = solarEstimateAddress.Gross_System_Cost_Loan__c * state.Loan_Preferred__r.Payment_Factor_1__c;
            
            Decimal competitorBaseSystemCostLoan = solarEstimateAddress.System_Size_kW_Loan__c * state.Competitor_Cash_PPW__c * 1000;
            Decimal competitorSystemCostLoan = competitorBaseSystemCostLoan + solarEstimateAddress.Additional_Cost_Loan__c + cityTierCost + pitchDegreesCost + solarTaxFilingServiceCost;
            Decimal competitorGrossSystemCostLoan = competitorSystemCostLoan / (1 - (state.Loan_Competitor__r.Dealer_Fee__c / 100));
            Decimal competitorFederalITCLoan = competitorGrossSystemCostLoan * 0.3;
            Decimal competitorIncentivesLoan = competitorFederalITCLoan;
            Decimal competitorFinalPriceLoan = competitorGrossSystemCostLoan * state.Loan_Competitor__r.Payment_Factor_1__c;
            
            solarEstimateAddress.Competitor_Incentives_Loan__c = competitorIncentivesLoan;
            solarEstimateAddress.Competitor_Final_Price_Loan__c = competitorFinalPriceLoan;
        }
    }
    
    public static void doTPOCalculation(Solar_Estimate_Address__c solarEstimateAddress, State__c state, Map<String, List<Decimal>> backupBatteryPrices,
                                        Decimal cityTierCost, Decimal pitchDegreesCost, Decimal solarTaxFilingServiceCost) 
    {
        solarEstimateAddress.Finance_Type_Available_TPO__c = String.isNotBlank(state.TPO_Panel__c) 
            && state.TPO_Panel__r.Production__c > 0
            && state.TPO_PPW__c > 0;
        
        if(solarEstimateAddress.Finance_Type_Available_TPO__c) {
            solarEstimateAddress.Batteries_Available_TPO__c =  backupBatteryPrices.containsKey('TPO');
            
            solarEstimateAddress.System_Size_kW_TPO__c = (solarEstimateAddress.Panels_Count__c * state.TPO_Panel__r.Production__c) / 1000;
            solarEstimateAddress.Additional_Cost_TPO__c = SolarEstimateProcessHelper.doAdditionalCostCalculation(solarEstimateAddress, backupBatteryPrices, 'TPO');
            solarEstimateAddress.Base_System_Cost_TPO__c = solarEstimateAddress.System_Size_kW_TPO__c * state.TPO_PPW__c * 1000;
            solarEstimateAddress.Total_System_Cost_TPO__c = solarEstimateAddress.Base_System_Cost_TPO__c + solarEstimateAddress.Additional_Cost_TPO__c + cityTierCost + pitchDegreesCost + (state.TPO_Type__c == 'Lease' ? solarTaxFilingServiceCost : 0);
            solarEstimateAddress.Target_PPW_TPO__c = solarEstimateAddress.Total_System_Cost_TPO__c / (solarEstimateAddress.System_Size_kW_TPO__c * 1000);
            solarEstimateAddress.Solar_Production_TPO__c = roundDownToNearest(solarEstimateAddress.Annual_kWh_Arcadia__c / solarEstimateAddress.System_Size_kW_TPO__c, 50);
            
            List<Pricing_Cube__c> priceCubes = [SELECT Id, Price_per_kWh__c 
                                                FROM Pricing_Cube__c 
                                                WHERE Yield_Factor__c = :solarEstimateAddress.Solar_Production_TPO__c
                                                AND Battery__c = :(solarEstimateAddress.Batteries_Available_TPO__c && solarEstimateAddress.Batteries_Count_TPO__c > 0)
                                                AND PPW__c >= :solarEstimateAddress.Target_PPW_TPO__c
                                                ORDER BY PPW__c ASC 
                                                LIMIT 1];
            
            if(priceCubes.isEmpty()) {
                solarEstimateAddress.Finance_Type_Available_TPO__c = false;
                
            } else {
                solarEstimateAddress.Price_Per_kWh_TPO__c = priceCubes[0].Price_per_kWh__c;
                solarEstimateAddress.Final_Price_TPO__c = (solarEstimateAddress.Solar_Production_TPO__c * solarEstimateAddress.System_Size_kW_TPO__c * solarEstimateAddress.Price_Per_kWh_TPO__c) / 12;
            }
        }
    }
    
    public static Decimal getCityTierCost(Solar_Estimate_Address__c solarEstimateAddress) {
        
        List<Discount_Config__c> discountConfigs = [SELECT Price__c
                                                    FROM Discount_Config__c
                                                    WHERE Product__r.Name = 'Distance Adder'
                                                    AND Min_Quantity__c = :solarEstimateAddress.City_Tier__c
                                                    AND Max_Quantity__c = :solarEstimateAddress.City_Tier__c
                                                    LIMIT 1];
        
        return !discountConfigs.isEmpty() 
            ? discountConfigs[0].Price__c 
            : 0;
    }
    
    public static Decimal getPitchDegreesCost(Solar_Estimate_Address__c solarEstimateAddress) {
        
        if(solarEstimateAddress.Average_Pitch_Degrees__c <= 10) {
            return 0;
        }
        
        List<Discount_Config__c> discountConfigs = [SELECT Price__c 
                                                    FROM Discount_Config__c 
                                                    WHERE Product__r.Name = 'Flat roof (<10 degrees)'
                                                    LIMIT 1];
        
        return !discountConfigs.isEmpty()
            ? discountConfigs[0].Price__c 
            : 0;
    }
    
    public static Decimal getSolarTaxFilingServiceCost(Solar_Estimate_Address__c solarEstimateAddress) {
        
        List<Discount_Config__c> discountConfigs = [SELECT Price__c 
                                                    FROM Discount_Config__c 
                                                    WHERE Product__r.Name = 'TaxHive Solar Credits'
                                                    LIMIT 1];
        
        return !discountConfigs.isEmpty()
            ? discountConfigs[0].Price__c 
            : 0;
    }
    
    private static Decimal doAdditionalCostCalculation(Solar_Estimate_Address__c solarEstimateAddress, Map<String, List<Decimal>> backupBatteryPrices, String financeType) {
        
        Decimal systemSize;
        Boolean batteriesAvailable;
        Decimal batteriesCount;
        
        if(financeType == 'Cash') {
            systemSize = solarEstimateAddress.System_Size_kW_Cash__c;
            batteriesAvailable = solarEstimateAddress.Batteries_Available_Cash__c;
            batteriesCount = solarEstimateAddress.Batteries_Count_Cash__c;
        }
        
        if(financeType == 'Loan') {
            systemSize = solarEstimateAddress.System_Size_kW_Loan__c;
            batteriesAvailable = solarEstimateAddress.Batteries_Available_Loan__c;
            batteriesCount = solarEstimateAddress.Batteries_Count_Loan__c;
        }
        
        if(financeType == 'TPO') {
            systemSize = solarEstimateAddress.System_Size_kW_TPO__c;
            batteriesAvailable = solarEstimateAddress.Batteries_Available_TPO__c;
            batteriesCount = solarEstimateAddress.Batteries_Count_TPO__c;
        }
        
        Decimal additionalCost = 0;
        
        if(batteriesAvailable && batteriesCount > 0) {
            
            if(backupBatteryPrices != null && !backupBatteryPrices.isEmpty() && backupBatteryPrices.containsKey(financeType)) {
                
                List<Decimal> result = backupBatteryPrices.get(financeType);
                
                for(Integer i = 0; i < batteriesCount; i++) {
                    additionalCost += result[i];
                }
            }
        }
        
        if(financeType == 'Cash') {
            solarEstimateAddress.Batteries_Cost_Cash__c = additionalCost;
        }
        
        if(financeType == 'Loan') {
            solarEstimateAddress.Batteries_Cost_Loan__c = additionalCost;
        }
        
        if(financeType == 'TPO') {
            solarEstimateAddress.Batteries_Cost_TPO__c = additionalCost;
        }
        
        if(solarEstimateAddress.Ground_Mount__c == 'Standard Ground Mount') {
            List<Discount_Config__c> discountConfigs = [SELECT Min_Quantity__c, Max_Quantity__c, Price__c
                                                        FROM Discount_Config__c
                                                        WHERE Product__r.Name = 'Ground Mount'
                                                        AND Min_Quantity__c <= :(systemSize * 1000)
                                                        AND (Max_Quantity__c = null
                                                             OR Max_Quantity__c >= :(systemSize * 1000))];
            
            if(!discountConfigs.isEmpty()) {
                additionalCost += discountConfigs[0].Price__c * systemSize * 1000;
            }
            
        } else if(solarEstimateAddress.Ground_Mount__c == 'Shade Structure Ground Mount') {
            List<Discount_Config__c> discountConfigs = [SELECT Price__c
                                                        FROM Discount_Config__c
                                                        WHERE Product__r.Name = 'Shade Structure Ground Mount'];
            
            if(!discountConfigs.isEmpty()) {
                additionalCost += discountConfigs[0].Price__c * systemSize * 1000;
            }
        }
        
        if(String.isNotBlank(solarEstimateAddress.Safe_Streets__c)) {
            
            List<Discount_Config__c> discountConfigs = [SELECT Price__c 
                                                        FROM Discount_Config__c 
                                                        WHERE Product__r.Name = :('SafeStreets / Google Smart Home: ' + solarEstimateAddress.Safe_Streets__c)
                                                        LIMIT 1];
            
            if(!discountConfigs.isEmpty()) {
                additionalCost += discountConfigs[0].Price__c;
            }
        }
        
        if(solarEstimateAddress.Solar_Tax_Filing_Service__c) {
            List<Discount_Config__c> discountConfigs = [SELECT Price__c
                                                        FROM Discount_Config__c 
                                                        WHERE Product__r.Name = 'Solar Tax Filing Service'
                                                        LIMIT 1];
            
            if(!discountConfigs.isEmpty()) {
                additionalCost += discountConfigs[0].Price__c;
            }
        }
        
        return additionalCost;
    }
    
    public static Map<String, List<Decimal>> getBackupBatteryPrices(State__c state) {
        
        Map<String, List<Decimal>> result = new Map<String, List<Decimal>>();
        
        List<Discount_Config__c> disConfigsWithState = [SELECT State__c, Product__c, Finance_Type__c, Min_Quantity__c, Max_Quantity__c, Price__c
                                                        FROM Discount_Config__c
                                                        WHERE State__c = :state.Id
                                                        AND Finance_Type__c != null
                                                        AND Product__c IN (:state.TPO_Battery__c, :state.Loan_Battery__c, :state.Cash_Battery__c)
                                                        AND Product__c != null
                                                        AND Product__r.Family = 'Battery'
                                                        AND Is_Active__c = true];
        
        List<Discount_Config__c> disConfigsWithoutState = [SELECT State__c, Product__c, Finance_Type__c, Min_Quantity__c, Max_Quantity__c, Price__c
                                                           FROM Discount_Config__c
                                                           WHERE State__c = null
                                                           AND Finance_Type__c != null
                                                           AND Product__c IN (:state.TPO_Battery__c, :state.Loan_Battery__c, :state.Cash_Battery__c)
                                                           AND Product__c != null
                                                           AND Product__r.Family = 'Battery'
                                                           AND Is_Active__c = true];
        
        for(Integer i = 1; i <= maxBatteriesCount; i++) {
            
            Decimal tpoBatteryPrice;
            Decimal loanBatteryPrice;
            Decimal cashBatteryPrice;
            
            for(Discount_Config__c disConfig : disConfigsWithState) {
                
                if(disConfig.Min_Quantity__c <= i
                   && (disConfig.Max_Quantity__c >= i 
                       || disConfig.Max_Quantity__c == null)) 
                {
                    if(tpoBatteryPrice == null 
                       && disConfig.Finance_Type__c.containsIgnoreCase('TPO') 
                       && disConfig.Product__c == state.TPO_Battery__c) 
                    {
                        tpoBatteryPrice = disConfig.Price__c;
                    }
                    
                    if(loanBatteryPrice == null 
                       && disConfig.Finance_Type__c.containsIgnoreCase('Loan') 
                       && disConfig.Product__c == state.Loan_Battery__c) 
                    {
                        loanBatteryPrice = disConfig.Price__c;
                    }
                    
                    if(cashBatteryPrice == null 
                       && disConfig.Finance_Type__c.containsIgnoreCase('Cash') 
                       && disConfig.Product__c == state.Cash_Battery__c) 
                    {
                        cashBatteryPrice = disConfig.Price__c;
                    }
                }                
            }
            
            for(Discount_Config__c disConfig : disConfigsWithoutState) {
                
                if(disConfig.Min_Quantity__c <= i
                   && (disConfig.Max_Quantity__c >= i 
                       || disConfig.Max_Quantity__c == null)) 
                {
                    if(tpoBatteryPrice == null 
                       && disConfig.Finance_Type__c.containsIgnoreCase('TPO') 
                       && disConfig.Product__c == state.TPO_Battery__c) 
                    {
                        tpoBatteryPrice = disConfig.Price__c;
                    }
                    
                    if(loanBatteryPrice == null 
                       && disConfig.Finance_Type__c.containsIgnoreCase('Loan') 
                       && disConfig.Product__c == state.Loan_Battery__c) 
                    {
                        loanBatteryPrice = disConfig.Price__c;
                    }
                    
                    if(cashBatteryPrice == null 
                       && disConfig.Finance_Type__c.containsIgnoreCase('Cash') 
                       && disConfig.Product__c == state.Cash_Battery__c) 
                    {
                        cashBatteryPrice = disConfig.Price__c;
                    }
                }   
            }
            
            if(tpoBatteryPrice == null && state.TPO_Battery__r.Standard_Price__c != null) {
                tpoBatteryPrice = state.TPO_Battery__r.Standard_Price__c;
            }
            
            if(loanBatteryPrice == null && state.Loan_Battery__r.Standard_Price__c != null) {
                loanBatteryPrice = state.Loan_Battery__r.Standard_Price__c;
            }
            
            if(cashBatteryPrice == null && state.Cash_Battery__r.Standard_Price__c != null) {
                cashBatteryPrice = state.Cash_Battery__r.Standard_Price__c;
            }
            
            if(i == 1) {
                result.put('TPO', new List<Decimal>());
                result.put('Loan', new List<Decimal>());
                result.put('Cash', new List<Decimal>());
            }
            
            if(tpoBatteryPrice == null) {
                result.remove('TPO');
            } else if(result.containsKey('TPO')) {
                result.get('TPO').add(tpoBatteryPrice);
            }
            
            if(loanBatteryPrice == null) {
                result.remove('Loan');
            } else if(result.containsKey('Loan')) {
                result.get('Loan').add(loanBatteryPrice);
            }
            
            if(cashBatteryPrice == null) {
                result.remove('Cash');
            } else if(result.containsKey('Cash')) {
                result.get('Cash').add(cashBatteryPrice);
            }
        }
        
        return result;
    }
    
    public static Decimal getDepreciation(Solar_Estimate_Address__c solarEstimateAddress, State__c state, String financeType) {
        
        HttpRequest request;
        HttpResponse response;
        String errorMessage;
        
        try {
            
            Date installDate = Date.today().addDays(-60);
            Integer yearClaimed = installDate.year();
            
            DepreciationRequest apiPayload = new DepreciationRequest();
            apiPayload.key = 'a53dbdd6-46be-ef11-96cd-002248041955';
            
            if(financeType == 'Cash') {
                apiPayload.systemprice = solarEstimateAddress.Gross_System_Cost_Cash__c;
                apiPayload.kilowatts = solarEstimateAddress.System_Size_kW_Cash__c ;
                apiPayload.purchased = true;
                apiPayload.amountfinanced = 0; 
                apiPayload.interestrate = 0;
                apiPayload.loanterm = 0;
            }
            
            if(financeType == 'Loan') {
                apiPayload.systemprice = solarEstimateAddress.Gross_System_Cost_Loan__c;
                apiPayload.kilowatts = solarEstimateAddress.System_Size_kW_Loan__c;
                apiPayload.purchased = true;
                apiPayload.amountfinanced = solarEstimateAddress.Gross_System_Cost_Loan__c; 
                apiPayload.interestrate = state.Loan_Preferred__r.APR__c;
                apiPayload.loanterm = 25;
            }
            
            if(financeType == 'TPO') {
                apiPayload.systemprice = solarEstimateAddress.Final_Price_TPO__c;
                apiPayload.kilowatts = solarEstimateAddress.System_Size_kW_TPO__c;
                apiPayload.purchased = false; 
                apiPayload.leasepayment = 290; 
                apiPayload.leaseyears = 25;
                apiPayload.escalatorrate =  0;
            }
            
            apiPayload.incentiveamount = 0;
            apiPayload.installcomplete = String.valueOf(installDate);
            apiPayload.yearclaimed = yearClaimed;
            apiPayload.formprepamount = 0;
            apiPayload.netmetering = true;
            apiPayload.businessintent = true;
            
            request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint('https://app.411core.com/solar/calculate');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(apiPayload));
            
            Integer statusCode = 200;
            String responseBody = '{"depreciationexpense":100}';
            
            if(!Test.isRunningTest()) {
                response = new Http().send(request);
                
                statusCode = response.getStatusCode();
                responseBody = response.getBody();
            }
            
            if(statusCode == 200 || statusCode == 201) {
                
                DepreciationResponse apiResponse = (DepreciationResponse) JSON.deserialize(responseBody, DepreciationResponse.Class);
                
                if(result.depreciationexpense != 0) {
                    return result.depreciationexpense;
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
        
        return 0;
    }
    
    public class DepreciationRequest {
        @AuraEnabled public String key {get; set;}
        @AuraEnabled public Decimal systemprice {get; set;}
        @AuraEnabled public Decimal incentiveamount {get; set;}
        @AuraEnabled public String installcomplete {get; set;}
        @AuraEnabled public Decimal kilowatts {get; set;}
        @AuraEnabled public Integer yearclaimed {get; set;}
        @AuraEnabled public Decimal formprepamount {get; set;}
        @AuraEnabled public Boolean netmetering {get; set;}
        @AuraEnabled public Boolean businessintent {get; set;}
        @AuraEnabled public Boolean purchased {get; set;}
        @AuraEnabled public Decimal amountfinanced {get; set;}
        @AuraEnabled public Decimal interestrate {get; set;}
        @AuraEnabled public Integer loanterm {get; set;}
        @AuraEnabled public Decimal leasepayment {get; set;}
        @AuraEnabled public Decimal escalatorrate {get; set;}
        @AuraEnabled public Integer leaseyears {get; set;}
    }
    
    public class DepreciationResponse {
        @AuraEnabled public Decimal depreciationexpense {get; set;}
    }
    
    private static Decimal roundDownToNearest(Decimal value, Integer nearest) {
        
        return nearest == 0 
            ? value 
            : Math.floor(value / nearest) * nearest;
    }
}