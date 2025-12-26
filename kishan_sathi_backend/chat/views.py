from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Max
from .models import ChatRoom, Message
from .serializers import ChatRoomSerializer, ChatRoomListSerializer, MessageSerializer


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
        
        # Check if chat room already exists with these participants
        existing_room = None
        for room in ChatRoom.objects.filter(participants=request.user):
            room_participants = set(room.participants.values_list('id', flat=True))
            if room_participants == all_participants:
                existing_room = room
                break
        
        if existing_room:
            serializer = self.get_serializer(existing_room)
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        # Create new chat room
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        chat_room = serializer.save()
        
        # Add current user to participants
        chat_room.participants.add(request.user)
        
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
        serializer = MessageSerializer(messages, many=True)
        
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
        
        return Response(
            MessageSerializer(message).data,
            status=status.HTTP_201_CREATED
        )
