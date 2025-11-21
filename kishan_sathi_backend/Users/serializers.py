from rest_framework import serializers

from .models import User


class UserSerializer(serializers.ModelSerializer):
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    doctor_status_display = serializers.CharField(source='get_doctor_status_display', read_only=True)
    
    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "full_name",
            "phone_number",
            "role",
            "role_display",
            "is_doctor_verified",
            "doctor_status",
            "doctor_status_display",
            "specialization",
            "experience_years",
            "license_number",
            "date_joined",
        )
        read_only_fields = ("id", "is_doctor_verified", "doctor_status", "date_joined")
