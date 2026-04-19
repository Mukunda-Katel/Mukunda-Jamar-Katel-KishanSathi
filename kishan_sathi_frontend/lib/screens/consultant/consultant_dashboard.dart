import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/notification/data/repositories/notification_repository.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/notification/presentation/bloc/notification_event.dart';
import '../../features/notification/presentation/bloc/notification_state.dart';
import '../../services/consultation_service.dart';
import '../community/community_feed_screen.dart';
import '../notification/notification_screen.dart';
import 'chat_requests_screen.dart';
import 'consultant_profile_screen.dart' as consultant_profile;

class ConsultantDashboard extends StatefulWidget {
  const ConsultantDashboard({super.key});

  @override
  State<ConsultantDashboard> createState() => _ConsultantDashboardState();
}

class _ConsultantDashboardState extends State<ConsultantDashboard> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
        ConsultantHomeScreen(
          onOpenChats: () => setState(() => _selectedIndex = 2),
          onWritePost: () => setState(() => _selectedIndex = 1),
        ),
        const CommunityFeedScreen(),
        const ChatRequestsScreen(),
        const consultant_profile.ConsultantProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final maxIndex = _screens.length - 1;
    final activeIndex = _selectedIndex > maxIndex ? maxIndex : _selectedIndex;

    if (_selectedIndex > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = maxIndex);
        }
      });
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final bloc = NotificationBloc(
              notificationRepository: NotificationRepository(),
            );
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthSuccess && authState.token.isNotEmpty) {
              bloc.add(GetNotificationCount(authState.token));
            }
            return bloc;
          },
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/auth',
              (route) => false,
            );
          }
        },
        child: Scaffold(
          body: _screens[activeIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.dashboard, 'Home', 0),
                    _buildNavItem(Icons.post_add, 'Community', 1),
                    _buildNavItem(Icons.chat_bubble, 'Chats', 2),
                    _buildNavItem(Icons.person, 'Profile', 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9800).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsultantHomeScreen extends StatefulWidget {
  final VoidCallback onOpenChats;
  final VoidCallback onWritePost;

  const ConsultantHomeScreen({
    super.key,
    required this.onOpenChats,
    required this.onWritePost,
  });

  @override
  State<ConsultantHomeScreen> createState() => _ConsultantHomeScreenState();
}

class _ConsultantHomeScreenState extends State<ConsultantHomeScreen> {
  late final ConsultationService _consultationService;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  bool _isLoadingDashboard = true;
  List<ConsultationRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _consultationService = ConsultationService(client: http.Client());
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((_) {
      _refreshNotificationCount();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    super.dispose();
  }

  void _refreshNotificationCount() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess && authState.token.isNotEmpty) {
      context.read<NotificationBloc>().add(GetNotificationCount(authState.token));
    }
  }

  Future<void> _loadDashboardData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess || authState.token.isEmpty) {
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
      }
      return;
    }

    _refreshNotificationCount();

    try {
      final requests = await _consultationService.getMyRequests(authState.token);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDashboard = false);
    }
  }

  int get _totalPatients {
    return _requests
        .map((request) => request.farmer?.id)
        .whereType<int>()
        .toSet()
        .length;
  }

  int get _todaysAppointments {
    final now = DateTime.now();
    return _requests.where((request) {
      if (request.status != 'approved' && request.status != 'pending') {
        return false;
      }
      final date = request.approvedAt ?? request.createdAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  List<ConsultationRequest> get _todaySchedule {
    final now = DateTime.now();
    final todayRequests = _requests.where((request) {
      final date = request.approvedAt ?? request.createdAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();

    todayRequests.sort((a, b) {
      final aDate = a.approvedAt ?? a.createdAt;
      final bDate = b.approvedAt ?? b.createdAt;
      return aDate.compareTo(bDate);
    });
    return todayRequests.take(3).toList();
  }

  String _formatAppointmentTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final doctorName =
            authState is AuthSuccess ? authState.user.fullName : 'Doctor';

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back! 👨‍⚕️',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doctorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Stack(
                                children: [
                                  BlocBuilder<NotificationBloc, NotificationState>(
                                    builder: (context, notificationState) {
                                      int unreadCount = 0;
                                      if (notificationState
                                          is NotificationCountLoaded) {
                                        unreadCount =
                                            notificationState.count.unreadCount;
                                      }

                                      return Stack(
                                        children: [
                                          IconButton(
                                            onPressed: () async {
                                              final state =
                                                  context.read<AuthBloc>().state;
                                              if (state is! AuthSuccess) return;

                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const NotificationScreen(),
                                                ),
                                              );

                                              if (!mounted) return;
                                              context.read<NotificationBloc>().add(
                                                    GetNotificationCount(
                                                        state.token),
                                                  );
                                            },
                                            icon: const Icon(
                                              Icons.notifications_outlined,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          if (unreadCount > 0)
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 18,
                                                  minHeight: 18,
                                                ),
                                                child: Text(
                                                  unreadCount > 99
                                                      ? '99+'
                                                      : unreadCount.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.people,
                                  label: 'Total Patients',
                                  value: _isLoadingDashboard
                                      ? '...'
                                      : _totalPatients.toString(),
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.calendar_today,
                                  label: 'Today\'s Appointments',
                                  value: _isLoadingDashboard
                                      ? '...'
                                      : _todaysAppointments.toString(),
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.chat,
                                  label: 'Start Consultation',
                                  color: const Color(0xFF4CAF50),
                                  onTap: widget.onOpenChats,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.post_add,
                                  label: 'Write Post',
                                  color: const Color(0xFFFF9800),
                                  onTap: widget.onWritePost,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Schedule',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFFFF9800),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_isLoadingDashboard)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_todaySchedule.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'No appointments scheduled for today.',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          )
                        else
                          ..._todaySchedule.expand((request) {
                            final farmerName =
                                request.farmer?.fullName ?? 'Unknown Farmer';
                            final time = _formatAppointmentTime(
                              request.approvedAt ?? request.createdAt,
                            );
                            final issue = (request.message != null &&
                                    request.message!.trim().isNotEmpty)
                                ? request.message!.trim()
                                : 'Consultation request';

                            return [
                              _AppointmentCard(
                                farmerName: farmerName,
                                time: time,
                                issue: issue,
                                status: request.status,
                              ),
                              const SizedBox(height: 12),
                            ];
                          }).toList(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF9800), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String farmerName;
  final String time;
  final String issue;
  final String status;

  const _AppointmentCard({
    required this.farmerName,
    required this.time,
    required this.issue,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFFFF9800),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Start', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
