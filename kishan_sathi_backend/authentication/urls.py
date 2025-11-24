from django.urls import path
from .views import login_view, register_view, doctor_register_view, logout_view

app_name = 'authentication'

urlpatterns = [
    path('login/', login_view, name='login'),
    path('register/', register_view, name='register'),
    path('register/doctor/', doctor_register_view, name='doctor-register'),
    path('logout/', logout_view, name='logout'),
]

