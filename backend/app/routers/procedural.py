from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from ..dependencies import get_current_user_id, get_db, get_ai
from ..agents.orchestrator import Orchestrator
from ..models.schemas import (
    TimelineGenerateRequest,
    ComplianceChecklistRequest,
    ProceduralResponse,
    CaseEventResponse,
    ComplianceItem,
)

router = APIRouter(prefix="/api/v1/procedural", tags=["Procedural Management"])


@router.post("/timeline", response_model=ProceduralResponse)
async def generate_timeline(
    request: TimelineGenerateRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    ai: Orchestrator = Depends(get_ai),
):
    """Generate an arbitration timeline with key deadlines and milestones.

    Safety → ProceduralAgent pipeline. Based on Act 798 and applicable rules.
    """
    # Fetch case details
    case_result = (
        db.table("arbitration_cases")
        .select("*")
        .eq("id", request.case_id)
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not case_result.data:
        raise HTTPException(status_code=404, detail="Case not found")

    case = case_result.data
    case["arbitration_rules"] = request.arbitration_rules or case.get("arbitration_rules", "ADR Act 798")

    result = await ai.do_timeline(case)

    now = datetime.now(timezone.utc).isoformat()
    saved_events = []

    for event in result.get("events", []):
        event_record = {
            "id": str(uuid4()),
            "case_id": request.case_id,
            "event_type": event.get("event_type", "milestone"),
            "title": event.get("title", ""),
            "description": event.get("description"),
            "due_date": event.get("due_date", now),
            "is_completed": event.get("is_completed", False),
            "created_at": now,
        }
        db.table("case_events").insert(event_record).execute()
        saved_events.append(CaseEventResponse(
            id=event_record["id"],
            case_id=request.case_id,
            event_type=event_record["event_type"],
            title=event_record["title"],
            description=event_record["description"],
            due_date=event_record["due_date"],
            is_completed=False,
            created_at=now,
        ))

    return ProceduralResponse(
        case_id=request.case_id,
        events=saved_events,
        summary=result.get("summary"),
    )


@router.post("/checklist", response_model=ProceduralResponse)
async def generate_checklist(
    request: ComplianceChecklistRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    ai: Orchestrator = Depends(get_ai),
):
    """Generate a compliance checklist for an arbitration case (Safety → ProceduralAgent)."""
    case_result = (
        db.table("arbitration_cases")
        .select("*")
        .eq("id", request.case_id)
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not case_result.data:
        raise HTTPException(status_code=404, detail="Case not found")

    case = case_result.data
    result = await ai.do_checklist(case)

    checklist = [
        ComplianceItem(**item)
        for item in result.get("checklist", [])
    ]

    return ProceduralResponse(
        case_id=request.case_id,
        checklist=checklist,
        summary=result.get("summary"),
    )


@router.get("/cases/{case_id}/events", response_model=list[CaseEventResponse])
async def list_case_events(
    case_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """List all events/deadlines for a case."""
    # Verify case ownership
    case = (
        db.table("arbitration_cases")
        .select("id")
        .eq("id", case_id)
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not case.data:
        raise HTTPException(status_code=404, detail="Case not found")

    result = (
        db.table("case_events")
        .select("*")
        .eq("case_id", case_id)
        .order("due_date", desc=False)
        .execute()
    )
    return result.data
