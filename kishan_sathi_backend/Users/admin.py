from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = [
        'email',
        'full_name',
        'role',
        'phone_number',
        'is_active',
        'created_at',
        'doctor_status_badge',  # Shows colored badge
    ]
    
    list_filter = [
        'role',
        'is_active',
        'is_staff',
        'is_superuser',
        'doctor_status',
        'is_doctor_verified',
    ]
    
    search_fields = ['email', 'full_name', 'phone_number', 'license_number']
    
    ordering = ['-created_at']
    
    # NEW: Make doctor_status editable from list view
    list_editable = []  # We'll use actions instead for safety
    
    fieldsets = (
        (None, {
            'fields': ('email', 'password')
        }),
        ('Personal Info', {
            'fields': ('full_name', 'phone_number', 'role')
        }),
        ('Doctor Information', {
            'fields': (
                'specialization',
                'experience_years',
                'license_number',
                'certificate',
                'is_doctor_verified',
                'doctor_status',  #  This is the approval field
                'approved_at',
            ),
            'classes': ('wide',),  #  Changed from 'collapse' to 'wide' so it's always visible
        }),
        ('Permissions', {
            'fields': (
                'is_active',
                'is_staff',
                'is_superuser',
                'groups',
                'user_permissions',
            ),
            'classes': ('collapse',),
        }),
        ('Important Dates', {
            'fields': ('last_login', 'created_at', 'updated_at'),
        }),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'email',
                'full_name',
                'phone_number',
                'role',
                'password1',
                'password2',
            ),
        }),
    )
    
    readonly_fields = [
        'last_login',
        'created_at',
        'updated_at',
        'approved_at',
        'certificate_link',  #  NEW: Show certificate as clickable link
    ]
    
    def certificate_link(self, obj):
        """Display certificate as downloadable link"""
        if obj.certificate:
            return format_html(
                '<a href="{}" target="_blank">View Certificate</a>',
                obj.certificate.url
            )
        return '-'
    
    certificate_link.short_description = 'Certificate File'
    
    def doctor_status_badge(self, obj):
        """Display colored badge for doctor status"""
        if obj.role != 'doctor':
            return '-'
        
        colors = {
            'pending': '#FFA500',  # Orange
            'approved': '#28A745',  # Green
            'rejected': '#DC3545',  # Red
        }
        
        icons = {
            'pending': '⏳',
            'approved': '✅',
            'rejected': '❌',
        }
        
        color = colors.get(obj.doctor_status, '#6C757D')
        icon = icons.get(obj.doctor_status, '?')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 12px; '
            'border-radius: 5px; font-weight: bold; font-size: 13px;">{} {}</span>',
            color,
            icon,
            obj.get_doctor_status_display() if obj.doctor_status else 'N/A'
        )
    
    doctor_status_badge.short_description = 'Status'
    
    def get_fieldsets(self, request, obj=None):
        """Show/hide doctor fields based on role"""
        fieldsets = super().get_fieldsets(request, obj)
        
        if obj and obj.role != 'doctor':
            # Hide doctor information section for non-doctors
            return tuple(
                fieldset for fieldset in fieldsets
                if fieldset[0] != 'Doctor Information'
            )
        
        return fieldsets
    
    def save_model(self, request, obj, form, change):
        """Custom save to handle doctor approval"""
        if change and obj.role == 'doctor':
            # Check if doctor status changed to approved
            old_obj = User.objects.get(pk=obj.pk)
            if old_obj.doctor_status != 'approved' and obj.doctor_status == 'approved':
                # Send notification email (optional - implement later)
                pass
        
        super().save_model(request, obj, form, change)
    
    # Bulk actions for quick approval/rejection
    actions = ['approve_doctors', 'reject_doctors', 'mark_as_pending']
    
    def approve_doctors(self, request, queryset):
        """Bulk approve selected doctors"""
        doctors = queryset.filter(role='doctor', doctor_status__in=['pending', 'rejected'])
        count = doctors.count()
        
        for doctor in doctors:
            doctor.doctor_status = 'approved'
            doctor.is_doctor_verified = True
            doctor.save()
        
        self.message_user(
            request,
            f' {count} doctor(s) approved successfully.'
        )
    
    approve_doctors.short_description = ' Approve selected doctors'
    
    def reject_doctors(self, request, queryset):
        """Bulk reject selected doctors"""
        doctors = queryset.filter(role='doctor', doctor_status__in=['pending', 'approved'])
        count = doctors.count()
        
        doctors.update(
            doctor_status='rejected',
            is_doctor_verified=False
        )
        
        self.message_user(
            request,
            f' {count} doctor(s) rejected.'
        )
    
    reject_doctors.short_description = 'Reject selected doctors'
    
    def mark_as_pending(self, request, queryset):
        """Mark selected doctors as pending"""
        doctors = queryset.filter(role='doctor')
        count = doctors.count()
        
        doctors.update(
            doctor_status='pending',
            is_doctor_verified=False
        )
        
        self.message_user(
            request,
            f' {count} doctor(s) marked as pending.'
        )
    
    mark_as_pending.short_description = 'Mark as pending'
    
    #  NEW: Add custom filter for pending doctors
    class PendingDoctorsFilter(admin.SimpleListFilter):
        title = 'Pending Approval'
        parameter_name = 'pending_doctors'
        
        def lookups(self, request, model_admin):
            return (
                ('pending', 'Pending Doctors'),
                ('approved', 'Approved Doctors'),
                ('rejected', 'Rejected Doctors'),
            )
        
        def queryset(self, request, queryset):
            if self.value() == 'pending':
                return queryset.filter(role='doctor', doctor_status='pending')
            elif self.value() == 'approved':
                return queryset.filter(role='doctor', doctor_status='approved')
            elif self.value() == 'rejected':
                return queryset.filter(role='doctor', doctor_status='rejected')
            return queryset
    
    list_filter = [
        PendingDoctorsFilter,  # NEW: Quick filter for pending doctors
        'role',
        'is_active',
        'is_staff',
        'is_superuser',
        'doctor_status',
        'is_doctor_verified',
    ]
