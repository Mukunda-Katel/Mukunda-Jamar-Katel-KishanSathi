import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_event.dart';
import '../../features/chat/presentation/bloc/chat_state.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class BuyerChatListScreen extends StatefulWidget {
  const BuyerChatListScreen({super.key});

  @override
  State<BuyerChatListScreen> createState() => _BuyerChatListScreenState();
}

class _BuyerChatListScreenState extends State<BuyerChatListScreen> with RouteAware {
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final token = authState is AuthSuccess ? authState.token : '';
    _chatBloc = ChatBloc(
      chatRepository: ChatRepository(),
      token: token,
    )..add(LoadChatRooms());
  }

  @override
  void dispose() {
    _chatBloc.close();
    super.dispose();
  }

  void _refreshChatList() {
    _chatBloc.add(LoadChatRooms());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: _BuyerChatListView(onRefresh: _refreshChatList),
    );
  }
}

class _BuyerChatListView extends StatelessWidget {
  final VoidCallback onRefresh;
  
  const _BuyerChatListView({required this.onRefresh});

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Search feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2196F3),
                    ),
                  );
                }

                if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading chats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            onRefresh();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ChatRoomsLoaded) {
                  if (state.chatRooms.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      onRefresh();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.chatRooms.length,
                      itemBuilder: (context, index) {
                        final chatRoom = state.chatRooms[index];
                        final otherUser = chatRoom.otherUser;
                        
                        if (otherUser == null) return const SizedBox.shrink();

                        return _buildChatItem(
                          context,
                          chatRoom.id,
                          otherUser.fullName,
                          otherUser.role,
                          chatRoom.lastMessage?.content ?? 'No messages yet',
                          _formatTimestamp(
                            chatRoom.lastMessage?.timestamp ?? chatRoom.createdAt,
                          ),
                          chatRoom.unreadCount,
                        );
                      },
                    ),
                  );
                }

                return _buildEmptyState(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    int roomId,
    String userName,
    String userRole,
    String lastMessage,
    String timestamp,
    int unreadCount,
  ) {
    final hasUnread = unreadCount > 0;
    
    return InkWell(
      onTap: () async {
        // Navigate to chat screen and wait for result
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerChatScreen(
              userName: userName,
              userRole: userRole,
              chatRoomId: roomId,
            ),
          ),
        );
        // Refresh chat list when returning from chat screen
        onRefresh();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? const Color(0xFF2196F3) : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with farmers',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
