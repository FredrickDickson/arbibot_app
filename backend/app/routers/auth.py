from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client

from ..dependencies import get_anon_db
from ..models.schemas import (
    AuthSignupRequest,
    AuthLoginRequest,
    AuthTokenResponse,
    AuthRefreshRequest,
    ProfileResponse,
    ErrorResponse,
)

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


@router.post("/signup", response_model=AuthTokenResponse, responses={400: {"model": ErrorResponse}})
async def signup(request: AuthSignupRequest, db: Client = Depends(get_anon_db)):
    """Register a new user with Supabase Auth and create a profile."""
    try:
        auth_response = db.auth.sign_up({
            "email": request.email,
            "password": request.password,
            "options": {
                "data": {
                    "full_name": request.full_name,
                    "title": request.title,
                    "organization": request.organization,
                }
            },
        })

        if not auth_response.user:
            raise HTTPException(status_code=400, detail="Signup failed")

        # Create profile record
        db.table("profiles").insert({
            "id": auth_response.user.id,
            "full_name": request.full_name,
            "title": request.title,
            "organization": request.organization,
        }).execute()

        return AuthTokenResponse(
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_id=auth_response.user.id,
            expires_at=auth_response.session.expires_at,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=AuthTokenResponse, responses={401: {"model": ErrorResponse}})
async def login(request: AuthLoginRequest, db: Client = Depends(get_anon_db)):
    """Authenticate a user and return access/refresh tokens."""
    try:
        auth_response = db.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password,
        })

        if not auth_response.user:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        return AuthTokenResponse(
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_id=auth_response.user.id,
            expires_at=auth_response.session.expires_at,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/refresh", response_model=AuthTokenResponse)
async def refresh_token(request: AuthRefreshRequest, db: Client = Depends(get_anon_db)):
    """Refresh an expired access token."""
    try:
        auth_response = db.auth.refresh_session(request.refresh_token)

        return AuthTokenResponse(
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_id=auth_response.user.id,
            expires_at=auth_response.session.expires_at,
        )
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))
