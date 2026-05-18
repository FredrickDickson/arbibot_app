from enum import Enum


class MessageRole(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class ConfidenceLevel(str, Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class DocumentType(str, Enum):
    STATEMENT_OF_CASE = "statement_of_case"
    LEGAL_OPINION = "legal_opinion"
    SUBMISSION = "submission"


class DraftStatus(str, Enum):
    DRAFT = "draft"
    PENDING_REVIEW = "pending_review"
    APPROVED = "approved"
    REJECTED = "rejected"


class CaseEventType(str, Enum):
    DEADLINE = "deadline"
    HEARING = "hearing"
    FILING = "filing"
    MILESTONE = "milestone"


class LegalSourceType(str, Enum):
    STATUTE = "statute"
    CASE_LAW = "case_law"
    REGULATION = "regulation"


class CaseStatus(str, Enum):
    ACTIVE = "active"
    PENDING = "pending"
    CLOSED = "closed"
    SETTLED = "settled"


class AgentType(str, Enum):
    SAFETY = "safety"
    RESEARCH = "research"
    DRAFTING = "drafting"
    PROCEDURAL = "procedural"
    NEGOTIATION = "negotiation"
