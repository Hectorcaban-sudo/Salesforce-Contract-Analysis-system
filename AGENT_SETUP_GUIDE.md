#### Topic 4: Citation & Authority Grounding
**Description**: Resolve and validate legal citations or supporting authorities using a Data Library / Retriever.

**Instructions**:
```
When a clause, finding, or user question references external authority (statute, case law, regulation, industry standard, internal policy, or playbook position):
- Call the Data Library / Retriever action (Intelligent Context) to retrieve supporting passages from the published search index (playbook, taxonomy, regulations, etc.).
- Validate whether the retrieved content supports the claim made in the contract or finding.
- Show the retrieved supporting text or highlight the relevant passage and note the source document.
- If the authority is ambiguous, outdated, or does not clearly support the position, flag it for lawyer review rather than asserting correctness.
Always prefer grounded retrieval over general knowledge. Note the source of any authority.
```

**Actions**:
- Data Library / Retriever: Intelligent Context search index (playbook + taxonomy + other sources)
  - Name in Agentforce: e.g. "Retrieve Playbook & Authority Context"
  - When to use: "When validating a citation, comparing to playbook standards, or retrieving supporting text from indexed documents."
