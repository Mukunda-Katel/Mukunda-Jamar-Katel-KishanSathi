"""
ChatConsumer – AsyncWebsocketConsumer for 1-to-1 real-time chat.

Auth is handled *inside* connect() via query-string token.
Supports JWT (simplejwt AccessToken) with DRF Token fallback.

WebSocket URL:
    ws(s)://<host>/ws/chat/<chat_room_id>/?token=<token>

Inbound message types:
    chat_message  – send a text message
    typing        – typing indicator
    mark_read     – mark specific message IDs as read

Outbound (group) event handlers:
    chat_message      – broadcast new message
    typing_indicator   – broadcast typing state (excluded for sender)
    messages_read      – broadcast read-receipt
"""

import json
import logging
from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth import get_user_model
from django.utils import timezone

from .models import ChatRoom, Message

User = get_user_model()
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helpers: token → user
# ---------------------------------------------------------------------------

@database_sync_to_async
def _get_user_from_jwt(raw_token: str):
    """Validate a simplejwt AccessToken and return the User, or None."""
    try:
        from rest_framework_simplejwt.tokens import AccessToken
        access = AccessToken(raw_token)
        user_id = access['user_id']
        return User.objects.get(pk=user_id)
    except Exception:
        return None


@database_sync_to_async
def _get_user_from_drf_token(raw_token: str):
    """Validate a DRF authtoken and return the User, or None."""
    try:
        from rest_framework.authtoken.models import Token
        return Token.objects.select_related('user').get(key=raw_token).user
    except Exception:
        return None


def _extract_token(scope) -> str | None:
    """Pull the raw token string out of the query-string ``?token=…``."""
    raw_qs = scope.get('query_string', b'').decode('utf-8')
    params = parse_qs(raw_qs)
    values = params.get('token')
    if not values:
        return None
    token = values[0].strip()
    # Strip common prefixes the client may accidentally include.
    lower = token.lower()
    if lower.startswith('token '):
        return token[6:].strip()
    if lower.startswith('bearer '):
        return token[7:].strip()
    return token


# ---------------------------------------------------------------------------
# Consumer
# ---------------------------------------------------------------------------

