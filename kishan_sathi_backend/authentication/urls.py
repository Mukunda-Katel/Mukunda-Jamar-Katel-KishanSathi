from django.urls import path

from .views import LoginView, RegisterView, DoctorRegisterView

urlpatterns = [
    path("register/", RegisterView.as_view(), name="auth-register"),
    path("register/doctor/", DoctorRegisterView.as_view(), name="auth-doctor-register"),
    path("login/", LoginView.as_view(), name="auth-login"),
]

