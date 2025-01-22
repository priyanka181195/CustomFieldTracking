public with sharing class FieldChangeLogJob implements Queueable, Database.AllowsCallouts {
    private List<Field_Tracking_Log__c> changeLogs;

    // Constructor to pass changeLogs
    public FieldChangeLogJob(List<Field_Tracking_Log__c> changeLogs) {
        this.changeLogs = changeLogs;
    }

    public void execute(QueueableContext context) {
        if (changeLogs == null || changeLogs.isEmpty()) {
            // No change logs to process
            return;
        }

        try {
            // Insert the change logs
            insert changeLogs;

            //~ we can insert condition for more than 10,000 logs
            //List<Field_Tracking_Log__c> batchToInsert;
            // if (changeLogs.size() > 10000) {
            //     batchToInsert = changeLogs.subList(0, 10000); // First 10,000 records
            // } else {
            //     batchToInsert = changeLogs;
            // }

            // insert batchToInsert;

            // Chain another Queueable job if more records remain
            // if (changeLogs.size() > 10000) {
            //     List<Field_Tracking_Log__c> remainingLogs = changeLogs.subList(10000, changeLogs.size());
            //     System.enqueueJob(new FieldChangeLogJob(remainingLogs));
            // }

            // Collect high-priority changes
            List<Field_Tracking_Log__c> highPriorityChanges = new List<Field_Tracking_Log__c>();
            for (Field_Tracking_Log__c change : changeLogs) {
                if (change.Is_High_Priority__c) {
                    highPriorityChanges.add(change);
                }
            }

            if (!highPriorityChanges.isEmpty()) {
                // Retrieve email addresses from Custom Metadata
                List<String> toAddresses = FieldChangeTracker.getRecipientEmails();

                if (!toAddresses.isEmpty()) {
                    // Delegate email sending to EmailService
                    EmailService.sendHighPriorityChangeEmail(
                        highPriorityChanges,
                        toAddresses
                    );
                } else {
                    System.debug(
                        'No email addresses found in Custom Metadata.'
                    );
                }
            } else {
                System.debug('No high-priority changes found.');
            }
        } catch (Exception e) {
            System.debug('Error in FieldChangeLogJob: ' + e.getMessage());
        }
    }
}
