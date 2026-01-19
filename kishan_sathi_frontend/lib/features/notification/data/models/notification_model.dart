import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final int? referenceId;
  final String? referenceType;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'],
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        isRead,
        referenceId,
        referenceType,
        createdAt,
        readAt,
      ];
}

class NotificationCount extends Equatable {
  final int unreadCount;
  final int totalCount;

  const NotificationCount({
    required this.unreadCount,
    required this.totalCount,
  });

  factory NotificationCount.fromJson(Map<String, dynamic> json) {
    return NotificationCount(
      unreadCount: json['unread_count'],
      totalCount: json['total_count'],
    );
  }

  @override
  List<Object?> get props => [unreadCount, totalCount];
}
