trigger AccountFieldTracking on Account(before update) {
    // We only track changes on update
    if (Trigger.isBefore && Trigger.isUpdate) {
        FieldChangeTracker.trackFieldChanges(
            Trigger.new,
            Trigger.old,
            'Account'
        );
    }
}
