//Field Change Tracking and a utility class for all triggers
public with sharing class FieldChangeTracker {
    //Map to store tracked fields by object
    @testVisible
    private static Map<String, Map<String, Boolean>> trackedFieldsMap;

    // Static initializer to load configuration from custom metadata
    static {
        trackedFieldsMap = new Map<String, Map<String, Boolean>>();
        for (Field_Tracking_Log_Config__mdt conf : [
            SELECT Object_API_Name__c, Field_API_Name__c, Is_High_Priority__c
            FROM Field_Tracking_Log_Config__mdt
        ]) {
            String objectKey = conf.Object_API_Name__c.toLowerCase();
            if (!trackedFieldsMap.containsKey(objectKey)) {
                trackedFieldsMap.put(objectKey, new Map<String, Boolean>());
            }
            trackedFieldsMap.get(objectKey)
                .put(conf.Field_API_Name__c, conf.Is_High_Priority__c);
        }
    }

    //Setting mockTrackFields for test methods of metadata
    @testVisible
    static void setMockTrackedFields(
        Map<String, Map<String, Boolean>> mockMap
    ) {
        trackedFieldsMap = mockMap;
    }

    //Generic method to get field changes. This is called by every object's trigger
    public static void trackFieldChanges(
        List<SObject> newList,
        List<SObject> oldList,
        String objectName
    ) {
        if (newList == null || oldList == null || newList.isEmpty()) {
            return;
        }

        String objectKey = objectName.toLowerCase();
        if (!trackedFieldsMap.containsKey(objectKey)) {
            // No fields to track for this object
            return;
        }

        Map<String, Boolean> trackedFields = trackedFieldsMap.get(objectKey);
        List<Field_Tracking_Log__c> changeLogs = new List<Field_Tracking_Log__c>();

        // Loop through each record in the trigger context
        for (Integer i = 0; i < newList.size(); i++) {
            SObject newRecord = newList[i];
            SObject oldRecord = oldList[i];

            // Check only the fields that are tracked for this object
            for (String fieldApiName : trackedFields.keySet()) {
                Object newValue = newRecord.get(fieldApiName);
                Object oldValue = oldRecord.get(fieldApiName);

                // Compare old vs. new values
                if (valuesDiffer(oldValue, newValue)) {
                    Field_Tracking_Log__c log = new Field_Tracking_Log__c();
                    log.Object_Name__c = objectName;
                    log.Record_Id__c = (Id) newRecord.get('Id');
                    log.Field_Name__c = fieldApiName;
                    log.Old_Value__c = oldValue != null
                        ? String.valueOf(oldValue)
                        : '';
                    log.New_Value__c = newValue != null
                        ? String.valueOf(newValue)
                        : '';
                    log.Changed_By__c = UserInfo.getUserId();
                    log.Change_Date_Time__c = System.now();
                    log.Is_High_Priority__c = trackedFields.get(fieldApiName);

                    changeLogs.add(log);
                }
            }
        }

        if (!changeLogs.isEmpty()) {
            try {
                System.enqueueJob(new FieldChangeLogJob(changeLogs));
            } catch (Exception e) {
                System.debug('Failed to enqueue job: ' + e.getMessage());
            }
        }

        //~Batchable Apex
        // if (!changeLogs.isEmpty()) {
        //     try {
        //         FieldChangeBatchJob batchJob = new FieldChangeBatchJob(
        //             changeLogs
        //         );
        //         Database.executeBatch(batchJob, 200); // Adjust batch size as needed
        //     } catch (Exception e) {
        //         System.debug('Failed to enqueue batch job: ' + e.getMessage());
        //     }
        // }
    }

    private static Boolean valuesDiffer(Object oldValue, Object newValue) {
        if (oldValue == null && newValue == null)
            return false;
        if (oldValue == null && newValue != null)
            return true;
        return !oldValue.equals(newValue);
    }

    //Retrieves all active email recipients from the Custom Metadata Type.
    public static List<String> getRecipientEmails() {
        List<String> recipientEmails = new List<String>();

        // Query all Email_Recipient__mdt records
        List<Email_Recipient__mdt> recipients = [
            SELECT Recipient_Email__c
            FROM Email_Recipient__mdt
            WHERE DeveloperName = 'Dev_Team'
        ];

        for (Email_Recipient__mdt recipient : recipients) {
            if (recipient.Recipient_Email__c != null) {
                recipientEmails.add(recipient.Recipient_Email__c);
            }
        }

        return recipientEmails;
    }
}
