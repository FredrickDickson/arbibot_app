from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from ..dependencies import get_current_user_id, get_db, get_llm
from ..services.llm_service import LLMService
from ..models.schemas import (
    DraftCreateRequest,
    DraftResponse,
    DraftApprovalRequest,
)
from ..models.enums import DraftStatus, ConfidenceLevel

router = APIRouter(prefix="/api/v1/drafts", tags=["Document Drafting"])


@router.post("/", response_model=DraftResponse)
async def create_draft(
    request: DraftCreateRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    llm: LLMService = Depends(get_llm),
):
    """Generate a legal document draft using AI.

    Supports: Statement of Case, Legal Opinion, Submission.
    All drafts require mandatory human approval.
    """
    draft_prompt = f"""Generate a professional legal document draft.

Document Type: {request.document_type.value.replace('_', ' ').title()}
Title: {request.title}
Jurisdiction: {request.jurisdiction}
Context: {request.context}

Provide your response as JSON with this structure:
{{
    "sections": [
        {{
            "title": "Section title (e.g., '1. Introduction and Background')",
            "content": "Detailed section content with proper legal language",
            "confidence": "high|medium|low",
            "citations": ["List of citation strings for this section"]
        }}
    ],
    "citations": [
        {{
            "source": "Full name of legal authority",
            "section": "Section reference",
            "year": "Year",
            "authority": "primary|secondary",
            "verified": false
        }}
    ],
    "legal_observations": ["Important legal observations about this draft"],
    "optional_clauses": ["Optional clauses the user might want to include"],
    "plain_english_explanation": "A plain-English summary of the document"
}}

IMPORTANT:
- Use formal legal language appropriate for {request.jurisdiction} jurisdiction
- Include relevant statutory and case law references
- Structure sections logically for the document type
- Never fabricate legal authorities
- Mark all citations as verified: false (verification comes later)"""

    messages = [{"role": "user", "content": draft_prompt}]
    result = await llm.generate_structured(
        messages=messages,
        response_format={"type": "json_object"},
    )

    now = datetime.now(timezone.utc).isoformat()
    draft_id = str(uuid4())

    draft_record = {
        "id": draft_id,
        "user_id": user_id,
        "conversation_id": request.conversation_id,
        "document_type": request.document_type.value,
        "title": request.title,
        "jurisdiction": request.jurisdiction,
        "status": DraftStatus.DRAFT.value,
        "sections": result.get("sections", []),
        "citations": result.get("citations", []),
        "created_at": now,
        "updated_at": now,
    }

    db.table("drafts").insert(draft_record).execute()

    return DraftResponse(
        id=draft_id,
        document_type=request.document_type,
        title=request.title,
        jurisdiction=request.jurisdiction,
        status=DraftStatus.DRAFT,
        sections=result.get("sections", []),
        citations=result.get("citations", []),
        legal_observations=result.get("legal_observations", []),
        optional_clauses=result.get("optional_clauses", []),
        plain_english_explanation=result.get("plain_english_explanation"),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )


@router.get("/", response_model=list[DraftResponse])
async def list_drafts(
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """List all drafts for the current user."""
    result = (
        db.table("drafts")
        .select("*")
        .eq("user_id", user_id)
        .order("updated_at", desc=True)
        .execute()
    )
    return result.data


@router.get("/{draft_id}", response_model=DraftResponse)
async def get_draft(
    draft_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Get a specific draft by ID."""
    result = (
        db.table("drafts")
        .select("*")
        .eq("id", draft_id)
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Draft not found")
    return result.data


@router.post("/{draft_id}/approve", response_model=DraftResponse)
async def approve_draft(
    draft_id: str,
    request: DraftApprovalRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Approve or reject a draft (mandatory human review)."""
    now = datetime.now(timezone.utc).isoformat()
    new_status = DraftStatus.APPROVED.value if request.approved else DraftStatus.REJECTED.value

    update_data = {
        "status": new_status,
        "updated_at": now,
    }
    if request.approved:
        update_data["approved_at"] = now

    result = (
        db.table("drafts")
        .update(update_data)
        .eq("id", draft_id)
        .eq("user_id", user_id)
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=404, detail="Draft not found")

    return result.data[0]
