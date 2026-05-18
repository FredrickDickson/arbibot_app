from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from .config import get_settings
from .middleware.auth import SupabaseAuthMiddleware
from .middleware.rate_limit import limiter
from .models.schemas import HealthResponse

from .routers import (
    auth,
    chat,
    research,
    drafts,
    documents,
    procedural,
    negotiation,
    cases,
)

settings = get_settings()

app = FastAPI(
    title="ArbiBot API",
    description="Jurisdiction-aware legal intelligence system for Ghanaian law, arbitration, and professional legal workflows.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Middleware ────────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(SupabaseAuthMiddleware)

# Rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── Routers ──────────────────────────────────────────────────────────

app.include_router(auth.router)
app.include_router(chat.router)
app.include_router(research.router)
app.include_router(drafts.router)
app.include_router(documents.router)
app.include_router(procedural.router)
app.include_router(negotiation.router)
app.include_router(cases.router)

# ── Health Check ─────────────────────────────────────────────────────


@app.get("/", response_model=HealthResponse, tags=["Health"])
async def root():
    return HealthResponse(status="ok", version="1.0.0")


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    return HealthResponse(status="ok", version="1.0.0")
