import logging
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.db.models import Q, Max
from .models import ChatRoom, Message
from .serializers import ChatRoomSerializer, ChatRoomListSerializer, MessageSerializer
from kishan_sathi_backend.fcm_utils import send_new_message_notification


logger = logging.getLogger(__name__)


class ChatRoomViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing chat rooms
    """
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'list':
            return ChatRoomListSerializer
        return ChatRoomSerializer
    
    def get_queryset(self):
        """Get chat rooms where the user is a participant"""
        user = self.request.user
        return ChatRoom.objects.filter(
            participants=user
        ).annotate(
            last_message_time=Max('messages__timestamp')
        ).order_by('-last_message_time')
    
    def create(self, request, *args, **kwargs):
        """
        Create a new chat room or return existing one
        Expects: { "participant_ids": [user_id] }
        """
        participant_ids = request.data.get('participant_ids', [])
        
        if not participant_ids:
            return Response(
                {'error': 'participant_ids is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Add current user to participants
        all_participants = set([request.user.id] + participant_ids)
        
        print(f"[CHAT] Looking for room with participants: {all_participants}")
        
        # Check if chat room already exists with these participants
        existing_room = None
        for room in ChatRoom.objects.filter(participants=request.user):
            room_participants = set(room.participants.values_list('id', flat=True))
            print(f"[CHAT] Checking room {room.id} with participants: {room_participants}")
            if room_participants == all_participants:
                existing_room = room
                print(f"[CHAT] Found existing room: {room.id}")
                break
        
        if existing_room:
            serializer = self.get_serializer(existing_room)
            print(f"[CHAT] Returning existing room {existing_room.id}")
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        # Create new chat room
        print(f"[CHAT] Creating new room")
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        chat_room = serializer.save()
        
        # Add current user to participants
        chat_room.participants.add(request.user)
        
        print(f"[CHAT] Created new room {chat_room.id} with participants: {list(chat_room.participants.values_list('id', flat=True))}")
        
        return Response(
            self.get_serializer(chat_room).data,
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """
        Get all messages in a chat room
        Query params: limit (default: 50), offset (default: 0)
        """
        chat_room = self.get_object()
        limit = int(request.query_params.get('limit', 50))
        offset = int(request.query_params.get('offset', 0))
        
        messages = chat_room.messages.order_by('-timestamp')[offset:offset + limit]
        serializer = MessageSerializer(messages, many=True, context={'request': request})
        
        return Response({
            'count': chat_room.messages.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark all messages in the chat room as read"""
        chat_room = self.get_object()
        chat_room.messages.exclude(sender=request.user).update(is_read=True)
        
        return Response({'status': 'Messages marked as read'})


class MessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing messages
    """
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_queryset(self):
        """Get messages where the user is a participant of the chat room"""
        user = self.request.user
        chat_room_id = self.request.query_params.get('chat_room')
        
        queryset = Message.objects.filter(
            chat_room__participants=user
        ).order_by('-timestamp')
        
        if chat_room_id:
            queryset = queryset.filter(chat_room_id=chat_room_id)
        
        return queryset
    
    def create(self, request, *args, **kwargs):
        """
        Create a new message
        Expects: { "chat_room": room_id, "content": "message text" }
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Check if user is a participant in the chat room
        chat_room_id = request.data.get('chat_room')
        try:
            chat_room = ChatRoom.objects.get(id=chat_room_id)
            if not chat_room.participants.filter(id=request.user.id).exists():
                return Response(
                    {'error': 'You are not a participant in this chat room'},
                    status=status.HTTP_403_FORBIDDEN
                )
        except ChatRoom.DoesNotExist:
            return Response(
                {'error': 'Chat room not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        message = serializer.save(sender=request.user)
        self._broadcast_chat_message(message=message, request=request)
        self._send_chat_push_notifications(
            chat_room=chat_room,
            sender=request.user,
            message_content=message.content,
        )
        
        return Response(
            MessageSerializer(message, context={'request': request}).data,
            status=status.HTTP_201_CREATED
        )

    def _broadcast_chat_message(self, *, message, request):
        """Broadcast newly created REST message to websocket room subscribers."""
        channel_layer = get_channel_layer()
        if channel_layer is None:
            return

        image_url = None
        if message.image:
            try:
                image_url = request.build_absolute_uri(message.image.url)
            except Exception:
                image_url = message.image.url

        payload = {
            'id': message.id,
            'content': message.content or '',
            'image_url': image_url,
            'timestamp': message.timestamp.isoformat(),
            'is_read': message.is_read,
            'chat_room': message.chat_room_id,
            'sender': {
                'id': message.sender.id,
                'full_name': message.sender.full_name,
                'role': message.sender.role,
            },
        }

        try:
            async_to_sync(channel_layer.group_send)(
                f'chat_{message.chat_room_id}',
                {
                    'type': 'chat_message',
                    'message': payload,
                },
            )
        except Exception as exc:
            logger.warning(
                "Failed to broadcast websocket message for room_id=%s: %s",
                message.chat_room_id,
                exc,
            )

    def _send_chat_push_notifications(self, *, chat_room, sender, message_content=None):
        """Send push notification to other room participants when a message arrives."""
        recipients = chat_room.participants.exclude(id=sender.id)

        for recipient in recipients:
            try:
                send_new_message_notification(
                    recipient=recipient,
                    sender_name=sender.full_name,
                    chat_room_id=chat_room.id,
                    sender_id=sender.id,
                    message_preview=message_content,
                )
            except Exception as exc:
                logger.warning(
                    "Failed to send chat push to user_id=%s in room_id=%s: %s",
                    recipient.id,
                    chat_room.id,
                    exc,
                )
