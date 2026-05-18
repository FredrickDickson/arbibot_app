from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
import httpx

from ..config import get_settings

PUBLIC_PATHS = {
    "/",
    "/health",
    "/docs",
    "/redoc",
    "/openapi.json",
    "/api/v1/auth/login",
    "/api/v1/auth/signup",
    "/api/v1/auth/refresh",
}


class SupabaseAuthMiddleware(BaseHTTPMiddleware):
    """Middleware that verifies Supabase JWT tokens.
    Extracts user_id and injects it into request.state."""

    async def dispatch(self, request: Request, call_next):
        if request.url.path in PUBLIC_PATHS or request.method == "OPTIONS":
            return await call_next(request)

        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid Authorization header",
            )

        token = auth_header.split("Bearer ")[1]

        try:
            user = await self._verify_token(token)
            request.state.user_id = user["id"]
            request.state.access_token = token
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
            )

        return await call_next(request)

    async def _verify_token(self, token: str) -> dict:
        """Verify the JWT by calling Supabase's auth.getUser endpoint."""
        settings = get_settings()
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.SUPABASE_URL}/auth/v1/user",
                headers={
                    "Authorization": f"Bearer {token}",
                    "apikey": settings.SUPABASE_ANON_KEY,
                },
            )
            if response.status_code != 200:
                raise ValueError("Token verification failed")
            return response.json()
