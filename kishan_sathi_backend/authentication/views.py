from django.contrib.auth import authenticate, get_user_model
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from Users.serializers import UserSerializer
from .serializers import DoctorRegisterSerializer, LoginSerializer, RegisterSerializer

User = get_user_model()


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """Login endpoint for all users"""
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        role = serializer.validated_data.get('role')  # Role is now optional

        user = authenticate(request, username=email, password=password)

        if user is None:
            return Response(
                {'non_field_errors': ['Invalid email or password.']},
                status=status.HTTP_400_BAD_REQUEST
            )

        # If role is provided, check if it matches; otherwise, use user's role
        if role and user.role != role:
            return Response(
                {'non_field_errors': [f'User is not registered as {role}.']},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if doctor is approved
        if user.role == 'doctor' and user.doctor_status != 'approved':
            status_messages = {
                'pending': 'Your account is pending admin approval. Please wait for verification.',
                'rejected': 'Your account has been rejected. Please contact support.',
            }
            message = status_messages.get(
                user.doctor_status,
                'Your account is not approved yet.'
            )
            return Response(
                {'non_field_errors': [message]},
                status=status.HTTP_403_FORBIDDEN
            )

        # Generate or get token
        token, created = Token.objects.get_or_create(user=user)

        return Response({
            'token': token.key,
            'user': UserSerializer(user).data,
            'message': f'Welcome back, {user.full_name}!'
        }, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    """Registration endpoint for farmers and buyers only"""
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token, created = Token.objects.get_or_create(user=user)

        return Response({
            'token': token.key,
            'user': UserSerializer(user).data,
            'message': f'Welcome to Kishan Sathi, {user.full_name}! Your account has been created successfully.'
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def doctor_register_view(request):
    """Registration endpoint for doctors (requires admin approval)"""
    serializer = DoctorRegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()

        return Response({
            'user': UserSerializer(user).data,
            'message': 'Your registration has been submitted successfully! '
                      'Your account is pending admin approval. '
                      'You will be notified once your account is verified.'
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def logout_view(request):
    """Logout endpoint - deletes user token"""
    if request.user.is_authenticated:
        try:
            request.user.auth_token.delete()
            return Response(
                {'message': 'Successfully logged out.'},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(
        {'error': 'User not authenticated.'},
        status=status.HTTP_400_BAD_REQUEST
    )