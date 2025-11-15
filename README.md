# Async Integration Future Callout Demo

This project demonstrates a lightweight Salesforce pattern for dispatching outbound HTTP callouts from an `@future` method after a record insert. It showcases how to keep trigger logic bulk-safe, isolate integration concerns in a service class, and provide robust tests with mocked callouts.

## Architecture
- `Integration_Request__c` custom object stores queued callout metadata (`Endpoint__c`, `Payload__c`, status fields). See `docs/integration_request_object.md` for detailed field definitions.
- `IntegrationRequestTrigger` (after insert) delegates to `IntegrationRequestTriggerHandler` to gather new request Ids and enqueue future work safely.
- `AsyncIntegrationService.processRequests` is annotated with `@future(callout=true)`, loads queued records, issues the HTTP call, and updates statuses (`Queued` → `Processing` → `Completed/Failed`).
- `AsyncIntegrationServiceTest` covers both success and failure responses with `HttpCalloutMock` implementations.

## Setup
1. Create the `Integration_Request__c` object and the required fields described in `docs/integration_request_object.md`. Add picklist values (`Queued`, `Processing`, `Completed`, `Failed`) and optional `Method__c` values (`POST`, `PUT`, `PATCH`, `DELETE`).
2. Grant CRUD/FLS access for the object to users or integration profiles that will insert request records.
3. Deploy the Apex classes and trigger using your preferred tooling (e.g., `sfdx force:source:deploy -p force-app/main/default`).

## Workflow
1. Business logic creates an `Integration_Request__c` row with `Status__c = "Queued"` (defaults recommended).
2. The after-insert trigger collects qualifying Ids and queues the future method exactly once per transaction.
3. The future method marks records `Processing`, executes the HTTP callout, and finalizes the status:
   - `Completed` with cleared `Error_Message__c` for 2xx responses.
   - `Failed` with a truncated error message for non-2xx responses or exceptions.

## Testing
- Run all tests from Setup → Apex Test Execution, or via CLI:\
  `sfdx force:apex:test:run -n AsyncIntegrationServiceTest -w 10 -r human`
- The test class resets recursion guards, inserts sample requests, registers `HttpCalloutMock` implementations, and verifies status transitions for both success and failure paths.

## Extending the Pattern
- Add retry logic using `Retry_Count__c`, or move failed records to a queue for manual review.
- Replace the inline `Http` client with an injectable interface if you need more elaborate mocking or dependency injection.
- Consider moving to Queueable Apex for chaining or complex orchestration once requirements grow beyond the simple future use case.

## References
- Salesforce Apex Developer Guide – Future Methods: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
- Salesforce Apex Testing Guide: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing.htm
- Queueable Apex Overview (alternative approach): https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
# Salesforce DX Project: Next Steps

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
