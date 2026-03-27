from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count, Q
from django.utils import timezone
from datetime import timedelta

from Users.models import User
from farmer.models import Product
from posts.models import Post
from consultation.models import ConsultationRequest
from .serializers import (
    AdminUserSerializer, AdminProductSerializer, AdminPostSerializer,
    DoctorVerificationSerializer, DashboardStatsSerializer
)
from .permissions import IsAdminUser


class AdminUserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing users in admin panel
    """
    queryset = User.objects.all().order_by('-created_at')
    serializer_class = AdminUserSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        queryset = super().get_queryset()
        role = self.request.query_params.get('role', None)
        if role:
            queryset = queryset.filter(role=role)
        return queryset

    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        """Toggle user active status"""
        user = self.get_object()
        user.is_active = not user.is_active
        user.save()
        return Response({
            'message': f'User {"activated" if user.is_active else "deactivated"} successfully',
            'is_active': user.is_active
        })

    @action(detail=True, methods=['post'])
    def change_role(self, request, pk=None):
        """Change user role"""
        user = self.get_object()
        new_role = request.data.get('role')
        
        if new_role not in dict(User.ROLE_CHOICES):
            return Response(
                {'error': 'Invalid role'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.role = new_role
        user.save()
        return Response({
            'message': f'User role changed to {new_role} successfully',
            'role': user.role
        })


class AdminProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing products in admin panel
    """
    queryset = Product.objects.all().select_related('farmer', 'category').order_by('-created_at')
    serializer_class = AdminProductSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        queryset = super().get_queryset()
        farmer_id = self.request.query_params.get('farmer_id', None)
        if farmer_id:
            queryset = queryset.filter(farmer_id=farmer_id)
        return queryset

    def destroy(self, request, *args, **kwargs):
        """Delete product"""
        product = self.get_object()
        product_name = product.name
        product.delete()
        return Response({
            'message': f'Product "{product_name}" deleted successfully'
        }, status=status.HTTP_200_OK)


class AdminPostViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing posts in admin panel
    """
    queryset = Post.objects.all().select_related('author').order_by('-created_at')
    serializer_class = AdminPostSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def destroy(self, request, *args, **kwargs):
        """Delete post"""
        post = self.get_object()
        post.delete()
        return Response({
            'message': 'Post deleted successfully'
        }, status=status.HTTP_200_OK)


class DoctorVerificationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for managing doctor verifications
    """
    queryset = User.objects.filter(role='doctor').order_by('-created_at')
    serializer_class = DoctorVerificationSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        queryset = super().get_queryset()
        status_filter = self.request.query_params.get('status', None)
        if status_filter:
            queryset = queryset.filter(doctor_status=status_filter)
        else:
            # By default, show only pending doctors
            queryset = queryset.filter(doctor_status='pending')
        return queryset

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve doctor"""
        doctor = self.get_object()
        if doctor.doctor_status == 'approved':
            return Response(
                {'error': 'Doctor already approved'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        doctor.doctor_status = 'approved'
        doctor.is_doctor_verified = True
        doctor.approved_at = timezone.now()
        doctor.save()
        
        return Response({
            'message': f'Doctor {doctor.full_name} approved successfully',
            'doctor': DoctorVerificationSerializer(doctor).data
        })

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject doctor"""
        doctor = self.get_object()
        if doctor.doctor_status == 'rejected':
            return Response(
                {'error': 'Doctor already rejected'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        reason = request.data.get('reason', '')
        doctor.doctor_status = 'rejected'
        doctor.is_doctor_verified = False
        doctor.save()
        
        return Response({
            'message': f'Doctor {doctor.full_name} rejected successfully',
            'reason': reason,
            'doctor': DoctorVerificationSerializer(doctor).data
        })


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def dashboard_stats(request):
    """
    Get dashboard statistics
    """
    # Total counts
    total_users = User.objects.count()
    total_farmers = User.objects.filter(role='farmer').count()
    total_buyers = User.objects.filter(role='buyer').count()
    total_doctors = User.objects.filter(role='doctor').count()
    pending_doctors = User.objects.filter(role='doctor', doctor_status='pending').count()
    total_products = Product.objects.count()
    total_posts = Post.objects.count()
    total_consultations = ConsultationRequest.objects.count()

    # Growth calculations (last 30 days vs previous 30 days)
    thirty_days_ago = timezone.now() - timedelta(days=30)
    sixty_days_ago = timezone.now() - timedelta(days=60)

    recent_users = User.objects.filter(created_at__gte=thirty_days_ago).count()
    previous_users = User.objects.filter(
        created_at__gte=sixty_days_ago,
        created_at__lt=thirty_days_ago
    ).count()
    
    recent_products = Product.objects.filter(created_at__gte=thirty_days_ago).count()
    previous_products = Product.objects.filter(
        created_at__gte=sixty_days_ago,
        created_at__lt=thirty_days_ago
    ).count()

    # Calculate growth percentages
    users_growth = ((recent_users - previous_users) / previous_users * 100) if previous_users > 0 else 0
    products_growth = ((recent_products - previous_products) / previous_products * 100) if previous_products > 0 else 0

    stats = {
        'total_users': total_users,
        'total_farmers': total_farmers,
        'total_buyers': total_buyers,
        'total_doctors': total_doctors,
        'pending_doctors': pending_doctors,
        'total_products': total_products,
        'total_posts': total_posts,
        'total_consultations': total_consultations,
        'recent_users_growth': round(users_growth, 2),
        'recent_products_growth': round(products_growth, 2),
    }

    serializer = DashboardStatsSerializer(stats)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def recent_activity(request):
    """
    Get recent activity on the platform
    """
    activities = []

    # Recent users
    recent_users = User.objects.order_by('-created_at')[:5]
    for user in recent_users:
        activities.append({
            'type': 'user_registration',
            'message': f'New {user.role} registration: {user.full_name} joined the platform',
            'timestamp': user.created_at,
            'user_id': user.id
        })

    # Recent doctor verifications
    recent_approvals = User.objects.filter(
        role='doctor',
        doctor_status='approved',
        approved_at__isnull=False
    ).order_by('-approved_at')[:5]
    for doctor in recent_approvals:
        activities.append({
            'type': 'doctor_verified',
            'message': f'Doctor verified: {doctor.full_name}\'s credentials approved',
            'timestamp': doctor.approved_at,
            'user_id': doctor.id
        })

    # Recent products
    recent_products = Product.objects.select_related('farmer').order_by('-created_at')[:5]
    for product in recent_products:
        activities.append({
            'type': 'product_listed',
            'message': f'New product listed: {product.name} by {product.farmer.full_name}',
            'timestamp': product.created_at,
            'product_id': product.id
        })

    # Sort all activities by timestamp
    activities.sort(key=lambda x: x['timestamp'], reverse=True)

    # Return top 10 most recent activities
    return Response(activities[:10])
