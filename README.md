# Contract Analysis Agentforce Starter

This Salesforce DX project provides the foundation for a Contract Analysis AI system using Agentforce, Document AI, Intelligent Context, and Knowledge Harmonization.

## What's Included

- Custom objects: `Contract_Review__c` and `Contract_Finding__c`
- Apex invocable actions:
  - `runAnalysis` — full analysis stub
  - `scoreClauseRisk` — simple keyword-based risk scoring for a clause
  - `createReview` — creates a review record
- Prompt Templates:
  - `Classify_Contract_Clause`
  - `Generate_Clause_Risk_Rationale`
- Flow: `Complete_Contract_Review`
- LWC: `contractFindingsPanel` — now includes **Accept** and **Override** buttons that call the new `captureOverride` Apex method and refresh the list
- New field: `Contract_Finding__c.Override_Note__c` (free-text note captured on override)
- LWC now shows a textarea for the note and displays any existing note on the finding
- Sample agent script: `sample-agent-script.agent` (skeleton you can adapt for Agentforce DX / AiAuthoringBundle)

See the full README in the repo for deployment and Agentforce setup instructions.
