public with sharing class ExtractContractAction {

    private static final String EXTRACTION_PROMPT = 'Extract_Contract_Document';

    public class ExtractionRequest {
        @InvocableVariable(required=true label='Document ID' description='ContentDocumentId or Salesforce File ID of the contract to extract.')
        public String documentId;

        @InvocableVariable(label='Extraction Template Name' description='Optional name of the Contracts AI / Document AI extraction template to use (e.g. for mods or agency-specific formats).')
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

    @InvocableMethod(label='Extract Contract with Document AI' description='Extracts contract fields and clauses from a document using a Prompt Template grounded on the uploaded file (Document AI / Contracts AI path).')
    public static List<ExtractionResult> extractContract(List<ExtractionRequest> requests) {
        List<ExtractionResult> results = new List<ExtractionResult>();
        for (ExtractionRequest req : requests) {
            results.add(extractSingle(req));
        }
        return results;
    }

    private static ExtractionResult extractSingle(ExtractionRequest req) {
        ExtractionResult res = new ExtractionResult();
        if (String.isBlank(req.documentId)) {
            res.message = 'Document ID is required.';
            res.confidenceScore = 0;
            res.fieldsJson = '{}';
            res.clausesJson = '[]';
            return res;
        }

        try {
            // Pass ContentDocument Id to the prompt template
            Map<String, String> fileRef = new Map<String, String>{
                'id' => req.documentId,
                'type' => 'ContentDocument'
            };
            ConnectApi.WrappedValue fileValue = new ConnectApi.WrappedValue();
            fileValue.value = fileRef;

            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            inputParams.put('Input:InputFile', fileValue);

            if (String.isNotBlank(req.templateName)) {
                ConnectApi.WrappedValue templateValue = new ConnectApi.WrappedValue();
                templateValue.value = req.templateName;
                inputParams.put('Input:TemplateName', templateValue);
            }

            ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            promptInput.inputParams = inputParams;
            promptInput.isPreview = false;
            promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            promptInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            promptInput.additionalConfig.temperature = 0.2;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(EXTRACTION_PROMPT, promptInput);

            String raw = (response != null && response.generations != null && !response.generations.isEmpty())
                ? response.generations[0].text
                : null;

            if (String.isBlank(raw)) {
                res.message = 'Extraction returned no content.';
                res.confidenceScore = 0;
                res.fieldsJson = '{}';
                res.clausesJson = '[]';
                return res;
            }

            // Strip markdown fences if the model added them
            String jsonText = raw.trim();
            if (jsonText.startsWith('```')) {
                jsonText = jsonText.replaceFirst('^```json', '').replaceFirst('^```', '');
                if (jsonText.endsWith('```')) {
                    jsonText = jsonText.substring(0, jsonText.length() - 3);
                }
                jsonText = jsonText.trim();
            }

            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonText);

            res.documentType = (String) parsed.get('documentType');
            res.confidenceScore = parsed.containsKey('confidenceScore')
                ? Integer.valueOf(String.valueOf(parsed.get('confidenceScore')))
                : 70;

            // Fields = everything except the clauses array
            Map<String, Object> fields = new Map<String, Object>(parsed);
            fields.remove('clauses');
            res.fieldsJson = JSON.serialize(fields);

            Object clauses = parsed.get('clauses');
            res.clausesJson = (clauses != null) ? JSON.serialize(clauses) : '[]';

            res.message = (res.confidenceScore < 70)
                ? 'Extraction complete. Low confidence — flag for human review.'
                : 'Extraction complete.';

        } catch (Exception e) {
            res.fieldsJson = '{}';
            res.clausesJson = '[]';
            res.documentType = 'Unknown';
            res.confidenceScore = 0;
            res.message = 'Extraction failed: ' + e.getMessage();
        }
        return res;
    }
}
