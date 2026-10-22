public with sharing class PresentFindingsInUIAction {

    public class PresentRequest {
        @InvocableVariable(required=true label='Review Id' description='Salesforce ID of the Contract_Review__c record whose findings should be presented.')
        public String reviewId;
    }

    public class PresentResult {
        @InvocableVariable(label='UI Payload JSON' description='JSON payload for PresentInUI. Contains findings list and a record link.')
        public String uiPayloadJson;

        @InvocableVariable(label='Record Link' description='Direct link to the Contract Review record.')
        public String recordLink;

        @InvocableVariable(label='Summary Message' description='Short message the agent can show with the UI.')
        public String summaryMessage;
    }

    @InvocableMethod(label='Present Findings in UI' description='Builds a PresentInUI payload with contract findings and a record link so the lawyer can review Accept/Override in the agent chat.')
    public static List<PresentResult> presentFindings(List<PresentRequest> requests) {
        List<PresentResult> results = new List<PresentResult>();
        for (PresentRequest req : requests) {
            PresentResult res = new PresentResult();

            // Build a simple record link
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            res.recordLink = baseUrl + '/lightning/r/Contract_Review__c/' + req.reviewId + '/view';

            // Stub payload — replace with real SOQL against Contract_Finding__c in production
            res.uiPayloadJson = '{"title":"Contract Findings","reviewId":"' + req.reviewId + '","link":"' + res.recordLink + '","findings":[{"clauseType":"Liability Limitation","riskLevel":"High","excerpt":"Sample excerpt...","status":"Pending"}]}';
            res.summaryMessage = 'Findings are ready for review. Open the record or use the panel below to Accept or Override.';

            results.add(res);
        }
        return results;
    }
}
