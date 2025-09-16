public without sharing class SolarQuoteTriggerHelper {
    
    public static void updateFields(List<Solar_Quote__c> newList, Map<Id, Solar_Quote__c> oldMap) {
        
        updateState(newList, oldMap);
        
        for(Solar_Quote__c solarQuote : newList) {
            Solar_Quote__c oldSolarQuote = Trigger.isUpdate ? oldMap.get(solarQuote.Id) : null;
            
            /*if(Trigger.isInsert 
               || (Trigger.isUpdate 
                   && ((solarQuote.Average_Monthly_Bill__c != oldSolarQuote.Average_Monthly_Bill__c
                        && solarQuote.Average_Monthly_Bill__c != null) 
                       || (solarQuote.Panels_Count__c != oldSolarQuote.Panels_Count__c
                           && (solarQuote.Panels_Count__c == null 
                               || solarQuote.Panels_Count__c == 0))
                       || (solarQuote.Ground_Mount__c != oldSolarQuote.Ground_Mount__c
                           && String.isNotBlank(solarQuote.Ground_Mount__c)))))
            {
                solarQuote.Set_Best_Electrical_Offset__c = true;
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && (solarQuote.Average_Monthly_Bill__c != oldSolarQuote.Average_Monthly_Bill__c
                        || solarQuote.Panels_Count__c != oldSolarQuote.Panels_Count__c)))
               && solarQuote.Average_Monthly_Bill__c != null
               && !solarQuote.Initiate_Solar_Quote_Process__c)
            {
                solarQuote.Initiate_Solar_Quote_Process__c = true;
            }*/
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Initiate_Solar_Quote_Process__c != oldSolarQuote.Initiate_Solar_Quote_Process__c))
               && solarQuote.Initiate_Solar_Quote_Process__c)
            {
                solarQuote.Completed_General_Process__c = false;
                solarQuote.Completed_Account_Process__c = false;
                solarQuote.Completed_Properties_Process__c = false;
                solarQuote.Completed_kWh_Process__c = false;
                solarQuote.Completed_Electricity_Profile_Process__c = false;
                solarQuote.Completed_Solar_Profiles_Process_Cash__c = false;
                solarQuote.Completed_Solar_Profiles_Process_Loan__c = false;
                solarQuote.Completed_Solar_Profiles_Process_TPO__c = false;
                solarQuote.Completed_Analysis_Process__c = false;
                solarQuote.Run_Typical_Analysis__c = false;
                solarQuote.Failed_Google_Building_Insights__c = false;
                solarQuote.Failed_Solar_Quote_Process__c = false;
                solarQuote.Account_Id__c = null;
                solarQuote.Master_Tariff_Id__c = null;
                solarQuote.Tariff_Name__c = null;
                solarQuote.Tariff_Code__c = null;
                solarQuote.Tariff_Code__c = null;
                solarQuote.Annual_kWh_Arcadia__c = null;
                solarQuote.Annual_Bill__c = null;
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Failed_Solar_Quote_Process__c != oldSolarQuote.Failed_Solar_Quote_Process__c))
               && solarQuote.Failed_Solar_Quote_Process__c)
            {
                solarQuote.Initiate_Solar_Quote_Process__c = false;
                solarQuote.Manual_Initiate_Solar_Quote_Process__c = false;
                solarQuote.Last_Process_Run_Timestamp__c = DateTime.now();
                solarQuote.Finance_Type_Available_Cash__c = false;
                solarQuote.Finance_Type_Available_Loan__c = false;
                solarQuote.Finance_Type_Available_TPO__c = false;
                solarQuote.Run_Typical_Analysis__c = false;
            }
            
            if(solarQuote.Completed_General_Process__c
               && solarQuote.Completed_Account_Process__c 
               && solarQuote.Completed_Properties_Process__c
               && solarQuote.Completed_kWh_Process__c
               && solarQuote.Completed_Electricity_Profile_Process__c
               && solarQuote.Completed_Solar_Profiles_Process_Cash__c
               && solarQuote.Completed_Solar_Profiles_Process_Loan__c
               && solarQuote.Completed_Solar_Profiles_Process_TPO__c
               && solarQuote.Completed_Analysis_Process__c
               && !solarQuote.Failed_Solar_Quote_Process__c)
            {
                solarQuote.Initiate_Solar_Quote_Process__c = false;
                solarQuote.Manual_Initiate_Solar_Quote_Process__c = false;
                solarQuote.Last_Successful_Process_Run_Timestamp__c = DateTime.now();
                solarQuote.Last_Process_Run_Timestamp__c = solarQuote.Last_Successful_Process_Run_Timestamp__c;
            }
            
            if(!solarQuote.Initiate_Solar_Quote_Process__c
               && !solarQuote.Run_Typical_Analysis__c)
            {
                solarQuote.Monthly_Savings_Typical__c = null;
                solarQuote.Yearly_Savings_Typical__c = null;
                solarQuote.Old_Lifetime_Utility_Cost_Typical__c = null;
                solarQuote.New_Lifetime_Solar_Cost_Typical__c = null;
                solarQuote.Total_Lifetime_Savings_Typical__c = null;
            }
            
            if(!solarQuote.Initiate_Solar_Quote_Process__c
               && !solarQuote.Finance_Type_Available_Cash__c)
            {
                solarQuote.Batteries_Available_Cash__c = false;
                solarQuote.System_Size_kW_Cash__c = null;
                solarQuote.Total_Baseline_Measures_Cash__c = null;
                solarQuote.Solar_Offset_Cash__c = null;
                solarQuote.Solar_Provider_Profile_Ids_Cash__c = null;
                solarQuote.Storage_Profile_Id_Cash__c = null;
                solarQuote.Additional_Cost_Cash__c = null;
                solarQuote.Base_System_Cost_Cash__c = null;
                solarQuote.Total_System_Cost_Cash__c = null;
                solarQuote.Gross_System_Cost_Cash__c = null;
                solarQuote.Federal_ITC_Cash__c = null;
                solarQuote.Domestic_Content_Credit_Cash__c = null;
                solarQuote.Depreciation_Cash__c = null;
                solarQuote.Incentives_Cash__c = null;
                solarQuote.Final_Price_Cash__c = null;
                solarQuote.Monthly_Savings_Cash__c = null;
                solarQuote.Yearly_Savings_Cash__c = null;
                solarQuote.Old_Lifetime_Utility_Cost_Cash__c = null;
                solarQuote.New_Lifetime_Solar_Cost_Cash__c = null;
                solarQuote.Total_Lifetime_Savings_Cash__c = null;
            }
            
            if(!solarQuote.Batteries_Available_Cash__c) {
                solarQuote.Batteries_Count_Cash__c = null;
                solarQuote.Batteries_Cost_Cash__c = null;
            }
            
            if(!solarQuote.Initiate_Solar_Quote_Process__c
               && !solarQuote.Finance_Type_Available_Loan__c)
            {
                solarQuote.Batteries_Available_Loan__c = false;
                solarQuote.System_Size_kW_Loan__c = null;
                solarQuote.Total_Baseline_Measures_Loan__c = null;
                solarQuote.Solar_Offset_Loan__c = null;
                solarQuote.Solar_Provider_Profile_Ids_Loan__c = null;
                solarQuote.Storage_Profile_Id_Loan__c = null;
                solarQuote.Additional_Cost_Loan__c = null;
                solarQuote.Base_System_Cost_Loan__c = null;
                solarQuote.Total_System_Cost_Loan__c = null;
                solarQuote.Gross_System_Cost_Loan__c = null;
                solarQuote.Federal_ITC_Loan__c = null;
                solarQuote.Domestic_Content_Credit_Loan__c = null;
                solarQuote.Depreciation_Loan__c = null;
                solarQuote.Incentives_Loan__c = null;
                solarQuote.Final_Price_Loan__c = null;                
                solarQuote.Monthly_Savings_Loan__c = null;
                solarQuote.Yearly_Savings_Loan__c = null;
                solarQuote.Old_Lifetime_Utility_Cost_Loan__c = null;
                solarQuote.New_Lifetime_Solar_Cost_Loan__c = null;
                solarQuote.Total_Lifetime_Savings_Loan__c = null;
                
            }
            
            if(!solarQuote.Batteries_Available_Loan__c) {
                solarQuote.Batteries_Count_Loan__c = null;
                solarQuote.Batteries_Cost_Loan__c = null;
            }
            
            if(!solarQuote.Initiate_Solar_Quote_Process__c
               && !solarQuote.Finance_Type_Available_TPO__c)
            {
                solarQuote.Batteries_Available_TPO__c = false;
                solarQuote.System_Size_kW_TPO__c = null;
                solarQuote.Total_Baseline_Measures_TPO__c = null;
                solarQuote.Solar_Offset_TPO__c = null;
                solarQuote.Solar_Provider_Profile_Ids_TPO__c = null;
                solarQuote.Storage_Profile_Id_TPO__c = null;
                solarQuote.Additional_Cost_TPO__c = null;
                solarQuote.Base_System_Cost_TPO__c = null;
                solarQuote.Total_System_Cost_TPO__c = null;
                solarQuote.Target_PPW_TPO__c = null;
                solarQuote.Solar_Production_TPO__c = null;
                solarQuote.Price_Per_kWh_TPO__c = null;
                solarQuote.Final_Price_TPO__c = null;
                solarQuote.Monthly_Savings_TPO__c = null;
                solarQuote.Yearly_Savings_TPO__c = null;
                solarQuote.Old_Lifetime_Utility_Cost_TPO__c = null;
                solarQuote.New_Lifetime_Solar_Cost_TPO__c = null;
                solarQuote.Total_Lifetime_Savings_TPO__c = null;
            }
            
            if(!solarQuote.Batteries_Available_TPO__c) {
                solarQuote.Batteries_Count_TPO__c = null;
                solarQuote.Batteries_Cost_TPO__c = null;
            }
        }
    }
    
    public static void updateState(List<Solar_Quote__c> newList, Map<Id, Solar_Quote__c> oldMap) {
        
        List<Solar_Quote__c> solarQuotesToProcess = new List<Solar_Quote__c>();
        Set<String> stateNames = new Set<String>();
        
        for(Solar_Quote__c solarQuote : newList) {
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.State__c != oldMap.get(solarQuote.Id).State__c))) 
            {
                solarQuotesToProcess.add(solarQuote);
                
                if(String.isNotBlank(solarQuote.State__c)) {
                    stateNames.add(solarQuote.State__c);
                }
            }
        }
        
        if(solarQuotesToProcess.isEmpty()) {
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
        
        for(Solar_Quote__c solarQuote : solarQuotesToProcess) {
            
            solarQuote.State_Lookup__c = String.isNotBlank(solarQuote.State__c)
                ? stateNameToStateId.get(solarQuote.State__c)
                : null;
        }
    } 
    
    public static void initiateSolarQuoteProcess(List<Solar_Quote__c> newList, Map<Id, Solar_Quote__c> oldMap) {
        
        for(Solar_Quote__c solarQuote : newList) {
            Solar_Quote__c oldSolarQuote = Trigger.isUpdate ? oldMap.get(solarQuote.Id) : null;
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Initiate_Solar_Quote_Process__c != oldSolarQuote.Initiate_Solar_Quote_Process__c))
               && solarQuote.Initiate_Solar_Quote_Process__c
               && !solarQuote.Manual_Initiate_Solar_Quote_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarQuoteId', solarQuote.Id);
                System.enqueueJob(new AsyncJobExecutor('SolarQuoteProcessHelper.startGeneralProcess', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Completed_General_Process__c != oldSolarQuote.Completed_General_Process__c))
               && solarQuote.Completed_General_Process__c
               && !solarQuote.Manual_Initiate_Solar_Quote_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarQuoteId', solarQuote.Id);
                System.enqueueJob(new AsyncJobExecutor('ArcadiaApiHelper.createAccount', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Completed_Electricity_Profile_Process__c != oldSolarQuote.Completed_Electricity_Profile_Process__c))
               && solarQuote.Completed_Electricity_Profile_Process__c
               && !solarQuote.Manual_Initiate_Solar_Quote_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarQuoteId', solarQuote.Id);
                arguments.put('financeType', 'Cash');
                System.enqueueJob(new AsyncJobExecutor('ArcadiaApiHelper.createSolarProfiles', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Completed_Solar_Profiles_Process_Cash__c != oldSolarQuote.Completed_Solar_Profiles_Process_Cash__c))
               && solarQuote.Completed_Solar_Profiles_Process_Cash__c
               && !solarQuote.Manual_Initiate_Solar_Quote_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarQuoteId', solarQuote.Id);
                arguments.put('financeType', 'Loan');
                System.enqueueJob(new AsyncJobExecutor('ArcadiaApiHelper.createSolarProfiles', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Completed_Solar_Profiles_Process_Loan__c != oldSolarQuote.Completed_Solar_Profiles_Process_Loan__c))
               && solarQuote.Completed_Solar_Profiles_Process_Loan__c
               && !solarQuote.Manual_Initiate_Solar_Quote_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarQuoteId', solarQuote.Id);
                arguments.put('financeType', 'TPO');
                System.enqueueJob(new AsyncJobExecutor('ArcadiaApiHelper.createSolarProfiles', arguments));
            }
            
            if((Trigger.isInsert 
                || (Trigger.isUpdate 
                    && solarQuote.Completed_Solar_Profiles_Process_TPO__c != oldSolarQuote.Completed_Solar_Profiles_Process_TPO__c))
               && solarQuote.Completed_Solar_Profiles_Process_TPO__c
               && !solarQuote.Manual_Initiate_Solar_Quote_Process__c)
            {
                Map<String, Object> arguments = new Map<String, Object>();
                arguments.put('solarQuoteId', solarQuote.Id);
                System.enqueueJob(new AsyncJobExecutor('ArcadiaApiHelper.getAnalysis', arguments));
            }
        }
    }
}