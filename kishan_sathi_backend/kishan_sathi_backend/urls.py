from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('authentication.urls')),    
    path('api/farmer/', include('farmer.urls')),
    path('api/buyer/', include('buyer.urls')),
    path('api/chat/', include('chat.urls')),
    path('api/consultation/', include('consultation.urls')),
    path('api/', include('posts.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
