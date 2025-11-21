from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("The Email field must be set")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)
        extra_fields.setdefault("role", User.Role.ADMIN)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        FARMER = "farmer", "Farmer"
        BUYER = "buyer", "Buyer"
        DOCTOR = "doctor", "Agricultural Consultant"
        ADMIN = "admin", "Admin"

    class DoctorStatus(models.TextChoices):
        PENDING = "pending", "Pending Approval"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=20, blank=True)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.BUYER)
    
    # Doctor-specific fields
    is_doctor_verified = models.BooleanField(default=False)
    doctor_status = models.CharField(
        max_length=10,
        choices=DoctorStatus.choices,
        blank=True,
        null=True,
    )
    degree_certificate = models.FileField(
        upload_to="doctor_certificates/%Y/%m/",
        blank=True,
        null=True,
        help_text="Upload your degree certificate (PDF, JPG, PNG)",
    )
    specialization = models.CharField(max_length=200, blank=True, null=True)
    experience_years = models.PositiveIntegerField(blank=True, null=True)
    license_number = models.CharField(max_length=100, blank=True, null=True)
    rejection_reason = models.TextField(blank=True, null=True)
    approved_at = models.DateTimeField(blank=True, null=True)
    
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    def __str__(self):
        return f"{self.email} ({self.get_role_display()})"

    def save(self, *args, **kwargs):
        # Auto-set doctor status based on role
        if self.role == self.Role.DOCTOR:
            if not self.doctor_status:
                self.doctor_status = self.DoctorStatus.PENDING
            
            # Set is_active based on approval status
            if self.doctor_status == self.DoctorStatus.APPROVED:
                self.is_active = True
                self.is_doctor_verified = True
            elif self.doctor_status in [self.DoctorStatus.PENDING, self.DoctorStatus.REJECTED]:
                self.is_active = False
                self.is_doctor_verified = False
        else:
            # Non-doctor users are active by default
            self.doctor_status = None
            self.is_active = True
            
        super().save(*args, **kwargs)

    class Meta:
        verbose_name = "User"
        verbose_name_plural = "Users"
