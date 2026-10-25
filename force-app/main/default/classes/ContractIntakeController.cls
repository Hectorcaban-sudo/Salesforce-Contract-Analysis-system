/**
 * Gov High intake path.
 * 1. Tries Document AI extraction first (configurable schema name).
 * 2. Falls back to the Extract_Contract_Document prompt template.
 * 3. Invokes the active Agentforce agent with the extraction result.
 */
public with sharing class ContractIntakeController {

    private static final String AGENT_API_NAME = 'Contract_Analysis_Agent';
    private static final String PROMPT_TEMPLATE = 'Extract_Contract_Document';
    // Change this to the Document AI schema / extraction template name you create in the org.
    private static final String DOCUMENT_AI_SCHEMA = 'Flexible_Contract_Schema';

    public class IntakeRequest {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String contractName;
        @AuraEnabled public String documentType;
        @AuraEnabled public String agency;
        @AuraEnabled public String notes;
        @AuraEnabled public Id draftReviewId;
    }

    public class IntakeResult {
        @AuraEnabled public Id reviewId;
        @AuraEnabled public String agentResponse;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String extractionSource;
    }

    @AuraEnabled
    public static Id createDraftReview() {
        Contract_Review__c review = new Contract_Review__c(
            Name = 'Draft ' + Datetime.now().format('yyyy-MM-dd HH:mm'),
            Status__c = 'Draft'
        );
        insert review;
        return review.Id;
    }

    @AuraEnabled
    public static IntakeResult startAnalysis(IntakeRequest request) {
        if (request == null || String.isBlank(request.contentDocumentId)) {
            throw new AuraHandledException('Upload a contract file before running analysis.');
        }

        Contract_Review__c review = upsertReview(request);
        linkFile(request.contentDocumentId, review.Id);

        IntakeResult result = new IntakeResult();
        result.reviewId = review.Id;

        // 1) Document AI first, 2) prompt template fallback
        ExtractionOutcome extraction = extractWithDocumentAi(request);
        if (!extraction.success) {
            extraction = extractWithPromptTemplate(request);
        }
        result.extractionSource = extraction.source;

        review.Extraction_Source__c = extraction.source;
        review.Extraction_Json__c = extraction.jsonText;
        update review;

        String userMessage = buildAgentMessage(request, review, extraction);

        try {
            Invocable.Action action = Invocable.Action.createCustomAction(
                'generateAiAgentResponse',
                null,
                AGENT_API_NAME,
                '1.0.0'
            );
            action.setInvocationParameter('userMessage', userMessage);

            List<Invocable.Action.Result> results = action.invoke();
            if (!results.isEmpty() && results[0].isSuccess()) {
                result.agentResponse = String.valueOf(results[0].getOutputParameters().get('agentResponse'));
                result.sessionId = String.valueOf(results[0].getOutputParameters().get('sessionId'));
                review.Status__c = 'Ready for Review';
                update review;
            } else {
                String err = results.isEmpty()
                    ? 'No response from agent'
                    : String.valueOf(results[0].getErrors());
                result.errorMessage = err;
                review.Status__c = 'Error';
                review.Notes__c = appendNote(review.Notes__c, 'Agent error: ' + err);
                update review;
            }
        } catch (Exception e) {
            result.errorMessage = e.getMessage();
            review.Status__c = 'Error';
            review.Notes__c = appendNote(review.Notes__c, 'Agent error: ' + e.getMessage());
            update review;
        }

        return result;
    }

    private static Contract_Review__c upsertReview(IntakeRequest request) {
        Contract_Review__c review;
        if (request.draftReviewId != null) {
            review = [
                SELECT Id, Name, Status__c, Notes__c
                FROM Contract_Review__c
                WHERE Id = :request.draftReviewId
                LIMIT 1
            ];
            review.Name = String.isNotBlank(request.contractName)
                ? request.contractName
                : review.Name;
        } else {
            review = new Contract_Review__c(
                Name = String.isNotBlank(request.contractName)
                    ? request.contractName
                    : 'Review ' + Datetime.now().format('yyyy-MM-dd HH:mm')
            );
        }

        review.Status__c = 'In Progress';
        review.Document_Type__c = request.documentType;
        review.Agency__c = request.agency;
        review.Notes__c = request.notes;
        review.ContentDocumentId__c = request.contentDocumentId;

        if (review.Id == null) {
            insert review;
        } else {
            update review;
        }
        return review;
    }

    private static void linkFile(String contentDocumentId, Id reviewId) {
        List<ContentDocumentLink> existing = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
              AND LinkedEntityId = :reviewId
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            insert new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = reviewId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
        }
    }

    /**
     * Document AI path.
     * Wire this to your org's Document AI / Contracts AI extraction once the schema is created.
     * Until the schema exists, this returns unsuccessful and the prompt template runs.
     */
    private static ExtractionOutcome extractWithDocumentAi(IntakeRequest request) {
        ExtractionOutcome outcome = new ExtractionOutcome();
        outcome.source = 'Document AI';
        try {
            // Placeholder: replace with the Document AI / Contracts AI invocable or Connect API
            // call for schema DOCUMENT_AI_SCHEMA once it is configured in the org.
            // Example shape once wired:
            //   Invocable.Action action = Invocable.Action.createStandardAction('documentAiExtract');
            //   action.setInvocationParameter('contentDocumentId', request.contentDocumentId);
            //   action.setInvocationParameter('schemaName', DOCUMENT_AI_SCHEMA);
            //   ...
            //
            // Until that call is wired, treat Document AI as not yet available so the
            // prompt template fallback runs.
            outcome.success = false;
            outcome.jsonText = 'Document AI schema "' + DOCUMENT_AI_SCHEMA + '" not yet wired in Apex.';
        } catch (Exception e) {
            outcome.success = false;
            outcome.jsonText = 'Document AI error: ' + e.getMessage();
        }
        return outcome;
    }

    private static ExtractionOutcome extractWithPromptTemplate(IntakeRequest request) {
        ExtractionOutcome outcome = new ExtractionOutcome();
        outcome.source = 'Prompt Template';
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();

            Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue fileParam = new ConnectApi.WrappedValue();
            fileParam.value = request.contentDocumentId;
            params.put('Input:InputFile', fileParam);

            ConnectApi.WrappedValue typeParam = new ConnectApi.WrappedValue();
            typeParam.value = request.documentType;
            params.put('Input:TemplateName', typeParam);

            input.inputParams = params;
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'PromptBuilderPreview';
            input.isPreview = false;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(PROMPT_TEMPLATE, input);

            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                outcome.jsonText = response.generations[0].text;
                outcome.success = String.isNotBlank(outcome.jsonText);
            } else {
                outcome.success = false;
                outcome.jsonText = 'Prompt template returned no generations.';
            }
        } catch (Exception e) {
            outcome.success = false;
            outcome.jsonText = 'Prompt template error: ' + e.getMessage();
        }
        return outcome;
    }

    private static String buildAgentMessage(IntakeRequest request, Contract_Review__c review, ExtractionOutcome extraction) {
        return
            'Analyze this contract. ContentDocumentId: ' + request.contentDocumentId +
            '. Review record Id: ' + review.Id +
            '. Document type: ' + (request.documentType == null ? 'Unknown' : request.documentType) +
            '. Agency: ' + (request.agency == null ? 'Unknown' : request.agency) +
            '. Extraction source: ' + extraction.source +
            '. Extracted JSON: ' + (extraction.jsonText == null ? '' : extraction.jsonText.abbreviate(12000)) +
            '. Compare clauses to the playbook and taxonomy. Create findings. ' +
            'Do not say you cannot process the file.';
    }

    private static String appendNote(String existing, String line) {
        return (existing == null ? '' : existing + '\n') + line;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract_Review__c> getRecentReviews() {
        return [
            SELECT Id, Name, Document_Type__c, Agency__c, Status__c, Overall_Risk_Score__c, CreatedDate
            FROM Contract_Review__c
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }

    private class ExtractionOutcome {
        public Boolean success = false;
        public String source;
        public String jsonText;
    }
}
