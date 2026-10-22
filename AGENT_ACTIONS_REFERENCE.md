## 2. Compare Clause to Playbook
**Prompt Template**: `Compare_Clause_to_Playbook`

**Action Description**  
Compares a contract clause to the embedded standard commercial playbook and taxonomy. Returns clause type, risk level, rationale, and recommended fallback language. Accepts optional retrieved context from a Data Library / Retriever.

**Loading Text**  
Comparing clause to playbook...

**Inputs**  
| Input | Description |
|-------|-------------|
| Clause Text | The exact text of the clause to evaluate. |
| Clause Type (optional) | Pre-classified clause type if known. |
| Retrieved Context (optional) | Additional passages from a Data Library / Retriever to prefer over the embedded baseline. |

**Outputs**  
| Output | Description |
|--------|-------------|
| Comparison Result | Clause type, risk level, rationale, and recommended language. |

**Notes**  
- Primary action for Topics 3 and 4. Embeds the playbook and taxonomy so no Retriever is required.
- If a Retriever becomes available later, pass its results into Retrieved Context.
