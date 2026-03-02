# ArbiBot – Full Product Requirements Document (PRD)

**Product Name:** ArbiBot
**Domain:** Legal Intelligence & Arbitration Support
**Primary Jurisdiction:** Ghana
**Document Version:** 1.0 (Consolidated)
**Status:** Build‑Ready

---

## 1. Product Overview

### 1.1 What is ArbiBot?

ArbiBot is a **jurisdiction‑aware legal intelligence system** focused on Ghanaian law, mediation, arbitration, and professional legal workflows. It combines **Computer Vision OCR**, **Retrieval‑Augmented Generation (RAG)**, and **multi‑agent orchestration (LangGraph)** to deliver **verifiable, citation‑backed legal research and drafting**.

ArbiBot is **not a general chatbot** and **does not provide final legal advice**. All outputs are clearly labeled as drafts or research assistance.

---

## 2. Problem Statement

* Ghanaian legal materials are fragmented, scanned, and difficult to search
* Legal professionals spend excessive time drafting repetitive documents
* Existing AI tools hallucinate, lack citations, and are unsafe for legal use
* No Ghana‑focused AI system enforces jurisdiction, confidence, and auditability

---

## 3. Product Goals

1. Enable fast, **citation‑accurate legal research** on Ghanaian law
2. Automate **draft preparation** (statements, opinions) with human review
3. Provide **professional tools** (CV builder, job discovery)
4. Enforce **legal safety, traceability, and confidence gating**
5. Scale toward institutional adoption (CIMA, courts, firms)

---

## 4. Target Users

* Arbitrators & Mediators
* Lawyers & Legal Researchers
* Law Students
* ADR Institutions

---

## 5. Non‑Goals (Explicitly Out of Scope)

* Final legal advice
* User‑uploaded legal source ingestion
* Non‑Ghanaian law (MVP)
* Offline autonomous legal reasoning

---

## 6. Feature Breakdown by Phase

### 6.1 MVP Features

**Legal Research**

* Query Ghanaian statutes
* Citation‑backed answers
* Page‑level references
* Confidence warnings

**Document Drafting**

* Statement of Case drafts
* Legal Opinions (draft only)
* Submissions
* Mandatory human approval

**OCR & RAG (Backend Only)**

* Computer Vision OCR for PDFs/images
* Legal‑aware chunking
* pgvector embeddings
* Confidence‑based retrieval

**Mobile App (Flutter)**

* Chat interface
* Document library
* Citation viewer

---

### 6.2 Phase 2 Features

* Case law ingestion & retrieval
* Job discovery & alerts
* Handwritten OCR
* Low‑confidence override (explicit user consent)

---

### 6.3 Phase 3 Features

* Arbitration awards ingestion (restricted)
* Multi‑jurisdiction support
* Institutional dashboards
* Advanced analytics

---

## 7. Mobile App Screens (MVP)

* Splash / Welcome
* Authentication
* Home Dashboard
* Chat List
* Chat Screen
* Source Viewer
* Draft Type Selection
* Draft Preview & Approval
* Documents Library
* Profile & Settings
* Legal Disclaimer Modal

---

## 8. Full System Architecture

### 8.1 High‑Level Architecture

* **Client:** Flutter + langchain.dart (UX‑level chains only)
* **API Gateway:** FastAPI (auth, rate limiting)
* **AI Core:** LangGraph (Python)
* **Database:** Supabase Postgres + pgvector
* **Storage:** Supabase private bucket
* **OCR:** Google Vision (primary), Tesseract (fallback)

### 8.2 Architectural Rules

* No OCR on client
* No embeddings on client
* No legal reasoning outside LangGraph
* No frontend uploads of legal sources

---

## 9. LangGraph Multi‑Agent Design

**Safety Agent**

* Jurisdiction enforcement (GH only)
* Confidence enforcement
* Hallucination blocking

**Retrieval Agent**

* Vector search
* Confidence‑based retrieval
* Citation assembly

**Drafting Agent**

* Draft generation only
* Uses retrieved sources exclusively

**CV / Jobs Agent**

* Non‑legal automation

---

## 10. OCR & Ingestion Pipeline

### 10.1 Storage Policy

* Bucket: `ghana_legal_sources`
* Private
* Backend/service‑role only

### 10.2 Pipeline Flow

Storage → OCR → Confidence Scoring → Legal Chunking → Embeddings → DB

### 10.3 OCR Requirements

* Store page‑level text
* Store block‑level layout
* Store confidence scores
* Preserve original files

---

## 11. Database Schema (Supabase)

### Core Tables

* raw_files
* ocr_pages
* ocr_blocks
* document_chunks
* document_embeddings
* ingestion_logs

(pgvector enabled)

---

## 12. Confidence‑Based Retrieval Logic

| Level  | Confidence | Behavior               |
| ------ | ---------- | ---------------------- |
| High   | ≥ 0.85     | Normal retrieval       |
| Medium | 0.75–0.84  | Retrieval with warning |
| Low    | < 0.75     | Blocked                |

