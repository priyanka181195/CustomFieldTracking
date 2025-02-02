@isTest
public class TrackFieldChangesTest {
    @testSetup
    static void setup() {
        // Insert initial account records
        Account acc1 = new Account(
            Name = 'Test Account 1',
            Phone = '1234567890',
            Rating = 'Hot'
        );
        Account acc2 = new Account(
            Name = 'Test Account 2',
            Phone = '0987654321'
        );
        insert new List<Account>{ acc1, acc2 };

        // Insert Contact records associated with the above Accounts
        Contact con1 = new Contact(
            FirstName = 'Ross',
            LastName = 'Geller',
            Phone = '1234567890',
            AccountId = acc1.Id,
            Email = 'ross.geller@example.com'
        );
        Contact con2 = new Contact(
            FirstName = 'Monica',
            LastName = 'Geller',
            Phone = '0987654321',
            AccountId = acc2.Id,
            Email = 'monica.geller@example.com'
        );
        insert new List<Contact>{ con1, con2 };

        Field_Tracking_Log__c log = new Field_Tracking_Log__c(
            Object_Name__c = 'Account',
            Record_Id__c = '001XXXXXXXXXXXXXXX',
            Field_Name__c = 'Rating',
            Old_Value__c = 'Cold',
            New_Value__c = 'Hot',
            Change_Date_Time__c = System.today().addDays(-90) // 90 days old log
        );
        insert log;

        // Insert Opportunity record
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addMonths(1),
            Amount = 5000
        );
        insert opp1;

