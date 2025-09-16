public without sharing class SolarQuoteTriggerHandler extends TriggerHandler {
    
    private List<Solar_Quote__c> newList;
    private Map<Id, Solar_Quote__c> oldMap;
    
    public SolarQuoteTriggerHandler() {
        newList = (List<Solar_Quote__c>) Trigger.new;
        oldMap = (Map<Id, Solar_Quote__c>) Trigger.oldMap;
    }
    
    protected override void beforeInsert() {
        SolarQuoteTriggerHelper.updateFields(newList, oldMap);
    }
    
    protected override void beforeUpdate() {
        SolarQuoteTriggerHelper.updateFields(newList, oldMap);
    }
    
    protected override void afterInsert() {
        SolarQuoteTriggerHelper.initiateSolarQuoteProcess(newList, oldMap);
    }
    
    protected override void afterUpdate() {
        SolarQuoteTriggerHelper.initiateSolarQuoteProcess(newList, oldMap);
    }
}