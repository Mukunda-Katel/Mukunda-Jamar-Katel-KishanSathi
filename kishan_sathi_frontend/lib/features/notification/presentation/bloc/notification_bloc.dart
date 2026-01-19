import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository})
      : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<GetNotificationCount>(_onGetNotificationCount);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteAllReadNotifications>(_onDeleteAllReadNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final notifications = await notificationRepository.getNotifications(
        token: event.token,
        type: event.type,
        isRead: event.isRead,
      );
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGetNotificationCount(
    GetNotificationCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await notificationRepository.getNotificationCount(event.token);
      emit(NotificationCountLoaded(count));
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notification = await notificationRepository.markAsRead(
        token: event.token,
        notificationId: event.notificationId,
      );
      emit(NotificationMarkedAsRead(notification));
      // Reload notifications
      final notifications = await notificationRepository.getNotifications(
        token: event.token,
      );
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await notificationRepository.markAllAsRead(event.token);
      emit(AllNotificationsMarkedAsRead(count));
      // Reload notifications
      final notifications = await notificationRepository.getNotifications(
        token: event.token,
      );
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.deleteNotification(
        token: event.token,
        notificationId: event.notificationId,
      );
      emit(const NotificationDeleted('Notification deleted'));
      // Reload notifications
      final notifications = await notificationRepository.getNotifications(
        token: event.token,
      );
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteAllReadNotifications(
    DeleteAllReadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await notificationRepository.deleteAllRead(event.token);
      emit(AllReadNotificationsDeleted(count));
      // Reload notifications
      final notifications = await notificationRepository.getNotifications(
        token: event.token,
      );
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
