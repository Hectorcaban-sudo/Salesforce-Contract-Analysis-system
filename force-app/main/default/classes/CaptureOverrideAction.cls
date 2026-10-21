public with sharing class CaptureOverrideAction {

    public class OverrideRequest {
        @InvocableVariable(required=true label='Finding Id')
        public Id findingId;

        @InvocableVariable(required=true label='Status (Accepted or Overridden)')
        public String status;

        @InvocableVariable(label='Override Note')
        public String note;
    }

    @AuraEnabled
    @InvocableMethod(label='Capture Finding Override' description='Marks a finding as Accepted or Overridden and stores optional note.')
    public static List<String> captureOverride(List<OverrideRequest> requests) {
        List<String> results = new List<String>();
        for (OverrideRequest req : requests) {
            Contract_Finding__c finding = new Contract_Finding__c(
                Id = req.findingId,
                Review_Status__c = req.status,
                Override_Note__c = req.note
            );
            update finding;
            results.add('Updated finding ' + req.findingId + ' to ' + req.status);
        }
        return results;
    }
}
