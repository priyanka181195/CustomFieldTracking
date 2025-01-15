public with sharing class FieldTrackingLogBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new FieldTrackingLogBatchCleanup(), 200);
    }
}
