from django.db import models
from django.contrib.auth.models import AbstractUser

class CustomUser(AbstractUser):
    USER_ROLE = (
        ('buyer', 'Buyer'),
        ('seller', 'Seller'),
        ('admin', 'Admin')
    )
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, unique=True)
    role = models.CharField(max_length=10, choices=USER_ROLE, default='buyer')
    location = models.CharField(max_length=200, help_text='User location/address', default='Not specified')
    is_verified = models.BooleanField(default=False)
    profile_picture = models.ImageField(upload_to='profile_pic/', null=True, blank=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    last_active = models.DateTimeField(auto_now=True)
    
  
    groups = models.ManyToManyField(
        'auth.Group',
        related_name='custom_user_set',  
        blank=True,
        help_text='The groups this user belongs to.',
        verbose_name='groups',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='custom_user_permissions_set',  
        blank=True,
        help_text='Specific permissions for this user.',
        verbose_name='user permissions',
    )
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'phone', 'location']
    
    def __str__(self):
        return self.username
    
class UserProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(max_length=500)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=10, choices=[('M', 'Male'), ('F', 'Female'), ('O', 'other')], blank=True)
    
    # Creating for sellers or the farmers 
    farm_name = models.CharField(max_length=100, blank=True)
    farm_size = models.CharField(max_length=100, blank=True)
    experience_years = models.PositiveIntegerField(null=True, blank=True)
    specialization = models.JSONField(default=list, blank=True)
    
    
    # Creating for rating and reviews 
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    total_reviews = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.first_name} Profile"