# Sample Data & Artifacts

These files provide starting material for playbooks, testing, and evaluation of the Contract Analysis system.

## Contents

- `playbooks/standard-commercial-playbook.md`  
  Preferred positions, risk thresholds, and fallback language for common commercial clauses. Ingest this into Data Cloud / Intelligent Context as a playbook source.

- `taxonomy/clause-taxonomy.md`  
  Standard clause categories and keywords. Use as reference when refining the Classify_Contract_Clause prompt or Apex classification logic.

- `contracts/sample-nda-excerpt.txt`  
  Short NDA excerpt containing high- and medium-risk language. Use for end-to-end testing of the agent and Document AI.

- `examples/sample-findings.json`  
  Example structured findings. Can be used to seed test Contract_Review__c / Contract_Finding__c records or to validate the LWC display.

## How to Use

1. Upload the playbook to your Data Cloud search index (Intelligent Context) so the agent can retrieve preferred positions.
2. Paste the sample NDA excerpt into an Agentforce conversation or feed it to Document AI for extraction testing.
3. Use the sample findings JSON to manually create test records and verify the Accept/Override LWC flow.
4. Extend the playbook and taxonomy with your organization’s actual positions as you gather lawyer feedback.

These artifacts are intentionally simple so they can be customized quickly.
