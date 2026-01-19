import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/notification/presentation/bloc/notification_event.dart';
import '../../features/notification/presentation/bloc/notification_state.dart';
import '../../features/notification/data/repositories/notification_repository.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _selectedFilter = 'all'; // all, unread, read

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final bloc = NotificationBloc(
          notificationRepository: NotificationRepository(),
        );
        if (authState is AuthSuccess) {
          bloc.add(LoadNotifications(token: authState.token));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.primaryGreen,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                final authState = context.read<AuthBloc>().state;
                if (authState is! AuthSuccess) return;

                if (value == 'mark_all_read') {
                  context.read<NotificationBloc>().add(
                        MarkAllNotificationsAsRead(authState.token),
                      );
                } else if (value == 'delete_read') {
                  _showDeleteConfirmation(context, authState.token);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 12),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_read',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete all read', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', 'unread'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Read', 'read'),
                ],
              ),
            ),
            const Divider(height: 1),
            // Notification List
            Expanded(
              child: BlocConsumer<NotificationBloc, NotificationState>(
                listener: (context, state) {
                  if (state is AllNotificationsMarkedAsRead) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${state.count} notifications marked as read'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is AllReadNotificationsDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${state.count} notifications deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is NotificationDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is NotificationError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is NotificationLoaded) {
                    final filteredNotifications = _filterNotifications(
                      state.notifications,
                      _selectedFilter,
                    );

                    if (filteredNotifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthSuccess) {
                          context.read<NotificationBloc>().add(
                                LoadNotifications(token: authState.token),
                              );
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];
                          return _buildNotificationCard(context, notification);
                        },
                      ),
                    );
                  } else if (state is NotificationError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthSuccess) {
          final bool? isRead = value == 'all' ? null : (value == 'read');
          context.read<NotificationBloc>().add(
                LoadNotifications(token: authState.token, isRead: isRead),
              );
        }
      },
      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List _filterNotifications(List notifications, String? filter) {
    if (filter == 'unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else if (filter == 'read') {
      return notifications.where((n) => n.isRead).toList();
    }
    return notifications;
  }

  Widget _buildNotificationCard(BuildContext context, notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthSuccess) {
          context.read<NotificationBloc>().add(
                DeleteNotification(
                  token: authState.token,
                  notificationId: notification.id,
                ),
              );
        }
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthSuccess) {
              context.read<NotificationBloc>().add(
                    MarkNotificationAsRead(
                      token: authState.token,
                      notificationId: notification.id,
                    ),
                  );
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : AppTheme.primaryGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey[300]!
                  : AppTheme.primaryGreen.withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they\'ll show up here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'cart':
        return Icons.shopping_cart;
      case 'order':
        return Icons.receipt_long;
      case 'consultation':
        return Icons.medical_services;
      case 'chat':
        return Icons.chat_bubble;
      case 'product':
        return Icons.inventory;
      case 'post':
        return Icons.article;
      case 'system':
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'cart':
        return Colors.orange;
      case 'order':
        return Colors.blue;
      case 'consultation':
        return AppTheme.primaryGreen;
      case 'chat':
        return Colors.purple;
      case 'product':
        return Colors.teal;
      case 'post':
        return Colors.indigo;
      case 'system':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  void _showDeleteConfirmation(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Read Notifications'),
        content: const Text(
          'Are you sure you want to delete all read notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<NotificationBloc>().add(
                    DeleteAllReadNotifications(token),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
