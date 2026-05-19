import json
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from supabase import Client

from ..dependencies import get_current_user_id, get_db, get_ai
from ..agents.orchestrator import Orchestrator
from ..models.schemas import (
    ChatMessageRequest,
    ChatMessageResponse,
    ConversationResponse,
)
from ..models.enums import MessageRole, ConfidenceLevel

router = APIRouter(prefix="/api/v1/chat", tags=["Chat"])


@router.get("/conversations", response_model=list[ConversationResponse])
async def list_conversations(
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """List all conversations for the current user."""
    result = (
        db.table("conversations")
        .select("*")
        .eq("user_id", user_id)
        .order("updated_at", desc=True)
        .execute()
    )
    return result.data


@router.get("/conversations/{conversation_id}/messages", response_model=list[ChatMessageResponse])
async def get_conversation_messages(
    conversation_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Get all messages in a conversation."""
    # Verify ownership
    conv = (
        db.table("conversations")
        .select("id")
        .eq("id", conversation_id)
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not conv.data:
        raise HTTPException(status_code=404, detail="Conversation not found")

    result = (
        db.table("messages")
        .select("*")
        .eq("conversation_id", conversation_id)
        .order("created_at", desc=False)
        .execute()
    )
    return result.data


@router.post("/send", response_model=ChatMessageResponse)
async def send_message(
    request: ChatMessageRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    ai: Orchestrator = Depends(get_ai),
):
    """Send a message and get an AI response (Safety → LLM pipeline)."""
    conversation_id = request.conversation_id

    # Create conversation if none provided
    if not conversation_id:
        conv_data = {
            "id": str(uuid4()),
            "user_id": user_id,
            "title": request.content[:80],
            "jurisdiction": request.jurisdiction,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        db.table("conversations").insert(conv_data).execute()
        conversation_id = conv_data["id"]

    # Save user message
    user_msg = {
        "id": str(uuid4()),
        "conversation_id": conversation_id,
        "user_id": user_id,
        "role": MessageRole.USER.value,
        "content": request.content,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    db.table("messages").insert(user_msg).execute()

    # Fetch conversation history for context
    history = (
        db.table("messages")
        .select("role, content")
        .eq("conversation_id", conversation_id)
        .order("created_at", desc=False)
        .limit(20)
        .execute()
    )

    messages = [{"role": m["role"], "content": m["content"]} for m in history.data]

    # Generate AI response through orchestrator (Safety → LLM → Safety)
    safe_response = await ai.chat(messages, jurisdiction=request.jurisdiction)
    ai_content = safe_response.get("content", "")
    confidence = safe_response.get("confidence", ConfidenceLevel.HIGH.value)
    disclaimer = safe_response.get("disclaimer", "This is legal research assistance only, not legal advice.")

    # Save AI message
    ai_msg = {
        "id": str(uuid4()),
        "conversation_id": conversation_id,
        "user_id": user_id,
        "role": MessageRole.ASSISTANT.value,
        "content": ai_content,
        "confidence": confidence if isinstance(confidence, str) else confidence.value,
        "citations": json.dumps(safe_response.get("citations", [])),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    db.table("messages").insert(ai_msg).execute()

    # Update conversation timestamp
    db.table("conversations").update({
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", conversation_id).execute()

    return ChatMessageResponse(
        id=ai_msg["id"],
        conversation_id=conversation_id,
        role=MessageRole.ASSISTANT,
        content=ai_content,
        confidence=ConfidenceLevel(confidence) if isinstance(confidence, str) else confidence,
        citations=[],
        disclaimer=disclaimer,
        created_at=datetime.now(timezone.utc),
    )


@router.post("/send/stream")
async def send_message_stream(
    request: ChatMessageRequest,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
    ai: Orchestrator = Depends(get_ai),
):
    """Send a message and get a streaming AI response via SSE (Safety pre-checked)."""
    conversation_id = request.conversation_id

    if not conversation_id:
        conv_data = {
            "id": str(uuid4()),
            "user_id": user_id,
            "title": request.content[:80],
            "jurisdiction": request.jurisdiction,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        db.table("conversations").insert(conv_data).execute()
        conversation_id = conv_data["id"]

    # Save user message
    user_msg = {
        "id": str(uuid4()),
        "conversation_id": conversation_id,
        "user_id": user_id,
        "role": MessageRole.USER.value,
        "content": request.content,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    db.table("messages").insert(user_msg).execute()

    # Fetch history
    history = (
        db.table("messages")
        .select("role, content")
        .eq("conversation_id", conversation_id)
        .order("created_at", desc=False)
        .limit(20)
        .execute()
    )
    messages = [{"role": m["role"], "content": m["content"]} for m in history.data]

    async def event_stream():
        full_content = []
        async for chunk in ai.chat_stream(messages, jurisdiction=request.jurisdiction):
            full_content.append(chunk)
            yield f"data: {json.dumps({'content': chunk})}\n\n"

        # Save complete AI response
        complete_content = "".join(full_content)
        ai_msg = {
            "id": str(uuid4()),
            "conversation_id": conversation_id,
            "user_id": user_id,
            "role": MessageRole.ASSISTANT.value,
            "content": complete_content,
            "confidence": ConfidenceLevel.HIGH.value,
            "citations": json.dumps([]),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        db.table("messages").insert(ai_msg).execute()

        yield f"data: {json.dumps({'done': True, 'message_id': ai_msg['id'], 'conversation_id': conversation_id})}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")


@router.delete("/conversations/{conversation_id}")
async def delete_conversation(
    conversation_id: str,
    user_id: str = Depends(get_current_user_id),
    db: Client = Depends(get_db),
):
    """Delete a conversation and all its messages."""
    db.table("messages").delete().eq("conversation_id", conversation_id).execute()
    db.table("conversations").delete().eq("id", conversation_id).eq("user_id", user_id).execute()
    return {"detail": "Conversation deleted"}
