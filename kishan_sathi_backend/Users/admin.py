from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from django.utils import timezone

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ("email",)
    list_display = (
        "email",
        "full_name",
        "role",
        "doctor_status_badge",
        "is_active",
        "date_joined",
    )
    list_filter = ("role", "is_active", "is_doctor_verified", "is_staff", "doctor_status")
    search_fields = ("email", "full_name", "phone_number", "license_number")
    
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal Info", {"fields": ("full_name", "phone_number")}),
        ("Role & Status", {"fields": ("role", "is_active", "is_staff", "is_superuser")}),
        (
            "Doctor Information",
            {
                "fields": (
                    "doctor_status",
                    "is_doctor_verified",
                    "specialization",
                    "experience_years",
                    "license_number",
                    "degree_certificate",
                    "rejection_reason",
                    "approved_at",
                ),
                "classes": ("collapse",),
            },
        ),
        ("Permissions", {"fields": ("groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )
    
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "email",
                    "full_name",
                    "phone_number",
                    "role",
                    "password1",
                    "password2",
                ),
            },
        ),
    )
    
    readonly_fields = ("date_joined", "last_login", "approved_at")
    
    actions = ["approve_doctors", "reject_doctors"]

    def doctor_status_badge(self, obj):
        """Display colored badge for doctor status"""
        if obj.role != User.Role.DOCTOR:
            return "-"
        
        color_map = {
            User.DoctorStatus.PENDING: "#ff9800",  # Orange
            User.DoctorStatus.APPROVED: "#4caf50",  # Green
            User.DoctorStatus.REJECTED: "#f44336",  # Red
        }
        color = color_map.get(obj.doctor_status, "#9e9e9e")
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 12px; '
            'border-radius: 4px; font-weight: bold; font-size: 11px;">{}</span>',
            color,
            obj.get_doctor_status_display() if obj.doctor_status else "N/A",
        )
    
    doctor_status_badge.short_description = "Doctor Status"

    def approve_doctors(self, request, queryset):
        """Approve selected doctor accounts"""
        updated = 0
        for user in queryset.filter(role=User.Role.DOCTOR, doctor_status=User.DoctorStatus.PENDING):
            user.doctor_status = User.DoctorStatus.APPROVED
            user.is_doctor_verified = True
            user.is_active = True
            user.rejection_reason = None
            user.approved_at = timezone.now()
            user.save()
            updated += 1
        
        self.message_user(
            request,
            f"{updated} doctor account(s) have been approved and activated.",
            level='success',
        )
    
    approve_doctors.short_description = "✓ Approve selected doctors"

    def reject_doctors(self, request, queryset):
        """Reject selected doctor accounts"""
        updated = 0
        for user in queryset.filter(role=User.Role.DOCTOR):
            user.doctor_status = User.DoctorStatus.REJECTED
            user.is_doctor_verified = False
            user.is_active = False
            if not user.rejection_reason:
                user.rejection_reason = "Application rejected by admin."
            user.save()
            updated += 1
        
        self.message_user(
            request,
            f"{updated} doctor account(s) have been rejected.",
            level='warning',
        )
    
    reject_doctors.short_description = "✗ Reject selected doctors"
