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
            filters.add('Object_Name__c = :objectName');
        }
        if (fieldName != null && fieldName != '') {
            filters.add('Field_Name__c = :fieldName');
        }
        if (startDate != null) {
            filters.add('Change_Date_Time__c >= :startDate');
        }
        if (endDate != null) {
            // endDate is inclusive. To include endDate's entire day, you might do endDate+1
            filters.add('Change_Date_Time__c <= :endDate');
        }

        if (!filters.isEmpty()) {
            baseQuery += ' AND ' + String.join(filters, ' AND ');
        }

        baseQuery += ' ORDER BY Change_Date_Time__c DESC LIMIT 1000';
        // Add limit to avoid performance issues

        return Database.query(baseQuery);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllSObjects() {
        // Query to get only standard and custom SObjects (excluding internal objects)
        List<EntityDefinition> entityDefs = [
            SELECT Label, QualifiedApiName
            FROM EntityDefinition
            WHERE IsCustomizable = TRUE AND IsDeprecatedAndHidden = FALSE
            ORDER BY QualifiedApiName
        ];

        // Build a list of maps with 'label' and 'value' keys for combobox
        List<Map<String, String>> sObjectList = new List<Map<String, String>>();
        for (EntityDefinition ed : entityDefs) {
            Map<String, String> sObjectMap = new Map<String, String>();
            sObjectMap.put('label', ed.Label);
            sObjectMap.put('value', ed.QualifiedApiName);
            sObjectList.add(sObjectMap);
        }

        return sObjectList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFields(String sObjectName) {
        // Describe the SObject
        Schema.SObjectType objType = Schema.getGlobalDescribe()
            .get(sObjectName);
        Map<String, Schema.SObjectField> fieldsMap = objType.getDescribe()
            .fields.getMap();

        // Build a list of maps with 'label' and 'value' keys for combobox
        List<Map<String, String>> fieldList = new List<Map<String, String>>();
        for (String fieldName : fieldsMap.keySet()) {
            Map<String, String> fieldMap = new Map<String, String>();
            fieldMap.put(
                'label',
                fieldsMap.get(fieldName).getDescribe().getLabel()
            );
            fieldMap.put('value', fieldName);
            fieldList.add(fieldMap);
        }

        return fieldList;
    }
}
