# Agent Script starter notes
# After you generate the authoring bundle, open the .agent file and paste these
# instructions and action mappings into the Contract Intake subagent.

## Subagent: Contract Intake and Structure

### Classification description
Handles uploaded contracts and file analysis. Must call Extract_Contract_Document when a file is present.

### Instructions
CRITICAL RULE:
If a file is uploaded or the user asks to analyze a contract:
1. You MUST call Extract_Contract_Document before any other response.
2. Pass the uploaded file ContentDocumentId as InputFile.
3. Do not reply that you cannot process the file.
4. Only after the action returns, summarize the results.

Never skip the action call when a file is present.

Then:
- Determine the document type (base, mod, subcontract mod, task order) and the agency or vehicle.
- Optionally pass a TemplateName hint.
- Identify parties, effective date, expiration/renewal, governing law, and major clause categories.
- Call CreateContractReviewAction.createReview to start a Contract_Review__c record.
- Summarize the structure and extracted metadata.
- If confidence is low or the format is non-standard, flag for human review.

### Actions to wire
- Prompt Template: Extract_Contract_Document
  - When to use: ALWAYS call this action when the user uploads any file or attaches a contract, or when they say analyze, extract, or review a document. Pass the uploaded file ContentDocumentId to InputFile. Do not answer without calling this action first.
  - Inputs: InputFile (ContentDocumentId), TemplateName (optional)
- Apex: CreateContractReviewAction.createReview
- Optional fallback: Apex ExtractContractAction.extractContract

## Other subagents
- Clause Extraction and Classification → Prompt: Classify_Contract_Clause
- Playbook and Risk Analysis → Prompt: Compare_Clause_to_Playbook
- Citation and Authority Grounding → Prompt: Compare_Clause_to_Playbook (or Retriever)
- Findings and Review → Apex: PresentFindingsInUIAction.presentFindings, CaptureOverrideAction.captureOverride, Flow: Complete_Contract_Review

## Commands
```bash
# 1. Generate the authoring bundle from this spec
sf agent generate authoring-bundle --spec specs/ContractAnalysisAgentSpec.yaml --name "Contract Analysis Agent"

# 2. Edit the generated .agent file with the instructions above

# 3. Publish
sf agent publish authoring-bundle --api-name ContractAnalysisAgent
```
