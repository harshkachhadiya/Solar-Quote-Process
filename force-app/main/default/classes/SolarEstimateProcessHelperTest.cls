@IsTest
public with sharing class SolarEstimateProcessHelperTest {
    
    @TestSetup
    static void setup() {
        
        Genability_Monthly_Limit__c genabilityMonthlyLimit = new Genability_Monthly_Limit__c();
        genabilityMonthlyLimit.Name = 'Test';
        genabilityMonthlyLimit.Start_Date__c = Date.today().addDays(-1);
        genabilityMonthlyLimit.End_Date__c = Date.today().addDays(1);
        genabilityMonthlyLimit.Standard_Solar_Accounts_Limit__c = 2;
        genabilityMonthlyLimit.Standard_Storage_Accounts_Limit__c = 1;
        insert genabilityMonthlyLimit;
        
        Genability_Provider_Account_Id__c genabilityProviderAccountId1 = new Genability_Provider_Account_Id__c();
        genabilityProviderAccountId1.Genability_Monthly_Limit__c = genabilityMonthlyLimit.Id;
        genabilityProviderAccountId1.Storage_Account__c = false;
        insert genabilityProviderAccountId1;

        Genability_Provider_Account_Id__c genabilityProviderAccountId2 = new Genability_Provider_Account_Id__c();
        genabilityProviderAccountId2.Genability_Monthly_Limit__c = genabilityMonthlyLimit.Id;
        genabilityProviderAccountId2.Storage_Account__c = true;
        insert genabilityProviderAccountId2;
        
        Product2 panel = new Product2();
        panel.RecordTypeId = SObjectUtil.getRecordTypeIdByName('Product2', 'Panel');
        panel.Name = 'Test Panel';
        panel.Production__c = 100;
        insert panel;
        
        Product2 battery = new Product2();
        battery.RecordTypeId = SObjectUtil.getRecordTypeIdByName('Product2', 'Battery');
        battery.Name = 'Test Battery';
        battery.Family = 'Battery';
        battery.IsActive = true;
        battery.Standard_Price__c = 100;
        battery.Rated_Output_Power__c = '1';
        battery.Energy_Capacity__c = '1';
        battery.Min_SoC__c = 1;
        battery.Max_SoC__c = 1;
        battery.Initial_SoC__c = 1;
        battery.DC_Coupled__c = true;
        battery.AC_to_DC_Efficiency__c = 1;
        battery.DC_to_AC_Efficiency__c = 1;
        battery.Solar_DC_to_AC_Efficiency__c = 1;
        battery.Allow_Battery_to_Grid__c = true;
        battery.Allow_Grid_to_Battery__c = true;
        battery.Allow_Solar_to_Grid__c = true;
        battery.Allow_Solar_to_Battery__c = true;
        insert battery;
        
        Product2 solarTaxFilingService = new Product2();
        solarTaxFilingService.RecordTypeId = SObjectUtil.getRecordTypeIdByName('Product2', 'Adder');
        solarTaxFilingService.Name = 'Solar Tax Filing Service';
        solarTaxFilingService.Family = 'Administrative';
        solarTaxFilingService.IsActive = true;
        insert solarTaxFilingService;
        
        Product2 safeStreetsBasicsPackage = new Product2();
        safeStreetsBasicsPackage.RecordTypeId = SObjectUtil.getRecordTypeIdByName('Product2', 'Adder');
        safeStreetsBasicsPackage.Name = 'SafeStreets / Google Smart Home: Basics Package';
        safeStreetsBasicsPackage.Family = 'Smart Home';
        safeStreetsBasicsPackage.IsActive = true;
        insert safeStreetsBasicsPackage;
        
        Pricing_Cube__c cashPreferred = new Pricing_Cube__c();
        cashPreferred.RecordTypeId = SObjectUtil.getRecordTypeIdByName('Pricing_Cube__c', 'Cash');
        cashPreferred.Dealer_Fee__c = 1.5;
        insert cashPreferred;
        
        Pricing_Cube__c loanPreferred = new Pricing_Cube__c();
        loanPreferred.RecordTypeId = SObjectUtil.getRecordTypeIdByName('Pricing_Cube__c', 'Loan');
        loanPreferred.Dealer_Fee__c = 1.5;
        loanPreferred.Payment_Factor_1__c = 0.1;
        insert loanPreferred;
        
        Discount_Config__c discountConfig1 = new Discount_Config__c();
        discountConfig1.Product__c = battery.Id;
        discountConfig1.Is_Active__c = true;
        discountConfig1.Finance_Type__c = 'Cash;Loan;TPO';
        discountConfig1.Min_Quantity__c = 1;
        discountConfig1.Max_Quantity__c = 3;
        discountConfig1.Price__c = 100;
        insert discountConfig1;
        
        Discount_Config__c discountConfig2 = new Discount_Config__c();
        discountConfig2.Product__c = solarTaxFilingService.Id;
        discountConfig2.Is_Active__c = true;
        discountConfig2.Min_Quantity__c = 1;
        discountConfig2.Price__c = 100;
        insert discountConfig2;
        
        Discount_Config__c discountConfig3 = new Discount_Config__c();
        discountConfig3.Product__c = safeStreetsBasicsPackage.Id;
        discountConfig3.Is_Active__c = true;
        discountConfig3.Min_Quantity__c = 1;
        discountConfig3.Price__c = 100;
        insert discountConfig3;
        
        State__c state = new State__c();
        state.Cash_Panel__c = panel.Id;
        state.Cash_Battery__c = battery.Id;
        state.Cash_Preferred__c = cashPreferred.Id;
        state.Loan_Panel__c = panel.Id;
        state.Loan_Battery__c = battery.Id;
        state.Loan_Preferred__c = loanPreferred.Id;
        state.Loan_Competitor__c = loanPreferred.Id;
        state.TPO_Panel__c = panel.Id;
        state.TPO_Battery__c = battery.Id;
        state.Name = 'CA';
        state.Start_Date__c = Date.today().addDays(-10);
        state.Auto_Recommend_Battery__c = true;
        state.Cash_Base_PPW__c = 0.1;
        state.Cash_Margin__c = 0.1;
        state.Competitor_Cash_PPW__c = 0.1;
        state.Loan_Base_PPW__c = 0.1;
        state.Loan_Margin__c = 0.1;
        state.TPO_Base_PPW__c = 0.1;
        state.TPO_Margin__c = 0.1;
        insert state;
        
        Lead ld = new Lead();
        ld.FirstName = 'FirstName';
        ld.LastName = 'LastName';
        ld.Company = 'Test Company';
        ld.Phone = '12345';
        ld.Email = 'FirstName.LastName@gmail.com';
        ld.Street = 'Test';
        ld.City = 'Test';
        ld.State = 'CA';
        ld.PostalCode = '12345';
        ld.Country = 'US';
        ld.Status = 'Open';
        ld.LeadSource = 'Web';
        ld.Utility_Company__c = 'Test';
        ld.Lse_Id__c = '12345';
        ld.Average_Monthly_Bill__c = 100;
        insert ld;
    }
    
    @IsTest
    static void solarEstimateProcessTest() {
        
        Lead ld = [SELECT Id 
                   FROM Lead 
                   LIMIT 1];
        
        Test.startTest();
        
        Map<String, String> defaultValues = SolarEstimateProcessHelper.getDefaultValuesForSolarEstimate();
        
        Solar_Estimate_Address__c solarEstimateAddress = SolarEstimateProcessHelper.upsertSolarEstimateAddress(ld.Id);
        
        solarEstimateAddress.Safe_Streets__c = 'Basics Package';
        solarEstimateAddress.Solar_Tax_Filing_Service__c = true;
        solarEstimateAddress.Initiate_Solar_Estimate_Process__c = true;
        
        update solarEstimateAddress;
        
        Test.stopTest();
    }
}