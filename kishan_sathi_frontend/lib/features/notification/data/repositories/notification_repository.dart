import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final NotificationService _service = NotificationService();

  Future<List<NotificationModel>> getNotifications({
    required String token,
    String? type,
    bool? isRead,
  }) async {
    try {
      return await _service.getNotifications(
        token: token,
        type: type,
        isRead: isRead,
      );
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<NotificationCount> getNotificationCount(String token) async {
    try {
      return await _service.getNotificationCount(token);
    } catch (e) {
      throw Exception('Failed to fetch notification count: $e');
    }
  }

  Future<NotificationModel> markAsRead({
    required String token,
    required int notificationId,
  }) async {
    try {
      return await _service.markAsRead(
        token: token,
        notificationId: notificationId,
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<int> markAllAsRead(String token) async {
    try {
      return await _service.markAllAsRead(token);
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  Future<void> deleteNotification({
    required String token,
    required int notificationId,
  }) async {
    try {
      await _service.deleteNotification(
        token: token,
        notificationId: notificationId,
      );
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<int> deleteAllRead(String token) async {
    try {
      return await _service.deleteAllRead(token);
    } catch (e) {
      throw Exception('Failed to delete read notifications: $e');
    }
  }
}
