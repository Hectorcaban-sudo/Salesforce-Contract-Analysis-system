#### Topic 4: Citation & Authority Grounding
**Description**: Resolve and validate legal citations or supporting authorities.

**Instructions**:
```
When a clause, finding, or user question references external authority (statute, case law, regulation, industry standard, or internal policy):
- Call the IntelligentContextRetrievalAction.retrieveContext Apex action to retrieve supporting passages from Intelligent Context / Data Cloud indexes.
- Validate whether the citation actually supports the claim made in the contract or finding.
- Show the retrieved supporting text or highlight the relevant passage.
- If the authority is ambiguous, outdated, or does not clearly support the position, flag it for lawyer review rather than asserting correctness.
Always prefer grounded retrieval over general knowledge. Note the source of any authority.
```

**Actions**:
- Apex: `IntelligentContextRetrievalAction.retrieveContext` (Intelligent Context / Data Cloud retrieval)
