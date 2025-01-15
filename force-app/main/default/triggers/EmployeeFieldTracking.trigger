trigger EmployeeFieldTracking on Employee__c(before update) {
    // We only track changes on update
    if (Trigger.isBefore && Trigger.isUpdate) {
        FieldChangeTracker.trackFieldChanges(
            Trigger.new,
            Trigger.old,
            'Employee__c'
        );
    }
}
