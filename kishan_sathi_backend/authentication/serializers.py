from django.contrib.auth import authenticate, get_user_model
from rest_framework import serializers

from Users.serializers import UserSerializer

User = get_user_model()


class RegisterSerializer(serializers.Serializer):
    """Serializer for regular user registration (Farmer/Buyer only)"""
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)
    role = serializers.ChoiceField(
        choices=[
            User.Role.FARMER,
            User.Role.BUYER,
        ]
    )

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_role(self, value):
        if value == User.Role.DOCTOR:
            raise serializers.ValidationError(
                "Doctors must register through the doctor registration endpoint (/api/auth/register/doctor/)."
            )
        if value == User.Role.ADMIN:
            raise serializers.ValidationError("Cannot register as admin.")
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(password=password, **validated_data)
        return user

    def to_representation(self, instance):
        return UserSerializer(instance).data


class DoctorRegisterSerializer(serializers.Serializer):
    """Serializer for doctor registration with degree submission"""
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)
    
    # Doctor-specific fields
    specialization = serializers.CharField(max_length=200)
    experience_years = serializers.IntegerField(min_value=0, required=False)
    license_number = serializers.CharField(max_length=100, required=False, allow_blank=True)
    degree_certificate = serializers.FileField(
        required=False,
        help_text="Upload your degree certificate (PDF, JPG, PNG, max 5MB)",
    )

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_degree_certificate(self, value):
        # Validate file size (max 5MB)
        if value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError("File size must not exceed 5MB.")
        
        # Validate file extension
        allowed_extensions = ['pdf', 'jpg', 'jpeg', 'png']
        ext = value.name.lower().split('.')[-1]
        if ext not in allowed_extensions:
            raise serializers.ValidationError(
                "Only PDF, JPG, and PNG files are allowed."
            )
        return value

    def validate_experience_years(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError("Experience years cannot be negative.")
        if value is not None and value > 100:
            raise serializers.ValidationError("Please enter a valid experience duration.")
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        validated_data['role'] = User.Role.DOCTOR
        validated_data['doctor_status'] = User.DoctorStatus.PENDING
        validated_data['is_active'] = False  # Will be activated upon approval
        
        user = User.objects.create_user(password=password, **validated_data)
        return user

    def to_representation(self, instance):
        return UserSerializer(instance).data


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=User.Role.choices)

    def validate(self, attrs):
        request = self.context.get("request")
        email = attrs.get("email")
        password = attrs.get("password")
        role = attrs.get("role")

        user = authenticate(request=request, email=email, password=password)
        
        if not user:
            raise serializers.ValidationError("Invalid email or password.")

        # Check if role matches
        if user.role != role:
            raise serializers.ValidationError(
                f"Selected role does not match your account. You are registered as {user.get_role_display()}."
            )

        # Check if account is active
        if not user.is_active:
            # Provide specific message for doctors
            if user.role == User.Role.DOCTOR:
                if user.doctor_status == User.DoctorStatus.PENDING:
                    raise serializers.ValidationError(
                        "Your account is pending admin approval. Please wait for verification of your credentials."
                    )
                elif user.doctor_status == User.DoctorStatus.REJECTED:
                    reason = user.rejection_reason or "Your application was rejected."
                    raise serializers.ValidationError(
                        f"Your account was rejected. Reason: {reason}"
                    )
            raise serializers.ValidationError("Your account is inactive. Please contact support.")

        attrs["user"] = user
        return attrs

    def to_representation(self, instance):
        return UserSerializer(instance).data

