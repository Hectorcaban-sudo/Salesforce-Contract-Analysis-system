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
}
