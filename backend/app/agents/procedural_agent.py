from ..services.llm_service import get_llm_service


PROCEDURAL_SYSTEM_PROMPT = """You are a procedural management specialist for arbitration proceedings under Ghanaian law.

You manage:
- Arbitration timelines based on statutory deadlines
- Hearing schedules
- Filing deadlines
- Procedural calendars
- Compliance checklists

PRIMARY REFERENCES:
- Alternative Dispute Resolution Act, 2010 (Act 798)
- Ghana Arbitration Centre Rules
- UNCITRAL Model Law (as adopted in Ghana)

RULES:
- Base all deadlines on statutory requirements
- Account for court vacation periods and public holidays in Ghana
- Flag any deadlines that may have already passed
- Provide the legal basis for each deadline or requirement"""


class ProceduralAgent:
    """Procedural Management Agent — automates timelines, schedules, and compliance.

    Stub implementation using direct LLM calls.
    Full implementation will integrate with calendar APIs and notification systems.
    """

    def __init__(self):
        self.llm = get_llm_service()

    async def generate_timeline(self, case_data: dict) -> dict:
        """Generate an arbitration timeline based on case details."""
        prompt = f"""Generate a detailed arbitration timeline for:

Case: {case_data.get('case_title', 'Untitled')}
Filing Date: {case_data.get('filing_date', 'Not specified')}
Rules: {case_data.get('arbitration_rules', 'ADR Act 798')}
Parties: {case_data.get('parties', {})}

Respond with JSON:
{{
    "events": [
        {{
            "event_type": "deadline|hearing|filing|milestone",
            "title": "Event title",
            "description": "Description with legal basis",
            "due_date": "ISO 8601 date",
            "is_completed": false,
            "legal_basis": "Statutory reference"
        }}
    ],
    "summary": "Case management summary",
    "warnings": ["Any urgent deadlines or concerns"]
}}"""

        messages = [
            {"role": "system", "content": PROCEDURAL_SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]

        return await self.llm.generate_structured(
            messages=messages,
            response_format={"type": "json_object"},
        )

    async def generate_checklist(self, case_data: dict) -> dict:
        """Generate a compliance checklist for arbitration proceedings."""
        prompt = f"""Generate a compliance checklist for:

Case: {case_data.get('case_title', 'Untitled')}
Rules: {case_data.get('arbitration_rules', 'ADR Act 798')}

Respond with JSON:
{{
    "checklist": [
        {{
            "requirement": "Compliance requirement",
            "status": "pending",
            "due_date": "ISO date or null",
            "notes": "Statutory reference",
            "category": "jurisdictional|procedural|disclosure|fairness|formality"
        }}
    ],
    "summary": "Overall compliance status"
}}"""

        messages = [
            {"role": "system", "content": PROCEDURAL_SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]

        return await self.llm.generate_structured(
            messages=messages,
            response_format={"type": "json_object"},
        )


def get_procedural_agent() -> ProceduralAgent:
    return ProceduralAgent()
