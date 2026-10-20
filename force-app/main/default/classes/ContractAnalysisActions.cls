public with sharing class ContractAnalysisActions {

    public class AnalysisRequest {
        @InvocableVariable(required=true label='Contract Text or Document ID')
        public String contractInput;

        @InvocableVariable(label='Playbook ID')
        public String playbookId;
    }

    public class AnalysisResult {
        @InvocableVariable(label='Overall Risk Score')
        public Integer overallRiskScore;

        @InvocableVariable(label='Findings JSON')
        public String findingsJson;

        @InvocableVariable(label='Status Message')
        public String message;
    }

    public class ClauseRequest {
        @InvocableVariable(required=true label='Clause Text')
        public String clauseText;
    }

    public class RiskResult {
        @InvocableVariable(label='Risk Level')
        public String riskLevel;

        @InvocableVariable(label='Score')
        public Integer score;

        @InvocableVariable(label='Rationale')
        public String rationale;
    }

    @InvocableMethod(label='Run Contract Analysis' description='Extracts clauses, scores risk, and generates findings for Agentforce.')
    public static List<AnalysisResult> runAnalysis(List<AnalysisRequest> requests) {
        List<AnalysisResult> results = new List<AnalysisResult>();
        for (AnalysisRequest req : requests) {
            AnalysisResult res = new AnalysisResult();
            res.overallRiskScore = 65;
            res.findingsJson = '[{"clauseType":"Liability Cap","riskLevel":"High","excerpt":"Sample liability language..."}]';
            res.message = 'Analysis complete (stub). Extend to call Document AI or your analysis engine.';
            results.add(res);
        }
        return results;
    }

    @InvocableMethod(label='Score Clause Risk' description='Scores risk for a single clause excerpt.')
    public static List<RiskResult> scoreClauseRisk(List<ClauseRequest> requests) {
        List<RiskResult> results = new List<RiskResult>();
        for (ClauseRequest req : requests) {
            RiskResult res = new RiskResult();
            String text = req.clauseText != null ? req.clauseText.toLowerCase() : '';
            if (text.contains('unlimited') || text.contains('uncapped') || text.contains('indemnify')) {
                res.riskLevel = 'High';
                res.score = 85;
                res.rationale = 'Contains high-risk language around liability or indemnification.';
            } else {
                res.riskLevel = 'Low';
                res.score = 25;
                res.rationale = 'Standard or low-risk clause language.';
            }
            results.add(res);
        }
        return results;
    }

    @InvocableMethod(label='Create Contract Review Record' description='Creates a Contract_Review__c from analysis results.')
    public static List<Id> createReview(List<AnalysisResult> analysisResults) {
        List<Id> reviewIds = new List<Id>();
        for (AnalysisResult ar : analysisResults) {
            Contract_Review__c review = new Contract_Review__c(
                Name = 'Review ' + Datetime.now().format('yyyy-MM-dd HH:mm'),
                Overall_Risk_Score__c = ar.overallRiskScore,
                Status__c = 'Ready for Review'
            );
            insert review;
            reviewIds.add(review.Id);
        }
        return reviewIds;
    }

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

    public class OverrideRequest {
        @InvocableVariable(required=true label='Finding Id')
        public Id findingId;

        @InvocableVariable(required=true label='Status (Accepted or Overridden)')
        public String status;

        @InvocableVariable(label='Override Note')
        public String note;
    }
}
