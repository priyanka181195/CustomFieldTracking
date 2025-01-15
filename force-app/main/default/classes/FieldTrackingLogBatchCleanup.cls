public with sharing class FieldTrackingLogBatchCleanup implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private static final Integer RETENTION_PERIOD_DAYS = 90;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Calculate the retention cutoff DateTime (90 days ago)
        DateTime cutoffDateTime = DateTime.now()
            .addDays(-RETENTION_PERIOD_DAYS);

        // Format the DateTime value for SOQL (ISO 8601 format)
        String formattedCutoff = cutoffDateTime.format(
            'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''
        );

        // Build the dynamic SOQL query
        String query =
            'SELECT Id FROM Field_Tracking_Log__c WHERE Change_Date_Time__c < ' +
            formattedCutoff;

        // Return the query locator
        return Database.getQueryLocator(query);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Field_Tracking_Log__c> scope
    ) {
        try {
            delete scope;
            System.debug(scope.size() + ' old logs deleted.');
        } catch (Exception e) {
            System.debug('Error during batch cleanup: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Field Tracking Log cleanup job completed.');
    }
}
