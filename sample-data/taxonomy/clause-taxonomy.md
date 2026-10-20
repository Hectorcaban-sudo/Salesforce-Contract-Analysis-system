# Clause Taxonomy
## Standard Categories for Contract Analysis

Use this taxonomy when classifying clauses (via the Classify_Contract_Clause prompt or Apex logic).

| Clause Type | Description | Common Keywords |
|-------------|-------------|-----------------|
| Liability Limitation | Caps or limits the amount or types of damages recoverable | "liability shall not exceed", "aggregate liability", "cap" |
| Indemnification | Obligations to defend or hold harmless | "indemnify", "hold harmless", "defend" |
| Termination | Rights to end the agreement | "terminate", "termination for convenience", "material breach" |
| Governing Law | Choice of law and venue | "governing law", "venue", "jurisdiction" |
| Confidentiality | Non-disclosure obligations | "confidential information", "non-disclosure" |
| Data Protection | Privacy, security, and processing terms | "personal data", "SOC 2", "data processing" |
| Intellectual Property | Ownership and license of IP | "intellectual property", "license", "ownership" |
| Assignment | Rights to assign the contract | "assign", "assignment" |
| Force Majeure | Excuse for non-performance due to extraordinary events | "force majeure", "act of God" |
| Audit Rights | Rights to inspect books or systems | "audit", "inspection" |
| Limitation of Remedies | Exclusions of certain damages | "consequential damages", "indirect damages" |
| Payment Terms | Fees, invoicing, and late payment | "payment", "invoice", "fees" |
| Warranty | Representations about quality or performance | "warranty", "represents and warrants" |
| Non-Solicitation | Restrictions on hiring the other party’s employees | "non-solicit", "solicit" |

### Usage Notes
- Prefer the most specific category that fits.
- If a clause covers multiple topics, classify the primary obligation and note secondary issues in the rationale.
- Missing standard clauses (for the known contract type) should be flagged as findings with risk level Medium or High.
