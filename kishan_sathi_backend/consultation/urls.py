from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ApprovedDoctorViewSet, ConsultationRequestViewSet

router = DefaultRouter()
router.register(r'doctors', ApprovedDoctorViewSet, basename='doctors')
router.register(r'requests', ConsultationRequestViewSet, basename='consultation-requests')

urlpatterns = [
    path('', include(router.urls)),
]
