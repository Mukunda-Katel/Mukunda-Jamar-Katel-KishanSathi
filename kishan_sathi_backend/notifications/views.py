from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Notification
from .serializers import NotificationSerializer, NotificationCountSerializer


class NotificationViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user notifications"""
    
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return notifications for the current user"""
        return Notification.objects.filter(user=self.request.user)
    
    def list(self, request, *args, **kwargs):
        """List all notifications for current user"""
        queryset = self.get_queryset()
        
        # Filter by type if provided
        notification_type = request.query_params.get('type')
        if notification_type:
            queryset = queryset.filter(type=notification_type)
        
        # Filter by read status if provided
        is_read = request.query_params.get('is_read')
        if is_read is not None:
            queryset = queryset.filter(is_read=is_read.lower() == 'true')
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def count(self, request):
        """Get notification counts"""
        queryset = self.get_queryset()
        unread_count = queryset.filter(is_read=False).count()
        total_count = queryset.count()
        
        serializer = NotificationCountSerializer({
            'unread_count': unread_count,
            'total_count': total_count
        })
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a notification as read"""
        notification = self.get_object()
        notification.mark_as_read()
        
        serializer = self.get_serializer(notification)
        return Response({
            'message': 'Notification marked as read',
            'notification': serializer.data
        })
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read"""
        updated_count = self.get_queryset().filter(is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
        
        return Response({
            'message': f'{updated_count} notifications marked as read',
            'count': updated_count
        })
    
    @action(detail=False, methods=['delete'])
    def delete_all_read(self, request):
        """Delete all read notifications"""
        deleted_count, _ = self.get_queryset().filter(is_read=True).delete()
        
        return Response({
            'message': f'{deleted_count} notifications deleted',
            'count': deleted_count
        })
    
    def destroy(self, request, *args, **kwargs):
        """Delete a single notification"""
        instance = self.get_object()
        instance.delete()
        return Response({
            'message': 'Notification deleted successfully'
        }, status=status.HTTP_200_OK)
