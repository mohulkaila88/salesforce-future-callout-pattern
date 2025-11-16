public with sharing class AsyncIntegrationService {
    @TestVisible private static Http httpClient;
    private static final Integer ERROR_FIELD_MAX_LENGTH = 32768;

    @future(callout=true)
    public static void processRequests(Set<Id> requestIds) {
        if (requestIds == null || requestIds.isEmpty()) {
            return;
        }

        List<Integration_Request__c> queuedRequests = [
            SELECT Id,
                   Endpoint__c,
                   Payload__c,
                   Status__c,
                   Method__c
            FROM Integration_Request__c
            WHERE Id IN :requestIds
            AND Status__c = 'Queued'
        ];

        if (queuedRequests.isEmpty()) {
            return;
        }

        //markAsProcessing(queuedRequests);

        Http http = getHttpClient();
        List<Integration_Request__c> updates = new List<Integration_Request__c>();

        for (Integration_Request__c requestRecord : queuedRequests) {
            Integration_Request__c updateRecord = new Integration_Request__c(Id = requestRecord.Id);
            try {
                HttpRequest httpRequest = buildHttpRequest(requestRecord);
                HttpResponse response = http.send(httpRequest);

                if (isSuccess(response)) {
                    updateRecord.Status__c = 'Completed';
                    updateRecord.Error_Message__c = null;
                } else {
                    updateRecord.Status__c = 'Failed';
                    updateRecord.Error_Message__c = truncateError(
                        'HTTP ' + response.getStatusCode() + ' - ' + response.getStatus()
                    );
                }
            } catch (Exception ex) {
                updateRecord.Status__c = 'Failed';
                updateRecord.Error_Message__c = truncateError(ex.getMessage());
            }
            updates.add(updateRecord);
        }

        if (!updates.isEmpty()) {
            Database.update(updates, false);
        }
    }

    private static void markAsProcessing(List<Integration_Request__c> queuedRequests) {
        List<Integration_Request__c> processingUpdates = new List<Integration_Request__c>();
        for (Integration_Request__c requestRecord : queuedRequests) {
            processingUpdates.add(new Integration_Request__c(
                Id = requestRecord.Id,
                Status__c = 'Processing'
            ));
        }

        if (!processingUpdates.isEmpty()) {
            update processingUpdates;
        }
    }

    @TestVisible
    private static Http getHttpClient() {
        if (httpClient != null) {
            return httpClient;
        }
        return new Http();
    }

    @TestVisible
    private static HttpRequest buildHttpRequest(Integration_Request__c requestRecord) {
        if (requestRecord == null) {
            throw new AsyncIntegrationException('Request record cannot be null.');
        }

        if (String.isBlank(requestRecord.Endpoint__c)) {
            throw new AsyncIntegrationException('Endpoint__c is required.');
        }

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(requestRecord.Endpoint__c);
        httpRequest.setMethod(String.isBlank(requestRecord.Method__c) ? 'POST' : requestRecord.Method__c);
        httpRequest.setTimeout(120000);

        if (!String.isBlank(requestRecord.Payload__c)) {
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(requestRecord.Payload__c);
        }

        return httpRequest;
    }

    @TestVisible
    private static Boolean isSuccess(HttpResponse response) {
        if (response == null) {
            return false;
        }
        Integer statusCode = response.getStatusCode();
        return statusCode >= 200 && statusCode < 300;
    }

    private static String truncateError(String message) {
        System.Debug('+++message: ' + message);
        if (message == null) {
            return null;
        }
        return message.length() > ERROR_FIELD_MAX_LENGTH
            ? message.substring(0, ERROR_FIELD_MAX_LENGTH)
            : message;
    }

    public class AsyncIntegrationException extends Exception {}
}

