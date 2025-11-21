from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from Users.serializers import UserSerializer

from .serializers import LoginSerializer, RegisterSerializer, DoctorRegisterSerializer


class RegisterView(APIView):
    """Regular user registration (Farmer/Buyer)"""
    permission_classes = [AllowAny]
    parser_classes = [JSONParser]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)
        
        return Response(
            {
                "user": UserSerializer(user).data,
                "token": token.key,
                "message": "Registration successful! You can now login."
            },
            status=status.HTTP_201_CREATED,
        )


class DoctorRegisterView(APIView):
    """Doctor registration with degree certificate upload"""
    permission_classes = [AllowAny]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = DoctorRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        return Response(
            {
                "user": UserSerializer(user).data,
                "message": (
                    "Registration successful! Your application is pending admin approval. "
                    "You will be able to login once an admin verifies your credentials."
                )
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """User login"""
    permission_classes = [AllowAny]
    parser_classes = [JSONParser]

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        
        return Response(
            {
                "user": UserSerializer(user).data,
                "token": token.key,
                "message": "Login successful."
            },
            status=status.HTTP_200_OK,
        )
