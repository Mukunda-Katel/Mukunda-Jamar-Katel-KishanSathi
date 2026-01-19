from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Notification


# Import models for signals
try:
    from buyer.models import CartItem
    from consultation.models import ConsultationRequest
    from farmer.models import Product
    from django.contrib.auth import get_user_model
    User = get_user_model()
except ImportError:
    pass


@receiver(post_save, sender=CartItem)
def create_cart_notification(sender, instance, created, **kwargs):
    """Create notification when item is added to cart"""
    if created:
        Notification.objects.create(
            user=instance.cart.buyer,
            type='cart',
            title='Item Added to Cart',
            message=f'{instance.product.name} has been added to your cart.',
            reference_id=instance.id,
            reference_type='cart_item'
        )


@receiver(post_save, sender=ConsultationRequest)
def create_consultation_notification(sender, instance, created, **kwargs):
    """Create notification for consultation request status changes"""
    if created:
        # Notify farmer that request was created
        Notification.objects.create(
            user=instance.farmer,
            type='consultation',
            title='Consultation Request Sent',
            message=f'Your consultation request to Dr. {instance.doctor.full_name} has been sent.',
            reference_id=instance.id,
            reference_type='consultation_request'
        )
        # Notify doctor about new request
        Notification.objects.create(
            user=instance.doctor,
            type='consultation',
            title='New Consultation Request',
            message=f'{instance.farmer.full_name} has requested a consultation.',
            reference_id=instance.id,
            reference_type='consultation_request'
        )
    else:
        # Get old instance to check status change
        try:
            old_instance = ConsultationRequest.objects.get(pk=instance.pk)
            old_status = old_instance.status
        except ConsultationRequest.DoesNotExist:
            old_status = None
        
        # Check if status changed
        if old_status and old_status != instance.status:
            if instance.status == 'approved':
                # Notify farmer that request was approved
                Notification.objects.create(
                    user=instance.farmer,
                    type='consultation',
                    title='Consultation Request Approved',
                    message=f'Dr. {instance.doctor.full_name} has approved your consultation request.',
                    reference_id=instance.id,
                    reference_type='consultation_request'
                )
            elif instance.status == 'rejected':
                # Notify farmer that request was rejected
                Notification.objects.create(
                    user=instance.farmer,
                    type='consultation',
                    title='Consultation Request Declined',
                    message=f'Dr. {instance.doctor.full_name} has declined your consultation request.',
                    reference_id=instance.id,
                    reference_type='consultation_request'
                )


@receiver(post_save, sender=Product)
def create_product_notification(sender, instance, created, **kwargs):
    """Create notification for buyers when a new product is added"""
    if created and instance.status == 'available':
        # Get all buyers
        buyers = User.objects.filter(role='buyer')
        
        # Create notification for each buyer
        notifications_to_create = [
            Notification(
                user=buyer,
                type='product',
                title='New Product Available',
                message=f'{instance.farmer.full_name} added {instance.name} - Rs. {instance.price} per {instance.unit}',
                reference_id=instance.id,
                reference_type='product'
            )
            for buyer in buyers
        ]
        
        # Bulk create notifications for better performance
        if notifications_to_create:
            Notification.objects.bulk_create(notifications_to_create)
