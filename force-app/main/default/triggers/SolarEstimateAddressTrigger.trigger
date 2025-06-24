trigger SolarEstimateAddressTrigger on Solar_Estimate_Address__c(before insert, 
                                                                 before update,
                                                                 after insert,
                                                                 after update)
{    
    new SolarEstimateAddressTriggerHandler().run();
}