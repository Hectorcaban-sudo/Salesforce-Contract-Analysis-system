# Agentforce Agent Manual Setup Guide
## Contract Analysis Agent

This guide walks you through creating the **Contract Analysis Agent** manually in Agentforce Builder (or via Agentforce DX). It includes recommended topics (subagents), instructions, action wiring, prompt usage, and sample questions.

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
**Description**: Load a new contract document, extract key fields and candidate clauses, and create a review record.

**Instructions**:
```
You are responsible for the initial intake of a contract.
- Prefer Document AI or Contracts AI extraction when available.
- Identify parties, dates, governing law, and major clause categories.
- Call the createReview Apex action to start a Contract_Review__c record.
- Summarize what was extracted and ask the user if they want to proceed to detailed analysis.
Always ground statements in the actual document content.
```

**Actions**:
- Document AI / Contracts AI extraction (if configured as an action)
- Apex: `ContractAnalysisActions.createReview`

#### Topic 2: Clause Extraction & Classification
**Description**: Extract specific clauses and classify them by type.

**Instructions**:
```
Extract and classify key commercial clauses (Liability, Indemnification, Termination, Governing Law, Confidentiality, etc.).
- Use the Classify_Contract_Clause prompt template for classification.
- Prefer exact text spans.
- Return structured results that can be stored as Contract_Finding__c records.
Be conservative and cite the source text.
```

**Actions**:
- Prompt Template: `Classify_Contract_Clause`
- Apex: `ContractAnalysisActions.scoreClauseRisk` (optional preliminary scoring)

#### Topic 3: Playbook & Risk Analysis
**Description**: Compare clauses to playbook standards and assign risk scores.

**Instructions**:
```
Score risk for extracted clauses against the organization's playbook or standard positions.
- Use the Generate_Clause_Risk_Rationale prompt.
- Call scoreClauseRisk or runAnalysis Apex actions as needed.
- Flag High-risk items clearly for mandatory human review.
- Suggest fallback language when there is a deviation.
Ground every risk assessment in the clause text and playbook (if provided).
```

**Actions**:
- Prompt Template: `Generate_Clause_Risk_Rationale`
- Apex: `ContractAnalysisActions.runAnalysis`
- Apex: `ContractAnalysisActions.scoreClauseRisk`

#### Topic 4: Citation & Authority Grounding
**Description**: Resolve and validate legal citations or supporting authorities.

**Instructions**:
```
When a clause or finding references external authority (statute, case, regulation, or internal policy):
- Retrieve supporting context via Intelligent Context / Data Cloud search.
- Validate that the citation supports the claim.
- If uncertain, flag for lawyer review rather than asserting correctness.
Always show the retrieved supporting text.
```

**Actions**:
- Intelligent Context / Data Cloud retrieval actions (configure as needed)

#### Topic 5: Findings & Review
**Description**: Present structured findings and capture lawyer feedback.

**Instructions**:
```
Generate or update the Contract Review and Findings.
- Summarize overall risk and list key findings.
- Direct the user to the Contract Findings Panel LWC for Accept / Override.
- When the user provides feedback, call the captureOverride Apex action.
- Always offer the option to mark the review complete via the Complete_Contract_Review Flow.
Present findings clearly with risk levels and excerpts.
```

**Actions**:
- Apex: `ContractAnalysisActions.captureOverride`
- Flow: `Complete_Contract_Review`
- (Optional) Apex methods that create/update findings

---

### 3. Sample Questions / Test Utterances

Use these to test routing and behavior:

| Sample Question | Expected Topic |
|-----------------|----------------|
| "Analyze this NDA and extract the key clauses" | Contract Intake or Clause Extraction |
| "What's the liability cap in this agreement and is it high risk?" | Playbook & Risk Analysis |
| "Classify the termination clause and suggest fallback language" | Clause Extraction + Risk Analysis |
| "Does the governing law clause match our playbook?" | Playbook & Risk Analysis |
| "Show me the findings and let me override the high-risk items" | Findings & Review |
| "Mark this review as complete" | Findings & Review |
| "Validate the citation to Section 12 of the UCC" | Citation & Authority Grounding |

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

Then edit the generated `.agent` file using the topic instructions and action mappings from this guide, and publish:

```bash
sf agent publish authoring-bundle --api-name ContractAnalysisAgent
```

---

### Notes
- Start with the five topics above. You can merge or split later.
- Always keep a human review gate for High-risk findings.
- Use Intelligent Context + Knowledge Harmonization for the best citation highlighting experience.
- The Apex methods are stubs — extend them to call real Document AI, external services, or Data Cloud retrievers as needed.

This setup gives you a complete, lawyer-in-the-loop Contract Analysis Agent grounded in Salesforce.
