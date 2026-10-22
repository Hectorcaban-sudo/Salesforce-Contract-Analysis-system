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
