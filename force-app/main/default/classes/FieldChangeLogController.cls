public with sharing class FieldChangeLogController {
    @AuraEnabled(cacheable=true)
    public static List<Field_Tracking_Log__c> getFieldChanges(
        String objectName,
        String fieldName,
        Date startDate,
        Date endDate
    ) {
        String baseQuery = 'SELECT Id, Object_Name__c, Record_Id__c, Field_Name__c, Old_Value__c, New_Value__c, Changed_By__c, Change_Date_Time__c FROM Field_Tracking_Log__c WHERE Id != null';

        List<String> filters = new List<String>();

        if (objectName != null && objectName != '') {
            filters.add(
                'Object_Name__c = \'' +
                    String.escapeSingleQuotes(objectName) +
                    '\''
            );
        }
        if (fieldName != null && fieldName != '') {
            filters.add(
                'Field_Name__c = \'' +
                    String.escapeSingleQuotes(fieldName) +
                    '\''
            );
        }
        if (startDate != null) {
            DateTime startDateTime = DateTime.newInstance(
                startDate.year(),
                startDate.month(),
                startDate.day()
            );
            filters.add(
                'Change_Date_Time__c >= ' +
                startDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
            );
        }
        if (endDate != null) {
            DateTime endDateTime = DateTime.newInstance(
                    endDate.year(),
                    endDate.month(),
                    endDate.day()
                )
                .addDays(1);
            filters.add(
                'Change_Date_Time__c < ' +
                endDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
            );
        }

        if (filters.isEmpty()) {
            baseQuery += ' ORDER BY Change_Date_Time__c DESC LIMIT 100';
        } else {
            baseQuery +=
                ' AND ' +
                String.join(filters, ' AND ') +
                ' ORDER BY Change_Date_Time__c DESC LIMIT 100';
        }

        return Database.query(baseQuery);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllSObjects() {
        // Query custom metadata for configured SObjects
        List<Field_Tracking_Log_Config__mdt> metadataConfigs = [
            SELECT Object_API_Name__c, Object_Name__c
            FROM Field_Tracking_Log_Config__mdt
        ];

        // Use a Set to avoid duplicates
        Set<String> addedSObjects = new Set<String>();
        List<Map<String, String>> sObjectList = new List<Map<String, String>>();

        for (Field_Tracking_Log_Config__mdt config : metadataConfigs) {
            if (!addedSObjects.contains(config.Object_API_Name__c)) {
                Map<String, String> sObjectMap = new Map<String, String>();
                sObjectMap.put('label', config.Object_Name__c); // Display label
                sObjectMap.put('value', config.Object_API_Name__c); // API name as value
                sObjectList.add(sObjectMap);
                addedSObjects.add(config.Object_API_Name__c); // Add to Set to track uniqueness
            }
        }

        return sObjectList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFields(String sObjectName) {
        // Query custom metadata for configured fields of the given SObject
        List<Field_Tracking_Log_Config__mdt> metadataConfigs = [
            SELECT Field_API_Name__c, Field_Name__c
            FROM Field_Tracking_Log_Config__mdt
            WHERE Object_API_Name__c = :sObjectName
        ];

        // Build a list of maps with 'label' and 'value' keys for combobox
        List<Map<String, String>> fieldList = new List<Map<String, String>>();
        for (Field_Tracking_Log_Config__mdt config : metadataConfigs) {
            Map<String, String> fieldMap = new Map<String, String>();
            fieldMap.put('label', config.Field_Name__c);
            fieldMap.put('value', config.Field_API_Name__c);
            fieldList.add(fieldMap);
        }

        return fieldList;
    }
}
