public class EmailService {
    /**
     * Sends an email notification for high-priority field changes.
     *
     * @param highPriorityChanges List of high-priority field changes.
     * @param toAddresses List of recipient email addresses.
     */
    public static void sendHighPriorityChangeEmail(
        List<Field_Tracking_Log__c> highPriorityChanges,
        List<String> toAddresses
    ) {
        if (highPriorityChanges == null || highPriorityChanges.isEmpty()) {
            System.debug('No high-priority changes to send.');
            return;
        }

        if (toAddresses == null || toAddresses.isEmpty()) {
            System.debug('No email addresses provided.');
            return;
        }

        // Build the HTML email body
        String htmlBody = '<h1>High-Priority Field Changes Detected:</h1><ul>';
        for (Field_Tracking_Log__c change : highPriorityChanges) {
            htmlBody +=
                '<strong>Object Name:</strong> ' +
                change.Object_Name__c +
                '<br/>';
            htmlBody +=
                '<strong>Record ID:</strong> ' +
                change.Record_Id__c +
                '<br/>';
            htmlBody +=
                '<strong>Field Name:</strong> ' +
                change.Field_Name__c +
                '<br/>';
            htmlBody +=
                '<strong>Old Value:</strong> ' +
                String.valueOf(change.Old_Value__c) +
                '<br/>';
            htmlBody +=
                '<strong>New Value:</strong> ' +
                String.valueOf(change.New_Value__c) +
                '<br/>';
            htmlBody +=
                '<strong>Changed By:</strong> ' +
                change.Changed_By__c +
                '<br/>';
            htmlBody +=
                '<strong>Change Time:</strong> ' +
                String.valueOf(change.Change_Date_Time__c);
            htmlBody += '<br/>';
        }
        htmlBody += '</ul>';

        // Define the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject('High-Priority Change Notifications');
        mail.setHtmlBody(htmlBody);

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            System.debug(
                'High-priority change notification email sent successfully.'
            );
        } catch (Exception e) {
            System.debug('Failed to send email: ' + e.getMessage());
            // Optionally, handle the exception (e.g., log to a custom object)
        }
    }
}
