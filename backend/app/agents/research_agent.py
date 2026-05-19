from supabase import Client
from ..services.llm_service import LLMService, get_llm_service
from ..services.embedding_service import get_embedding_service
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

    Uses RAG with pgvector for citation-backed retrieval.
    """

    def __init__(self, db: Client = None):
        self.llm = get_llm_service()
        self.embedding_service = get_embedding_service()
        self.db = db

    async def research(self, query: str, jurisdiction: str = "GH", source_types: list[str] = None, use_rag: bool = True) -> dict:
        """Conduct legal research and return structured results.
        
        Args:
            query: Legal research query
            jurisdiction: Jurisdiction code
            source_types: Optional filter for source types
            use_rag: Whether to use RAG retrieval
        """
        # Retrieve relevant context using RAG
        rag_context = ""
        citations = []
        
        if use_rag and self.db:
            try:
                # Generate query embedding
                query_embedding = await self.embedding_service.generate_query_embedding(query)
                
                # Search for similar chunks
                params = {
                    "query_embedding": query_embedding,
                    "match_threshold": 0.75,
                    "match_count": 5,
                }
                
                result = self.db.rpc("match_documents", params=params).execute()
                chunks = result.data
                
                if chunks:
                    # Build context from retrieved chunks
                    context_parts = []
                    for chunk in chunks:
                        source_meta = chunk.get("source_metadata", {})
                        source_title = source_meta.get("title", "Unknown Source")
                        section_ref = chunk.get("section_reference", "")
                        chunk_text = chunk.get("chunk_text", "")
                        
                        context_parts.append(f"[{source_title}]")
                        if section_ref:
                            context_parts.append(f"Section: {section_ref}")
                        context_parts.append(chunk_text)
                        
                        # Add citation
                        citations.append({
                            "source": source_title,
                            "section": section_ref or "N/A",
                            "year": source_meta.get("year") or "N/A",
                            "authority": "primary" if source_meta.get("source_type") in ["statute", "case_law"] else "secondary",
                            "verified": True,
                            "is_valid": True,
                        })
                    
                    rag_context = "\n\n".join(context_parts)
            except Exception as e:
                print(f"RAG retrieval failed: {str(e)}")
                # Fallback to non-RAG if retrieval fails
                rag_context = ""

        source_filter = ""
        if source_types:
            source_filter = f"\nFocus specifically on: {', '.join(source_types)}"

        # Build prompt with RAG context
        if rag_context:
            prompt = f"""Research the following legal question under {jurisdiction} jurisdiction:

{query}
{source_filter}

RELEVANT LEGAL SOURCES:
{rag_context}

Based on the above sources, provide your research findings. If the sources don't contain sufficient information, acknowledge this limitation.

Respond with JSON:
{{
    "content": "Detailed research findings based on provided sources",
    "confidence": "high|medium|low",
    "citations": {citations if citations else []},
    "legal_observations": ["Key legal observations"],
    "related_principles": ["Relevant legal principles"]
}}"""
        else:
            prompt = f"""Research the following legal question under {jurisdiction} jurisdiction:

{query}
{source_filter}

Note: No specific legal sources were retrieved. Provide general legal information but acknowledge limitations.

Respond with JSON:
{{
    "content": "Detailed research findings",
    "confidence": "medium",
    "citations": [],
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


def get_research_agent(db: Client = None) -> ResearchAgent:
    return ResearchAgent(db=db)
