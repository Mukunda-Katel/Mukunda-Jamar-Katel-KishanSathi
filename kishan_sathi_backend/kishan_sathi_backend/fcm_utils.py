"""
Firebase Cloud Messaging utilities for sending push notifications
Uses Firebase Admin SDK with FCM API (V1)
"""
import logging
import json
from pathlib import Path
from django.conf import settings

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    
    # Check if Firebase is already initialized
    if not firebase_admin._apps:
        # Get service account path from settings
        service_account_path = getattr(settings, 'FIREBASE_SERVICE_ACCOUNT_KEY', None)
        
        if service_account_path and Path(service_account_path).exists():
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized successfully")
        else:
            logger.warning("Firebase service account key not configured. Push notifications will not work.")
            logger.info("Please add FIREBASE_SERVICE_ACCOUNT_KEY to settings.py")
except ImportError:
    logger.error("firebase-admin package not installed. Run: pip install firebase-admin")
    firebase_admin = None
    messaging = None
except Exception as e:
    logger.error(f"Error initializing Firebase Admin SDK: {str(e)}")
    firebase_admin = None
    messaging = None


def send_push_notification(fcm_token, title, body, data=None):
    """
    Send a push notification via Firebase Cloud Messaging API (V1)
    
    Args:
        fcm_token (str): The FCM token of the target device
        title (str): Notification title
        body (str): Notification body
        data (dict): Additional data to send with the notification
        
    Returns:
        bool: True if successful, False otherwise
    """
    if not fcm_token:
        logger.warning("No FCM token provided")
        return False
    
    if not firebase_admin or not messaging:
        logger.error("Firebase Admin SDK not initialized")
        return False
    
    try:
        # Prepare the message
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    priority='high',
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                    ),
                ),
            ),
        )
        
        # Send the message
        response = messaging.send(message)
        logger.info(f"Push notification sent successfully. Message ID: {response}")
        return True
        
    except messaging.UnregisteredError:
        logger.warning(f"FCM token is invalid or unregistered: {fcm_token[:20]}...")
        return False
    except messaging.SenderIdMismatchError:
        logger.error(f"FCM token doesn't match the sender ID")
        return False
    except Exception as e:
        logger.error(f"Error sending push notification: {str(e)}")
        return False


def send_consultation_approved_notification(farmer):
    """
    Send notification to farmer when consultation request is approved
    
    Args:
        farmer: User object (farmer)
        
    Returns:
        bool: True if successful, False otherwise
    """
    if not farmer.fcm_token:
        logger.warning(f"Farmer {farmer.email} has no FCM token")
        return False
    
    title = "Consultation Request Approved! 🎉"
    body = "Your consultation request has been approved. You can now start chatting with the doctor."
    data = {
        "type": "consultation_approved",
        "farmer_id": str(farmer.id),
    }
    
    return send_push_notification(farmer.fcm_token, title, body, data)


def send_consultation_rejected_notification(farmer):
    """
    Send notification to farmer when consultation request is rejected
    
    Args:
        farmer: User object (farmer)
        
    Returns:
        bool: True if successful, False otherwise
    """
    if not farmer.fcm_token:
        logger.warning(f"Farmer {farmer.email} has no FCM token")
        return False
    
    title = "Consultation Request Updates"
    body = "Unfortunately, your consultation request was not approved. Please try another doctor."
    data = {
        "type": "consultation_rejected",
        "farmer_id": str(farmer.id),
    }
    
    return send_push_notification(farmer.fcm_token, title, body, data)


def send_new_message_notification(recipient, sender_name):
    """
    Send notification for new chat message
    
    Args:
        recipient: User object (message recipient)
        sender_name: Name of the message sender
        
    Returns:
        bool: True if successful, False otherwise
    """
    if not recipient.fcm_token:
        logger.warning(f"User {recipient.email} has no FCM token")
        return False
    
    title = f"New message from {sender_name}"
    body = "You have a new message"
    data = {
        "type": "new_message",
        "sender_name": sender_name,
    }
    
    return send_push_notification(recipient.fcm_token, title, body, data)
