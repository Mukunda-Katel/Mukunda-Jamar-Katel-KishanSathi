from rest_framework import serializers
from .models import ChatRoom, Message
from Users.models import User


class UserSerializer(serializers.ModelSerializer):
    """Serializer for user information in chat"""
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'role']


class MessageSerializer(serializers.ModelSerializer):
    """Serializer for chat messages"""
    sender = UserSerializer(read_only=True)
    sender_id = serializers.IntegerField(write_only=True, required=False)
    
    class Meta:
        model = Message
        fields = ['id', 'chat_room', 'sender', 'sender_id', 'content', 'timestamp', 'is_read']
        read_only_fields = ['timestamp']


class ChatRoomSerializer(serializers.ModelSerializer):
    """Serializer for chat rooms"""
    participants = UserSerializer(many=True, read_only=True)
    participant_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False
    )
    last_message = MessageSerializer(read_only=True)
    unread_count = serializers.SerializerMethodField()
    other_user = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = [
            'id', 'participants', 'participant_ids', 'last_message', 
            'unread_count', 'other_user', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_unread_count(self, obj):
        """Get count of unread messages for current user"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0
    
    def get_other_user(self, obj):
        """Get the other user in the chat (for one-to-one chats)"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            other_users = obj.participants.exclude(id=request.user.id)
            if other_users.exists():
                return UserSerializer(other_users.first()).data
        return None
    
    def create(self, validated_data):
        participant_ids = validated_data.pop('participant_ids', [])
        chat_room = ChatRoom.objects.create(**validated_data)
        
        # Add participants
        if participant_ids:
            users = User.objects.filter(id__in=participant_ids)
            chat_room.participants.set(users)
        
        return chat_room


class ChatRoomListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing chat rooms"""
    other_user = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = ['id', 'other_user', 'last_message', 'unread_count', 'updated_at']
    
    def get_other_user(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            other_users = obj.participants.exclude(id=request.user.id)
            if other_users.exists():
                return UserSerializer(other_users.first()).data
        return None
    
    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-timestamp').first()
        if last_msg:
            return {
                'content': last_msg.content,
                'timestamp': last_msg.timestamp,
                'sender_id': last_msg.sender.id
            }
        return None
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0
