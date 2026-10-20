# Contract Analysis Agentforce Starter

This Salesforce DX project provides the foundation for a production-ready, lawyer-in-the-loop **Contract Analysis AI system** built on Salesforce Agentforce, Document AI / Contracts AI, Intelligent Context, and Knowledge Harmonization.

## Architecture Overview

The system is designed as a modular, human-in-the-loop pipeline optimized for legal precision, grounded citations, and continuous improvement.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Document       │───▶│  Hybrid Indexing │───▶│  Retrieval      │
│  Ingestion      │    │  (Intelligent    │    │  Layer          │
│  (Document AI / │    │   Context +      │    │  (Data Cloud    │
│   Contracts AI) │    │   Knowledge      │    │   RAG +         │
│                 │    │   Harmonization) │    │   Playbooks)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                              │
         ▼                                              ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Analysis       │◀───│  Agentforce      │───▶│  Output &       │
│  Engine         │    │  Topics /        │    │  Human Review   │
│  (Apex +        │    │  Subagents       │    │  (LWC +         │
│   Prompt        │    │                  │    │   Override      │
│   Templates)    │    │                  │    │   Feedback)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Layer Details

1. **Document Ingestion**  
   Document AI / Contracts AI extracts structured fields and candidate clauses from PDFs/DOCX. Supports real-time and batch modes.

2. **Hybrid Indexing**  
   Intelligent Context creates domain-tuned search indexes. Knowledge Harmonization normalizes content for consistent citation rendering and in-app highlighting.

3. **Retrieval Layer**  
   Hybrid retrieval (dense embeddings + sparse) over contracts, playbooks, and authorities. Grounds every analysis step.

4. **Analysis Engine**  
   Agentforce topics orchestrate Apex invocable actions and Prompt Templates for clause classification, risk scoring, playbook comparison, and citation validation.

5. **Output & Human Review**  
   Structured findings written to `Contract_Review__c` / `Contract_Finding__c`. LWC panel presents results with Accept / Override + free-text notes. Feedback improves future runs.

### Recommended Agentforce Topics / Subagents

| Topic | Purpose | Key Actions |
|-------|---------|-------------|
| Contract Intake & Structure | Load document, extract fields/clauses | Document AI / Contracts AI, createReview |
| Clause Extraction & Classification | Identify and classify key clauses | Classify_Contract_Clause prompt, scoreClauseRisk |
| Playbook & Risk Analysis | Compare to standards, score risk | Generate_Clause_Risk_Rationale, runAnalysis |
| Citation & Authority Grounding | Resolve and validate citations | Intelligent Context retrieval |
| Findings & Review | Present results and capture feedback | PresentInUI (LWC), captureOverride |

## What's Included in This Project

- Custom objects: `Contract_Review__c` and `Contract_Finding__c` (with Review Status + Override Note)
- Apex invocable actions: `runAnalysis`, `scoreClauseRisk`, `createReview`, `captureOverride`
- Prompt Templates: `Classify_Contract_Clause`, `Generate_Clause_Risk_Rationale`
- Flow: `Complete_Contract_Review`
- LWC: `contractFindingsPanel` (Accept / Override + free-text note)
- Sample agent script: `sample-agent-script.agent`
- Detailed manual setup guide: `AGENT_SETUP_GUIDE.md`

## Prerequisites

- Salesforce org with Agentforce + Data Cloud (Data 360) + Einstein Generative AI
- Salesforce CLI (`sf`) and VS Code with Salesforce Extension Pack + Agentforce DX extensions
- Contracts AI / Salesforce Contracts recommended
- API version 64+

## Deployment Steps

1. Authenticate:
   ```bash
   sf org login web
   ```

2. Deploy:
   ```bash
   sf project deploy start --source-dir force-app
   ```

3. Post-deploy configuration:
   - Assign permissions for custom objects.
   - Enable Agentforce, Data Cloud, Einstein.
   - Configure Document AI / Contracts AI schemas.
   - Set up Intelligent Context indexes and Knowledge Harmonization.
   - Add the LWC to Contract Review record pages.

## Next Steps

See **AGENT_SETUP_GUIDE.md** for step-by-step instructions to create the Agentforce agent manually (topics, instructions, prompts, sample questions, and action wiring).

For Agentforce DX generation:
```bash
sf agent generate agent-spec --name ContractAnalysisAgent --type Employee --role "Analyze commercial contracts for risk, clause compliance, and playbook alignment"
```

Then refine and publish.
