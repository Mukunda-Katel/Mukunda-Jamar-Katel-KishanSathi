from django.contrib import admin
from .models import ConsultationRequest


@admin.register(ConsultationRequest)
class ConsultationRequestAdmin(admin.ModelAdmin):
    list_display = ['id', 'farmer', 'doctor', 'status', 'created_at', 'approved_at']
    list_filter = ['status', 'created_at']
    search_fields = ['farmer__full_name', 'doctor__full_name', 'farmer__email', 'doctor__email']
    readonly_fields = ['created_at', 'updated_at', 'approved_at']
    
    fieldsets = (
        ('Request Information', {
            'fields': ('farmer', 'doctor', 'message')
        }),
        ('Status', {
            'fields': ('status', 'chat_room')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'approved_at')
        }),
    )

