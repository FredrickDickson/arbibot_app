from ..services.llm_service import LLMService, get_llm_service
from ..models.enums import ConfidenceLevel


RESEARCH_SYSTEM_PROMPT = """You are a legal research specialist focused on Ghanaian law.

Your role is to find and present:
- Statutes and legislative provisions
- Case law and judicial decisions
- Legal principles and doctrines
- Relevant precedents

RULES:
- Prioritize official and authoritative Ghanaian sources
- Use structured legal citations in the format: [Authority Name] [Year] [Section/Page]
- Indicate whether authorities remain valid (not repealed or overruled)
- Never fabricate case citations or legal authorities
- If you are uncertain about a citation, say so explicitly
- Distinguish between primary authorities (statutes, case law) and secondary sources"""


class ResearchAgent:
    """Legal Research Agent — searches statutes, case law, principles, and precedents.

    Stub implementation using direct LLM calls.
    Full implementation will use RAG with pgvector for citation-backed retrieval.
    """

    def __init__(self):
        self.llm = get_llm_service()

    async def research(self, query: str, jurisdiction: str = "GH", source_types: list[str] = None) -> dict:
        """Conduct legal research and return structured results."""
        source_filter = ""
        if source_types:
            source_filter = f"\nFocus specifically on: {', '.join(source_types)}"

        prompt = f"""Research the following legal question under {jurisdiction} jurisdiction:

{query}
{source_filter}

Respond with JSON:
{{
    "content": "Detailed research findings",
    "confidence": "high|medium|low",
    "citations": [
        {{
            "source": "Authority name",
            "section": "Section reference",
            "year": "Year",
            "authority": "primary|secondary",
            "verified": false,
            "is_valid": true
        }}
    ],
    "legal_observations": ["Key legal observations"],
    "related_principles": ["Relevant legal principles"]
}}"""

        messages = [
            {"role": "system", "content": RESEARCH_SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]

        result = await self.llm.generate_structured(
            messages=messages,
            response_format={"type": "json_object"},
        )

        return result


def get_research_agent() -> ResearchAgent:
    return ResearchAgent()
