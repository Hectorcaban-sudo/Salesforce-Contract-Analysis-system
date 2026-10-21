# Agentforce Actions Reference
## Contract Analysis Agent

Use these descriptions, loading messages, and input/output details when wiring actions in Agentforce Builder.

---

## 1. Run Contract Analysis
**Apex**: `ContractAnalysisActions.runAnalysis`

**Action Description**  
Analyzes a contract document, extracts key clauses, scores risk against playbook standards, and returns structured findings.

**Loading Text**  
Analyzing contract and scoring risk...

**Inputs**  
| Input | Description |
|-------|-------------|
| Contract Text or Document ID | The full contract text, a Salesforce File ID, or a ContentDocument ID to analyze. |
| Playbook ID (optional) | Identifier of the playbook or preferred-position record to use for comparison. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Overall Risk Score | Numeric risk score (0–100) for the entire contract. |
| Findings JSON | JSON array of findings with clause type, risk level, excerpt, and rationale. |
| Status Message | Human-readable summary of the analysis result or any issues. |

---

## 2. Score Clause Risk
**Apex**: `ScoreClauseRiskAction.scoreClauseRisk`

**Action Description**  
Scores the risk of a single clause excerpt based on language patterns and playbook standards.

**Loading Text**  
Scoring clause risk...

**Inputs**  
| Input | Description |
|-------|-------------|
| Clause Text | The exact text of the clause to evaluate. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Risk Level | Low, Medium, or High. |
| Score | Numeric risk score for the clause. |
| Rationale | Short explanation of why the risk level was assigned. |

---

## 3. Create Contract Review Record
**Apex**: `CreateContractReviewAction.createReview`

**Action Description**  
Creates a new Contract Review record to store analysis results and findings.

**Loading Text**  
Creating contract review record...

**Inputs**  
| Input | Description |
|-------|-------------|
| Overall Risk Score | Numeric risk score to store on the review record. |
| Findings JSON (optional) | JSON of findings to associate with the review. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Review Id | Salesforce ID of the newly created Contract_Review__c record. |

---

## 4. Capture Finding Override
**Apex**: `CaptureOverrideAction.captureOverride`

**Action Description**  
Records a lawyer’s decision to Accept or Override a specific finding and stores any note.

**Loading Text**  
Saving review decision...

**Inputs**  
| Input | Description |
|-------|-------------|
| Finding Id | Salesforce ID of the Contract_Finding__c record to update. |
| Status | Accepted or Overridden. |
| Override Note (optional) | Free-text note explaining the override or providing context. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Result Message | Confirmation that the finding was updated. |

---

## 5. Classify Contract Clause
**Prompt Template**: `Classify_Contract_Clause`

**Action Description**  
Classifies a contract clause excerpt into a standard type and assigns a preliminary risk level.

**Loading Text**  
Classifying clause...

**Inputs**  
| Input | Description |
|-------|-------------|
| Clause Text | The clause excerpt to classify. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Classification Result | JSON containing clauseType, riskLevel, and shortRationale. |

---

## 6. Generate Clause Risk Rationale
**Prompt Template**: `Generate_Clause_Risk_Rationale`

**Action Description**  
Generates a risk level, rationale, and recommended fallback language for a clause compared to playbook standards.

**Loading Text**  
Generating risk rationale...

**Inputs**  
| Input | Description |
|-------|-------------|
| Clause Type | The classified type of the clause (e.g., Liability Limitation). |
| Clause Text | The exact clause text. |
| Playbook Position (optional) | Preferred position or standard language from the playbook. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Risk Rationale | Concise risk assessment, rationale, and recommended action or fallback language. |

---

## 7. Complete Contract Review
**Flow**: `Complete_Contract_Review`

**Action Description**  
Marks a Contract Review record as complete after the lawyer finishes reviewing findings.

**Loading Text**  
Completing review...

**Inputs**  
| Input | Description |
|-------|-------------|
| Review Id | Salesforce ID of the Contract_Review__c to mark complete. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Status Message | Confirmation that the review was marked complete. |

---

## Usage Tips
- Paste the **Action Description** into the action configuration in Agentforce Builder.
- Use the **Loading Text** for the “Loading message” or progress indicator.
- Map inputs/outputs using the descriptions above so the agent understands when and how to call each action.
- Keep loading text short (under 60 characters preferred) so it displays cleanly in the chat UI.
