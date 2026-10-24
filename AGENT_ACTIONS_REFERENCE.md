## 1. Extract Contract Document
**Prompt Template**: `Extract_Contract_Document`

**Action Description**  
Extracts contract fields, document type, and key clauses from an uploaded file. Handles non-standard formats, government agency variations, modifications (mods), and subcontract mods. Returns structured JSON and a confidence score.

**Loading Text**  
Extracting contract details...

**Inputs**  
| Input | Description |
|-------|-------------|
| InputFile | ContentDocumentId of the uploaded contract. |
| TemplateName (optional) | Hint for document type or extraction template (e.g. base, mod, subcontract mod, agency). |

**Outputs**  
| Output | Description |
|--------|-------------|
| Extraction Result | JSON with documentType, parties, dates, governingLaw, clauses, and confidenceScore. |

**Notes**  
- Primary action for the Contract Intake & Structure topic.
- Wire it as a Prompt Template action and map the uploaded file to InputFile.
- Flag results with confidence below 70 for human review.
- Apex `ExtractContractAction` remains an optional fallback only.