        // Insert Employee__c record
        Employee__c emp1 = new Employee__c(
            First_Name__c = 'Chandler',
            Last_Name__c = 'Bing'
        );
        insert emp1;
    }

    //Testing Account Trigger
    @isTest
    static void testTrackFieldChangesForAccount() {
        // Mock tracked fields (without any high-priority fields)
        Map<String, Map<String, Boolean>> mockTrackedFields = new Map<String, Map<String, Boolean>>{
            'account' => new Map<String, Boolean>{
                'Name' => false, // 'Name' is tracked but not high-priority
                'Phone' => false // 'Phone' is tracked but not high-priority
            }
        };
        FieldChangeTracker.setMockTrackedFields(mockTrackedFields);

        // Query existing accounts inserted via @testSetup
        List<Account> accounts = [SELECT Id, Name, Phone FROM Account];

        // Update the records to trigger the field tracking logic
        accounts[0].Name = 'Updated Account Name';
        accounts[1].Phone = '1111111111';

        // Ensure that the queued job runs
        Test.startTest();
        update accounts;
        Test.stopTest();

        // Verify logs
        List<Field_Tracking_Log__c> logs = [
            SELECT
                Field_Name__c,
                Old_Value__c,
                New_Value__c,
                Is_High_Priority__c
            FROM Field_Tracking_Log__c
        ];
        System.assertEquals(3, logs.size(), 'Three logs should be created');

        // Verify that no high-priority log is created
        Integer highPriorityCount = 0;
        for (Field_Tracking_Log__c log : logs) {
            if (log.Is_High_Priority__c) {
                highPriorityCount++;
            }
        }
        System.assertEquals(
            0,
            highPriorityCount,
            'No high-priority log should be created'
        );
    }

    //Testing Contact Trigger
    @isTest
    static void testTrackFieldChangesForContact() {
        // Mock tracked fields (without any high-priority fields for Contact)
        Map<String, Map<String, Boolean>> mockTrackedFields = new Map<String, Map<String, Boolean>>{
            'contact' => new Map<String, Boolean>{
                'LastName' => false, // 'LastName' is tracked but not high-priority
                'Phone' => false // 'Phone' is tracked but not high-priority
            }
        };
        FieldChangeTracker.setMockTrackedFields(mockTrackedFields);

        // Query existing Contact records inserted via @testSetup
        List<Contact> contacts = [SELECT Id, LastName, Phone FROM Contact];

        // Update the records to trigger the field tracking logic
        contacts[0].LastName = 'Updated Doe';
        contacts[1].Phone = '1111111111';

        Test.startTest();
        update contacts;
        Test.stopTest();

        // Verify logs
        List<Field_Tracking_Log__c> logs = [
            SELECT
                Field_Name__c,
                Old_Value__c,
                New_Value__c,
                Is_High_Priority__c
            FROM Field_Tracking_Log__c
            WHERE Object_Name__c = 'Contact'
        ];
        System.assertEquals(
            2,
            logs.size(),
            'Two logs should be created for Contact'
        );
    }

    //Testing Opportunity Trigger
    @isTest
    static void testOpportunityFieldTracking() {
        // Mock tracked fields for Opportunity with Amount as high priority
        Map<String, Map<String, Boolean>> mockTrackedFields = new Map<String, Map<String, Boolean>>{
            'opportunity' => new Map<String, Boolean>{
                'Amount' => true // High priority
            }
        };
        FieldChangeTracker.setMockTrackedFields(mockTrackedFields);

        // Query the Opportunity record
        Opportunity opp = [SELECT Id, Amount FROM Opportunity LIMIT 1];

        // Update the opportunity amount to trigger tracking
        opp.Amount = 10000;
        Test.startTest();
        update opp;
        Test.stopTest();

        // Verify logs
        List<Field_Tracking_Log__c> logs = [
            SELECT
                Field_Name__c,
                Old_Value__c,
                New_Value__c,
                Is_High_Priority__c
            FROM Field_Tracking_Log__c
            WHERE Object_Name__c = 'Opportunity'
        ];
        System.assertEquals(
            1,
            logs.size(),
            'One log should be created for Opportunity'
        );
        System.assertEquals(
            'Amount',
            logs[0].Field_Name__c,
            'Field name should match'
        );
        System.assertEquals(
            '5000.00',
            logs[0].Old_Value__c,
            'Old value should be "5000.00"'
        );
        System.assertEquals(
            '10000.00',
            logs[0].New_Value__c,
            'New value should be "10000.00"'
        );
        System.assert(
            logs[0].Is_High_Priority__c,
            'Change should be marked as high priority'
        );
    }

    //Testing Employee Trigger
    @isTest
    static void testEmployeeFieldTracking() {
        // Mock tracked fields for Employee__c without any high-priority fields
        Map<String, Map<String, Boolean>> mockTrackedFields = new Map<String, Map<String, Boolean>>{
            'employee__c' => new Map<String, Boolean>{
                'First_Name__c' => false // Not high priority
            }
        };
        FieldChangeTracker.setMockTrackedFields(mockTrackedFields);

        // Query the Employee__c record
        Employee__c emp = [SELECT Id, First_Name__c FROM Employee__c LIMIT 1];

        // Update the first name to trigger tracking
        emp.First_Name__c = 'Chandler Muriel';
        Test.startTest();
        update emp;
        Test.stopTest();

        // Verify logs
        List<Field_Tracking_Log__c> logs = [
            SELECT
                Field_Name__c,
                Old_Value__c,
                New_Value__c,
                Is_High_Priority__c
            FROM Field_Tracking_Log__c
            WHERE Object_Name__c = 'Employee__c'
        ];
        System.assertEquals(
            1,
            logs.size(),
            'One log should be created for Employee__c'
        );
        System.assertEquals(
            'First_Name__c',
            logs[0].Field_Name__c,
            'Field name should match'
        );
        System.assertEquals(
            'Chandler',
            logs[0].Old_Value__c,
            'Old value should be "Chandler"'
        );
        System.assertEquals(
            'Chandler Muriel',
            logs[0].New_Value__c,
            'New value should be "Chandler Muriel"'
        );
        System.assert(
            !logs[0].Is_High_Priority__c,
            'Change should not be marked as high priority'
        );
    }
    @isTest
    static void testProjectFieldTracking() {
        // Mock tracked fields with 'Type__c' marked as high-priority (true)
        Map<String, Map<String, Boolean>> mockTrackedFields = new Map<String, Map<String, Boolean>>{
            'project__c' => new Map<String, Boolean>{
                'Type__c' => true // 'Rating' is tracked and marked as high-priority
            }
        };
        FieldChangeTracker.setMockTrackedFields(mockTrackedFields);

        // Create a Project record
        Project__c proj = new Project__c(
            Project_Title__c = 'Test Project title',
            Type__c = 'Critical'
        );
        insert proj;

        // Update the Project record to trigger field tracking
        proj.Type__c = 'Major';
        update proj;

        // Ensure the queued job runs
        Test.startTest();
        Test.stopTest();

        // Query the Field_Tracking_Log__c object to verify the log was created
        List<Field_Tracking_Log__c> logs = [
            SELECT
                Id,
                Field_Name__c,
                Old_Value__c,
                New_Value__c,
                Is_High_Priority__c
            FROM Field_Tracking_Log__c
            WHERE Record_Id__c = :proj.Id
        ];

        // Assertions
        System.assertEquals(
            1,
            logs.size(),
            'There should be one change log entry'
        );
        System.assertEquals(
            'Type__c',
            logs[0].Field_Name__c,
            'Field name should match'
        );
        System.assertEquals(
            'Critical',
            logs[0].Old_Value__c,
            'Old value should be "Critical"'
        );
        System.assertEquals(
            'Major',
            logs[0].New_Value__c,
            'New value should be "Major"'
        );
        System.assert(
            logs[0].Is_High_Priority__c,
            'The change should be marked as high priority'
        );
    }

    @isTest
    static void testFieldTrackingWithHighPriority() {
        // Mock tracked fields with 'Rating' marked as high-priority (true)
        Map<String, Map<String, Boolean>> mockTrackedFields = new Map<String, Map<String, Boolean>>{
            'account' => new Map<String, Boolean>{
                'Rating' => true // 'Rating' is tracked and marked as high-priority
            }
        };
        FieldChangeTracker.setMockTrackedFields(mockTrackedFields);

        // Create an Account record
        Account acc = new Account(Name = 'Test Account', Rating = 'Hot');
        insert acc;

        // Update the Account record to trigger field tracking
        acc.Rating = 'Warm';
        update acc;

        // Ensure the queued job runs
        Test.startTest();
        Test.stopTest();

        // Query the Field_Tracking_Log__c object to verify the log was created
        List<Field_Tracking_Log__c> logs = [
            SELECT
                Id,
                Field_Name__c,
                Old_Value__c,
                New_Value__c,
                Is_High_Priority__c
            FROM Field_Tracking_Log__c
            WHERE Record_Id__c = :acc.Id
        ];

        // Assertions
        System.assertEquals(
            1,
            logs.size(),
            'There should be one change log entry'
        );
        System.assertEquals(
            'Rating',
            logs[0].Field_Name__c,
            'Field name should match'
        );
        System.assertEquals(
            'Hot',
            logs[0].Old_Value__c,
            'Old value should be "Hot"'
        );
        System.assertEquals(
            'Warm',
            logs[0].New_Value__c,
            'New value should be "Warm"'
        );
        System.assert(
            logs[0].Is_High_Priority__c,
            'The change should be marked as high priority'
        );
    }

    @isTest
    static void testCleanupBatch() {
        // Insert old logs for cleanup
        Field_Tracking_Log__c oldLog = new Field_Tracking_Log__c(
            Object_Name__c = 'Account',
            Record_Id__c = '001XXXXXXXXXXXXXXX',
            Field_Name__c = 'Rating',
            Old_Value__c = 'Cold',
            New_Value__c = 'Hot',
            Change_Date_Time__c = System.today().addDays(-90) // 90 days old log
        );
        insert oldLog;

        Test.startTest();
        FieldTrackingLogBatchCleanup batch = new FieldTrackingLogBatchCleanup();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that old logs are deleted
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Field_Tracking_Log__c],
            'Old logs should be deleted'
        );
    }

    @isTest
    static void testSchedulerExecution() {
        // Create an instance of the scheduler
        FieldTrackingLogBatchScheduler scheduler = new FieldTrackingLogBatchScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Verify that the batch job executed correctly
        Integer logCount = [SELECT COUNT() FROM Field_Tracking_Log__c];
        System.assertEquals(
            0,
            logCount,
            'Old logs should be deleted by the batch job'
        );
    }
}
