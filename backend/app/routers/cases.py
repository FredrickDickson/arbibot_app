from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from ..dependencies import get_current_user_id, get_db
from ..models.schemas import CaseCreateRequest, CaseResponse
from ..models.enums import CaseStatus

router = APIRouter(prefix="/api/v1/cases", tags=["Arbitration Cases"])


@router.post("/", response_model=CaseResponse)
async def create_case(
    request: CaseCreateRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Create a new arbitration case."""
    now = datetime.now(timezone.utc).isoformat()
    case_id = str(uuid4())

    record = {
        "id": case_id,
        "user_id": user_id,
        "case_title": request.case_title,
        "case_number": request.case_number,
        "parties": request.parties,
        "arbitration_rules": request.arbitration_rules,
        "jurisdiction": request.jurisdiction,
        "filing_date": request.filing_date.isoformat() if request.filing_date else None,
        "status": CaseStatus.ACTIVE.value,
        "created_at": now,
        "updated_at": now,
    }
    db.table("arbitration_cases").insert(record).execute()

    return CaseResponse(
        id=case_id,
        case_title=request.case_title,
        case_number=request.case_number,
        parties=request.parties,
        arbitration_rules=request.arbitration_rules,
        jurisdiction=request.jurisdiction,
        filing_date=request.filing_date,
        status=CaseStatus.ACTIVE,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )


@router.get("/", response_model=list[CaseResponse])
async def list_cases(
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """List all arbitration cases for the current user."""
    result = (
        db.table("arbitration_cases")
        .select("*")
        .eq("user_id", user_id)
        .order("updated_at", desc=True)
        .execute()
    )
    return result.data


@router.get("/{case_id}", response_model=CaseResponse)
async def get_case(
    case_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Get a specific arbitration case."""
    result = (
        db.table("arbitration_cases")
        .select("*")
        .eq("id", case_id)
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Case not found")
    return result.data


@router.put("/{case_id}", response_model=CaseResponse)
async def update_case(
    case_id: str,
    request: CaseCreateRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Update an arbitration case."""
    now = datetime.now(timezone.utc).isoformat()

    update_data = {
        "case_title": request.case_title,
        "case_number": request.case_number,
        "parties": request.parties,
        "arbitration_rules": request.arbitration_rules,
        "jurisdiction": request.jurisdiction,
        "filing_date": request.filing_date.isoformat() if request.filing_date else None,
        "updated_at": now,
    }

    result = (
        db.table("arbitration_cases")
        .update(update_data)
        .eq("id", case_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Case not found")
    return result.data[0]


@router.delete("/{case_id}")
async def delete_case(
    case_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Delete an arbitration case and related events."""
    db.table("case_events").delete().eq("case_id", case_id).execute()
    db.table("arbitration_cases").delete().eq("id", case_id).eq("user_id", user_id).execute()
    return {"detail": "Case deleted"}
