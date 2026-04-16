import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_event.dart';
import '../../features/chat/presentation/bloc/chat_state.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/data/models/chat_models.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final String userRole;
  final int chatRoomId;

  const ChatScreen({
    super.key,
    required this.userName,
    this.profileImageUrl,
    required this.userRole,
    required this.chatRoomId,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final token = authState is AuthSuccess ? authState.token : '';

    return BlocProvider(
      create: (context) => ChatBloc(
        chatRepository: ChatRepository(),
        token: token,
      )..add(LoadMessages(roomId: chatRoomId)),
      child: _ChatScreenContent(
        userName: userName,
        profileImageUrl: profileImageUrl,
        userRole: userRole,
        chatRoomId: chatRoomId,
      ),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final String userName;
  final String? profileImageUrl;
  final String userRole;
  final int chatRoomId;

  const _ChatScreenContent({
    required this.userName,
    this.profileImageUrl,
    required this.userRole,
    required this.chatRoomId,
  });

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  int? _currentUserId;
  List<ChatMessage> _messages = [];
  File? _selectedImage;

  String _initialFor(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _currentUserId = authState.user.id;
    }
    // Mark messages as read when opening chat
    Future.delayed(Duration.zero, () {
      context.read<ChatBloc>().add(MarkMessagesAsRead(roomId: widget.chatRoomId));
    });
    // Scroll to bottom after messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), _scrollToBottom);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    
    if (content.isEmpty && _selectedImage == null) return;

    _messageController.clear();

    context.read<ChatBloc>().add(
      SendMessage(
        chatRoomId: widget.chatRoomId,
        content: content,
        imagePath: _selectedImage?.path,
      ),
    );

    setState(() {
      _selectedImage = null;
    });

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(timestamp);
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final isTinyScreen = screenWidth < 360;

    final appBarAvatarRadius = isTinyScreen ? 16.0 : 20.0;
    final appBarInitialFontSize = isTinyScreen ? 14.0 : 18.0;
    final appBarNameFontSize = isTinyScreen ? 14.0 : 16.0;
    final appBarRoleFontSize = isTinyScreen ? 11.0 : 12.0;
    final appBarSpacing = isTinyScreen ? 8.0 : 12.0;

    final messageListHorizontalPadding = isTinyScreen ? 8.0 : 12.0;
    final messageListVerticalPadding = isTinyScreen ? 12.0 : 16.0;
    final bubbleMaxWidth = screenWidth * (isTinyScreen ? 0.84 : 0.78);
    final bubbleFontSize = isTinyScreen ? 14.0 : 15.0;
    final bubbleTimeSize = isTinyScreen ? 10.0 : 11.0;
    final bubblePaddingHorizontal = isTinyScreen ? 12.0 : 16.0;
    final bubblePaddingVertical = isTinyScreen ? 8.0 : 10.0;
    final bubbleImageHeight = isTinyScreen ? 160.0 : 200.0;

    final inputHorizontalPadding = isTinyScreen ? 8.0 : 12.0;
    final inputVerticalPadding = isTinyScreen ? 6.0 : 8.0;
    final inputTextPaddingHorizontal = isTinyScreen ? 12.0 : 16.0;
    final inputTextPaddingVertical = isTinyScreen ? 8.0 : 10.0;
    final attachIconSize = isTinyScreen ? 24.0 : 28.0;
    final sendIconSize = isTinyScreen ? 18.0 : 20.0;
    final sendButtonPadding = isTinyScreen ? 10.0 : 12.0;
    final selectedImageSize = isTinyScreen ? 52.0 : 60.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 2,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: appBarAvatarRadius,
              backgroundColor: Colors.white,
              backgroundImage: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.profileImageUrl!)
                  : null,
              child: widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty
                  ? Text(
                      _initialFor(widget.userName),
                      style: TextStyle(
                        fontSize: appBarInitialFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: appBarSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontSize: appBarNameFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.userRole,
                    style: TextStyle(
                      fontSize: appBarRoleFontSize,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'view_profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View ${widget.userName}\'s profile')),
                  );
                  break;
                case 'block':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Block user feature coming soon!')),
                  );
                  break;
                case 'report':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report feature coming soon!')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view_profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 12),
                    Text('Block User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20),
                    SizedBox(width: 12),
                    Text('Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is MessageSent) {
            context.read<ChatBloc>().add(LoadMessages(roomId: widget.chatRoomId));
          }
          if (state is MessagesLoaded) {
            setState(() {
              _messages = state.messages;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
            });
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Messages List
              Expanded(
                child: state is ChatLoading && _messages.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : state is ChatError && _messages.isEmpty
                        ? Center(
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
                                  'Error loading messages',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
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
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<ChatBloc>().add(
                                          LoadMessages(roomId: widget.chatRoomId),
                                        );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No messages yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Send a message to start the conversation',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  context.read<ChatBloc>().add(
                                        LoadMessages(roomId: widget.chatRoomId),
                                      );
                                },
                                child: ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: messageListHorizontalPadding,
                                    vertical: messageListVerticalPadding,
                                  ),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    return _buildMessageBubble(
                                      message,
                                      maxWidth: bubbleMaxWidth,
                                      textFontSize: bubbleFontSize,
                                      timeFontSize: bubbleTimeSize,
                                      horizontalPadding: bubblePaddingHorizontal,
                                      verticalPadding: bubblePaddingVertical,
                                      imageHeight: bubbleImageHeight,
                                      peerAvatarRadius: isTinyScreen ? 14.0 : 16.0,
                                      peerAvatarFontSize: isTinyScreen ? 11.0 : 12.0,
                                      outerSpacing: isTinyScreen ? 6.0 : 8.0,
                                      timestampIconSize: isTinyScreen ? 12.0 : 14.0,
                                    );
                                  },
                                ),
                              ),
              ),

              // Typing indicator (optional)
              if (_isTyping)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTinyScreen ? 12 : 16,
                    vertical: isTinyScreen ? 6 : 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${widget.userName} is typing',
                        style: TextStyle(
                          fontSize: isTinyScreen ? 11 : 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                    width: isTinyScreen ? 16 : 20,
                    height: isTinyScreen ? 16 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: inputHorizontalPadding,
                  vertical: inputVerticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image preview
                    if (_selectedImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                width: selectedImageSize,
                                height: selectedImageSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Image selected',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: isTinyScreen ? 13 : 14,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input row
                    Row(
                      children: [
                        // Attachment button
                        IconButton(
                          onPressed: _pickImage,
                          icon: Icon(
                            Icons.image,
                            color: AppTheme.primaryGreen,
                            size: attachIconSize,
                          ),
                        ),

                        // Text input
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: isTinyScreen ? 13 : 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: inputTextPaddingHorizontal,
                                  vertical: inputTextPaddingVertical,
                                ),
                              ),
                              onChanged: (value) {
                                // TODO: Send typing indicator via WebSocket
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Send button
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: EdgeInsets.all(sendButtonPadding),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: sendIconSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message, {
    required double maxWidth,
    required double textFontSize,
    required double timeFontSize,
    required double horizontalPadding,
    required double verticalPadding,
    required double imageHeight,
    required double peerAvatarRadius,
    required double peerAvatarFontSize,
    required double outerSpacing,
    required double timestampIconSize,
  }) {
    final isSent = message.sender.id == _currentUserId;
    final hasImage = message.image != null && message.image!.isNotEmpty;
    final hasText = message.content.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: peerAvatarRadius,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              backgroundImage: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.profileImageUrl!)
                  : null,
              child: widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty
                  ? Text(
                      _initialFor(widget.userName),
                      style: TextStyle(
                        fontSize: peerAvatarFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: outerSpacing),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              decoration: BoxDecoration(
                color: isSent ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isSent ? 18 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.image!,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: imageHeight,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: isSent ? Colors.white : AppTheme.primaryGreen,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: imageHeight,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: isSent ? Colors.white70 : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: isSent ? Colors.white70 : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasText) const SizedBox(height: 8),
                  ],
                  if (hasText)
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: textFontSize,
                        color: isSent ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: timeFontSize,
                          color: isSent ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: timestampIconSize,
                          color: message.isRead ? Colors.white : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSent) SizedBox(width: outerSpacing),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttachmentOption(
                Icons.photo_library,
                'Gallery',
                Colors.purple,
                () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gallery feature coming soon!')),
                  );
                },
              ),
              _buildAttachmentOption(
                Icons.insert_drive_file,
                'Document',
                Colors.blue,
                () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
