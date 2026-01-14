from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CategoryViewSet, ProductViewSet, get_current_weather, get_weather_forecast

router = DefaultRouter()
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'products', ProductViewSet, basename='product')

urlpatterns = [
    path('', include(router.urls)),
    path('weather/current/', get_current_weather, name='current-weather'),
    path('weather/forecast/', get_weather_forecast, name='weather-forecast'),
]
