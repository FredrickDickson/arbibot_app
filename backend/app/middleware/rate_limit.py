from slowapi import Limiter
from slowapi.util import get_remote_address
from fastapi import Request

from ..config import get_settings


def _get_user_or_ip(request: Request) -> str:
    """Rate limit by user_id if authenticated, otherwise by IP."""
    user_id = getattr(request.state, "user_id", None)
    if user_id:
        return user_id
    return get_remote_address(request)


settings = get_settings()
limiter = Limiter(
    key_func=_get_user_or_ip,
    default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"],
)