class ChatConsumer(AsyncWebsocketConsumer):
    """Real-time 1-to-1 chat consumer with in-consumer auth."""

    # ---- lifecycle -----------------------------------------------------------

    async def connect(self):
        self.chat_room_id = self.scope['url_route']['kwargs']['chat_room_id']
        self.room_group_name = f'chat_{self.chat_room_id}'
        self.user = None

        # 1. Extract token from query string
        raw_token = _extract_token(self.scope)
        if not raw_token:
            await self.close(code=4001)
            return

        # 2. Authenticate – try JWT first, then DRF Token
        user = await _get_user_from_jwt(raw_token)
        if user is None:
            user = await _get_user_from_drf_token(raw_token)
        if user is None:
            await self.close(code=4001)
            return

        self.user = user

        # 3. Authorise – user must be a participant in the room
        chat_room = await self._get_chat_room()
        if chat_room is None:
            await self.close(code=4003)
            return

        is_member = await database_sync_to_async(chat_room.is_participant)(self.user)
        if not is_member:
            await self.close(code=4003)
            return

        # 4. Join the channel-layer group and accept
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name,
        )
        await self.accept()

        # 5. Confirm connection to the client
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'chat_room_id': int(self.chat_room_id),
            'user_id': self.user.pk,
        }))

    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name,
            )

    # ---- receive (inbound from client) ---------------------------------------

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
        except json.JSONDecodeError:
            await self._send_error('Invalid JSON format')
            return

        msg_type = data.get('type', '')

        try:
            if msg_type == 'chat_message':
                await self._handle_chat_message(data)
            elif msg_type == 'typing':
                await self._handle_typing(data)
            elif msg_type == 'mark_read':
                await self._handle_mark_read(data)
            # Backward compat: old client sends type="message"
            elif msg_type == 'message':
                await self._handle_chat_message_legacy(data)
            # Backward compat: old client sends type="read_receipt"
            elif msg_type == 'read_receipt':
                await self._handle_read_receipt_legacy()
            else:
                await self._send_error(f'Unknown message type: {msg_type}')
        except Exception as exc:
            logger.exception('Error processing WS message type=%s', msg_type)
            await self._send_error(str(exc))

    # ---- inbound handlers ----------------------------------------------------

    async def _handle_chat_message(self, data: dict):
        content = (data.get('content') or '').strip()
        message_type = data.get('message_type', 'text')

        if not content:
            await self._send_error('Message content cannot be empty')
            return

        message = await self._save_message(content, message_type)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': {
                    'message_id': message.pk,
                    'sender_id': self.user.pk,
                    'sender_name': self.user.full_name,
                    'content': message.content,
                    'message_type': message.message_type,
                    'created_at': message.created_at.isoformat(),
                    'is_read': False,
                },
            },
        )

        # Fire-and-forget push notification
        await self._send_push_notification(message)

    async def _handle_chat_message_legacy(self, data: dict):
        """Support the old ``{ "type": "message", "message": "Hi" }`` format."""
        content = (data.get('message') or data.get('content') or '').strip()
        if not content:
            await self._send_error('Message content cannot be empty')
            return

        message = await self._save_message(content, 'text')

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': {
                    'message_id': message.pk,
                    'id': message.pk,
                    'sender_id': self.user.pk,
                    'sender_name': self.user.full_name,
                    'content': message.content,
                    'message_type': message.message_type,
                    'created_at': message.created_at.isoformat(),
                    'timestamp': message.created_at.isoformat(),
                    'is_read': False,
                    'chat_room': int(self.chat_room_id),
                    'sender': {
                        'id': self.user.pk,
                        'full_name': self.user.full_name,
                        'role': self.user.role,
                    },
                    'image_url': None,
                },
            },
        )

    async def _handle_typing(self, data: dict):
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_indicator',
                'user_id': self.user.pk,
                'is_typing': bool(data.get('is_typing', False)),
            },
        )

    async def _handle_mark_read(self, data: dict):
        message_ids = data.get('message_ids', [])
        if not isinstance(message_ids, list) or not message_ids:
            await self._send_error('message_ids must be a non-empty list')
            return

        read_at = timezone.now()
        await self._mark_messages_read(message_ids, read_at)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'messages_read',
                'message_ids': message_ids,
                'read_by': self.user.pk,
                'read_at': read_at.isoformat(),
            },
        )

    async def _handle_read_receipt_legacy(self):
        """Old protocol: mark ALL unread messages in this room."""
        await self._mark_all_messages_read()
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'read_receipt',
                'user_id': self.user.pk,
            },
        )

    # ---- group event handlers (outbound to WebSocket) ------------------------

    async def chat_message(self, event):
        """Broadcast a new message to every connected participant."""
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': event['message'],
        }))

    async def typing_indicator(self, event):
        """Send typing status – only to the *other* user (skip sender)."""
        if event['user_id'] != self.user.pk:
            await self.send(text_data=json.dumps({
                'type': 'typing',
                'user_id': event['user_id'],
                'is_typing': event['is_typing'],
            }))

    async def messages_read(self, event):
        """Notify all participants that messages were read."""
        await self.send(text_data=json.dumps({
            'type': 'messages_read',
            'message_ids': event['message_ids'],
            'read_by': event['read_by'],
            'read_at': event['read_at'],
        }))

    async def read_receipt(self, event):
        """Legacy read-receipt broadcast."""
        await self.send(text_data=json.dumps({
            'type': 'read_receipt',
            'user_id': event['user_id'],
        }))

    # ---- DB helpers ----------------------------------------------------------

    @database_sync_to_async
    def _get_chat_room(self):
        try:
            return ChatRoom.objects.get(pk=self.chat_room_id)
        except ChatRoom.DoesNotExist:
            return None

    @database_sync_to_async
    def _save_message(self, content: str, message_type: str = 'text'):
        chat_room = ChatRoom.objects.get(pk=self.chat_room_id)
        message = Message.objects.create(
            chat_room=chat_room,
            sender=self.user,
            content=content,
            message_type=message_type,
        )
        # Update last_message_at
        ChatRoom.objects.filter(pk=self.chat_room_id).update(
            last_message_at=message.created_at,
        )
        return message

    @database_sync_to_async
    def _mark_messages_read(self, message_ids: list, read_at):
        """Mark specific messages as read (exclude messages sent by this user)."""
        Message.objects.filter(
            pk__in=message_ids,
            chat_room_id=self.chat_room_id,
        ).exclude(
            sender=self.user,
        ).update(is_read=True, read_at=read_at)

    @database_sync_to_async
    def _mark_all_messages_read(self):
        """Mark every unread message from the other user as read."""
        now = timezone.now()
        Message.objects.filter(
            chat_room_id=self.chat_room_id,
            is_read=False,
        ).exclude(
            sender=self.user,
        ).update(is_read=True, read_at=now)

    async def _send_push_notification(self, message):
        """Send FCM push to the other participant (best-effort)."""
        try:
            await self._do_send_push(message)
        except Exception as exc:
            logger.warning('Push notification failed for room %s: %s', self.chat_room_id, exc)

    @database_sync_to_async
    def _do_send_push(self, message):
        from kishan_sathi_backend.fcm_utils import send_new_message_notification

        chat_room = ChatRoom.objects.get(pk=self.chat_room_id)

        # Determine the other participant (FK first, M2M fallback)
        recipient = None
        if chat_room.participant_one_id and chat_room.participant_two_id:
            if chat_room.participant_one_id == self.user.pk:
                recipient = chat_room.participant_two
            else:
                recipient = chat_room.participant_one
        else:
            recipients = chat_room.participants.exclude(pk=self.user.pk)
            recipient = recipients.first()

        if recipient is None:
            return

        send_new_message_notification(
            recipient=recipient,
            sender_name=self.user.full_name,
            chat_room_id=chat_room.pk,
            sender_id=self.user.pk,
            message_preview=message.content,
        )

    # ---- utility -------------------------------------------------------------

    async def _send_error(self, msg: str):
        await self.send(text_data=json.dumps({
            'type': 'error',
            'message': msg,
        }))
