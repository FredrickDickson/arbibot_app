from fastapi import APIRouter, Depends
from supabase import Client

from ..dependencies import get_current_user_id, get_db
from ..models.schemas import DocumentListItem

router = APIRouter(prefix="/api/v1/documents", tags=["Documents Library"])


@router.get("/", response_model=list[DocumentListItem])
async def list_documents(
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """List all user documents: drafts, research outputs, and saved citations.

    Aggregates from multiple tables into a unified document library view.
    """
    documents = []

    # Fetch drafts
    drafts = (
        db.table("drafts")
        .select("id, document_type, title, status, jurisdiction, created_at, updated_at")
        .eq("user_id", user_id)
        .order("updated_at", desc=True)
        .execute()
    )
    for d in drafts.data:
        documents.append(DocumentListItem(
            id=d["id"],
            type=d["document_type"],
            title=d["title"],
            status=d.get("status"),
            jurisdiction=d.get("jurisdiction", "GH"),
            created_at=d["created_at"],
            updated_at=d["updated_at"],
        ))

    # Fetch negotiation analyses
    analyses = (
        db.table("negotiation_analyses")
        .select("id, dispute_summary, created_at")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .execute()
    )
    for a in analyses.data:
        documents.append(DocumentListItem(
            id=a["id"],
            type="negotiation_analysis",
            title=a["dispute_summary"][:80] if a.get("dispute_summary") else "Negotiation Analysis",
            jurisdiction="GH",
            created_at=a["created_at"],
            updated_at=a["created_at"],
        ))

    # Sort by updated_at descending
    documents.sort(key=lambda x: x.updated_at, reverse=True)
    return documents
