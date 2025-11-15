@IsTest
private class AsyncIntegrationServiceTest {
    @IsTest
    static void triggerQueuesFutureAndCompletesSuccessfully() {
        IntegrationRequestTriggerHandler.resetFutureQueuedFlag();

        Integration_Request__c requestRecord = new Integration_Request__c(
            Endpoint__c = 'https://example.org/success',
            Payload__c = '{"message":"hello"}',
            Status__c = 'Queued',
            Method__c = 'POST'
        );

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        insert requestRecord;
        Test.stopTest();

        Integration_Request__c processedRecord = [
            SELECT Status__c, Error_Message__c
            FROM Integration_Request__c
            WHERE Id = :requestRecord.Id
            LIMIT 1
        ];

        System.assertEquals('Completed', processedRecord.Status__c, 'Status should update to Completed.');
        System.assertEquals(null, processedRecord.Error_Message__c, 'Error message should be cleared.');
    }

    @IsTest
    static void futureHandlesFailedResponses() {
        IntegrationRequestTriggerHandler.resetFutureQueuedFlag();

        Integration_Request__c requestRecord = new Integration_Request__c(
            Endpoint__c = 'https://example.org/failure',
            Payload__c = '{"message":"fail"}',
            Status__c = 'Queued',
            Method__c = 'POST'
        );
        insert requestRecord;

        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Test.startTest();
        AsyncIntegrationService.processRequests(new Set<Id>{ requestRecord.Id });
        Test.stopTest();

        Integration_Request__c processedRecord = [
            SELECT Status__c, Error_Message__c
            FROM Integration_Request__c
            WHERE Id = :requestRecord.Id
            LIMIT 1
        ];

        System.assertEquals('Failed', processedRecord.Status__c, 'Status should update to Failed.');
        System.assertNotEquals(null, processedRecord.Error_Message__c, 'Error message should capture failure details.');
    }

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"success":true}');
            return response;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setStatus('Server Error');
            response.setBody('{"success":false}');
            return response;
        }
    }
}

