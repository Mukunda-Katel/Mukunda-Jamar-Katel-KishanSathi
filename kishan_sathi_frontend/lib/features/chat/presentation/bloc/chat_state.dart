import '../../data/models/chat_models.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> chatRooms;

  ChatRoomsLoaded({required this.chatRooms});
}

class ChatRoomCreated extends ChatState {
  final ChatRoom chatRoom;

  ChatRoomCreated({required this.chatRoom});
}

class MessagesLoaded extends ChatState {
  final List<ChatMessage> messages;
  final int totalCount;
  final int currentRoomId;

  MessagesLoaded({
    required this.messages,
    required this.totalCount,
    required this.currentRoomId,
  });
}

class MessageSent extends ChatState {
  final ChatMessage message;

  MessageSent({required this.message});
}

class ChatMessageReceived extends ChatState {
  final ChatMessage message;

  ChatMessageReceived({required this.message});
}

class MessagesMarkedAsRead extends ChatState {}

class TypingStatusChanged extends ChatState {
  final int userId;
  final bool isTyping;

  TypingStatusChanged({
    required this.userId,
    required this.isTyping,
  });
}

class ChatError extends ChatState {
  final String message;

  ChatError({required this.message});
}
