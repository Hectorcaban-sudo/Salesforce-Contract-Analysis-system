# Agentforce Agent Manual Setup Guide
## Contract Analysis Agent

This guide walks you through creating the **Contract Analysis Agent** manually in Agentforce Builder (or via Agentforce DX). It includes recommended topics (subagents), detailed instructions, action wiring, prompt usage, and expanded sample questions.

### Prerequisites
- Project deployed (see main README).
- Agentforce + Einstein Generative AI enabled.
- Document AI / Contracts AI and Intelligent Context configured (recommended).
- Custom objects, Apex, prompts, Flow, and LWC deployed.

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
**Description**: Load a new contract document, extract key fields and candidate clauses, and create a review record. Handles non-standard formats, government agency variations, modifications (mods), and subcontract mods.

**Instructions**:
```
You are responsible for the initial intake of a contract.
- Prefer Document AI or Contracts AI extraction when available.
- Determine the document type (base contract, modification/mod, subcontract mod, task order, etc.) and the agency or vehicle if identifiable.
- Select the most appropriate extraction template or playbook based on document type and agency.
- Identify parties, effective date, expiration/renewal, governing law, and major clause categories (Liability, Indemnification, Termination, Confidentiality, IP, etc.).
- Segment the document into logical sections while preserving hierarchy.
- Call the ExtractContractAction.extractContract Apex action to extract fields and clauses from the document.
- Call the createReview Apex action to start a Contract_Review__c record and store the overall risk placeholder.
- Summarize the high-level structure and extracted metadata.
- If the format is non-standard, agency-specific, or extraction confidence is low, clearly flag the findings for human review and include the exact text spans.
- Ask the user whether they want to proceed to clause-level analysis or focus on specific sections.
Always ground statements in the actual document content. If extraction confidence is low, flag it for human review.
```

**Actions**:
- Apex: `ExtractContractAction.extractContract` (Document AI / Contracts AI extraction)
- Apex: `CreateContractReviewAction.createReview`

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
- Use the Generate_Clause_Risk_Rationale prompt for detailed rationale and recommended language.
- Call scoreClauseRisk or runAnalysis Apex actions as needed for batch processing.
- Perform cross-clause reasoning where relevant (e.g., how an indemnification interacts with a liability cap or limitation of remedies).
- Detect deviations, missing protections, and unfavorable positions.
- Flag High-risk items clearly for mandatory human review.
- Suggest specific fallback or preferred language when there is a material deviation.
Ground every risk assessment in the clause text and playbook (if provided). Use confidence/abstention: if evidence is weak, escalate rather than assert.
```

**Actions**:
- Prompt Template: `Generate_Clause_Risk_Rationale`
- Apex: `ContractAnalysisActions.runAnalysis`
- Apex: `ScoreClauseRiskAction.scoreClauseRisk`

#### Topic 4: Citation & Authority Grounding
**Description**: Resolve and validate legal citations or supporting authorities.

**Instructions**:
```
When a clause, finding, or user question references external authority (statute, case law, regulation, industry standard, or internal policy):
- Retrieve supporting context via Intelligent Context / Data Cloud search indexes.
- Validate whether the citation actually supports the claim made in the contract or finding.
- Show the retrieved supporting text or highlight the relevant passage.
- If the authority is ambiguous, outdated, or does not clearly support the position, flag it for lawyer review rather than asserting correctness.
Always prefer grounded retrieval over general knowledge. Note the source of any authority.
```

**Actions**:
- Intelligent Context / Data Cloud retrieval actions (configure as needed)

#### Topic 5: Findings & Review
**Description**: Present structured findings and capture lawyer feedback for the feedback loop.

**Instructions**:
```
Generate or update the Contract Review and Findings for lawyer review.
- Summarize overall risk score and list key findings with clause type, risk level, and excerpt.
- Direct the user to the Contract Findings Panel LWC on the Contract_Review__c record for Accept / Override actions.
- When the user provides feedback (accept, override, or a note), call the captureOverride Apex action and store the note.
- Offer the option to mark the review complete via the Complete_Contract_Review Flow once the lawyer is satisfied.
- Maintain an audit-friendly tone: every material statement should be traceable to a span or retrieval.
Present findings clearly. Escalate low-confidence or High-risk items explicitly.
```

**Actions**:
- Apex: `CaptureOverrideAction.captureOverride`
- Flow: `Complete_Contract_Review`
- (Optional) Apex methods that create/update findings

---

### 2.1 Sub-agent Scopes and Classifications

| Sub-agent / Topic | Primary Scope | Classification | Key Output |
|-------------------|---------------|----------------|------------|
| **Contract Intake & Structure** | Load & structure document (including non-standard, gov, mods) | Orchestration / entry point | `Contract_Review__c` + structured text |
| **Clause Extraction & Classification** | Identify & label clauses | Extraction + classification | Classified clause spans with exact excerpts |
| **Playbook & Risk Analysis** | Compare to standards & score risk | Reasoning / risk assessment | Risk levels, rationales, fallback suggestions |
| **Citation & Authority Grounding** | Resolve and validate citations | Grounding / retrieval | Citation status and supporting passages |
| **Findings & Review** | Present results and capture feedback | Human-in-the-loop / presentation | Accepted or Overridden findings with notes |

**Detailed scopes**:

- **Contract Intake & Structure**: Accept a contract (PDF, DOCX, or text), detect document type (base, mod, subcontract mod, etc.) and agency/vehicle, recover sections/definitions/schedules, create the review record, and hand off structured content. Handles variable government formats. Classification: Document processing / orchestration.
- **Clause Extraction & Classification**: Segment into clause-level spans, classify against the taxonomy (Liability Limitation, Indemnification, Termination, etc.), and preserve section paths. Classification: Extraction + classification.
- **Playbook & Risk Analysis**: Retrieve preferred positions (agency- or type-specific when available), detect deviations and missing clauses, assign risk levels, and generate rationales or fallback language. Classification: Reasoning / risk assessment.
- **Citation & Authority Grounding**: Parse citations, retrieve supporting authorities, and confirm they support the clause. Classification: Grounding / retrieval.
- **Findings & Review**: Write findings to `Contract_Finding__c`, surface them in the LWC panel, capture Accept/Override + notes, and allow marking complete. Classification: Presentation / human-in-the-loop.

These focused scopes keep routing reliable and ensure the lawyer remains the final decision maker.

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

Example for captureOverride:
- Action name: Capture Finding Override
- When to use: "When the lawyer accepts or overrides a specific finding and provides a note."

---

### 6. Testing & Iteration

1. Deploy the agent.
2. Test with the sample questions above.
3. Review the Contract Findings Panel LWC on a Contract_Review__c record.
4. Capture overrides and verify they store the note and status.
5. Refine topic instructions based on lawyer feedback.

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
- Use Intelligent Context + Knowledge Harmonization for the best citation highlighting experience.
- The Apex methods are stubs — extend them to call real Document AI, external services, or Data Cloud retrievers as needed.
- For government and multi-agency work, create multiple Document AI extraction templates (base contracts, mods, subcontract mods, agency-specific) and instruct the agent to select the appropriate one.

This setup gives you a complete, lawyer-in-the-loop Contract Analysis Agent grounded in Salesforce.
