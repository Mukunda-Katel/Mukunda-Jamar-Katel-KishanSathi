import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;

  const NotificationLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class NotificationCountLoaded extends NotificationState {
  final NotificationCount count;

  const NotificationCountLoaded(this.count);

  @override
  List<Object?> get props => [count];
}

class NotificationMarkedAsRead extends NotificationState {
  final NotificationModel notification;

  const NotificationMarkedAsRead(this.notification);

  @override
  List<Object?> get props => [notification];
}

class AllNotificationsMarkedAsRead extends NotificationState {
  final int count;

  const AllNotificationsMarkedAsRead(this.count);

  @override
  List<Object?> get props => [count];
}

class NotificationDeleted extends NotificationState {
  final String message;

  const NotificationDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class AllReadNotificationsDeleted extends NotificationState {
  final int count;

  const AllReadNotificationsDeleted(this.count);

  @override
  List<Object?> get props => [count];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