* No answer without sources
* No silent use of low confidence text

---

## 13. API Design (Simplified)

```
POST /chat
POST /research
POST /draft
GET  /documents
```

All APIs:

* Require auth
* Pass through Safety Agent

---

## 14. Security Checklist

* Private storage buckets
* RLS on all tables
* Service‑role ingestion only
* Rate limiting
* Audit logs
* Prompt injection protection

---

## 15. Legal & Compliance Safeguards

* Draft‑only labeling
* Mandatory disclaimers
* Citation requirement
* Jurisdiction enforcement
* Confidence warnings

---

## 16. Tech Stack Summary

| Layer            | Tech                     |
| ---------------- | ------------------------ |
| Mobile           | Flutter, langchain.dart  |
| API              | FastAPI                  |
| AI Orchestration | LangGraph (Python)       |
| OCR              | Google Vision, Tesseract |
| DB               | Supabase Postgres        |
| Vectors          | pgvector                 |
| Storage          | Supabase Storage         |

---

## 17. Success Metrics

* Citation accuracy rate
* OCR confidence distribution
* Draft approval rate
* User retention

---

## 18. Final Statement

ArbiBot is designed as a **court‑defensible, jurisdiction‑aware legal intelligence system**, not a general chatbot. Every architectural and product decision prioritizes **trust, safety, and professional use**.

---

---

## 19. Technical Implementation Roadmap

This roadmap translates the PRD into an execution‑ready engineering plan. Timelines assume a small, senior team (1 backend/AI, 1 mobile, 1 DevOps/PM).

---

### Phase 0: Foundations (Week 0–1)

**Objective:** Prepare infrastructure and guardrails before feature work.

**Backend / DevOps**

* Create Supabase project (prod + staging)
* Enable pgvector extension
* Create private storage bucket: `ghana_legal_sources`
* Define service‑role key usage policy (ingestion only)
* Configure environment secrets (OCR APIs, LLM keys)

**Security**

* Define RLS templates (deny‑by‑default)
* Define audit log strategy
* Set API rate limits

**Deliverables**

* Empty Supabase schema
* Storage bucket live
* CI/CD skeleton

---

### Phase 1: Data & OCR Ingestion (Week 1–3)

**Objective:** Make Ghanaian legal materials searchable and trustworthy.

**Ingestion Worker (Python)**

* Monitor Supabase Storage bucket
* Extract PDFs / images
* Run Computer Vision OCR
* Store:

  * raw files
  * page text
  * block layout
  * OCR confidence scores

**Processing**

* Legal‑aware chunking (section, article, clause)
* Generate embeddings (pgvector)
* Store ingestion logs

**Deliverables**

* End‑to‑end OCR → vector pipeline
* Confidence metrics visible in DB

---

### Phase 2: Core AI System (Week 3–5)

**Objective:** Enable safe, citation‑backed legal reasoning.

**LangGraph (Python)**

* Safety Agent
* Retrieval Agent
* Drafting Agent
* Confidence‑based gating

**Rules Enforcement**

* Ghana‑only jurisdiction filter
* Block low‑confidence retrieval
* Require citations for all outputs

**Deliverables**

* LangGraph DAG running locally
* Unit tests for safety failures

---

### Phase 3: API Layer (Week 5–6)

**Objective:** Securely expose AI functionality.

**FastAPI**

* Auth middleware
* Rate limiting
* Request validation

**Endpoints**

* /chat
* /research
* /draft
* /documents

**Integration**

* API → LangGraph
* LangGraph → Supabase

**Deliverables**

* Deployed API
* OpenAPI spec

---

### Phase 4: Mobile App (Week 6–8)

**Objective:** Deliver a professional legal UX.

**Flutter App**

* Authentication
* Chat UI
* Citation viewer
* Draft preview & approval flow

**AI Integration**

* langchain.dart (client‑side chains only)
* No embeddings or OCR on device

**Deliverables**

* TestFlight / APK build
* UX sign‑off

---

### Phase 5: Hardening & Compliance (Week 8–9)

**Objective:** Make ArbiBot institution‑ready.

* Security testing
* Prompt injection testing
* OCR accuracy review
* Performance tuning (pgvector indexes)

**Deliverables**

* Security checklist signed
* Go‑live approval

---

### Phase 6: Phase 2 Feature Expansion (Post‑Launch)

* Case law ingestion
* Job discovery agent
* Handwritten OCR
* Explicit low‑confidence override

---

### Phase 7: Phase 3 / Institutional Scale

* Multi‑jurisdiction
* Arbitration awards
* Admin dashboards
* Analytics

---

## 20. Ownership Map

| Area            | Owner       |
| --------------- | ----------- |
| OCR & Ingestion | Backend/AI  |
| LangGraph       | Backend/AI  |
| Supabase        | Backend     |
| Mobile App      | Flutter Dev |
| Security        | Tech Lead   |

---

**End of PRD**
