class ChatRoom {
  final int id;
  final List<ChatUser> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final ChatUser? otherUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    this.otherUser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as int? ?? 0,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => ChatUser.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      otherUser: json['other_user'] != null
          ? ChatUser.fromJson(json['other_user'])
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'other_user': otherUser?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChatMessage {
  final int id;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final ChatUser sender;
  final int chatRoomId;

  ChatMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.sender,
    required this.chatRoomId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      sender: json['sender'] != null
          ? ChatUser.fromJson(json['sender'] as Map<String, dynamic>)
          : ChatUser(
              id: 0,
              fullName: 'Unknown',
              email: '',
              role: 'unknown',
            ),
      chatRoomId: json['chat_room'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'sender': sender.toJson(),
      'chat_room': chatRoomId,
    };
  }
}

class ChatUser {
  final int id;
  final String fullName;
  final String email;
  final String role;

  ChatUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
    };
  }
}

class CreateChatRoomRequest {
  final List<int> participantIds;

  CreateChatRoomRequest({required this.participantIds});

  Map<String, dynamic> toJson() {
    return {
      'participant_ids': participantIds,
    };
  }
}

class SendMessageRequest {
  final int chatRoom;
  final String content;

  SendMessageRequest({
    required this.chatRoom,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'chat_room': chatRoom,
      'content': content,
    };
  }
}
