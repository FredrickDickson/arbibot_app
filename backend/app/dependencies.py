from fastapi import Depends, Request, HTTPException, status

from .services.supabase_client import get_supabase_client, get_supabase_anon_client
from .services.llm_service import get_llm_service, LLMService
from .config import get_settings, Settings


async def get_current_user_id(request: Request) -> str:
    """Extract the authenticated user's ID from the request state.
    Set by the auth middleware."""
    user_id = getattr(request.state, "user_id", None)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
        )
    return user_id


async def get_db():
    """Get the Supabase service-role client for backend operations."""
    return get_supabase_client()


async def get_anon_db():
    """Get the Supabase anon client."""
    return get_supabase_anon_client()


async def get_llm() -> LLMService:
    """Get the LLM service instance."""
    return get_llm_service()


async def get_app_settings() -> Settings:
    """Get application settings."""
    return get_settings()
