from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends
from supabase import Client

from ..dependencies import get_current_user_id, get_db, get_ai
from ..agents.orchestrator import Orchestrator
from ..models.schemas import ResearchRequest, ResearchResult
from ..models.enums import ConfidenceLevel

router = APIRouter(prefix="/api/v1/research", tags=["Legal Research"])


@router.post("/", response_model=ResearchResult)
async def conduct_research(
    request: ResearchRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    ai: Orchestrator = Depends(get_ai),
):
    """Conduct structured legal research with citation-backed results.

    Safety → ResearchAgent pipeline. Searches Ghanaian statutes, case law,
    legal principles, and precedents.
    """
    source_types = [st.value for st in request.source_types] if request.source_types else None

    result = await ai.do_research(
        query=request.query,
        jurisdiction=request.jurisdiction,
        source_types=source_types,
    )

    # Handle both structured and raw responses
    if result.get("raw"):
        return ResearchResult(
            content=result.get("content", ""),
            confidence=ConfidenceLevel.MEDIUM,
            citations=[],
            jurisdiction=request.jurisdiction,
            legal_observations=[],
            disclaimer=result.get("disclaimer", "This is legal research assistance only, not legal advice."),
        )

    return ResearchResult(
        content=result.get("content", ""),
        confidence=ConfidenceLevel(result.get("confidence", "medium")),
        citations=result.get("citations", []),
        jurisdiction=request.jurisdiction,
        legal_observations=result.get("legal_observations", []),
        disclaimer=result.get("disclaimer", "This is legal research assistance only, not legal advice."),
    )
