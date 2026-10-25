# Deployment Guide
## Contract Analysis Agentforce System

This guide covers technical deployment, admin configuration, day-to-day operations, and the files/actions needed by lawyers and stakeholders.

---

## 1. Technical Deployment

### Prerequisites
- Salesforce org with **Agentforce** and **Einstein Generative AI** enabled
- Salesforce CLI (`sf`) installed
- API version **68.0**
- Gov High: Agent Script may be unavailable. Use the intake page path below.

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

### Key Deployed Components
| Component | Type | Purpose |
|-----------|------|---------|
| `Contract_Review__c` | Custom Object | Parent review record |
| `Contract_Finding__c` | Custom Object | Individual clause findings |
| `ContractIntakeController` | Apex Class | Upload path: creates review and invokes Agentforce headlessly |
| `contractIntake` | LWC | Upload page for lawyers (no chat file upload required) |
| `contractReviewWorkspace` | LWC | Dual-pane review UI |
| `Extract_Contract_Document` | Prompt Template | Contract extraction |
| `Compare_Clause_to_Playbook` | Prompt Template | Playbook comparison |

---

## 2. Gov High path (no Agent Script, no chat file upload)

Agent Script files remain in the repo for later. They are not required for this path.

1. Deploy the project.
2. Create and activate the Contract Analysis Agent in the **Legacy Builder** (or New Builder if available).
3. Confirm the agent API name is `Contract_Analysis_Agent`. If different, update `AGENT_API_NAME` in `ContractIntakeController.cls`.
4. Assign a permission set with access to `Contract_Review__c`, `Contract_Finding__c`, Files, and the Apex class.
5. Create an App Page:
   - Lightning App Builder → New → App Page
   - Add the **contractIntake** component (or activate the deployed `Contract_Intake_Page`)
   - Activate for your legal app
6. Add `contractReviewWorkspace` to the Contract Review Lightning record page.
7. Lawyers open the intake page, upload a PDF/DOCX, set type/agency, and click **Upload & Run Analysis**.
8. The page creates the review, links the file, and calls Agentforce via `generateAiAgentResponse`.
9. The user is taken to the Contract Review Workspace to Accept/Override findings.

### Agent API name
If the headless call fails with "AgentIAType not found", the agent is not active or the API name does not match. Copy the exact API name from the agent Details page and set it in `ContractIntakeController.cls`.

---

## 3. Admin Configuration

1. Permissions for legal users and the agent user.
2. Agentforce enabled; agent active.
3. Prompt templates deployed and available as agent actions.
4. LWC on the intake app page and on the Contract Review record page.

---

## 4. Lawyer workflow (Gov High)
1. Open the Contract Intake page.
2. Upload the contract (PDF or DOCX).
3. Set document type and agency.
4. Click **Upload & Run Analysis**.
5. Review findings in the Contract Review Workspace.
6. Accept or Override each finding.
7. Use **Re-run Analysis** if needed.

---

## 5. Quick Reference

```bash
sf project deploy start --source-dir force-app
```

Agent Script / DX files (`specs/`, `sample-agent-spec.yaml`) are retained for when Gov High enables scripts. They are not required for the intake path.
