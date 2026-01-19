from django.contrib import admin
from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """Admin interface for Notification model"""
    
    list_display = ['user', 'type', 'title', 'is_read', 'created_at']
    list_filter = ['type', 'is_read', 'created_at']
    search_fields = ['user__email', 'user__full_name', 'title', 'message']
    readonly_fields = ['created_at', 'read_at']
    date_hierarchy = 'created_at'
    
    fieldsets = [
        ('User Information', {
            'fields': ('user',)
        }),
        ('Notification Details', {
            'fields': ('type', 'title', 'message', 'is_read')
        }),
        ('Reference', {
            'fields': ('reference_id', 'reference_type'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'read_at'),
            'classes': ('collapse',)
        }),
    ]
    
    actions = ['mark_as_read', 'mark_as_unread', 'delete_selected_notifications']
    
    def mark_as_read(self, request, queryset):
        """Mark selected notifications as read"""
        from django.utils import timezone
        updated = queryset.filter(is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
        self.message_user(request, f'{updated} notifications marked as read.')
    mark_as_read.short_description = 'Mark selected as read'
    
    def mark_as_unread(self, request, queryset):
        """Mark selected notifications as unread"""
        updated = queryset.filter(is_read=True).update(
            is_read=False,
            read_at=None
        )
        self.message_user(request, f'{updated} notifications marked as unread.')
    mark_as_unread.short_description = 'Mark selected as unread'
    
    def delete_selected_notifications(self, request, queryset):
        """Delete selected notifications"""
        count = queryset.count()
        queryset.delete()
        self.message_user(request, f'{count} notifications deleted.')
    delete_selected_notifications.short_description = 'Delete selected notifications'
