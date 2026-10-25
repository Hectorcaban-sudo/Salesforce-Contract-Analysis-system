/**
 * Gov High intake path.
 * Creates a Contract Review, links the uploaded file, and invokes the active
 * Agentforce agent headlessly via generateAiAgentResponse.
 * Does not require Agent Script or in-chat file upload.
 */
public with sharing class ContractIntakeController {

    private static final String AGENT_API_NAME = 'Contract_Analysis_Agent';

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

        List<ContentDocumentLink> existing = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :request.contentDocumentId
              AND LinkedEntityId = :review.Id
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            insert new ContentDocumentLink(
                ContentDocumentId = request.contentDocumentId,
                LinkedEntityId = review.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
        }

        IntakeResult result = new IntakeResult();
        result.reviewId = review.Id;

        String userMessage =
            'Analyze this contract. ContentDocumentId: ' + request.contentDocumentId +
            '. Review record Id: ' + review.Id +
            '. Document type: ' + (request.documentType == null ? 'Unknown' : request.documentType) +
            '. Agency: ' + (request.agency == null ? 'Unknown' : request.agency) +
            '. Extract parties, governing law, key clauses, and risk findings. ' +
            'Do not say you cannot process the file. Use the ContentDocumentId.';

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
                review.Notes__c = (review.Notes__c == null ? '' : review.Notes__c + '\n') + 'Agent error: ' + err;
                update review;
            }
        } catch (Exception e) {
            result.errorMessage = e.getMessage();
            review.Status__c = 'Error';
            review.Notes__c = (review.Notes__c == null ? '' : review.Notes__c + '\n') + 'Agent error: ' + e.getMessage();
            update review;
        }

        return result;
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
}
