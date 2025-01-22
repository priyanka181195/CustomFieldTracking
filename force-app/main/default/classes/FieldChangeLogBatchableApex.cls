//Alternative approach to Queueable
global class FieldChangeLogBatchableApex implements Database.Batchable<SObject>, Database.Stateful {
    private List<Field_Tracking_Log__c> changeLogs = new List<Field_Tracking_Log__c>();

    public FieldChangeLogBatchableApex(List<Field_Tracking_Log__c> logs) {
        this.changeLogs = logs;
    }

    // No need to fetch records
    global Database.QueryLocator start(Database.BatchableContext context) {
        return null;
    }

    global void execute(Database.BatchableContext context) {
        if (!changeLogs.isEmpty()) {
            insert changeLogs; // Insert logs in bulk
        }
    }

    global void finish(Database.BatchableContext context) {
        System.debug('Batch Job Completed!');
    }
}
