from ..services.llm_service import LLMService, get_llm_service
from ..models.enums import DocumentType


DRAFTING_SYSTEM_PROMPT = """You are a legal document drafting specialist focused on Ghanaian law.

You draft the following document types:
1. Statement of Case — formal statement of facts, legal issues, and arguments for arbitration
2. Legal Opinion — professional legal analysis with expert interpretation
3. Submission — formal arguments submitted to tribunals or courts

RULES:
- Use formal legal language appropriate for Ghanaian jurisdiction
- Structure documents with clear numbered sections
- Include relevant statutory and case law references
- All outputs are DRAFTS requiring mandatory human review and approval
- Never present a draft as final legal advice
- Include citations for all legal claims
- Never fabricate legal authorities"""

DOCUMENT_TEMPLATES = {
    DocumentType.STATEMENT_OF_CASE: [
        "1. Introduction and Background",
        "2. Statement of Facts",
        "3. Legal Issues",
        "4. Legal Arguments",
        "5. Relief Sought",
        "6. Supporting Authorities",
    ],
    DocumentType.LEGAL_OPINION: [
        "1. Introduction and Background",
        "2. Legal Framework and Applicable Law",
        "3. Analysis",
        "4. Conclusion and Recommendations",
    ],
    DocumentType.SUBMISSION: [
        "1. Preliminary Matters",
        "2. Summary of Facts",
        "3. Legal Arguments",
        "4. Authorities Relied Upon",
        "5. Conclusion and Prayer",
    ],
}


class DraftingAgent:
    """Drafting Agent — generates legal documents using retrieved sources.

    Stub implementation using direct LLM calls.
    Full implementation will use LangGraph with Research Agent output as input.
    """

    def __init__(self):
        self.llm = get_llm_service()

    async def generate_draft(
        self,
        document_type: DocumentType,
        title: str,
        context: str,
        jurisdiction: str = "GH",
    ) -> dict:
        """Generate a structured legal document draft."""
        template_sections = DOCUMENT_TEMPLATES.get(document_type, [])
        sections_str = "\n".join(f"- {s}" for s in template_sections)

        prompt = f"""Draft a {document_type.value.replace('_', ' ').title()} for the following matter:

Title: {title}
Jurisdiction: {jurisdiction}
Context: {context}

Use these sections as a guide:
{sections_str}

Respond with JSON:
{{
    "sections": [
        {{
            "title": "Section title",
            "content": "Section content with proper legal language",
            "confidence": "high|medium|low",
            "citations": ["Citation strings"]
        }}
    ],
    "citations": [
        {{
            "source": "Authority name",
            "section": "Section reference",
            "year": "Year",
            "authority": "primary|secondary",
            "verified": false
        }}
    ],
    "legal_observations": ["Important observations"],
    "optional_clauses": ["Optional clauses to consider"],
    "plain_english_explanation": "Plain-English summary"
}}"""

        messages = [
            {"role": "system", "content": DRAFTING_SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]

        result = await self.llm.generate_structured(
            messages=messages,
            response_format={"type": "json_object"},
        )

        return result


def get_drafting_agent() -> DraftingAgent:
    return DraftingAgent()
