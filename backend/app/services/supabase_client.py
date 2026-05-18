from supabase import create_client, Client
from functools import lru_cache

from ..config import get_settings


@lru_cache()
def get_supabase_client() -> Client:
    """Get Supabase client using the service role key (backend-only operations)."""
    settings = get_settings()
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)


@lru_cache()
def get_supabase_anon_client() -> Client:
    """Get Supabase client using the anon key (user-scoped operations)."""
    settings = get_settings()
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)


def get_supabase_auth_client(access_token: str) -> Client:
    """Get a Supabase client authenticated with a user's access token."""
    settings = get_settings()
    client = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)
    client.auth.set_session(access_token, "")
    return client
