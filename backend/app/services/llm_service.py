import json
from typing import AsyncGenerator
from openai import AsyncOpenAI

from ..config import get_settings

ARBIBOT_SYSTEM_PROMPT = """You are ArbiBot, a jurisdiction-aware legal intelligence system focused on Ghanaian law, mediation, arbitration, and professional legal workflows.

CORE CAPABILITIES:
- Legal research: Statutes, case law, legal principles, relevant precedents
- Document drafting: Statement of Case, Legal Opinion, Submission
- Procedural management: Arbitration timelines, hearing schedules, filing deadlines
- Negotiation support: Settlement strategy, BATNA/WATNA analysis, mediation prep

JURISDICTION: Ghana (primary). Prioritize official and authoritative sources. Use structured legal citations. Indicate whether authorities remain valid.

KEY LEGAL SOURCES:
- Alternative Dispute Resolution Act, 2010 (Act 798)
- Arbitration Act, 1961 (Act 38)
- Constitution of Ghana, 1992
- Courts Act, 1993 (Act 459)
- Ghana Arbitration Centre Rules

ETHICS & CONFIDENTIALITY:
- Preserve confidentiality at all times
- Distinguish legal information from legal advice
- Never fabricate legal authorities or case citations
- Never produce biased awards
- Never ignore jurisdictional requirements
- Maintain professional legal standards

RESPONSE FORMAT (for every task):
1. Identify document type
2. Confirm jurisdiction
3. Request missing information if needed
4. Generate draft or analysis
5. Provide legal observations
6. Suggest optional clauses where applicable
7. Provide plain-English explanation

Always prioritize: Accuracy, Enforceability, Clarity, Efficiency, Procedural fairness.

You are NOT a general chatbot. You do NOT provide final legal advice. All outputs are drafts or research assistance only."""


class LLMService:
    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        self.model = "gpt-4o"

    async def generate_response(
        self,
        messages: list[dict],
        temperature: float = 0.3,
        max_tokens: int = 4096,
    ) -> dict:
        """Generate a non-streaming response from the LLM."""
        system_messages = [{"role": "system", "content": ARBIBOT_SYSTEM_PROMPT}]
        all_messages = system_messages + messages

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=all_messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )

        return {
            "content": response.choices[0].message.content,
            "usage": {
                "prompt_tokens": response.usage.prompt_tokens,
                "completion_tokens": response.usage.completion_tokens,
            },
        }

    async def generate_stream(
        self,
        messages: list[dict],
        temperature: float = 0.3,
        max_tokens: int = 4096,
    ) -> AsyncGenerator[str, None]:
        """Generate a streaming response from the LLM via SSE."""
        system_messages = [{"role": "system", "content": ARBIBOT_SYSTEM_PROMPT}]
        all_messages = system_messages + messages

        stream = await self.client.chat.completions.create(
            model=self.model,
            messages=all_messages,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=True,
        )

        async for chunk in stream:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content

    async def generate_structured(
        self,
        messages: list[dict],
        response_format: dict | None = None,
        temperature: float = 0.2,
        max_tokens: int = 4096,
    ) -> dict:
        """Generate a structured JSON response from the LLM."""
        system_messages = [{"role": "system", "content": ARBIBOT_SYSTEM_PROMPT}]
        all_messages = system_messages + messages

        kwargs = {
            "model": self.model,
            "messages": all_messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if response_format:
            kwargs["response_format"] = response_format

        response = await self.client.chat.completions.create(**kwargs)
        content = response.choices[0].message.content

        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return {"content": content, "raw": True}


def get_llm_service() -> LLMService:
    return LLMService()
