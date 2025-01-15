trigger ProjectFieldTracking on Project__c(before update) {
    // We only track changes on update
    if (Trigger.isBefore && Trigger.isUpdate) {
        FieldChangeTracker.trackFieldChanges(
            Trigger.new,
            Trigger.old,
            'Project__c'
        );
    }
}
