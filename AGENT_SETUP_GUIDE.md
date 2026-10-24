#### Topic 1: Contract Intake & Structure
**Description**: Load a new contract document, extract key fields and candidate clauses, and create a review record. Handles uploaded files, non-standard formats, government agency variations, modifications (mods), and subcontract mods.

**Classification Description**:
```
Handles uploaded contracts and file analysis. Must call Extract_Contract_Document when a file is present.
```

**Instructions**:
```
CRITICAL RULE:
If a file is uploaded or the user asks to analyze a contract:
1. You MUST call Extract_Contract_Document before any other response.
2. Pass the uploaded file ContentDocumentId as InputFile.
3. Do not reply that you cannot process the file.
4. Only after the action returns, summarize the results.

Never skip the action call when a file is present.

Then:
- Determine the document type (base contract, modification/mod, subcontract mod, task order, etc.) and the agency or vehicle if identifiable.
- Optionally pass a TemplateName hint (base, mod, subcontract mod, agency).
- Identify parties, effective date, expiration/renewal, governing law, and major clause categories.
- Call the createReview Apex action to start a Contract_Review__c record.
- Summarize the high-level structure and extracted metadata.
- If the format is non-standard, agency-specific, or extraction confidence is low, flag the findings for human review and include the exact text spans.
- Ask the user whether they want to proceed to clause-level analysis or focus on specific sections.
Always ground statements in the actual document content. If extraction confidence is low, flag it for human review.
```

**Actions**:
- Prompt Template: `Extract_Contract_Document` (primary for intake)
  - When to use: "ALWAYS call this action when the user uploads any file or attaches a contract, or when they say analyze, extract, or review a document. Pass the uploaded file’s ContentDocumentId to InputFile. Do not answer without calling this action first."
  - Inputs: InputFile (ContentDocumentId), TemplateName (optional)
- Apex: `CreateContractReviewAction.createReview`
- (Optional fallback) Apex: `ExtractContractAction.extractContract`
