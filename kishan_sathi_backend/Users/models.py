from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from django.utils import timezone


class UserManager(models.Manager):
    def normalize_email(self, email):
        """Normalize email address by lowercasing the domain part."""
        email = email or ''
        try:
            email_name, domain_part = email.strip().rsplit('@', 1)
        except ValueError:
            pass
        else:
            email = email_name + '@' + domain_part.lower()
        return email

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'admin')
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(email, password, **extra_fields)

    def get_by_natural_key(self, email):
        """
        Get user by email (the natural key for authentication)
        """
        return self.get(**{self.model.USERNAME_FIELD: email})


class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = [
        ('farmer', 'Farmer'),
        ('buyer', 'Buyer'),
        ('doctor', 'Doctor'),
        ('admin', 'Admin'),
    ]

    DOCTOR_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    profile_picture = models.ImageField(
        upload_to='profile_pictures/',
        blank=True,
        null=True,
        help_text='Optional user profile picture',
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='farmer')
    
    # Doctor-specific fields
    specialization = models.CharField(max_length=100, blank=True, null=True)
    experience_years = models.IntegerField(blank=True, null=True)
    license_number = models.CharField(max_length=50, blank=True, null=True, unique=True)
    
    # Certificate upload field
    certificate = models.FileField(
        upload_to='doctor_certificates/',
        blank=True,
        null=True,
        help_text='Upload veterinary license certificate (PDF, JPG, PNG)'
    )
    
    is_doctor_verified = models.BooleanField(default=False)
    doctor_status = models.CharField(
        max_length=10,
        choices=DOCTOR_STATUS_CHOICES,
        default='pending',
        blank=True,
        null=True
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    approved_at = models.DateTimeField(blank=True, null=True)
    
    # FCM token for push notifications
    fcm_token = models.TextField(blank=True, null=True, help_text='Firebase Cloud Messaging token')
    device_type = models.CharField(max_length=10, blank=True, null=True, choices=[('android', 'Android'), ('ios', 'iOS')])
    
    # Django required fields
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.full_name} ({self.email}) - {self.get_role_display()}"

    def natural_key(self):
        """
        Return the natural key (email) for this user
        """
        return (self.email,)

    def save(self, *args, **kwargs):
        # Set approved_at timestamp when doctor is approved
        if self.role == 'doctor' and self.doctor_status == 'approved' and not self.approved_at:
            self.approved_at = timezone.now()
            self.is_doctor_verified = True
        super().save(*args, **kwargs)
