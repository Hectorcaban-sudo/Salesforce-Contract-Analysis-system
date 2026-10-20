# Deployment Guide
## Contract Analysis Agentforce System

This guide covers technical deployment, admin configuration, day-to-day operations, and the files/actions needed by lawyers and stakeholders.

---

## 1. Technical Deployment

### Prerequisites
- Salesforce org with **Agentforce**, **Data Cloud (Data 360)**, and **Einstein Generative AI** enabled
- Salesforce CLI (`sf`) installed
- VS Code with Salesforce Extension Pack + Agentforce DX extensions (recommended)
- Contracts AI / Salesforce Contracts license (recommended for full Document AI features)
- API version 64+

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/Hectorcaban-sudo/Salesforce-Contract-Analysis-system.git
   cd Salesforce-Contract-Analysis-system
   ```

2. Authenticate to the target org:
   ```bash
   sf org login web
   ```

3. Deploy the metadata:
   ```bash
   sf project deploy start --source-dir force-app
   ```

4. Verify deployment:
   - Custom objects `Contract_Review__c` and `Contract_Finding__c` exist
   - Apex class `ContractAnalysisActions` is active
   - Prompt templates and Flow are present
   - LWC `contractFindingsPanel` is available

### Key Deployed Components
| Component | Type | Purpose |
|-----------|------|---------|
| `Contract_Review__c` | Custom Object | Parent review record |
| `Contract_Finding__c` | Custom Object | Individual clause findings |
| `ContractAnalysisActions` | Apex Class | Invocable analysis & override actions |
| `Classify_Contract_Clause` | Prompt Template | Clause classification |
| `Generate_Clause_Risk_Rationale` | Prompt Template | Risk rationale + fallback language |
| `Complete_Contract_Review` | Flow | Mark review complete |
| `contractFindingsPanel` | LWC | Lawyer review UI (Accept / Override + note) |

---

## 2. Admin Configuration

### Post-Deploy Setup
1. **Permissions**
   - Create a Permission Set (e.g., `Contract_Analysis_User`) granting:
     - Read/Create/Edit on `Contract_Review__c` and `Contract_Finding__c`
     - Access to the Apex class and Flow
   - Assign to legal users and the Agentforce agent user (if applicable)

2. **Agentforce**
   - Enable Agentforce in Setup
   - Create the agent following `AGENT_SETUP_GUIDE.md`
   - Wire the Apex methods, Prompt Templates, and Flow as actions under the five topics

3. **Document AI / Contracts AI** (recommended)
   - Enable Document AI / Contracts AI
   - Configure extraction schemas or context definitions for contract fields and clauses
   - Make extraction available as an Agentforce action (or call via Apex)

4. **Data Cloud / Intelligent Context / Knowledge Harmonization**
   - Enable Data Cloud and Intelligent Context
   - Create search index configurations for contracts, playbooks, and authorities
   - Turn on Knowledge Harmonization for consistent citation rendering and highlighting
   - Ingest playbooks and historical precedents

5. **UI**
   - Add the `contractFindingsPanel` LWC to the Contract Review Lightning record page
   - (Optional) Create a list view or app for legal users

6. **Security & Governance**
   - Review sharing rules (default is private/controlled by parent)
   - Confirm Einstein trust boundary and data residency settings
   - Enable audit logging if required by your compliance program

---

## 3. One-Time / Ongoing Operations

### One-Time Setup Checklist
- [ ] Deploy metadata
- [ ] Assign permissions
- [ ] Create and activate the Agentforce agent
- [ ] Configure Document AI schemas
- [ ] Set up Intelligent Context indexes + Knowledge Harmonization
- [ ] Add LWC to record page
- [ ] Test end-to-end with a sample contract

### Ongoing Operations
- **Index maintenance**: Re-index new playbooks or contract templates in Data Cloud
- **Prompt / instruction tuning**: Update topic instructions or prompt templates based on lawyer feedback
- **Feedback loop**: Review Override notes stored on `Contract_Finding__c` to improve future analysis
- **Monitoring**: Check Agentforce conversation logs and error rates
- **License / limit monitoring**: Track Document AI and Einstein credit consumption

---

## 4. Files & Actions Needed by Lawyers and Stakeholders

### For Lawyers (Day-to-Day Use)
| Need | How to Access | Related File / Action |
|------|---------------|-----------------------|
| Start a new review | Chat with the Contract Analysis Agent | Agentforce agent + `createReview` action |
| View findings | Open Contract Review record | LWC `contractFindingsPanel` |
| Accept a finding | Click **Accept** on the LWC | Apex `captureOverride` |
| Override a finding + add note | Enter note + click **Override** | Apex `captureOverride` + `Override_Note__c` field |
| Mark review complete | Ask the agent or run Flow | Flow `Complete_Contract_Review` |
| Ask questions about a contract | Chat with the agent | Agent topics (Intake, Extraction, Risk, Citation, Review) |

### For Stakeholders / Legal Ops
| Need | Location | Purpose |
|------|----------|---------|
| Architecture overview | `README.md` | Understand the system design |
| Manual agent setup | `AGENT_SETUP_GUIDE.md` | Create or refine the Agentforce agent |
| Sample agent spec | `sample-agent-spec.yaml` | Starting point for Agentforce DX |
| Sample agent script | `sample-agent-script.agent` | Topic instructions + action mappings |
| This deployment guide | `DEPLOYMENT_GUIDE.md` | Technical + admin + operations checklist |
| Feedback data | `Contract_Finding__c.Override_Note__c` | Improve playbooks and prompts |

### Recommended Lawyer Workflow
1. Upload or reference a contract and ask the agent to analyze it.
2. Review the summary and overall risk score.
3. Open the Contract Review record and use the Findings Panel LWC.
4. Accept or Override individual findings (add notes on overrides).
5. Ask follow-up questions (e.g., cross-clause interaction, citation validation).
6. Mark the review complete when finished.

---

## 5. Quick Reference Commands

```bash
# Deploy
sf project deploy start --source-dir force-app

# Generate agent spec (Agentforce DX)
sf agent generate agent-spec --name ContractAnalysisAgent --type Employee \
  --role "Analyze commercial contracts for risk, clause compliance, and playbook alignment"

# Retrieve agent metadata
sf project retrieve start --metadata AiAgentDefinitionVersion --root-type-with-dependencies AiAgentDefinitionVersion
```

---

## 6. Support & Next Steps
- Start with the sample questions in `AGENT_SETUP_GUIDE.md` to validate routing.
- Extend the Apex stubs in `ContractAnalysisActions.cls` to call real Document AI, external services, or Data Cloud retrievers.
- Use lawyer Override notes as labeled data for future prompt or retrieval improvements.

The system is designed to be assistive. Lawyers retain final accountability for all legal judgments.
