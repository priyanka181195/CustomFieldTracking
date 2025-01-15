trigger ContactFieldTrackingTrigger on Contact(before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        FieldChangeTracker.trackFieldChanges(
            Trigger.new,
            Trigger.old,
            'Contact'
        );
    }
}
