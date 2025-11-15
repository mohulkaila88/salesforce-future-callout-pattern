<!-- Integration Request custom object definition -->

# `Integration_Request__c` Metadata Notes

## Purpose
Capture payloads queued for outbound HTTP callouts so they can be processed asynchronously by `AsyncIntegrationService`.

## Required Fields
- `Name` (Auto Number recommended, Display Format `REQ-{000000}`).
- `Endpoint__c` (URL, 255). Target endpoint for the callout.
- `Payload__c` (Long Text Area, 32768). Serialized JSON payload.
- `Status__c` (Picklist). Values: `Queued`, `Processing`, `Completed`, `Failed`.
- `Error_Message__c` (Long Text Area, 32768, optional). Stores last failure message.

## Optional Fields
- `Method__c` (Picklist). Values: `POST`, `PUT`, `PATCH`, `DELETE`. Defaults to `POST`.
- `Retry_Count__c` (Number, 3,0). Track retry attempts if you extend the pattern.

## Recommended Automation
- Default `Status__c` to `Queued` on insert.
- Validation to require `Endpoint__c` and `Payload__c`.
- Flow or Trigger to populate payload and insert the record.

## Deployment Notes
- Add the object to `package.xml` (`CustomObject` type) if you want to source-control the metadata.
- Provide CRUD/FLS to the integration user profile or permission set.

