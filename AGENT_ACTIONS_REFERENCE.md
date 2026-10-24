## 1. Extract Contract with Document AI
**Apex**: `ExtractContractAction.extractContract`  
**Prompt Template**: `Extract_Contract_Document`

**Action Description**  
Extracts contract fields and clauses from an uploaded document by calling the `Extract_Contract_Document` prompt template with the ContentDocumentId. Handles non-standard formats, government agency variations, modifications (mods), and subcontract mods. Returns structured JSON and a confidence score.

**Loading Text**  
Extracting contract details...

**Inputs**  
| Input | Description |
|-------|-------------|
| Document ID | ContentDocumentId or Salesforce File ID of the contract to extract. |
| Extraction Template Name (optional) | Hint for document type or Contracts AI template (e.g. for mods or agency-specific formats). Passed to the prompt as TemplateName. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Extracted Fields JSON | JSON of extracted contract fields (parties, dates, governing law, contract number, etc.). |
| Extracted Clauses JSON | JSON array of extracted clauses with type, excerpt, and section path. |
| Document Type | Detected type: Base Contract, Modification, Subcontract Mod, Task Order, etc. |
| Confidence Score | Overall extraction confidence (0-100). Values below 70 should be flagged for human review. |
| Status Message | Human-readable result or any warnings. |

**Notes**  
- Requires the `Extract_Contract_Document` prompt template to be deployed and published.
- The Apex action passes the ContentDocument Id into the prompt so the model can read the uploaded file.
- For higher accuracy on government or agency-specific formats, create dedicated Contracts AI / Document AI extraction templates and pass the template name.
