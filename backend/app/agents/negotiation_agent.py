from ..services.llm_service import get_llm_service


NEGOTIATION_SYSTEM_PROMPT = """You are a negotiation and settlement analysis specialist focused on Ghanaian legal disputes.

You assist with:
- Settlement strategy development
- Negotiation summaries
- BATNA (Best Alternative to Negotiated Agreement) analysis
- WATNA (Worst Alternative to Negotiated Agreement) analysis
- Risk-adjusted settlement ranges
- Mediation preparation briefs

RULES:
- This is analytical support ONLY, never a legal decision
- Never recommend a specific settlement amount as binding
- Consider costs of litigation/arbitration in all value assessments
- Base analysis on Ghanaian legal principles and precedent outcomes
- Identify key leverage points for each party
- Account for enforcement practicalities in Ghana
- Maintain neutrality — do not advocate for either party"""


class NegotiationAgent:
    """Negotiation Support Agent — provides settlement and mediation analysis.

    Stub implementation using direct LLM calls.
    Full implementation will integrate case history and precedent database.
    """

    def __init__(self):
        self.llm = get_llm_service()

    async def analyze(self, dispute_summary: str, party_positions: dict, jurisdiction: str = "GH") -> dict:
        """Generate BATNA/WATNA analysis and settlement strategy."""
        prompt = f"""Provide a comprehensive negotiation analysis for:

Dispute: {dispute_summary}
Party Positions: {party_positions}
Jurisdiction: {jurisdiction}

Respond with JSON:
{{
    "batna": [
        {{
            "scenario": "Best alternative scenario",
            "likelihood": "high|medium|low",
            "outcome_description": "Description",
            "estimated_value": "Value estimate"
        }}
    ],
    "watna": [
        {{
            "scenario": "Worst alternative scenario",
            "likelihood": "high|medium|low",
            "outcome_description": "Description",
            "estimated_value": "Value estimate"
        }}
    ],
    "settlement_range": {{
        "minimum": "Floor value",
        "maximum": "Ceiling value",
        "recommended_zone": "ZOPA description",
        "risk_factors": ["Risk factors"]
    }},
    "strategy_notes": "Strategic recommendations",
    "mediation_brief": "Mediation preparation notes",
    "key_leverage_points": {{
        "claimant": ["Claimant leverage points"],
        "respondent": ["Respondent leverage points"]
    }}
}}"""

        messages = [
            {"role": "system", "content": NEGOTIATION_SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]

        return await self.llm.generate_structured(
            messages=messages,
            response_format={"type": "json_object"},
        )


def get_negotiation_agent() -> NegotiationAgent:
    return NegotiationAgent()
