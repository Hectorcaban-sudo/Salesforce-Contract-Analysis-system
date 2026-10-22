public with sharing class IntelligentContextRetrievalAction {

    public class RetrievalRequest {
        @InvocableVariable(required=true label='Search Query' description='The citation, clause text, or question to retrieve supporting context for.')
        public String searchQuery;

        @InvocableVariable(label='Index Name' description='Optional Intelligent Context / Data Cloud index to search (e.g. Playbooks, Regulations, HistoricalContracts).')
        public String indexName;

        @InvocableVariable(label='Max Results' description='Maximum number of supporting passages to return. Defaults to 5.')
        public Integer maxResults;
    }

    public class RetrievalResult {
        @InvocableVariable(label='Supporting Passages JSON' description='JSON array of retrieved passages with source, text, and relevance score.')
        public String passagesJson;

        @InvocableVariable(label='Citation Status' description='Supported, Partially Supported, Not Supported, or Insufficient Context.')
        public String citationStatus;

        @InvocableVariable(label='Confidence Score' description='Confidence that the retrieved context supports the claim (0-100).')
        public Integer confidenceScore;

        @InvocableVariable(label='Status Message' description='Human-readable result or any warnings.')
        public String message;
    }

    @InvocableMethod(label='Retrieve Intelligent Context' description='Retrieves supporting passages from Intelligent Context / Data Cloud indexes for citation validation, playbook comparison, or authority grounding.')
    public static List<RetrievalResult> retrieveContext(List<RetrievalRequest> requests) {
        List<RetrievalResult> results = new List<RetrievalResult>();
        for (RetrievalRequest req : requests) {
            RetrievalResult res = new RetrievalResult();
            // TODO: Replace stub with real Intelligent Context / Data Cloud retrieval call
            // Example: query the specified index with req.searchQuery and limit to req.maxResults
            res.passagesJson = '[{"source":"Playbook - Liability","text":"Preferred liability cap is 12 months of fees or $1M, whichever is less.","score":0.92}]';
            res.citationStatus = 'Partially Supported';
            res.confidenceScore = 75;
            res.message = 'Retrieval complete (stub). Extend to call Intelligent Context or Data Cloud search. Flag for review if confidence < 70.';
            results.add(res);
        }
        return results;
    }
}
