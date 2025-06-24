public without sharing class SolarEstimateAddressTriggerHandler extends TriggerHandler {
    
    private List<Solar_Estimate_Address__c> newList;
    private Map<Id, Solar_Estimate_Address__c> oldMap;
    
    public SolarEstimateAddressTriggerHandler() {
        newList = (List<Solar_Estimate_Address__c>) Trigger.new;
        oldMap = (Map<Id, Solar_Estimate_Address__c>) Trigger.oldMap;
    }
    
    protected override void beforeInsert() {
        SolarEstimateAddressTriggerHelper.updateFields(newList, oldMap);
    }
    
    protected override void beforeUpdate() {
        SolarEstimateAddressTriggerHelper.updateFields(newList, oldMap);
    }
    
    protected override void afterInsert() {
        SolarEstimateAddressTriggerHelper.initiateSolarEstimateProcess(newList, oldMap);
    }
    
    protected override void afterUpdate() {
        SolarEstimateAddressTriggerHelper.initiateSolarEstimateProcess(newList, oldMap);
    }
}