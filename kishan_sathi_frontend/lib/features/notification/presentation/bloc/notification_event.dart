import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String token;
  final String? type;
  final bool? isRead;

  const LoadNotifications({
    required this.token,
    this.type,
    this.isRead,
  });

  @override
  List<Object?> get props => [token, type, isRead];
}

class GetNotificationCount extends NotificationEvent {
  final String token;

  const GetNotificationCount(this.token);

  @override
  List<Object?> get props => [token];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String token;
  final int notificationId;

  const MarkNotificationAsRead({
    required this.token,
    required this.notificationId,
  });

  @override
  List<Object?> get props => [token, notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  final String token;

  const MarkAllNotificationsAsRead(this.token);

  @override
  List<Object?> get props => [token];
}

class DeleteNotification extends NotificationEvent {
  final String token;
  final int notificationId;

  const DeleteNotification({
    required this.token,
    required this.notificationId,
  });

  @override
  List<Object?> get props => [token, notificationId];
}

class DeleteAllReadNotifications extends NotificationEvent {
  final String token;

  const DeleteAllReadNotifications(this.token);

  @override
  List<Object?> get props => [token];
}
