from django.urls import path
from .views import (
    doctor_register_view,
    login_view,
    logout_view,
    profile_view,
    register_view,
    update_fcm_token,
)

app_name = 'authentication'

urlpatterns = [
    path('login/', login_view, name='login'),
    path('register/', register_view, name='register'),
    path('register/doctor/', doctor_register_view, name='doctor-register'),
    path('logout/', logout_view, name='logout'),
    path('fcm-token/', update_fcm_token, name='update-fcm-token'),
    path('profile/', profile_view, name='profile'),
]

