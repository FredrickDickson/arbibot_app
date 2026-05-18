from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends
from supabase import Client

from ..dependencies import get_current_user_id, get_db, get_llm
from ..services.llm_service import LLMService
from ..models.schemas import ResearchRequest, ResearchResult
from ..models.enums import ConfidenceLevel

router = APIRouter(prefix="/api/v1/research", tags=["Legal Research"])


@router.post("/", response_model=ResearchResult)
async def conduct_research(
    request: ResearchRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    llm: LLMService = Depends(get_llm),
):
    """Conduct structured legal research with citation-backed results.

    Searches Ghanaian statutes, case law, legal principles, and precedents.
    Returns structured results with confidence indicators and citations.
    """
    source_filter = ""
    if request.source_types:
        types_str = ", ".join(st.value for st in request.source_types)
        source_filter = f"\nFocus on these source types: {types_str}"

    research_prompt = f"""Conduct legal research for the following query under {request.jurisdiction} jurisdiction.

Query: {request.query}
{source_filter}

Provide your response as JSON with this structure:
{{
    "content": "Detailed research findings with structured legal analysis",
    "confidence": "high|medium|low",
    "citations": [
        {{
            "source": "Full name of the legal authority",
            "section": "Specific section or paragraph reference",
            "page": null,
            "year": "Year of the authority",
            "authority": "primary|secondary|persuasive",
            "verified": false
        }}
    ],
    "legal_observations": ["List of important legal observations"],
    "disclaimer": "This is legal research assistance only, not legal advice."
}}

IMPORTANT:
- Prioritize official and authoritative Ghanaian sources
- Use structured legal citations
- Indicate whether authorities remain valid
- Never fabricate case citations or legal authorities
- If uncertain about a citation, mark verified as false"""

    messages = [{"role": "user", "content": research_prompt}]

    result = await llm.generate_structured(
        messages=messages,
        response_format={"type": "json_object"},
    )

    # Handle both structured and raw responses
    if result.get("raw"):
        return ResearchResult(
            content=result.get("content", ""),
            confidence=ConfidenceLevel.MEDIUM,
            citations=[],
            jurisdiction=request.jurisdiction,
            legal_observations=[],
            disclaimer="This is legal research assistance only, not legal advice.",
        )

    return ResearchResult(
        content=result.get("content", ""),
        confidence=ConfidenceLevel(result.get("confidence", "medium")),
        citations=result.get("citations", []),
        jurisdiction=request.jurisdiction,
        legal_observations=result.get("legal_observations", []),
        disclaimer=result.get("disclaimer", "This is legal research assistance only, not legal advice."),
    )
