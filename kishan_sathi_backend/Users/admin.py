from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
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
            'pending': '#FFA500',  
            'approved': '#28A745',  
            'rejected': '#DC3545',  
        }
        
        icons = {
            'pending': '',
            'approved': '',
            'rejected': '',
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
        """Custom save to handle doctor approval and send email notifications"""
        if change and obj.role == 'doctor':
            old_obj = User.objects.get(pk=obj.pk)
            
            # Check if doctor status changed to approved
            if old_obj.doctor_status != 'approved' and obj.doctor_status == 'approved':
                obj.approved_at = timezone.now()
                obj.is_doctor_verified = True
                super().save_model(request, obj, form, change)
                self._send_approval_email(obj)
                return
            
            # Check if doctor status changed to rejected
            if old_obj.doctor_status != 'rejected' and obj.doctor_status == 'rejected':
                obj.is_doctor_verified = False
                super().save_model(request, obj, form, change)
                self._send_rejection_email(obj)
                return
        
        super().save_model(request, obj, form, change)
    
    def _send_approval_email(self, doctor):
        """Send approval notification email to doctor"""
        subject = '🎉 Your Kishan Sathi Doctor Account Has Been Approved!'
        message = f"""
Dear Dr. {doctor.full_name},

Congratulations! Your doctor account registration on Kishan Sathi has been approved.

Your Account Details:
- Email: {doctor.email}
- Specialization: {doctor.specialization}
- License Number: {doctor.license_number or 'N/A'}
- Approval Date: {timezone.now().strftime('%B %d, %Y at %I:%M %p')}

You can now log in to your account and start providing consultations to farmers.

Thank you for joining Kishan Sathi!

Best regards,
Kishan Sathi Team
        """
        
        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[doctor.email],
                fail_silently=False,
            )
        except Exception as e:
            print(f"Failed to send approval email to {doctor.email}: {str(e)}")
    
    def _send_rejection_email(self, doctor):
        """Send rejection notification email to doctor"""
        subject = ' Kishan Sathi Doctor Account Registration Update'
        message = f"""
Dear {doctor.full_name},

Thank you for your interest in joining Kishan Sathi as a veterinary consultant.

After careful review, we regret to inform you that we are unable to approve your doctor account registration at this time.

Possible reasons for rejection:
- Incomplete or unclear certification documents
- Unable to verify credentials
- Information mismatch

If you believe this is an error or would like to resubmit your application with updated information, please contact our support team.

Support Email: {settings.ADMIN_EMAIL}

Best regards,
Kishan Sathi Team
        """
        
        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[doctor.email],
                fail_silently=False,
            )
        except Exception as e:
            print(f"Failed to send rejection email to {doctor.email}: {str(e)}")
    
    # Bulk actions for quick approval/rejection
    actions = ['approve_doctors', 'reject_doctors', 'mark_as_pending']
    
    def approve_doctors(self, request, queryset):
        """Bulk approve selected doctors and send approval emails"""
        doctors = queryset.filter(role='doctor', doctor_status__in=['pending', 'rejected'])
        count = doctors.count()
        
        for doctor in doctors:
            doctor.doctor_status = 'approved'
            doctor.is_doctor_verified = True
            doctor.approved_at = timezone.now()
            doctor.save()
            # Send approval email
            self._send_approval_email(doctor)
        
        self.message_user(
            request,
            f' {count} doctor(s) approved successfully. Approval emails sent.'
        )
    
    approve_doctors.short_description = ' Approve selected doctors'
    
    def reject_doctors(self, request, queryset):
        """Bulk reject selected doctors and send rejection emails"""
        doctors = queryset.filter(role='doctor', doctor_status__in=['pending', 'approved'])
        count = doctors.count()
        
        for doctor in doctors:
            doctor.doctor_status = 'rejected'
            doctor.is_doctor_verified = False
            doctor.save()
            # Send rejection email
            self._send_rejection_email(doctor)
        
        self.message_user(
            request,
            f' {count} doctor(s) rejected. Rejection emails sent.'
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
        PendingDoctorsFilter,  
        'role',
        'is_active',
        'is_staff',
        'is_superuser',
        'doctor_status',
        'is_doctor_verified',
    ]
