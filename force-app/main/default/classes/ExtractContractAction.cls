public with sharing class ExtractContractAction {

    public class ExtractionRequest {
        @InvocableVariable(required=true label='Document ID' description='ContentDocumentId or Salesforce File ID of the contract to extract.')
        public String documentId;

        @InvocableVariable(label='Extraction Template Name' description='Optional name of the Contracts AI extraction template to use (e.g. for mods or agency-specific formats).')
        public String templateName;
    }

    public class ExtractionResult {
        @InvocableVariable(label='Extracted Fields JSON' description='JSON of extracted contract fields (parties, dates, governing law, etc.).')
        public String fieldsJson;

        @InvocableVariable(label='Extracted Clauses JSON' description='JSON array of extracted clauses with type, excerpt, and section path.')
        public String clausesJson;

        @InvocableVariable(label='Document Type' description='Detected type: Base Contract, Modification, Subcontract Mod, Task Order, etc.')
        public String documentType;

        @InvocableVariable(label='Confidence Score' description='Overall extraction confidence (0-100). Low values should be flagged for human review.')
        public Integer confidenceScore;

        @InvocableVariable(label='Status Message' description='Human-readable result or any warnings.')
        public String message;
    }

    @InvocableMethod(label='Extract Contract with Document AI' description='Extracts contract fields and clauses from a document using Document AI / Contracts AI. Handles non-standard formats, mods, and agency variations.')
    public static List<ExtractionResult> extractContract(List<ExtractionRequest> requests) {
        List<ExtractionResult> results = new List<ExtractionResult>();
        for (ExtractionRequest req : requests) {
            ExtractionResult res = new ExtractionResult();
            // TODO: Replace stub with real Document AI / Contracts AI call
            // Example: call extraction service, pass req.documentId and req.templateName
            res.fieldsJson = '{"parties":["Acme Corp","Government Agency"],"effectiveDate":"2026-01-15","governingLaw":"Federal"}';
            res.clausesJson = '[{"clauseType":"Liability Limitation","excerpt":"Sample liability text...","section":"12.1"}]';
            res.documentType = 'Base Contract';
            res.confidenceScore = 82;
            res.message = 'Extraction complete (stub). Extend to call Document AI / Contracts AI. Flag for review if confidence < 70.';
            results.add(res);
        }
        return results;
    }
}
