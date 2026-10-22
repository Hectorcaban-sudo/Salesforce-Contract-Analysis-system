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
