public with sharing class IntegrationRequestTriggerHandler {
    @TestVisible private static Boolean futureQueued = false;

    public static void handleAfterInsert(List<Integration_Request__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> queuedIds = new Set<Id>();
        for (Integration_Request__c record : newRecords) {
            if (record == null) {
                continue;
            }

            if (record.Status__c == null || record.Status__c == 'Queued') {
                queuedIds.add(record.Id);
            }
        }

        if (queuedIds.isEmpty() || futureQueued) {
            return;
        }

        futureQueued = true;
        AsyncIntegrationService.processRequests(queuedIds);
    }

    @TestVisible
    static void resetFutureQueuedFlag() {
        futureQueued = false;
    }
}

