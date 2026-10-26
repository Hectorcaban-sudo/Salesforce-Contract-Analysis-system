/**
 * Gov High intake path.
 * DML and callouts are in separate transactions so Agentforce can be invoked
 * and failed reviews can be reprocessed.
 */
public with sharing class ContractIntakeController {

    private static final String AGENT_API_NAME = 'Contract_Analysis_Agent';
    private static final String PROMPT_TEMPLATE = 'Extract_Contract_Document';
    private static final String DOCUMENT_AI_SCHEMA = 'Flexible_Contract_Schema';

    public class IntakeResult {
        @AuraEnabled public Id reviewId;
        @AuraEnabled public String agentResponse;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String extractionSource;
    }

    @AuraEnabled
    public static Id getOrCreateDraft() {
        List<Contract_Review__c> existing = [
            SELECT Id
            FROM Contract_Review__c
            WHERE OwnerId = :UserInfo.getUserId()
              AND Status__c = 'Draft'
              AND ContentDocumentId__c = null
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }

        Contract_Review__c review = new Contract_Review__c(
            Name = 'Draft ' + Datetime.now().format('yyyy-MM-dd HH:mm'),
            Status__c = 'Draft'
        );
        insert review;
        return review.Id;
    }

    @AuraEnabled
    public static IntakeResult startAnalysis(
        String contentDocumentId,
        String contractName,
        String documentType,
        String agency,
        String notes,
        Id draftReviewId
    ) {
        if (String.isBlank(contentDocumentId)) {
            throw new AuraHandledException('Upload a contract file before running analysis.');
        }

        Contract_Review__c review = upsertReview(contentDocumentId, contractName, documentType, agency, notes, draftReviewId);
        linkFile(contentDocumentId, review.Id);

        IntakeResult result = new IntakeResult();
        result.reviewId = review.Id;
        return result;
    }

    @AuraEnabled
    public static IntakeResult runAnalysis(Id reviewId) {
        Contract_Review__c review = [
            SELECT Id, Name, ContentDocumentId__c, Document_Type__c, Agency__c, Notes__c, Status__c
            FROM Contract_Review__c
            WHERE Id = :reviewId
            LIMIT 1
        ];

        if (String.isBlank(review.ContentDocumentId__c)) {
            throw new AuraHandledException('This review has no attached file.');
        }

        IntakeResult result = new IntakeResult();
        result.reviewId = review.Id;

        ExtractionOutcome extraction = extractWithDocumentAi(review.ContentDocumentId__c, review.Document_Type__c);
        if (!extraction.success) {
            extraction = extractWithPromptTemplate(review.ContentDocumentId__c, review.Document_Type__c);
        }
        result.extractionSource = extraction.source;

        String userMessage = buildAgentMessage(review, extraction);
        String agentError;

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
            } else {
                agentError = results.isEmpty()
                    ? 'No response from agent'
                    : String.valueOf(results[0].getErrors());
                result.errorMessage = agentError;
            }
        } catch (Exception e) {
            agentError = e.getMessage();
            result.errorMessage = agentError;
        }

        review.Extraction_Source__c = extraction.source;
        review.Extraction_Json__c = extraction.jsonText;
        review.Agent_Response__c = result.agentResponse;
        if (agentError == null) {
            review.Status__c = 'Ready for Review';
            persistFindings(review.Id, result.agentResponse);
        } else {
            review.Status__c = 'Error';
            review.Notes__c = appendNote(review.Notes__c, 'Agent error: ' + agentError);
        }
        update review;

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract_Finding__c> getFindings(Id reviewId) {
        return [
            SELECT Id, Clause_Type__c, Risk_Level__c, Excerpt__c, Review_Status__c, Override_Note__c
            FROM Contract_Finding__c
            WHERE Contract_Review__c = :reviewId
            ORDER BY CreatedDate ASC
        ];
    }

    private static void persistFindings(Id reviewId, String agentResponse) {
        if (String.isBlank(agentResponse)) {
            return;
        }

        delete [SELECT Id FROM Contract_Finding__c WHERE Contract_Review__c = :reviewId];

        List<Contract_Finding__c> toInsert = new List<Contract_Finding__c>();
        Pattern block = Pattern.compile('(?i)Clause Type:\s*(.+?)\s*Risk Level:\s*(.+?)\s*Excerpt:\s*"?(.+?)"?(?=\s*Clause Type:|\s*Overall Risk Score:|$)');
        Matcher m = block.matcher(agentResponse);
        while (m.find()) {
            String clauseType = m.group(1).trim();
            String risk = normalizeRisk(m.group(2));
            String excerpt = m.group(3).trim();
            toInsert.add(new Contract_Finding__c(
                Contract_Review__c = reviewId,
                Clause_Type__c = clauseType.abbreviate(255),
                Risk_Level__c = risk,
                Excerpt__c = excerpt.abbreviate(32000),
                Review_Status__c = 'Not Reviewed'
            ));
        }

        if (toInsert.isEmpty()) {
            toInsert.add(new Contract_Finding__c(
                Contract_Review__c = reviewId,
                Clause_Type__c = 'Agent Response',
                Risk_Level__c = 'Medium',
                Excerpt__c = agentResponse.abbreviate(32000),
                Review_Status__c = 'Not Reviewed'
            ));
        }
        insert toInsert;

        Matcher scoreMatch = Pattern.compile('(?i)Overall Risk Score:\s*(\d+)').matcher(agentResponse);
        if (scoreMatch.find()) {
            update new Contract_Review__c(
                Id = reviewId,
                Overall_Risk_Score__c = Decimal.valueOf(scoreMatch.group(1))
            );
        }
    }

    private static String normalizeRisk(String raw) {
        if (raw == null) return 'Medium';
        String v = raw.toLowerCase();
        if (v.contains('high')) return 'High';
        if (v.contains('low')) return 'Low';
        return 'Medium';
    }

    private static Contract_Review__c upsertReview(
        String contentDocumentId,
        String contractName,
        String documentType,
        String agency,
        String notes,
        Id draftReviewId
    ) {
        Contract_Review__c review;
        if (draftReviewId != null) {
            review = [
                SELECT Id, Name, Status__c, Notes__c
                FROM Contract_Review__c
                WHERE Id = :draftReviewId
                LIMIT 1
            ];
            review.Name = String.isNotBlank(contractName)
                ? contractName
                : review.Name;
        } else {
            review = new Contract_Review__c(
                Name = String.isNotBlank(contractName)
                    ? contractName
                    : 'Review ' + Datetime.now().format('yyyy-MM-dd HH:mm')
            );
        }

        review.Status__c = 'In Progress';
        review.Document_Type__c = documentType;
        review.Agency__c = agency;
        review.Notes__c = notes;
        review.ContentDocumentId__c = contentDocumentId;

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

    private static ExtractionOutcome extractWithDocumentAi(String contentDocumentId, String documentType) {
        ExtractionOutcome outcome = new ExtractionOutcome();
        outcome.source = 'Document AI';
        outcome.success = false;
        outcome.jsonText = 'Document AI schema "' + DOCUMENT_AI_SCHEMA + '" not yet wired in Apex.';
        return outcome;
    }

    private static ExtractionOutcome extractWithPromptTemplate(String contentDocumentId, String documentType) {
        ExtractionOutcome outcome = new ExtractionOutcome();
        outcome.source = 'Prompt Template';
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();

            Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue fileParam = new ConnectApi.WrappedValue();
            fileParam.value = new Map<String, String>{
                'id' => contentDocumentId,
                'type' => 'ContentDocument'
            };
            params.put('Input:InputFile', fileParam);

            if (String.isNotBlank(documentType)) {
                ConnectApi.WrappedValue typeParam = new ConnectApi.WrappedValue();
                typeParam.value = documentType;
                params.put('Input:TemplateName', typeParam);
            }

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

    private static String buildAgentMessage(Contract_Review__c review, ExtractionOutcome extraction) {
        return
            'Analyze this contract. ContentDocumentId: ' + review.ContentDocumentId__c +
            '. Review record Id: ' + review.Id +
            '. Document type: ' + (review.Document_Type__c == null ? 'Unknown' : review.Document_Type__c) +
            '. Agency: ' + (review.Agency__c == null ? 'Unknown' : review.Agency__c) +
            '. Extraction source: ' + extraction.source +
            '. Extracted JSON: ' + (extraction.jsonText == null ? '' : extraction.jsonText.abbreviate(12000)) +
            '. Compare clauses to the playbook and taxonomy. ' +
            'Return findings in this exact format for each clause:\n' +
            'Clause Type: <type>\nRisk Level: High|Medium|Low\nExcerpt: "<text>"\n' +
            'Then end with Overall Risk Score: <0-100>. ' +
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
            WHERE Status__c != 'Draft'
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
