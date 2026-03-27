from django.urls import path

from .views import (
    BusinessKhaltiAccountView,
    CheckBusinessKhaltiStatusView,
    InitiateKhaltiPaymentView,
    VerifyKhaltiPaymentView,
)

urlpatterns = [
    path('khalti/account/', BusinessKhaltiAccountView.as_view(), name='khalti-account'),
    path('khalti/status/<int:relationship_id>/', CheckBusinessKhaltiStatusView.as_view(), name='khalti-status'),
    path('khalti/initiate/', InitiateKhaltiPaymentView.as_view(), name='khalti-initiate'),
    path('khalti/verify/', VerifyKhaltiPaymentView.as_view(), name='khalti-verify'),
]
