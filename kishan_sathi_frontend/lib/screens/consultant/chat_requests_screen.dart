import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/consultation/data/repositories/consultation_request_repository_impl.dart';
import '../../features/consultation/domain/entities/consultation_request_entity.dart';
import '../../features/consultation/domain/usecases/approve_consultation_request.dart';
import '../../features/consultation/domain/usecases/get_consultation_requests.dart';
import '../../features/consultation/domain/usecases/reject_consultation_request.dart';
import '../../features/consultation/presentation/bloc/consultation_requests_bloc.dart';
import '../../features/consultation/presentation/bloc/consultation_requests_event.dart';
import '../../features/consultation/presentation/bloc/consultation_requests_state.dart';
import '../farmer/chat_screen.dart';

class ChatRequestsScreen extends StatelessWidget {
  const ChatRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthSuccess) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Consultation Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFFF9800),
        ),
        body: const Center(
          child: Text('Please sign in again to view consultation requests.'),
        ),
      );
    }

    return BlocProvider(
      create: (_) {
        final repository = ConsultationRequestRepositoryImpl();
        return ConsultationRequestsBloc(
          getConsultationRequests:
              GetConsultationRequests(repository: repository),
          approveConsultationRequest:
              ApproveConsultationRequest(repository: repository),
          rejectConsultationRequest:
              RejectConsultationRequest(repository: repository),
        )..add(ConsultationRequestsFetchRequested(token: authState.token));
      },
      child: _ChatRequestsView(token: authState.token),
    );
  }
}

class _ChatRequestsView extends StatelessWidget {
  final String token;

  const _ChatRequestsView({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Consultation Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
      ),
      body: BlocConsumer<ConsultationRequestsBloc, ConsultationRequestsState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            context
                .read<ConsultationRequestsBloc>()
                .add(const ConsultationRequestsFeedbackCleared());
          } else if (state.successMessage != null &&
              state.successMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
            context
                .read<ConsultationRequestsBloc>()
                .add(const ConsultationRequestsFeedbackCleared());
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No consultation requests',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ConsultationRequestsBloc>().add(
                    ConsultationRequestsFetchRequested(token: token),
                  );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                return _buildRequestCard(
                  context: context,
                  request: request,
                  isActionInProgress: state.isActionInProgress,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard({
    required BuildContext context,
    required ConsultationRequestEntity request,
    required bool isActionInProgress,
  }) {
    final farmer = request.farmer;
    if (farmer == null) return const SizedBox.shrink();

    final status = _statusVisual(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: request.isPending
            ? BorderSide(
                color: const Color(0xFFFF9800).withOpacity(0.3),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                  child: Text(
                    farmer.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmer.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(status.icon, size: 16, color: status.color),
                          const SizedBox(width: 4),
                          Text(
                            request.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: status.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Requested: ${_formatDate(request.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (farmer.phoneNumber != null &&
                    farmer.phoneNumber!.trim().isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    farmer.phoneNumber!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (request.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isActionInProgress
                          ? null
                          : () => _confirmAndReject(context, request.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isActionInProgress
                          ? null
                          : () {
                              context.read<ConsultationRequestsBloc>().add(
                                    ConsultationRequestApproveRequested(
                                      token: token,
                                      requestId: request.id,
                                    ),
                                  );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        isActionInProgress ? 'Processing...' : 'Approve',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (request.isApproved && request.chatRoomId != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          userName: farmer.fullName,
                          userRole: 'farmer',
                          chatRoomId: request.chatRoomId!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    'Open Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndReject(BuildContext context, int requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: const Text(
          'Are you sure you want to reject this consultation request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ConsultationRequestsBloc>().add(
            ConsultationRequestRejectRequested(
              token: token,
              requestId: requestId,
            ),
          );
    }
  }

  _RequestStatusVisual _statusVisual(String status) {
    switch (status) {
      case 'approved':
        return const _RequestStatusVisual(
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'rejected':
        return const _RequestStatusVisual(
          color: Colors.red,
          icon: Icons.cancel,
        );
      case 'completed':
        return const _RequestStatusVisual(
          color: Colors.blue,
          icon: Icons.done_all,
        );
      default:
        return const _RequestStatusVisual(
          color: Colors.orange,
          icon: Icons.schedule,
        );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RequestStatusVisual {
  final Color color;
  final IconData icon;

  const _RequestStatusVisual({
    required this.color,
    required this.icon,
  });
}
