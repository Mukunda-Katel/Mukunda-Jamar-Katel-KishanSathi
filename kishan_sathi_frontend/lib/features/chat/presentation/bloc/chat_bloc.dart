import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final String token;

  ChatBloc({
    required this.chatRepository,
    required this.token,
  }) : super(ChatInitial()) {
    on<LoadChatRooms>(_onLoadChatRooms);
    on<CreateChatRoom>(_onCreateChatRoom);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<MessageReceived>(_onMessageReceivedEvent);
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
  }

  Future<void> _onLoadChatRooms(
    LoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final chatRooms = await chatRepository.getChatRooms(token);
      emit(ChatRoomsLoaded(chatRooms: chatRooms));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onCreateChatRoom(
    CreateChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final chatRoom = await chatRepository.createOrGetChatRoom(
        token,
        event.participantIds,
      );
      emit(ChatRoomCreated(chatRoom: chatRoom));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final result = await chatRepository.getMessages(
        token,
        event.roomId,
        limit: event.limit,
        offset: event.offset,
      );
      emit(MessagesLoaded(
        messages: result['messages'],
        totalCount: result['count'],
        currentRoomId: event.roomId,
      ));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await chatRepository.sendMessage(
        token,
        event.chatRoomId,
        event.content,
        imagePath: event.imagePath,
      );
      emit(MessageSent(message: message));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.markAsRead(token, event.roomId);
      emit(MessagesMarkedAsRead());
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  void _onMessageReceivedEvent(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatMessageReceived(message: event.message));
  }

  void _onUpdateTypingStatus(
    UpdateTypingStatus event,
    Emitter<ChatState> emit,
  ) {
    emit(TypingStatusChanged(
      userId: event.userId,
      isTyping: event.isTyping,
    ));
  }
}
