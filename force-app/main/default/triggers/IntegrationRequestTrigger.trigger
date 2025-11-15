trigger IntegrationRequestTrigger on Integration_Request__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        IntegrationRequestTriggerHandler.handleAfterInsert(Trigger.new);
    }
}

