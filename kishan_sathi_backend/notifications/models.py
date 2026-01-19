from django.db import models
from django.conf import settings


class Notification(models.Model):
    """Model for user notifications"""
    
    NOTIFICATION_TYPES = [
        ('cart', 'Cart'),
        ('order', 'Order'),
        ('consultation', 'Consultation'),
        ('chat', 'Chat'),
        ('product', 'Product'),
        ('post', 'Post'),
        ('system', 'System'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    
    # Optional reference to related object
    reference_id = models.IntegerField(null=True, blank=True)
    reference_type = models.CharField(max_length=50, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'notification'
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['user', 'is_read']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.title}"
    
    def mark_as_read(self):
        """Mark notification as read"""
        if not self.is_read:
            self.is_read = True
            from django.utils import timezone
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])
