from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from ..dependencies import get_current_user_id, get_db, get_ai
from ..agents.orchestrator import Orchestrator
from ..models.schemas import (
    NegotiationAnalysisRequest,
    NegotiationAnalysisResponse,
)

router = APIRouter(prefix="/api/v1/negotiation", tags=["Negotiation Support"])


@router.post("/analysis", response_model=NegotiationAnalysisResponse)
async def create_analysis(
    request: NegotiationAnalysisRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    ai: Orchestrator = Depends(get_ai),
):
    """Generate BATNA/WATNA analysis and settlement strategy.

    Safety → NegotiationAgent pipeline.
    Does NOT make final legal decisions.
    """
    result = await ai.do_negotiation(
        dispute_summary=request.dispute_summary,
        party_positions=request.party_positions,
        jurisdiction=request.jurisdiction,
    )

    now = datetime.now(timezone.utc).isoformat()
    analysis_id = str(uuid4())

    record = {
        "id": analysis_id,
        "user_id": user_id,
        "case_id": request.case_id,
        "dispute_summary": request.dispute_summary,
        "batna": result.get("batna", []),
        "watna": result.get("watna", []),
        "settlement_range": result.get("settlement_range", {}),
        "strategy_notes": result.get("strategy_notes", ""),
        "created_at": now,
    }
    db.table("negotiation_analyses").insert(record).execute()

    return NegotiationAnalysisResponse(
        id=analysis_id,
        dispute_summary=request.dispute_summary,
        batna=result.get("batna", []),
        watna=result.get("watna", []),
        settlement_range=result.get("settlement_range", {}),
        strategy_notes=result.get("strategy_notes", ""),
        mediation_brief=result.get("mediation_brief"),
        disclaimer="This is analytical support only, not a legal decision.",
        created_at=datetime.now(timezone.utc),
    )


@router.get("/{analysis_id}", response_model=NegotiationAnalysisResponse)
async def get_analysis(
    analysis_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Get a specific negotiation analysis."""
    result = (
        db.table("negotiation_analyses")
        .select("*")
        .eq("id", analysis_id)
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Analysis not found")

    data = result.data
    return NegotiationAnalysisResponse(
        id=data["id"],
        dispute_summary=data["dispute_summary"],
        batna=data.get("batna", []),
        watna=data.get("watna", []),
        settlement_range=data.get("settlement_range", {}),
        strategy_notes=data.get("strategy_notes", ""),
        disclaimer="This is analytical support only, not a legal decision.",
        created_at=data["created_at"],
    )
