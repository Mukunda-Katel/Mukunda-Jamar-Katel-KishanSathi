from rest_framework import serializers
from .models import User


def _file_exists(field_file):
    if not field_file:
        return False
    name = getattr(field_file, 'name', None)
    storage = getattr(field_file, 'storage', None)
    if not name or storage is None:
        return False
    try:
        return storage.exists(name)
    except Exception:
        return False


def _build_file_url(serializer, field_file):
    url = field_file.url
    request = serializer.context.get('request')
    if request and not (url.startswith('http://') or url.startswith('https://')):
        return request.build_absolute_uri(url)
    return url


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
        if obj.certificate and _file_exists(obj.certificate):
            return _build_file_url(self, obj.certificate)
        return None

    def get_profile_picture_url(self, obj):
        """Return full URL for profile picture file"""
        if obj.profile_picture and _file_exists(obj.profile_picture):
            return _build_file_url(self, obj.profile_picture)
        return None
