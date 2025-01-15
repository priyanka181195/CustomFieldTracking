@IsTest
public with sharing class FieldChangeLogControllerTest {
    @IsTest
    static void testGetFieldChanges() {
        // Step 1: Set up test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Field_Tracking_Log__c log1 = new Field_Tracking_Log__c(
            Object_Name__c = 'Account',
            Record_Id__c = testAccount.Id,
            Field_Name__c = 'Name',
            Old_Value__c = 'Old Name',
            New_Value__c = 'New Name',
            Changed_By__c = UserInfo.getUserId(),
            Change_Date_Time__c = System.now().addDays(-5)
        );
        insert log1;

        Field_Tracking_Log__c log2 = new Field_Tracking_Log__c(
            Object_Name__c = 'Account',
            Record_Id__c = testAccount.Id,
            Field_Name__c = 'Name',
            Old_Value__c = 'New Name',
            New_Value__c = 'Final Name',
            Changed_By__c = UserInfo.getUserId(),
            Change_Date_Time__c = System.now().addDays(-1)
        );
        insert log2;

        // Step 2: Call the method with valid filters
        List<Field_Tracking_Log__c> result = FieldChangeLogController.getFieldChanges(
            'Account',
            'Name',
            Date.today().addDays(-7),
            Date.today()
        );

        System.assertEquals(
            2,
            result.size(),
            'Expected two field change logs.'
        );

        // Step 3: Call the method with no filters (should return all logs)
        result = FieldChangeLogController.getFieldChanges('', '', null, null);
        System.assertEquals(
            2,
            result.size(),
            'Expected all field change logs.'
        );

        // Step 4: Call the method with only start date
        result = FieldChangeLogController.getFieldChanges(
            '',
            '',
            Date.today().addDays(-3),
            null
        );
        System.assertEquals(1, result.size(), 'Expected one field change log.');

        // Step 5: Call the method with only end date
        result = FieldChangeLogController.getFieldChanges(
            '',
            '',
            null,
            Date.today().addDays(-4)
        );
        System.assertEquals(1, result.size(), 'Expected one field change log.');
    }

    @IsTest
    static void testGetAllSObjects() {
        // Call the method and check results
        List<Map<String, String>> sObjectList = FieldChangeLogController.getAllSObjects();
        System.assertNotEquals(
            0,
            sObjectList.size(),
            'Expected some SObjects to be returned.'
        );
    }

    @IsTest
    static void testGetFields() {
        // Call the method for a standard object (Account)
        List<Map<String, String>> fieldList = FieldChangeLogController.getFields(
            'Account'
        );
        System.assertNotEquals(
            0,
            fieldList.size(),
            'Expected some fields to be returned for Account.'
        );
    }
}
