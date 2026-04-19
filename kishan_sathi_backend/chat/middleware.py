from urllib.parse import parse_qs

from channels.auth import AuthMiddlewareStack
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from django.db import close_old_connections
from rest_framework.authtoken.models import Token


@database_sync_to_async
def _get_user_from_token(token_key):
    try:
        return Token.objects.select_related('user').get(key=token_key).user
    except Token.DoesNotExist:
        return AnonymousUser()


class TokenAuthMiddleware:
    """Authenticate websocket users with DRF token from query string."""

    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        close_old_connections()

        user = scope.get('user')
        if user is None or not user.is_authenticated:
            token_key = self._extract_token(scope)
            scope['user'] = (
                await _get_user_from_token(token_key)
                if token_key
                else AnonymousUser()
            )

        return await self.inner(scope, receive, send)

    @staticmethod
    def _extract_token(scope):
        raw_query = scope.get('query_string', b'').decode()
        query_params = parse_qs(raw_query)
        token = (query_params.get('token') or [None])[0]

        if not token:
            return None

        normalized = token.strip()
        lower = normalized.lower()
        if lower.startswith('token '):
            return normalized[6:].strip()
        if lower.startswith('bearer '):
            return normalized[7:].strip()
        return normalized


def TokenAuthMiddlewareStack(inner):
    return TokenAuthMiddleware(AuthMiddlewareStack(inner))
