public without sharing class SolarEstimateAddressTriggerHelper {
    
    public static void updateFields(List<Solar_Estimate_Address__c> newList, Map<Id, Solar_Estimate_Address__c> oldMap) {
        
        updateState(newList, oldMap);
        
        for(Solar_Estimate_Address__c solarEstimateAddress : newList) {
            Solar_Estimate_Address__c oldSolarEstimateAddress = Trigger.isUpdate ? oldMap.get(solarEstimateAddress.Id) : null;
            
            /*if(Trigger.isInsert 
               || (Trigger.isUpdate 
                   && ((solarEstimateAddress.Average_Monthly_Bill__c != oldSolarEstimateAddress.Average_Monthly_Bill__c
                        && solarEstimateAddress.Average_Monthly_Bill__c != null) 
                       || (solarEstimateAddress.Panels_Count__c != oldSolarEstimateAddress.Panels_Count__c
                           && (solarEstimateAddress.Panels_Count__c == null 
                               || solarEstimateAddress.Panels_Count__c == 0))
                       || (solarEstimateAddress.Ground_Mount__c != oldSolarEstimateAddress.Ground_Mount__c
                           && String.isNotBlank(solarEstimateAddress.Ground_Mount__c)))))
            {
                solarEstimateAddress.Set_Best_Electrical_Offset__c = true;
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && (solarEstimateAddress.Average_Monthly_Bill__c != oldSolarEstimateAddress.Average_Monthly_Bill__c
                        || solarEstimateAddress.Panels_Count__c != oldSolarEstimateAddress.Panels_Count__c)))
               && solarEstimateAddress.Average_Monthly_Bill__c != null
               && !solarEstimateAddress.Initiate_Solar_Estimate_Process__c)
            {
                solarEstimateAddress.Initiate_Solar_Estimate_Process__c = true;
            }*/
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Initiate_Solar_Estimate_Process__c != oldSolarEstimateAddress.Initiate_Solar_Estimate_Process__c))
               && solarEstimateAddress.Initiate_Solar_Estimate_Process__c)
            {
                solarEstimateAddress.Completed_General_Process__c = false;
                solarEstimateAddress.Completed_Account_Process__c = false;
                solarEstimateAddress.Completed_Properties_Process__c = false;
                solarEstimateAddress.Completed_kWh_Process__c = false;
                solarEstimateAddress.Completed_Electricity_Profile_Process__c = false;
                solarEstimateAddress.Completed_Solar_Profiles_Process_Cash__c = false;
                solarEstimateAddress.Completed_Solar_Profiles_Process_Loan__c = false;
                solarEstimateAddress.Completed_Solar_Profiles_Process_TPO__c = false;
                solarEstimateAddress.Completed_Analysis_Process__c = false;
                solarEstimateAddress.Run_Typical_Analysis__c = false;
                solarEstimateAddress.Failed_Google_Building_Insights__c = false;
                solarEstimateAddress.Failed_Solar_Estimate_Process__c = false;
                solarEstimateAddress.Account_Id__c = null;
                solarEstimateAddress.Master_Tariff_Id__c = null;
                solarEstimateAddress.Tariff_Name__c = null;
                solarEstimateAddress.Tariff_Code__c = null;
                solarEstimateAddress.Tariff_Code__c = null;
                solarEstimateAddress.Annual_kWh_Arcadia__c = null;
                solarEstimateAddress.Annual_Bill__c = null;
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Failed_Solar_Estimate_Process__c != oldSolarEstimateAddress.Failed_Solar_Estimate_Process__c))
               && solarEstimateAddress.Failed_Solar_Estimate_Process__c)
            {
                solarEstimateAddress.Initiate_Solar_Estimate_Process__c = false;
                solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c = false;
                solarEstimateAddress.Last_Process_Run_Timestamp__c = DateTime.now();
                solarEstimateAddress.Finance_Type_Available_Cash__c = false;
                solarEstimateAddress.Finance_Type_Available_Loan__c = false;
                solarEstimateAddress.Finance_Type_Available_TPO__c = false;
                solarEstimateAddress.Run_Typical_Analysis__c = false;
            }
            
            if(solarEstimateAddress.Completed_General_Process__c
               && solarEstimateAddress.Completed_Account_Process__c 
               && solarEstimateAddress.Completed_Properties_Process__c
               && solarEstimateAddress.Completed_kWh_Process__c
               && solarEstimateAddress.Completed_Electricity_Profile_Process__c
               && solarEstimateAddress.Completed_Solar_Profiles_Process_Cash__c
               && solarEstimateAddress.Completed_Solar_Profiles_Process_Loan__c
               && solarEstimateAddress.Completed_Solar_Profiles_Process_TPO__c
               && solarEstimateAddress.Completed_Analysis_Process__c
               && !solarEstimateAddress.Failed_Solar_Estimate_Process__c)
            {
                solarEstimateAddress.Initiate_Solar_Estimate_Process__c = false;
                solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c = false;
                solarEstimateAddress.Last_Successful_Process_Run_Timestamp__c = DateTime.now();
                solarEstimateAddress.Last_Process_Run_Timestamp__c = solarEstimateAddress.Last_Successful_Process_Run_Timestamp__c;
            }
            
            if(!solarEstimateAddress.Initiate_Solar_Estimate_Process__c
               && !solarEstimateAddress.Run_Typical_Analysis__c)
            {
                solarEstimateAddress.Monthly_Savings_Typical__c = null;
                solarEstimateAddress.Yearly_Savings_Typical__c = null;
                solarEstimateAddress.Old_Lifetime_Utility_Cost_Typical__c = null;
                solarEstimateAddress.New_Lifetime_Solar_Cost_Typical__c = null;
                solarEstimateAddress.Total_Lifetime_Savings_Typical__c = null;
            }
            
            if(!solarEstimateAddress.Initiate_Solar_Estimate_Process__c
               && !solarEstimateAddress.Finance_Type_Available_Cash__c)
            {
                solarEstimateAddress.Batteries_Available_Cash__c = false;
                solarEstimateAddress.System_Size_kW_Cash__c = null;
                solarEstimateAddress.Total_Baseline_Measures_Cash__c = null;
                solarEstimateAddress.Solar_Offset_Cash__c = null;
                solarEstimateAddress.Solar_Provider_Profile_Ids_Cash__c = null;
                solarEstimateAddress.Storage_Profile_Id_Cash__c = null;
                solarEstimateAddress.Additional_Cost_Cash__c = null;
                solarEstimateAddress.Base_System_Cost_Cash__c = null;
                solarEstimateAddress.Total_System_Cost_Cash__c = null;
                solarEstimateAddress.Gross_System_Cost_Cash__c = null;
                solarEstimateAddress.Federal_ITC_Cash__c = null;
                solarEstimateAddress.Domestic_Content_Credit_Cash__c = null;
                solarEstimateAddress.Depreciation_Cash__c = null;
                solarEstimateAddress.Incentives_Cash__c = null;
                solarEstimateAddress.Final_Price_Cash__c = null;
                solarEstimateAddress.Monthly_Savings_Cash__c = null;
                solarEstimateAddress.Yearly_Savings_Cash__c = null;
                solarEstimateAddress.Old_Lifetime_Utility_Cost_Cash__c = null;
                solarEstimateAddress.New_Lifetime_Solar_Cost_Cash__c = null;
                solarEstimateAddress.Total_Lifetime_Savings_Cash__c = null;
            }
            
            if(!solarEstimateAddress.Batteries_Available_Cash__c) {
                solarEstimateAddress.Batteries_Count_Cash__c = null;
                solarEstimateAddress.Batteries_Cost_Cash__c = null;
            }
            
            if(!solarEstimateAddress.Initiate_Solar_Estimate_Process__c
               && !solarEstimateAddress.Finance_Type_Available_Loan__c)
            {
                solarEstimateAddress.Batteries_Available_Loan__c = false;
                solarEstimateAddress.System_Size_kW_Loan__c = null;
                solarEstimateAddress.Total_Baseline_Measures_Loan__c = null;
                solarEstimateAddress.Solar_Offset_Loan__c = null;
                solarEstimateAddress.Solar_Provider_Profile_Ids_Loan__c = null;
                solarEstimateAddress.Storage_Profile_Id_Loan__c = null;
                solarEstimateAddress.Additional_Cost_Loan__c = null;
                solarEstimateAddress.Base_System_Cost_Loan__c = null;
                solarEstimateAddress.Total_System_Cost_Loan__c = null;
                solarEstimateAddress.Gross_System_Cost_Loan__c = null;
                solarEstimateAddress.Federal_ITC_Loan__c = null;
                solarEstimateAddress.Domestic_Content_Credit_Loan__c = null;
                solarEstimateAddress.Depreciation_Loan__c = null;
                solarEstimateAddress.Incentives_Loan__c = null;
                solarEstimateAddress.Final_Price_Loan__c = null;                
                solarEstimateAddress.Monthly_Savings_Loan__c = null;
                solarEstimateAddress.Yearly_Savings_Loan__c = null;
                solarEstimateAddress.Old_Lifetime_Utility_Cost_Loan__c = null;
                solarEstimateAddress.New_Lifetime_Solar_Cost_Loan__c = null;
                solarEstimateAddress.Total_Lifetime_Savings_Loan__c = null;
                
            }
            
            if(!solarEstimateAddress.Batteries_Available_Loan__c) {
                solarEstimateAddress.Batteries_Count_Loan__c = null;
                solarEstimateAddress.Batteries_Cost_Loan__c = null;
            }
            
            if(!solarEstimateAddress.Initiate_Solar_Estimate_Process__c
               && !solarEstimateAddress.Finance_Type_Available_TPO__c)
            {
                solarEstimateAddress.Batteries_Available_TPO__c = false;
                solarEstimateAddress.System_Size_kW_TPO__c = null;
                solarEstimateAddress.Total_Baseline_Measures_TPO__c = null;
                solarEstimateAddress.Solar_Offset_TPO__c = null;
                solarEstimateAddress.Solar_Provider_Profile_Ids_TPO__c = null;
                solarEstimateAddress.Storage_Profile_Id_TPO__c = null;
                solarEstimateAddress.Additional_Cost_TPO__c = null;
                solarEstimateAddress.Base_System_Cost_TPO__c = null;
                solarEstimateAddress.Total_System_Cost_TPO__c = null;
                solarEstimateAddress.Target_PPW_TPO__c = null;
                solarEstimateAddress.Solar_Production_TPO__c = null;
                solarEstimateAddress.Price_Per_kWh_TPO__c = null;
                solarEstimateAddress.Final_Price_TPO__c = null;
                solarEstimateAddress.Monthly_Savings_TPO__c = null;
                solarEstimateAddress.Yearly_Savings_TPO__c = null;
                solarEstimateAddress.Old_Lifetime_Utility_Cost_TPO__c = null;
                solarEstimateAddress.New_Lifetime_Solar_Cost_TPO__c = null;
                solarEstimateAddress.Total_Lifetime_Savings_TPO__c = null;
            }
            
            if(!solarEstimateAddress.Batteries_Available_TPO__c) {
                solarEstimateAddress.Batteries_Count_TPO__c = null;
                solarEstimateAddress.Batteries_Cost_TPO__c = null;
            }
        }
    }
    
    public static void updateState(List<Solar_Estimate_Address__c> newList, Map<Id, Solar_Estimate_Address__c> oldMap) {
        
        List<Solar_Estimate_Address__c> solarEstimateAddressesToProcess = new List<Solar_Estimate_Address__c>();
        Set<String> stateNames = new Set<String>();
        
        for(Solar_Estimate_Address__c solarEstimateAddress : newList) {
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.State__c != oldMap.get(solarEstimateAddress.Id).State__c))) 
            {
                solarEstimateAddressesToProcess.add(solarEstimateAddress);
                
                if(String.isNotBlank(solarEstimateAddress.State__c)) {
                    stateNames.add(solarEstimateAddress.State__c);
                }
            }
        }
        
        if(solarEstimateAddressesToProcess.isEmpty()) {
            return;
        }
        
        Map<String, Id> stateNameToStateId = new Map<String, Id>();
        
        if(!stateNames.isEmpty()) {
            
            for(State__c state : [SELECT Id, Name 
                                  FROM State__c 
                                  WHERE Name IN :stateNames]) 
            {
                stateNameToStateId.put(state.Name, state.Id);
            }
        }
        
        for(Solar_Estimate_Address__c solarEstimateAddress : solarEstimateAddressesToProcess) {
            
            solarEstimateAddress.State_Lookup__c = String.isNotBlank(solarEstimateAddress.State__c)
                ? stateNameToStateId.get(solarEstimateAddress.State__c)
                : null;
        }
    } 
    
    public static void initiateSolarEstimateProcess(List<Solar_Estimate_Address__c> newList, Map<Id, Solar_Estimate_Address__c> oldMap) {
        
        for(Solar_Estimate_Address__c solarEstimateAddress : newList) {
            Solar_Estimate_Address__c oldSolarEstimateAddress = Trigger.isUpdate ? oldMap.get(solarEstimateAddress.Id) : null;
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Initiate_Solar_Estimate_Process__c != oldSolarEstimateAddress.Initiate_Solar_Estimate_Process__c))
               && solarEstimateAddress.Initiate_Solar_Estimate_Process__c
               && !solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarEstimateAddressId', solarEstimateAddress.Id);
                System.enqueueJob(new QueueableUtility('SolarEstimateProcessHelper.startGeneralProcess', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Completed_General_Process__c != oldSolarEstimateAddress.Completed_General_Process__c))
               && solarEstimateAddress.Completed_General_Process__c
               && !solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarEstimateAddressId', solarEstimateAddress.Id);
                System.enqueueJob(new QueueableUtility('ArcadiaApiHelper.createAccount', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Completed_Electricity_Profile_Process__c != oldSolarEstimateAddress.Completed_Electricity_Profile_Process__c))
               && solarEstimateAddress.Completed_Electricity_Profile_Process__c
               && !solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarEstimateAddressId', solarEstimateAddress.Id);
                arguments.put('financeType', 'Cash');
                System.enqueueJob(new QueueableUtility('ArcadiaApiHelper.createSolarProfiles', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Completed_Solar_Profiles_Process_Cash__c != oldSolarEstimateAddress.Completed_Solar_Profiles_Process_Cash__c))
               && solarEstimateAddress.Completed_Solar_Profiles_Process_Cash__c
               && !solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarEstimateAddressId', solarEstimateAddress.Id);
                arguments.put('financeType', 'Loan');
                System.enqueueJob(new QueueableUtility('ArcadiaApiHelper.createSolarProfiles', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Completed_Solar_Profiles_Process_Loan__c != oldSolarEstimateAddress.Completed_Solar_Profiles_Process_Loan__c))
               && solarEstimateAddress.Completed_Solar_Profiles_Process_Loan__c
               && !solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarEstimateAddressId', solarEstimateAddress.Id);
                arguments.put('financeType', 'TPO');
                System.enqueueJob(new QueueableUtility('ArcadiaApiHelper.createSolarProfiles', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarEstimateAddress.Completed_Solar_Profiles_Process_TPO__c != oldSolarEstimateAddress.Completed_Solar_Profiles_Process_TPO__c))
               && solarEstimateAddress.Completed_Solar_Profiles_Process_TPO__c
               && !solarEstimateAddress.Manual_Initiate_Solar_Estimate_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarEstimateAddressId', solarEstimateAddress.Id);
                System.enqueueJob(new QueueableUtility('ArcadiaApiHelper.getAnalysis', arguments));
            }
        }
    }
}