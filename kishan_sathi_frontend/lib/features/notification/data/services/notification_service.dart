import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  final String baseUrl = '${ApiConstants.apiBaseUrl}/notifications';

  Future<List<NotificationModel>> getNotifications({
    required String token,
    String? type,
    bool? isRead,
  }) async {
    var uri = Uri.parse('$baseUrl/');
    
    // Add query parameters
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (isRead != null) queryParams['is_read'] = isRead.toString();
    
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.body}');
    }
  }

  Future<NotificationCount> getNotificationCount(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/count/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return NotificationCount.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load notification count: ${response.body}');
    }
  }

  Future<NotificationModel> markAsRead({
    required String token,
    required int notificationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$notificationId/mark_read/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NotificationModel.fromJson(data['notification']);
    } else {
      throw Exception('Failed to mark notification as read: ${response.body}');
    }
  }

  Future<int> markAllAsRead(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mark_all_read/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'];
    } else {
      throw Exception('Failed to mark all as read: ${response.body}');
    }
  }

  Future<void> deleteNotification({
    required String token,
    required int notificationId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$notificationId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification: ${response.body}');
    }
  }

  Future<int> deleteAllRead(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_all_read/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'];
    } else {
      throw Exception('Failed to delete read notifications: ${response.body}');
    }
  }
}
