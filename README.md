# Contract Analysis Agentforce Starter

This Salesforce DX project provides the foundation for a production-ready, lawyer-in-the-loop **Contract Analysis AI system** built on Salesforce Agentforce, Document AI / Contracts AI, Intelligent Context, and Knowledge Harmonization.

## System Architecture Overview

1. **Ingestion and structuring** — Accept PDFs, DOCX, or text. Use layout-aware parsers (or OCR + layout models for scans) to recover sections, definitions, schedules, and cross-references. Segment into clause-level chunks while preserving hierarchy and section paths. Normalize citations, defined terms, and boilerplate.

2. **Indexing** — Hybrid index: dense embeddings (legal-domain preferred) + sparse/BM25 for exact matches (citation strings, party names, numbers). Store metadata (contract type, jurisdiction, date, parties, risk tags). Separate indexes or namespaces for (a) the contract under review, (b) internal playbooks/preferred language/historical precedents, and (c) external authorities (statutes, cases, regulations).

3. **Analysis layer** — Multi-step pipeline:
   - Clause detection and classification (extractive span finding or classification against your taxonomy).
   - Comparison to playbook positions (deviation detection, missing clauses, risk scoring).
   - Cross-clause reasoning (e.g., how an indemnification clause interacts with a liability cap or limitation of remedies).
   - Citation resolution and grounding.
   - Optional redline or fallback-language suggestions.

4. **Generation and interface** — Structured outputs (JSON + highlights) with mandatory citations/spans. Lawyer UI for review, override, and feedback. Full audit log of retrievals, model calls, and human actions. Confidence/abstention thresholds so low-confidence findings escalate.

5. **Feedback loop** — Reviewed corrections become labeled data for continued improvement (fine-tuning or retrieval tuning).

The system is assistive. Lawyers retain accountability; the model does not replace legal judgment.

## Architecture Overview (Salesforce Implementation)

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
- Sample agent spec: `sample-agent-spec.yaml`
- Detailed manual setup guide: `AGENT_SETUP_GUIDE.md`
- Deployment guide (technical, admin, operations, lawyer/stakeholder): `DEPLOYMENT_GUIDE.md`
- Sample data & artifacts: `sample-data/` (playbooks, clause taxonomy, sample NDA excerpt, example findings)

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
   - Ingest sample playbooks from `sample-data/playbooks/`.
   - Add the LWC to Contract Review record pages.

## Next Steps

- See **DEPLOYMENT_GUIDE.md** for the full technical, admin, operations, and stakeholder checklist.
- See **AGENT_SETUP_GUIDE.md** for step-by-step instructions to create the Agentforce agent manually (topics, instructions, prompts, sample questions, and action wiring).
- See **sample-data/README.md** for playbooks, taxonomy, and test contracts.

For Agentforce DX generation:
```bash
sf agent generate agent-spec --name ContractAnalysisAgent --type Employee --role "Analyze commercial contracts for risk, clause compliance, and playbook alignment"
```

Then refine and publish.
