from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Q
import logging

from .models import ConsultationRequest
from .serializers import ConsultationRequestSerializer, DoctorSerializer
from Users.models import User
from chat.models import ChatRoom
from kishan_sathi_backend.fcm_utils import (
    send_consultation_approved_notification,
    send_consultation_rejected_notification,
    send_consultation_request_notification,
)


logger = logging.getLogger(__name__)


class ApprovedDoctorViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing approved doctors"""
    serializer_class = DoctorSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return User.objects.filter(
            role='doctor',
            doctor_status='approved',
            is_active=True
        ).order_by('-created_at')


class ConsultationRequestViewSet(viewsets.ModelViewSet):
    """ViewSet for managing consultation requests"""
    serializer_class = ConsultationRequestSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.role == 'farmer':
            # Farmers see their own requests
            return ConsultationRequest.objects.filter(farmer=user)
        elif user.role == 'doctor':
            # Doctors see requests made to them
            return ConsultationRequest.objects.filter(doctor=user)
        
        return ConsultationRequest.objects.none()
    
    def create(self, request, *args, **kwargs):
        """Create a consultation request (only farmers can do this)"""
        if request.user.role != 'farmer':
            return Response(
                {'error': 'Only farmers can request consultations'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        consultation_request = serializer.save()

        # Send push + in-app notification to consultant/doctor.
        try:
            send_consultation_request_notification(
                recipient=consultation_request.doctor,
                farmer_name=request.user.full_name,
                consultation_request_id=consultation_request.id,
                message_preview=consultation_request.message,
            )
        except Exception as exc:
            logger.warning(
                "Failed to send consultation request notification for request_id=%s: %s",
                consultation_request.id,
                exc,
            )
        
        output = self.get_serializer(consultation_request)
        return Response(output.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a consultation request (only doctors can do this)"""
        consultation_request = self.get_object()
        
        if request.user.role != 'doctor':
            return Response(
                {'error': 'Only doctors can approve requests'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if consultation_request.doctor.id != request.user.id:
            return Response(
                {'error': 'You can only approve requests made to you'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if consultation_request.status != 'pending':
            return Response(
                {'error': f'Request is already {consultation_request.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create or get chat room
        chat_room = ChatRoom.objects.filter(
            participants=consultation_request.farmer
        ).filter(
            participants=consultation_request.doctor
        ).first()
        
        if not chat_room:
            chat_room = ChatRoom.objects.create()
            chat_room.participants.add(consultation_request.farmer, consultation_request.doctor)
        
        # Update consultation request
        consultation_request.status = 'approved'
        consultation_request.approved_at = timezone.now()
        consultation_request.chat_room = chat_room
        consultation_request.save()
        
        # Send push notification to farmer
        try:
            send_consultation_approved_notification(consultation_request.farmer)
        except Exception as e:
            # Log error but don't fail the request
            logger.warning("Failed to send consultation approved push notification: %s", e)
        
        serializer = self.get_serializer(consultation_request)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a consultation request (only doctors can do this)"""
        consultation_request = self.get_object()
        
        if request.user.role != 'doctor':
            return Response(
                {'error': 'Only doctors can reject requests'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if consultation_request.doctor.id != request.user.id:
            return Response(
                {'error': 'You can only reject requests made to you'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if consultation_request.status != 'pending':
            return Response(
                {'error': f'Request is already {consultation_request.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        consultation_request.status = 'rejected'
        consultation_request.save()
        
        # Send push notification to farmer
        try:
            send_consultation_rejected_notification(consultation_request.farmer)
        except Exception as e:
            # Log error but don't fail the request
            logger.warning("Failed to send consultation rejected push notification: %s", e)
        
        serializer = self.get_serializer(consultation_request)
        return Response(serializer.data)

