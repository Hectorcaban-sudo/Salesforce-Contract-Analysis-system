# Agentforce Agent Manual Setup Guide
## Contract Analysis Agent

This guide walks you through creating the **Contract Analysis Agent** manually in Agentforce Builder (or via Agentforce DX). It includes recommended topics (subagents), detailed instructions, action wiring, prompt usage, and expanded sample questions.

### Prerequisites
- Project deployed (see main README).
- Agentforce + Einstein Generative AI enabled.
- Document AI / Contracts AI and Intelligent Context configured (recommended).
- Custom objects, Apex, prompts, Flow, and LWC deployed.
- Prompt template `Extract_Contract_Document` deployed (primary for Contract Intake).
- Prompt template `Compare_Clause_to_Playbook` deployed (embeds playbook + taxonomy).

---

### 1. Create the Agent

In **Agentforce Builder** (Setup → Agentforce → Agents):

- **Name**: Contract Analysis Agent
- **Type**: Employee Agent (internal legal team)
- **Role**: Analyze commercial contracts for material clauses, risk scoring, playbook compliance, and grounded citations. Present findings for lawyer review and capture feedback.
- **Description**: Assists the legal team by extracting clauses, scoring risk against playbooks, validating citations, and generating structured findings with a human-in-the-loop review interface.

---

### 2. Topics / Subagents

Create the following topics. For each, add clear routing instructions so the Agent Router selects the right one.

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

#### Topic 2: Clause Extraction & Classification
**Description**: Extract specific clauses and classify them by type with exact spans.

**Instructions**:
```
Extract and classify key commercial clauses against the standard taxonomy (Liability Limitation, Indemnification, Termination, Governing Law, Confidentiality, Assignment, Force Majeure, Audit Rights, etc.).
- Use the Classify_Contract_Clause prompt template for classification and preliminary risk.
- Prefer exact text spans and preserve section paths or clause numbers.
- Detect missing standard clauses when the contract type is known.
- Return structured results suitable for Contract_Finding__c records (clause type, excerpt, risk level).
Be conservative on classification. Cite the source text for every finding. If a clause is ambiguous, note it rather than force a category.
```

**Actions**:
- Prompt Template: `Classify_Contract_Clause`
- Apex: `ScoreClauseRiskAction.scoreClauseRisk` (optional preliminary scoring)

#### Topic 3: Playbook & Risk Analysis
**Description**: Compare clauses to playbook standards, score risk, and suggest fallbacks.

**Instructions**:
```
Score risk for extracted clauses against the organization's playbook or standard positions.
- Call the Compare_Clause_to_Playbook prompt template. Pass the clause text and (if known) the clause type.
- If a Data Library / Retriever is available, optionally retrieve additional context and pass it as RetrievedContext.
- Use the Generate_Clause_Risk_Rationale prompt only if you need a shorter rationale after the main comparison.
- Call scoreClauseRisk or runAnalysis Apex actions as needed for batch processing.
- Perform cross-clause reasoning where relevant (e.g., how an indemnification interacts with a liability cap or limitation of remedies).
- Detect deviations, missing protections, and unfavorable positions.
- Flag High-risk items clearly for mandatory human review.
- Suggest specific fallback or preferred language when there is a material deviation.
Ground every risk assessment in the clause text and the playbook. Use confidence/abstention: if evidence is weak, escalate rather than assert.
```

**Actions**:
- Prompt Template: `Compare_Clause_to_Playbook` (primary — embeds playbook + taxonomy)
- Prompt Template: `Generate_Clause_Risk_Rationale` (optional follow-up)
- Apex: `ContractAnalysisActions.runAnalysis`
- Apex: `ScoreClauseRiskAction.scoreClauseRisk`
- (Optional) Data Library / Retriever if available

#### Topic 4: Citation & Authority Grounding
**Description**: Resolve and validate legal citations or supporting authorities.

**Instructions**:
```
When a clause, finding, or user question references external authority (statute, case law, regulation, industry standard, internal policy, or playbook position):
- Prefer the Compare_Clause_to_Playbook prompt template when the question is about playbook alignment.
- If a Data Library / Retriever is available, use it to retrieve supporting passages and pass them as RetrievedContext.
- Validate whether the retrieved or embedded content supports the claim.
- Show the supporting text or highlight the relevant passage and note the source.
- If the authority is ambiguous, outdated, or does not clearly support the position, flag it for lawyer review rather than asserting correctness.
Always prefer grounded content over general knowledge.
```

**Actions**:
- Prompt Template: `Compare_Clause_to_Playbook`
- (Optional) Data Library / Retriever if available

#### Topic 5: Findings & Review
**Description**: Present structured findings in the agent chat and capture lawyer feedback for the feedback loop.

**Instructions**:
```
Generate or update the Contract Review and Findings for lawyer review.
- Call the PresentFindingsInUIAction.presentFindings Apex action to surface findings and a record link inside the agent chat.
- Summarize overall risk score and list key findings with clause type, risk level, and excerpt.
- Provide the record link so the lawyer can open the full Contract Review record and use the LWC for Accept / Override if preferred.
- When the user provides feedback (accept, override, or a note), call the captureOverride Apex action and store the note.
- Offer the option to mark the review complete via the Complete_Contract_Review Flow once the lawyer is satisfied.
- Maintain an audit-friendly tone: every material statement should be traceable to a span or retrieval.
Present findings clearly in the chat. Escalate low-confidence or High-risk items explicitly.
```

