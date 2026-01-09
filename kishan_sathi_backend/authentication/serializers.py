from django.contrib.auth import get_user_model
from rest_framework import serializers
from Users.serializers import UserSerializer
import os

User = get_user_model()


class LoginSerializer(serializers.Serializer):
    """Serializer for user login"""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(
        choices=[
            ('farmer', 'Farmer'),
            ('buyer', 'Buyer'),
            ('doctor', 'Doctor'),
        ],
        required=False,  # Make role optional
        allow_blank=True
    )


class RegisterSerializer(serializers.Serializer):
    """Serializer for regular user registration (Farmer/Buyer only)"""
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)
    role = serializers.ChoiceField(
        choices=[
            ('farmer', 'Farmer'),
            ('buyer', 'Buyer'),
        ]
    )

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_role(self, value):
        if value == 'doctor':
            raise serializers.ValidationError(
                "Doctors must register through the doctor registration endpoint."
            )
        if value == 'admin':
            raise serializers.ValidationError("Cannot register as admin.")
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(password=password, **validated_data)
        return user

    def to_representation(self, instance):
        return UserSerializer(instance).data


class DoctorRegisterSerializer(serializers.Serializer):
    """Serializer for doctor registration (requires admin approval)"""
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True, min_length=6)
    specialization = serializers.CharField(max_length=100)
    experience_years = serializers.IntegerField(min_value=0)
    license_number = serializers.CharField(max_length=50)
    
    # NEW: Certificate file field
    certificate = serializers.FileField(
        required=True,
        help_text='Upload veterinary license certificate (PDF, JPG, PNG, max 10MB)'
    )

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_license_number(self, value):
        if User.objects.filter(license_number=value).exists():
            raise serializers.ValidationError("This license number is already registered.")
        return value

    def validate_certificate(self, value):
        """Validate certificate file"""
        # Check file size (max 10MB)
        if value.size > 10485760:
            raise serializers.ValidationError("Certificate file size must not exceed 10MB.")
        
        # Check file extension
        ext = os.path.splitext(value.name)[1].lower()
        allowed_extensions = ['.pdf', '.jpg', '.jpeg', '.png']
        
        if ext not in allowed_extensions:
            raise serializers.ValidationError(
                f"Invalid file type. Allowed types: {', '.join(allowed_extensions)}"
            )
        
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        certificate = validated_data.pop("certificate")
        
        # Create doctor with pending status
        user = User.objects.create_user(
            password=password,
            role='doctor',
            doctor_status='pending',
            is_doctor_verified=False,
            certificate=certificate,
            **validated_data
        )
        return user

    def to_representation(self, instance):
        return UserSerializer(instance).data