"""LangGraph orchestration DAG for ArbiBot.

Defines a stateful graph that routes user queries through:
  1. Intent classification
  2. Safety pre-check
  3. Domain agent (research / drafting / negotiation / procedural / general chat)
  4. Safety post-check (confidence gating, disclaimer injection)

Usage:
    from .graph import run_graph
    result = await run_graph(messages, jurisdiction="GH")
"""

from __future__ import annotations

from typing import Any, TypedDict

from langgraph.graph import StateGraph, END

from .safety_agent import get_safety_agent
from .research_agent import get_research_agent
from .drafting_agent import get_drafting_agent
from .negotiation_agent import get_negotiation_agent
from .procedural_agent import get_procedural_agent
from ..services.llm_service import get_llm_service
from ..models.enums import ConfidenceLevel


# ── State ─────────────────────────────────────────────────────────────

class GraphState(TypedDict, total=False):
    """Shared state flowing through the graph."""
    messages: list[dict]
    jurisdiction: str
    intent: str
    query: str
    extra: dict
    db: Any
    result: dict
    blocked: bool
    error: str | None


# ── Nodes ─────────────────────────────────────────────────────────────

INTENT_KEYWORDS = {
    "research": ["research", "find", "search", "case law", "statute", "precedent", "citation"],
    "draft": ["draft", "write", "compose", "statement of case", "legal opinion", "submission"],
    "negotiation": ["negotiate", "settlement", "batna", "watna", "mediation", "compromise"],
    "procedural": ["timeline", "checklist", "deadline", "procedure", "compliance", "schedule"],
}


async def classify_intent(state: GraphState) -> GraphState:
    """Classify user intent from the latest message."""
    query = state.get("query", "")
    if not query and state.get("messages"):
        query = state["messages"][-1].get("content", "")

    query_lower = query.lower()

    for intent, keywords in INTENT_KEYWORDS.items():
        if any(kw in query_lower for kw in keywords):
            state["intent"] = intent
            state["query"] = query
            return state

    state["intent"] = "chat"
    state["query"] = query
    return state


async def safety_pre_check(state: GraphState) -> GraphState:
    """Run jurisdiction check before routing to agents."""
    safety = get_safety_agent()
    jurisdiction = state.get("jurisdiction", "GH")
    result = safety.check_jurisdiction(jurisdiction)

    if not result["allowed"]:
        state["blocked"] = True
        state["error"] = result["reason"]
        state["result"] = {"blocked": True, "reason": result["reason"]}
    else:
        state["blocked"] = False

    return state


async def run_chat_agent(state: GraphState) -> GraphState:
    """Handle general chat / Q&A via LLM."""
    llm = get_llm_service()
    messages = state.get("messages", [])
    response = await llm.generate_response(messages)
    state["result"] = {
        "content": response["content"],
        "confidence": ConfidenceLevel.HIGH.value,
        "citations": [],
    }
    return state


async def run_research_agent(state: GraphState) -> GraphState:
    """Delegate to the research agent."""
    db = state.get("db")
    agent = get_research_agent(db)
    query = state.get("query", "")
    jurisdiction = state.get("jurisdiction", "GH")
    result = await agent.research(query, jurisdiction)
    state["result"] = result
    return state


async def run_drafting_agent(state: GraphState) -> GraphState:
    """Delegate to the drafting agent."""
    agent = get_drafting_agent()
    extra = state.get("extra", {})
    result = await agent.generate_draft(
        document_type=extra.get("document_type", "statement_of_case"),
        context=state.get("query", ""),
        jurisdiction=state.get("jurisdiction", "GH"),
        parties=extra.get("parties", {}),
    )
    state["result"] = result
    return state


async def run_negotiation_agent(state: GraphState) -> GraphState:
    """Delegate to the negotiation agent."""
    agent = get_negotiation_agent()
    result = await agent.analyze(
        dispute_summary=state.get("query", ""),
        jurisdiction=state.get("jurisdiction", "GH"),
    )
    state["result"] = result
    return state


async def run_procedural_agent(state: GraphState) -> GraphState:
    """Delegate to the procedural agent."""
    agent = get_procedural_agent()
    extra = state.get("extra", {})
    task = extra.get("task", "timeline")

    if task == "checklist":
        result = await agent.generate_checklist(
            case_type=extra.get("case_type", "commercial_arbitration"),
            rules=extra.get("rules", "ADR Act 2010"),
            jurisdiction=state.get("jurisdiction", "GH"),
        )
    else:
        result = await agent.generate_timeline(
            case_data=extra.get("case_data", {}),
            rules=extra.get("rules", "ADR Act 2010"),
            jurisdiction=state.get("jurisdiction", "GH"),
        )

    state["result"] = result
    return state


