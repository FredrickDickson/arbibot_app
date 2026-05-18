from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

from .enums import (
    MessageRole,
    ConfidenceLevel,
    DocumentType,
    DraftStatus,
    CaseEventType,
    LegalSourceType,
    CaseStatus,
)


# ── Auth ──────────────────────────────────────────────────────────────

class AuthSignupRequest(BaseModel):
    email: str
    password: str
    full_name: str
    title: Optional[str] = None
    organization: Optional[str] = None


class AuthLoginRequest(BaseModel):
    email: str
    password: str


class AuthTokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str
    expires_at: int


class AuthRefreshRequest(BaseModel):
    refresh_token: str


# ── Profile ───────────────────────────────────────────────────────────

class ProfileResponse(BaseModel):
    id: str
    full_name: str
    title: Optional[str] = None
    organization: Optional[str] = None
    created_at: datetime


# ── Chat / Messages ──────────────────────────────────────────────────

class Citation(BaseModel):
    source: str
    section: Optional[str] = None
    page: Optional[int] = None
    year: Optional[str] = None
    authority: Optional[str] = None
    verified: bool = False


class ChatMessageRequest(BaseModel):
    conversation_id: Optional[str] = None
    content: str
    jurisdiction: str = "GH"


class ChatMessageResponse(BaseModel):
    id: str
    conversation_id: str
    role: MessageRole
    content: str
    confidence: Optional[ConfidenceLevel] = None
    citations: list[Citation] = []
    disclaimer: Optional[str] = None
    created_at: datetime


class ConversationResponse(BaseModel):
    id: str
    title: str
    topic: Optional[str] = None
    jurisdiction: str = "GH"
    message_count: int = 0
    created_at: datetime
    updated_at: datetime


# ── Research ─────────────────────────────────────────────────────────

class ResearchRequest(BaseModel):
    query: str
    jurisdiction: str = "GH"
    source_types: list[LegalSourceType] = []


class ResearchResult(BaseModel):
    content: str
    confidence: ConfidenceLevel
    citations: list[Citation] = []
    jurisdiction: str
    legal_observations: list[str] = []
    disclaimer: str


# ── Drafts ───────────────────────────────────────────────────────────

class DraftSection(BaseModel):
    title: str
    content: str
    confidence: ConfidenceLevel = ConfidenceLevel.HIGH
    citations: list[str] = []


class DraftCreateRequest(BaseModel):
    document_type: DocumentType
    title: str
    jurisdiction: str = "GH"
    context: str = ""
    conversation_id: Optional[str] = None


class DraftResponse(BaseModel):
    id: str
    document_type: DocumentType
    title: str
    jurisdiction: str
    status: DraftStatus
    sections: list[DraftSection] = []
    citations: list[Citation] = []
    legal_observations: list[str] = []
    optional_clauses: list[str] = []
    plain_english_explanation: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    approved_at: Optional[datetime] = None


class DraftApprovalRequest(BaseModel):
    approved: bool
    reviewer_notes: Optional[str] = None


# ── Arbitration Cases ────────────────────────────────────────────────

class CaseCreateRequest(BaseModel):
    case_title: str
    case_number: Optional[str] = None
    parties: dict = {}
    arbitration_rules: Optional[str] = None
    jurisdiction: str = "GH"
    filing_date: Optional[datetime] = None


class CaseResponse(BaseModel):
    id: str
    case_title: str
    case_number: Optional[str] = None
    parties: dict = {}
    arbitration_rules: Optional[str] = None
    jurisdiction: str
    filing_date: Optional[datetime] = None
    status: CaseStatus
    created_at: datetime
    updated_at: datetime


# ── Case Events (Procedural) ────────────────────────────────────────

class CaseEventCreate(BaseModel):
    event_type: CaseEventType
    title: str
    description: Optional[str] = None
    due_date: datetime


class CaseEventResponse(BaseModel):
    id: str
    case_id: str
    event_type: CaseEventType
    title: str
    description: Optional[str] = None
    due_date: datetime
    is_completed: bool = False
    completed_at: Optional[datetime] = None
    created_at: datetime


class TimelineGenerateRequest(BaseModel):
    case_id: str
    arbitration_rules: Optional[str] = None


class ComplianceChecklistRequest(BaseModel):
    case_id: str


class ComplianceItem(BaseModel):
    requirement: str
    status: str
    due_date: Optional[datetime] = None
    notes: Optional[str] = None


class ProceduralResponse(BaseModel):
    case_id: str
    events: list[CaseEventResponse] = []
    checklist: list[ComplianceItem] = []
    summary: Optional[str] = None


# ── Negotiation ──────────────────────────────────────────────────────

class NegotiationAnalysisRequest(BaseModel):
    case_id: Optional[str] = None
    dispute_summary: str
    party_positions: dict = {}
    jurisdiction: str = "GH"


class BATNAWATNAItem(BaseModel):
    scenario: str
    likelihood: str
    outcome_description: str
    estimated_value: Optional[str] = None


class NegotiationAnalysisResponse(BaseModel):
    id: str
    dispute_summary: str
    batna: list[BATNAWATNAItem] = []
    watna: list[BATNAWATNAItem] = []
    settlement_range: dict = {}
    strategy_notes: str = ""
    mediation_brief: Optional[str] = None
    disclaimer: str = "This is analytical support only, not a legal decision."
    created_at: datetime


# ── Documents Library ────────────────────────────────────────────────

class DocumentListItem(BaseModel):
    id: str
    type: str
    title: str
    status: Optional[str] = None
    jurisdiction: str = "GH"
    created_at: datetime
    updated_at: datetime


# ── Generic ──────────────────────────────────────────────────────────

class ErrorResponse(BaseModel):
    detail: str
    code: Optional[str] = None


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
