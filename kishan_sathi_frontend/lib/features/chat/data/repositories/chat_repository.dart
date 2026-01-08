import 'package:http/http.dart' as http;
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepository({ChatRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? 
          ChatRemoteDataSource(client: http.Client());

  Future<List<ChatRoom>> getChatRooms(String token) async {
    try {
      return await remoteDataSource.getChatRooms(token);
    } catch (e) {
      throw Exception('Failed to get chat rooms: $e');
    }
  }

  Future<ChatRoom> createOrGetChatRoom(
    String token,
    List<int> participantIds,
  ) async {
    try {
      return await remoteDataSource.createOrGetChatRoom(token, participantIds);
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<Map<String, dynamic>> getMessages(
    String token,
    int roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await remoteDataSource.getMessages(
        token,
        roomId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Future<ChatMessage> sendMessage(
    String token,
    int chatRoomId,
    String content, {
    String? imagePath,
  }) async {
    try {
      return await remoteDataSource.sendMessage(
        token,
        chatRoomId,
        content,
        imagePath: imagePath,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markAsRead(String token, int roomId) async {
    try {
      await remoteDataSource.markAsRead(token, roomId);
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }
}
