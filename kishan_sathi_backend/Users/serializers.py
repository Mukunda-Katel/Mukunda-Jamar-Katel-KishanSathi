from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    doctor_status_display = serializers.CharField(
        source='get_doctor_status_display',
        read_only=True
    )
    #NEW: Include certificate URL
    certificate_url = serializers.SerializerMethodField()
    profile_picture_url = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'full_name',
            'phone_number',
            'profile_picture',
            'profile_picture_url',
            'role',
            'role_display',
            'specialization',
            'experience_years',
            'license_number',
            'certificate',  
            'certificate_url',  
            'is_doctor_verified',
            'doctor_status',
            'doctor_status_display',
            'created_at',
            'updated_at',
            'approved_at',
            'is_active',
        ]
        read_only_fields = [
            'id',
            'created_at',
            'updated_at',
            'approved_at',
            'is_doctor_verified',
            'doctor_status',
        ]

    def get_certificate_url(self, obj):
        """Return full URL for certificate file"""
        if obj.certificate:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.certificate.url)
            return obj.certificate.url
        return None

    def get_profile_picture_url(self, obj):
        """Return full URL for profile picture file"""
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None
