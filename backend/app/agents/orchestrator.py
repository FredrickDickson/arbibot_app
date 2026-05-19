"""Central orchestrator — routes requests through Safety Agent before delegating to
the appropriate domain agent. Every AI-facing endpoint should call through here."""

from fastapi import HTTPException

from .safety_agent import SafetyAgent, get_safety_agent
from .research_agent import ResearchAgent, get_research_agent
from .drafting_agent import DraftingAgent, get_drafting_agent
from .negotiation_agent import NegotiationAgent, get_negotiation_agent
from .procedural_agent import ProceduralAgent, get_procedural_agent
from ..services.llm_service import LLMService, get_llm_service
from ..models.enums import ConfidenceLevel


class Orchestrator:
    """Runs Safety checks then delegates to the right agent."""

    def __init__(self, db=None):
        self.safety = get_safety_agent()
        self.research = get_research_agent(db)
        self.drafting = get_drafting_agent()
        self.negotiation = get_negotiation_agent()
        self.procedural = get_procedural_agent()
        self.llm = get_llm_service()

    # ── helpers ───────────────────────────────────────────────────────

    def _enforce_safety(self, jurisdiction: str, content: dict) -> dict:
        """Run safety checks; raise 422 if blocked."""
        result = self.safety.run(jurisdiction, content)
        if result.get("blocked"):
            raise HTTPException(status_code=422, detail=result["reason"])
        return result.get("content", content)

    # ── chat ──────────────────────────────────────────────────────────

    async def chat(
        self, messages: list[dict], jurisdiction: str = "GH"
    ) -> dict:
        """General chat — Safety → LLM → Safety post-check."""
        # Pre-check jurisdiction
        jur = self.safety.check_jurisdiction(jurisdiction)
        if not jur["allowed"]:
            raise HTTPException(status_code=422, detail=jur["reason"])

        response = await self.llm.generate_response(messages)
        content = {"content": response["content"], "confidence": ConfidenceLevel.HIGH.value}
        safe = self._enforce_safety(jurisdiction, content)
        return safe

    async def chat_stream(
        self, messages: list[dict], jurisdiction: str = "GH"
    ):
        """Streaming chat — safety pre-check, then stream tokens."""
        jur = self.safety.check_jurisdiction(jurisdiction)
        if not jur["allowed"]:
            raise HTTPException(status_code=422, detail=jur["reason"])

        async for chunk in self.llm.generate_stream(messages):
            yield chunk

    # ── research ──────────────────────────────────────────────────────

    async def do_research(
        self, query: str, jurisdiction: str = "GH", source_types: list[str] | None = None
    ) -> dict:
        """Safety → ResearchAgent → Safety post-check."""
        jur = self.safety.check_jurisdiction(jurisdiction)
        if not jur["allowed"]:
            raise HTTPException(status_code=422, detail=jur["reason"])

        result = await self.research.research(query, jurisdiction, source_types)
        safe = self._enforce_safety(jurisdiction, result)
        return safe

    # ── drafting ──────────────────────────────────────────────────────

    async def do_draft(
        self, document_type, title: str, context: str, jurisdiction: str = "GH"
    ) -> dict:
        """Safety → DraftingAgent → Safety post-check."""
        jur = self.safety.check_jurisdiction(jurisdiction)
        if not jur["allowed"]:
            raise HTTPException(status_code=422, detail=jur["reason"])

        result = await self.drafting.generate_draft(document_type, title, context, jurisdiction)
        safe = self._enforce_safety(jurisdiction, result)
        return safe

    # ── negotiation ───────────────────────────────────────────────────

    async def do_negotiation(
        self, dispute_summary: str, party_positions: dict, jurisdiction: str = "GH"
    ) -> dict:
        """Safety → NegotiationAgent → Safety post-check."""
        jur = self.safety.check_jurisdiction(jurisdiction)
        if not jur["allowed"]:
            raise HTTPException(status_code=422, detail=jur["reason"])

        result = await self.negotiation.analyze(dispute_summary, party_positions, jurisdiction)
        safe = self._enforce_safety(jurisdiction, result)
        return safe

    # ── procedural ────────────────────────────────────────────────────

    async def do_timeline(self, case_data: dict) -> dict:
        """Safety → ProceduralAgent.generate_timeline → Safety post-check."""
        jurisdiction = case_data.get("jurisdiction", "GH")
        jur = self.safety.check_jurisdiction(jurisdiction)
        if not jur["allowed"]:
            raise HTTPException(status_code=422, detail=jur["reason"])

        result = await self.procedural.generate_timeline(case_data)
        safe = self._enforce_safety(jurisdiction, result)
        return safe

    async def do_checklist(self, case_data: dict) -> dict:
        """Safety → ProceduralAgent.generate_checklist → Safety post-check."""
        jurisdiction = case_data.get("jurisdiction", "GH")
        jur = self.safety.check_jurisdiction(jurisdiction)
        if not jur["allowed"]:
            raise HTTPException(status_code=422, detail=jur["reason"])

        result = await self.procedural.generate_checklist(case_data)
        safe = self._enforce_safety(jurisdiction, result)
        return safe


    # ── graph-based routing (auto intent classification) ──────────────

    async def chat_graph(
        self, messages: list[dict], jurisdiction: str = "GH", extra: dict | None = None
    ) -> dict:
        """Route through the LangGraph DAG with automatic intent classification."""
        from .graph import run_graph
        return await run_graph(messages, jurisdiction=jurisdiction, extra=extra, db=self.research.db)


_orchestrator: Orchestrator | None = None


def get_orchestrator(db=None) -> Orchestrator:
    return Orchestrator(db=db)
