from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AdminUserViewSet, AdminProductViewSet, AdminPostViewSet,
    DoctorVerificationViewSet, dashboard_stats, recent_activity
)

router = DefaultRouter()
router.register(r'users', AdminUserViewSet, basename='admin-users')
router.register(r'products', AdminProductViewSet, basename='admin-products')
router.register(r'posts', AdminPostViewSet, basename='admin-posts')
router.register(r'doctors', DoctorVerificationViewSet, basename='admin-doctors')

urlpatterns = [
    path('', include(router.urls)),
    path('stats/', dashboard_stats, name='dashboard-stats'),
    path('activity/', recent_activity, name='recent-activity'),
]
