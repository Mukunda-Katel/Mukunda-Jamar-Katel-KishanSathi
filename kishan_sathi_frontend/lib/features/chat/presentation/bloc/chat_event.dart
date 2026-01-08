import '../../data/models/chat_models.dart';

abstract class ChatEvent {}

class LoadChatRooms extends ChatEvent {}

class CreateChatRoom extends ChatEvent {
  final List<int> participantIds;

  CreateChatRoom({required this.participantIds});
}

class LoadMessages extends ChatEvent {
  final int roomId;
  final int limit;
  final int offset;

  LoadMessages({
    required this.roomId,
    this.limit = 50,
    this.offset = 0,
  });
}

class SendMessage extends ChatEvent {
  final int chatRoomId;
  final String content;
  final String? imagePath;

  SendMessage({
    required this.chatRoomId,
    required this.content,
    this.imagePath,
  });
}

class MarkMessagesAsRead extends ChatEvent {
  final int roomId;

  MarkMessagesAsRead({required this.roomId});
}

class MessageReceived extends ChatEvent {
  final ChatMessage message;

  MessageReceived({required this.message});
}

class UpdateTypingStatus extends ChatEvent {
  final int userId;
  final bool isTyping;

  UpdateTypingStatus({
    required this.userId,
    required this.isTyping,
  });
}
