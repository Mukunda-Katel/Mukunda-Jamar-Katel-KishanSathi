from django.db import models
from Users.models import User


class ConsultationRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
    ]

    farmer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='consultation_requests_as_farmer',
        limit_choices_to={'role': 'farmer'}
    )
    doctor = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='consultation_requests_as_doctor',
        limit_choices_to={'role': 'doctor', 'doctor_status': 'approved'}
    )
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default='pending'
    )
    message = models.TextField(blank=True, null=True, help_text='Optional message from farmer')
    
    # Chat room will be created when request is approved
    chat_room = models.ForeignKey(
        'chat.ChatRoom',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='consultation_request'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['farmer', 'doctor', 'status']
        
    def __str__(self):
        return f"{self.farmer.full_name} -> {self.doctor.full_name} ({self.status})"