**Actions**:
- Apex: `PresentFindingsInUIAction.presentFindings` (PresentInUI — findings card + record link)
- Apex: `CaptureOverrideAction.captureOverride`
- Flow: `Complete_Contract_Review`

---

### 2.1 Sub-agent Scopes and Classifications

| Sub-agent / Topic | Primary Scope | Classification | Key Output |
|-------------------|---------------|----------------|------------|
| **Contract Intake & Structure** | Load & structure document (including non-standard, gov, mods) | Orchestration / entry point | `Contract_Review__c` + structured text |
| **Clause Extraction & Classification** | Identify & label clauses | Extraction + classification | Classified clause spans with exact excerpts |
| **Playbook & Risk Analysis** | Compare to standards & score risk | Reasoning / risk assessment | Risk levels, rationales, fallback suggestions |
| **Citation & Authority Grounding** | Resolve and validate citations | Grounding / retrieval | Citation status and supporting passages |
| **Findings & Review** | Present results in chat and capture feedback | Human-in-the-loop / presentation | Findings card + record link + Accept/Override |

**Detailed scopes**:

- **Contract Intake & Structure**: Accept a contract (PDF, DOCX, or text), detect document type (base, mod, subcontract mod, etc.) and agency/vehicle, recover sections/definitions/schedules, create the review record, and hand off structured content. Handles variable government formats. When a file is uploaded, you MUST call Extract_Contract_Document before any other response. Classification: Document processing / orchestration.
- **Clause Extraction & Classification**: Segment into clause-level spans, classify against the taxonomy, and preserve section paths. Classification: Extraction + classification.
- **Playbook & Risk Analysis**: Use the Compare_Clause_to_Playbook prompt (which embeds the playbook and taxonomy) to detect deviations, assign risk, and suggest fallback language. Classification: Reasoning / risk assessment.
- **Citation & Authority Grounding**: Use the same prompt or optional Retriever to validate claims against playbook and other sources. Classification: Grounding / retrieval.
- **Findings & Review**: Present findings in the agent chat via PresentInUI, provide a record link, capture Accept/Override + notes, and allow marking complete. Classification: Presentation / human-in-the-loop.

These focused scopes keep routing reliable and ensure the lawyer remains the final decision maker.

---

### 2.2 Playbook & Taxonomy via Prompt Template

The `Compare_Clause_to_Playbook` prompt template embeds the standard commercial playbook and taxonomy. Use it as the primary action on Topics 3 and 4.

1. Deploy the project so the prompt template is available.
2. In Agentforce Builder, on **Topic 3** and **Topic 4**:
   - Add Action → Prompt Template → `Compare_Clause_to_Playbook`.
   - Map `ClauseText` (required) and optionally `ClauseType` and `RetrievedContext`.
3. A Data Library / Retriever is optional. If you later create one, pass its results into the `RetrievedContext` input.

Updating the playbook or taxonomy requires editing and redeploying the prompt template (or switching to a Retriever later).

---

### 3. Sample Questions / Test Utterances

Use these to test routing and behavior. Questions are grouped by expected primary topic and by contract type.

#### By Contract Type
- **NDA**: "Analyze this NDA and extract the confidentiality obligations and any exceptions."
- **MSA**: "Load this MSA, identify the liability cap, and check it against our playbook."
- **SaaS Agreement**: "Extract the data protection and security clauses from this SaaS agreement and score their risk."
- **Base Contract**: "Analyze this base contract and summarize the key commercial terms."
- **Modification (Mod)**: "This is a GSA schedule mod — extract the key changes and flag any high-risk updates."
- **Subcontract Mod**: "Analyze this subcontract modification from a DoD agency and compare the indemnification to our standards."
- **Task Order**: "Review this task order and extract the period of performance and any special clauses."
- **Government Contract**: "Analyze this government contract and identify any FAR or agency-specific requirements."

#### Contract Intake & Structure
- "Analyze this NDA and extract the key clauses"
- "What parties are involved and what is the governing law?"
- "Load this MSA and create a new review record"
- "Summarize the structure of this agreement and list the major sections"
- "Who are the parties and what is the effective date?"
- "This is a GSA schedule mod — extract the key changes"
- "Analyze this subcontract modification from a DoD agency"
- "Is this a base contract or a modification?"
- "Analyze this contract" (with file attached)

#### Clause Extraction & Classification
- "Classify the termination clause and suggest fallback language"
- "Are there any missing standard clauses for a SaaS agreement?"
- "Extract the confidentiality obligations and score their risk"
- "Find all indemnification clauses and show me the exact text"
- "Identify the limitation of liability and any related carve-outs"
- "What data protection or security commitments are in this contract?"

