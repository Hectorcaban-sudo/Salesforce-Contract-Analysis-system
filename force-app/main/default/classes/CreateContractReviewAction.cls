public with sharing class CreateContractReviewAction {

    public class ReviewInput {
        @InvocableVariable(label='Overall Risk Score')
        public Integer overallRiskScore;

        @InvocableVariable(label='Findings JSON')
        public String findingsJson;
    }

    @InvocableMethod(label='Create Contract Review Record' description='Creates a Contract_Review__c from analysis results.')
    public static List<Id> createReview(List<ReviewInput> inputs) {
        List<Id> reviewIds = new List<Id>();
        for (ReviewInput input : inputs) {
            Contract_Review__c review = new Contract_Review__c(
                Name = 'Review ' + Datetime.now().format('yyyy-MM-dd HH:mm'),
                Overall_Risk_Score__c = input.overallRiskScore,
                Status__c = 'Ready for Review'
            );
            insert review;
            reviewIds.add(review.Id);
        }
        return reviewIds;
    }
}
