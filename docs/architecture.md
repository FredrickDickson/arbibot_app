# ArbiBot – Full System Architecture (Visual)

Below is a **visual, layered architecture diagram** representing the complete ArbiBot system as agreed throughout this project. This diagram is suitable for **engineering onboarding, investors, and auditors**.

---

## 🏛️ High-Level Architecture Diagram

```
┌──────────────────────────────────────────────┐
│                Mobile App (Flutter)          │
│        UI + Conversation UX                  │
│        langchain.dart (UI Chains)            │
│  - Prompt formatting                         │
│  - Follow-up suggestions                    │
│  - Citation rendering                       │
└───────────────────┬──────────────────────────┘
                    │ HTTPS (JWT Auth)
                    ▼
┌──────────────────────────────────────────────┐
│            API Gateway (FastAPI)              │
│  - Auth verification (Supabase Auth)          │
│  - Rate limiting                              │
│  - Input validation                           │
│  - Logging & tracing                          │
└───────────────────┬──────────────────────────┘
                    │ Internal Calls
                    ▼
┌──────────────────────────────────────────────┐
│          LangGraph Orchestration Layer        │
│      (Authoritative AI – Python)              │
│                                              │
│   ┌──────────────┐    ┌──────────────────┐   │
│   │ Safety Agent │◄───►│ Retrieval Agent  │   │
│   └──────────────┘    └──────────────────┘   │
│           │                      │            │
│           ▼                      ▼            │
│   ┌──────────────┐    ┌──────────────────┐   │
│   │ Drafting     │    │ CV / Jobs Agent  │   │
│   │ Agent        │    │ (Non-legal)      │   │
│   └──────────────┘    └──────────────────┘   │
└───────────────────┬──────────────────────────┘
                    │ SQL + Vector Queries
                    ▼
┌──────────────────────────────────────────────┐
│                Supabase                      │
│                                              │
│  ┌────────────────────┐  ┌────────────────┐ │
│  │ Postgres + pgvector│  │ Storage        │ │
│  │                    │  │ (Private)      │ │
│  │ - raw_files        │  │ ghana_legal_   │ │
│  │ - ocr_pages        │  │ sources        │ │
│  │ - document_chunks │  └────────────────┘ │
│  │ - embeddings      │                     │
│  └────────────────────┘                     │
└───────────────────┬──────────────────────────┘
                    │ Backend Workers
                    ▼
┌──────────────────────────────────────────────┐
│        OCR & Ingestion Pipeline               │
│                                              │
│  Storage → OCR (Vision AI) → Confidence       │
│           → Legal Chunking → Embeddings       │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🔄 Runtime Query Flow (Simplified)

```
User Question
   ↓
Flutter + langchain.dart (UX-level chain)
   ↓
API Gateway (validate + auth)
   ↓
LangGraph Safety Agent
   ↓
Confidence-Gated Retrieval (pgvector)
   ↓
Drafting / Research Agent
   ↓
Citations + Warnings
   ↓
Response to Mobile App
```

---

## 🔐 Security & Trust Boundaries (Visual)

```
[ Client ]        → No access to sources
[ API ]           → No embeddings logic
[ LangGraph ]     → Only layer allowed to reason
[ Supabase DB ]   → RLS enforced
[ Storage ]       → Backend service-role only
```

---

## 🧠 Key Architectural Guarantees

* No OCR or embeddings on client
* No legal reasoning outside LangGraph
* No answer without authoritative Ghanaian sources
* OCR confidence always enforced
* Full audit trail preserved

---

## 📌 How to Use This Diagram

* **Engineering**: system boundaries & responsibilities
* **Investors**: defensibility & moat
* **Legal partners**: compliance assurance
* **Auditors**: traceability & control

---

> ArbiBot is not a chatbot. It is a **jurisdiction-aware legal intelligence system** built with safety-first architecture.
