import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/chatbot_service.dart';
import 'chatbot_event.dart';
import 'chatbot_state.dart';

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final ChatbotService chatbotService;
  final List<ChatMessage> _messages = [];

  String _normalizeErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '').trim();
    }
    return raw;
  }

  ChatbotBloc({required this.chatbotService}) : super(ChatbotInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ClearChat>(_onClearChat);
    on<LoadChatHistory>(_onLoadChatHistory);
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatbotState> emit) async {
    try {
      // Add user message
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      );
      _messages.add(userMessage);

      emit(ChatbotLoading(List.from(_messages)));

      // Prepare conversation history for API (exclude the last message as it will be added by the service)
      final conversationHistory = _messages.sublist(0, _messages.length - 1).map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.message,
        };
      }).toList();

      // Get AI response
      final aiResponse = await chatbotService.sendMessage(event.message, conversationHistory);

      // Add AI message
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);

      emit(ChatbotLoaded(List.from(_messages)));
    } catch (e) {
      emit(ChatbotError(_normalizeErrorMessage(e), List.from(_messages)));
    }
  }

  void _onClearChat(ClearChat event, Emitter<ChatbotState> emit) async {
    try {
      // Clear messages from backend
      await chatbotService.clearChatHistory();
      _messages.clear();
      emit(ChatbotInitial());
    } catch (e) {
      // Clear locally even if backend fails
      _messages.clear();
      emit(ChatbotInitial());
    }
  }

  Future<void> _onLoadChatHistory(LoadChatHistory event, Emitter<ChatbotState> emit) async {
    try {
      emit(ChatbotLoading([]));
      
      // Fetch chat history from backend
      final history = await chatbotService.getChatHistory(limit: 50);
      
      // Convert backend history to ChatMessage objects
      _messages.clear();
      for (var item in history.reversed) {
        // Add user message
        _messages.add(ChatMessage(
          id: '${item['id']}_user',
          message: item['message'],
          isUser: true,
          timestamp: DateTime.parse(item['created_at']),
        ));
        
        // Add AI response
        _messages.add(ChatMessage(
          id: '${item['id']}_ai',
          message: item['response'],
          isUser: false,
          timestamp: DateTime.parse(item['created_at']),
        ));
      }
      
      if (_messages.isEmpty) {
        emit(ChatbotInitial());
      } else {
        emit(ChatbotLoaded(List.from(_messages)));
      }
    } catch (e) {
      print('Error loading chat history: $e');
      emit(ChatbotInitial());
    }
  }
}
