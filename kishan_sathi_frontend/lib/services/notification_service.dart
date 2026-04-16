import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

/// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Stream controller for notification taps
  final StreamController<String> _notificationTapController =
      StreamController<String>.broadcast();
  Stream<String> get notificationTapStream => _notificationTapController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Get FCM token
      await _getFCMToken();

      if (kDebugMode) {
        print('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('Notification permission status: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permissions: $e');
      }
    }
  }

  /// Initialize local notifications (for foreground messages)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _notificationTapController.add(response.payload!);
        }
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'consultation_notifications',
      'Consultation Notifications',
      description: 'Notifications for consultation requests and approvals',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message if app was opened from a notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    if (kDebugMode) {
      print('Firebase Messaging initialized');
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        // TODO: Send updated token to backend
        _sendTokenToBackend(newToken);
      });

      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Show local notification
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'consultation_notifications',
      'Consultation Notifications',
      channelDescription: 'Notifications for consultation requests and approvals',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Kishan Sathi',
      message.notification?.body ?? '',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.messageId}');
      print('Data: ${message.data}');
    }

    // Emit event with notification data
    final data = jsonEncode(message.data);
    _notificationTapController.add(data);

    // TODO: Navigate to appropriate screen based on notification type
    // Example: if type is 'consultation_approved', navigate to chat
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await _secureStorage.read(key: 'auth_token');

      if (authToken == null || authToken.isEmpty) {
        if (kDebugMode) {
          print('No auth token available, skipping FCM token upload');
        }
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/auth/fcm-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({
          'fcm_token': token,
          'device_type': 'android', // or 'ios'
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('FCM token sent to backend successfully');
        }
      } else {
        if (kDebugMode) {
          print('Failed to send FCM token: ${response.statusCode}');
          print('Response: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM token to backend: $e');
      }
    }
  }

  /// Update FCM token when user logs in
  Future<void> updateFCMToken(String authToken) async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      await _sendTokenToBackend(_fcmToken!);
    } else {
      // Get token if not available yet
      final token = await _getFCMToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    }
  }

  /// Clear FCM token when user logs out
  Future<void> clearFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      if (kDebugMode) {
        print('FCM token cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing FCM token: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}
