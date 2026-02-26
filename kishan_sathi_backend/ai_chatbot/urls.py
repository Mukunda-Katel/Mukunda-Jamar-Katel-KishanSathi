from django.urls import path
from . import views

urlpatterns = [
    path('chat/', views.chat_with_ai, name='chat_with_ai'),
    path('history/', views.get_chat_history, name='get_chat_history'),
    path('history/clear/', views.clear_chat_history, name='clear_chat_history'),
]