async def safety_post_check(state: GraphState) -> GraphState:
    """Run confidence gating and disclaimer injection on the result."""
    safety = get_safety_agent()
    result = state.get("result", {})

    if state.get("blocked"):
        return state

    content = dict(result)
    confidence_str = content.get("confidence", ConfidenceLevel.HIGH.value)
    if isinstance(confidence_str, str):
        try:
            confidence_str = ConfidenceLevel(confidence_str)
        except ValueError:
            confidence_str = ConfidenceLevel.HIGH
    content["confidence"] = confidence_str.value if hasattr(confidence_str, "value") else confidence_str

    final = safety.run(state.get("jurisdiction", "GH"), content)
    state["result"] = final.get("content", final)
    state["blocked"] = final.get("blocked", False)

    if final.get("blocked"):
        state["error"] = final.get("reason")

    return state


# ── Routing ───────────────────────────────────────────────────────────

def route_by_intent(state: GraphState) -> str:
    """Route to the appropriate agent based on classified intent."""
    if state.get("blocked"):
        return "end"
    intent = state.get("intent", "chat")
    return {
        "chat": "chat_agent",
        "research": "research_agent",
        "draft": "drafting_agent",
        "negotiation": "negotiation_agent",
        "procedural": "procedural_agent",
    }.get(intent, "chat_agent")


# ── Graph Construction ────────────────────────────────────────────────

def build_graph() -> StateGraph:
    """Construct the ArbiBot LangGraph DAG."""
    graph = StateGraph(GraphState)

    # Add nodes
    graph.add_node("classify", classify_intent)
    graph.add_node("safety_pre", safety_pre_check)
    graph.add_node("chat_agent", run_chat_agent)
    graph.add_node("research_agent", run_research_agent)
    graph.add_node("drafting_agent", run_drafting_agent)
    graph.add_node("negotiation_agent", run_negotiation_agent)
    graph.add_node("procedural_agent", run_procedural_agent)
    graph.add_node("safety_post", safety_post_check)

    # Edges: entry -> classify -> safety_pre -> conditional routing
    graph.set_entry_point("classify")
    graph.add_edge("classify", "safety_pre")

    # Conditional: safety_pre routes to agent or END
    graph.add_conditional_edges(
        "safety_pre",
        route_by_intent,
        {
            "chat_agent": "chat_agent",
            "research_agent": "research_agent",
            "drafting_agent": "drafting_agent",
            "negotiation_agent": "negotiation_agent",
            "procedural_agent": "procedural_agent",
            "end": END,
        },
    )

    # All agents flow to safety_post
    for agent_node in ["chat_agent", "research_agent", "drafting_agent", "negotiation_agent", "procedural_agent"]:
        graph.add_edge(agent_node, "safety_post")

    # safety_post -> END
    graph.add_edge("safety_post", END)

    return graph


# ── Public API ────────────────────────────────────────────────────────

_compiled_graph = None


def get_compiled_graph():
    """Get or create the compiled graph (singleton)."""
    global _compiled_graph
    if _compiled_graph is None:
        _compiled_graph = build_graph().compile()
    return _compiled_graph


async def run_graph(
    messages: list[dict],
    jurisdiction: str = "GH",
    intent: str | None = None,
    extra: dict | None = None,
    db: Any = None,
) -> dict:
    """Execute the orchestration graph and return the final result.

    Args:
        messages: Conversation history with role/content dicts.
        jurisdiction: Target jurisdiction code.
        intent: Optional pre-classified intent (skips classification if provided).
        extra: Agent-specific parameters.
        db: Supabase client for RAG operations.

    Returns:
        Dict with 'content', 'confidence', 'citations', 'disclaimer', etc.
    """
    graph = get_compiled_graph()

    initial_state: GraphState = {
        "messages": messages,
        "jurisdiction": jurisdiction,
        "query": messages[-1]["content"] if messages else "",
        "extra": extra or {},
        "db": db,
        "blocked": False,
        "error": None,
        "result": {},
    }

    if intent:
        initial_state["intent"] = intent

    final_state = await graph.ainvoke(initial_state)

    if final_state.get("blocked"):
        return {
            "blocked": True,
            "reason": final_state.get("error", "Request blocked by safety checks."),
        }

    return final_state.get("result", {})
