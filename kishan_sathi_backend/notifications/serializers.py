from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for Notification model"""
    
    class Meta:
        model = Notification
        fields = [
            'id',
            'type',
            'title',
            'message',
            'is_read',
            'reference_id',
            'reference_type',
            'created_at',
            'read_at',
        ]
        read_only_fields = ['id', 'created_at', 'read_at']


class NotificationCountSerializer(serializers.Serializer):
    """Serializer for notification count"""
    unread_count = serializers.IntegerField()
    total_count = serializers.IntegerField()
