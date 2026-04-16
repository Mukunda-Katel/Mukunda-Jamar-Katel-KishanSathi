import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_event.dart';
import '../../features/chat/presentation/bloc/chat_state.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../core/theme/app_theme.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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

  String _initialFor(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;

    final headerPadding = isTinyScreen ? 12.0 : (isSmallScreen ? 16.0 : 18.0);
    final headerIconSize = isTinyScreen ? 24.0 : 28.0;
    final headerTitleSize = isTinyScreen ? 20.0 : (isSmallScreen ? 22.0 : 24.0);
    final headerActionIconSize = isTinyScreen ? 22.0 : 24.0;
    final listVerticalPadding = isTinyScreen ? 6.0 : 8.0;

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
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
                  padding: EdgeInsets.all(headerPadding),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble,
                        color: Colors.white,
                        size: headerIconSize,
                      ),
                      SizedBox(width: isTinyScreen ? 8 : 12),
                      Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: headerTitleSize,
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
                          size: 22,
                        ),
                        iconSize: headerActionIconSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Chat List
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
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
                              _refreshChatList();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ChatRoomsLoaded) {
                    if (state.chatRooms.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshChatList();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: listVerticalPadding),
                        itemCount: state.chatRooms.length,
                        itemBuilder: (context, index) {
                          final chatRoom = state.chatRooms[index];
                          final otherUser = chatRoom.otherUser;
                          
                          if (otherUser == null) return const SizedBox.shrink();

                          return _buildChatItem(
                            context,
                            chatRoom.id,
                            otherUser.fullName,
                            otherUser.profilePictureUrl,
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

                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    int roomId,
    String userName,
    String? profilePictureUrl,
    String userRole,
    String lastMessage,
    String timestamp,
    int unreadCount,
  ) {
    final hasUnread = unreadCount > 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;

    final avatarRadius = isTinyScreen ? 24.0 : (isSmallScreen ? 26.0 : 28.0);
    final initialFontSize = isTinyScreen ? 20.0 : 24.0;
    final cardRadius = isTinyScreen ? 10.0 : 12.0;
    final cardPadding = isTinyScreen ? 10.0 : 12.0;
    final cardMarginHorizontal = isTinyScreen ? 6.0 : 8.0;
    final nameFontSize = isTinyScreen ? 15.0 : 16.0;
    final timestampFontSize = isTinyScreen ? 11.0 : 12.0;
    final roleFontSize = isTinyScreen ? 9.0 : 10.0;
    final messageFontSize = isTinyScreen ? 13.0 : 14.0;
    final badgeFontSize = isTinyScreen ? 11.0 : 12.0;
    final badgePadding = isTinyScreen ? 5.0 : 6.0;
    final rowSpacing = isTinyScreen ? 10.0 : 12.0;
    final sectionSpacing = isTinyScreen ? 4.0 : 6.0;
    
    return InkWell(
      onTap: () async {
        // Navigate to chat screen and wait for result
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userName: userName,
              profileImageUrl: profilePictureUrl,
              userRole: userRole,
              chatRoomId: roomId,
            ),
          ),
        );
        // Refresh chat list when returning from chat screen
        _refreshChatList();
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: cardMarginHorizontal, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                    ? NetworkImage(profilePictureUrl)
                    : null,
                child: profilePictureUrl == null || profilePictureUrl.isEmpty
                    ? Text(
                        _initialFor(userName),
                        style: TextStyle(
                          fontSize: initialFontSize,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: rowSpacing),
              
              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name
                        Expanded(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: nameFontSize,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Timestamp
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: timestampFontSize,
                            color: hasUnread ? AppTheme.primaryGreen : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                    
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userRole,
                        style: TextStyle(
                          fontSize: roleFontSize,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing + 2),
                    
                    // Last Message
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: messageFontSize,
                              color: hasUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          SizedBox(width: sectionSpacing + 2),
                          Container(
                            padding: EdgeInsets.all(badgePadding),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: badgeFontSize,
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

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: isTinyScreen ? 64 : 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: isTinyScreen ? 12 : 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: isTinyScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isTinyScreen ? 6 : 8),
          Text(
            'Start chatting with buyers',
            style: TextStyle(
              fontSize: isTinyScreen ? 13 : 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
