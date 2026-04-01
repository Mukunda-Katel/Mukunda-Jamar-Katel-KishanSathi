import 'package:equatable/equatable.dart';
import '../../data/models/chat_message_model.dart';

abstract class ChatbotState extends Equatable {
  const ChatbotState();

  @override
  List<Object?> get props => [];
}

class ChatbotInitial extends ChatbotState {}

class ChatbotLoading extends ChatbotState {
  final List<ChatMessage> messages;

  const ChatbotLoading(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatbotLoaded extends ChatbotState {
  final List<ChatMessage> messages;

  const ChatbotLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatbotError extends ChatbotState {
  final String message;
  final List<ChatMessage> messages;

  const ChatbotError(this.message, this.messages);

  @override
  List<Object?> get props => [message, messages];
}
