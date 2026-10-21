public with sharing class ScoreClauseRiskAction {

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
}
