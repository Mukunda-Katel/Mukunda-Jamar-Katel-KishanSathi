import 'package:equatable/equatable.dart';

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends ChatbotEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearChat extends ChatbotEvent {
  const ClearChat();
}

class LoadChatHistory extends ChatbotEvent {
  const LoadChatHistory();
}