#### Playbook & Risk Analysis
- "What's the liability cap in this agreement and is it high risk?"
- "Does the governing law clause match our playbook?"
- "How does the indemnification interact with the liability limitation?"
- "Flag any unlimited liability or uncapped indemnity language"
- "Compare this termination for convenience language to our preferred position"
- "Is the confidentiality survival period acceptable under our standards?"
- "Score the risk of the assignment clause and recommend fallback language"

#### Citation & Authority Grounding
- "Validate the citation to Section 12 of the UCC"
- "Does the reference to GDPR Article 28 actually support the data processing terms?"
- "Check whether the cited case supports the indemnification position"
- "Show me the supporting text for the governing law reference"

#### Findings & Review
- "Show me the findings and let me override the high-risk items"
- "Mark this review as complete"
- "Accept the termination finding and override the liability one with a note that we negotiated a $1M cap"
- "List all high-risk findings and their excerpts"
- "I want to add a note to the indemnification finding and mark it overridden"
- "What is the overall risk score and which findings are still pending?"

#### Mixed / Multi-step
- "Analyze this contract, classify the key clauses, and flag anything that deviates from our playbook"
- "Extract the liability and indemnification clauses, score them, and show me the findings"

---

### 4. Prompt Template Usage

The deployed prompt templates can be added as actions:

- **Extract_Contract_Document** (primary for Contract Intake)  
  Inputs: InputFile (ContentDocumentId), TemplateName (optional)  
  Output: structured JSON of fields, clauses, document type, and confidence

- **Compare_Clause_to_Playbook** (primary for playbook/taxonomy)  
  Inputs: `ClauseText` (required), `ClauseType` (optional), `RetrievedContext` (optional)  
  Output: Clause type, risk level, rationale, and recommended language

- **Classify_Contract_Clause**  
  Inputs: `ClauseText`  
  Output: JSON with clauseType, riskLevel, shortRationale

- **Generate_Clause_Risk_Rationale**  
  Inputs: `ClauseType`, `ClauseText`, `PlaybookPosition` (optional)  
  Output: Risk level + rationale + recommended action

Wire them under the appropriate topics and reference them in the topic instructions.

---

### 5. Wiring Actions

1. In each topic, click **Add Action**.
2. Choose Apex, Flow, or Prompt Template.
3. Map inputs/outputs.
4. Add the action name and brief instructions so the LLM knows when to call it.

Example for Extract Contract Document:
- Action name: Extract Contract Document
- Type: Prompt Template → `Extract_Contract_Document`
- When to use: "ALWAYS call this action when the user uploads any file or attaches a contract, or when they say analyze, extract, or review a document. Pass the uploaded file’s ContentDocumentId to InputFile. Do not answer without calling this action first."

Example for Compare_Clause_to_Playbook:
- Action name: Compare Clause to Playbook
- When to use: "When scoring risk or comparing a clause to the standard playbook and taxonomy."

Example for PresentFindingsInUI:
- Action name: Present Findings in UI
- When to use: "When findings are ready and the lawyer should review them in the chat or via a record link."

Example for captureOverride:
- Action name: Capture Finding Override
- When to use: "When the lawyer accepts or overrides a specific finding and provides a note."

---

### 6. Testing & Iteration

1. Deploy the agent and the prompt templates.
2. On Contract Intake & Structure, confirm Extract_Contract_Document is listed under This Subagent’s Actions.
3. Use the mandatory CRITICAL RULE instructions and the strengthened When to use text.
4. Upload a PDF and say "Analyze this contract." Confirm the event log shows an action invocation for Extract_Contract_Document (not only InstructionAdherence LOW).
5. Test with the sample questions above.
6. Confirm Compare_Clause_to_Playbook returns risk level, rationale, and fallback language.
7. Verify the PresentInUI payload and record link appear in the chat.
8. Review the Contract Review Workspace LWC on a Contract_Review__c record.
9. Capture overrides and verify they store the note and status.
10. Refine topic instructions based on lawyer feedback.

---

### 7. Agentforce DX Alternative

Instead of pure UI creation, you can:

```bash
sf agent generate agent-spec --name ContractAnalysisAgent --type Employee \
  --role "Analyze commercial contracts for risk, clause compliance, and playbook alignment" \
  --company-description "Legal team contract review system"
```

Then edit the generated `.agent` file using the topic instructions and action mappings from this guide (see also `sample-agent-spec.yaml`), and publish:

```bash
sf agent publish authoring-bundle --api-name ContractAnalysisAgent
```

---

### Notes
- Start with the five topics above. You can merge or split later.
- Always keep a human review gate for High-risk findings.
- Use the `Extract_Contract_Document` prompt template as the primary action on Contract Intake. The agent must call it when a file is uploaded. The Apex `ExtractContractAction` is an optional fallback only.
- Use the `Compare_Clause_to_Playbook` prompt template as the primary way to apply the playbook and taxonomy.
- For government and multi-agency work, pass a TemplateName hint or create dedicated extraction templates and select the appropriate one.
- PresentFindingsInUIAction returns a UI payload and record link; the Agentforce runtime determines the exact visual treatment of the card.

This setup gives you a complete, lawyer-in-the-loop Contract Analysis Agent grounded in Salesforce.
