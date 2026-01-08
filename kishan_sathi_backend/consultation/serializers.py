from rest_framework import serializers
from .models import ConsultationRequest
from Users.models import User
from django.utils import timezone


class DoctorSerializer(serializers.ModelSerializer):
    """Serializer for doctor information"""
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'specialization', 'experience_years', 'phone_number']


class ConsultationRequestSerializer(serializers.ModelSerializer):
    """Serializer for consultation requests"""
    farmer = DoctorSerializer(read_only=True)
    doctor = DoctorSerializer(read_only=True)
    doctor_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = ConsultationRequest
        fields = [
            'id', 'farmer', 'doctor', 'doctor_id', 'status', 'message',
            'chat_room', 'created_at', 'updated_at', 'approved_at'
        ]
        read_only_fields = ['farmer', 'status', 'chat_room', 'created_at', 'updated_at', 'approved_at']
    
    def create(self, validated_data):
        doctor_id = validated_data.pop('doctor_id')
        
        # Check if doctor exists and is approved
        try:
            doctor = User.objects.get(id=doctor_id, role='doctor', doctor_status='approved')
        except User.DoesNotExist:
            raise serializers.ValidationError({'doctor_id': 'Doctor not found or not approved'})
        
        # Check if there's already a pending request
        existing_request = ConsultationRequest.objects.filter(
            farmer=self.context['request'].user,
            doctor=doctor,
            status='pending'
        ).first()
        
        if existing_request:
            raise serializers.ValidationError({'detail': 'You already have a pending request with this doctor'})
        
        consultation_request = ConsultationRequest.objects.create(
            farmer=self.context['request'].user,
            doctor=doctor,
            **validated_data
        )
        
        return consultation_request
