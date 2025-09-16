trigger SolarQuoteTrigger on Solar_Quote__c(before insert, 
                                            before update,
                                            after insert,
                                            after update)
{    
    new SolarQuoteTriggerHandler().run();
}