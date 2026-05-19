# ArbiBot Backend

FastAPI backend for the ArbiBot legal intelligence platform. Provides AI-powered legal research, document drafting, procedural management, and negotiation support for Ghanaian law.

## Setup

### 1. Install Python dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env with your actual keys
```

Required environment variables:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
OPENAI_API_KEY=your_openai_api_key
OLLAMA_BASE_URL=http://localhost:11434
TAVILY_API_KEY=your_tavily_api_key
```

### 3. Install Ollama (for local embeddings)

Ollama is required for local text embedding generation using the nomic-embed-text model.

**Linux/macOS:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows:**
Download from https://ollama.com/download

**Pull the embedding model:**
```bash
ollama pull nomic-embed-text
```

**Verify installation:**
```bash
ollama list
```

### 4. Install Tesseract OCR (optional, for scanned PDFs)

**Ubuntu/Debian:**
```bash
sudo apt-get install tesseract-ocr
```

**macOS:**
```bash
brew install tesseract
```

**Windows:**
Download from https://github.com/UB-Mannheim/tesseract/wiki

### 5. Run the server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 6. View API docs

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/signup` | Register new user |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/auth/refresh` | Refresh token |
| GET | `/api/v1/chat/conversations` | List conversations |
| POST | `/api/v1/chat/send` | Send message (non-streaming) |
| POST | `/api/v1/chat/send/stream` | Send message (SSE streaming) |
| POST | `/api/v1/research/` | Conduct legal research |
| POST | `/api/v1/drafts/` | Generate document draft |
| GET | `/api/v1/drafts/` | List drafts |
| POST | `/api/v1/drafts/{id}/approve` | Approve/reject draft |
| GET | `/api/v1/documents/` | List all documents |
| POST | `/api/v1/cases/` | Create arbitration case |
| GET | `/api/v1/cases/` | List cases |
| POST | `/api/v1/procedural/timeline` | Generate timeline |
| POST | `/api/v1/procedural/checklist` | Generate compliance checklist |
| POST | `/api/v1/negotiation/analysis` | BATNA/WATNA analysis |
| POST | `/api/v1/ingestion/upload` | Upload document (PDF/text) |
| POST | `/api/v1/ingestion/text` | Ingest plain text |
| GET | `/api/v1/ingestion/stats` | Get ingestion statistics |
| DELETE | `/api/v1/ingestion/{id}` | Delete document |
| POST | `/api/v1/ingestion/search` | Search similar chunks |
| GET | `/api/v1/ingestion/health` | Check Ollama status |
| POST | `/api/v1/ingestion/batch` | Bulk ingestion (admin) |

## Architecture

```
app/
├── main.py              # FastAPI entry point
├── config.py            # Environment settings
├── dependencies.py      # Shared dependencies
├── middleware/
│   ├── auth.py          # Supabase JWT verification
│   └── rate_limit.py    # Per-user rate limiting
├── routers/             # API route handlers
├── models/              # Pydantic schemas & enums
├── services/            # Supabase & LLM clients
└── agents/              # AI agent stubs (Safety, Research, Drafting, Procedural, Negotiation)
```
