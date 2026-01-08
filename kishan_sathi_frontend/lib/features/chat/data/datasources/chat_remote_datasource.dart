import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../models/chat_models.dart';

class ChatRemoteDataSource {
  final http.Client client;

  ChatRemoteDataSource({required this.client});

  Future<List<ChatRoom>> getChatRooms(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/chat/rooms/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((room) => ChatRoom.fromJson(room)).toList();
      } else {
        throw Exception('Failed to load chat rooms: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get chat rooms: $e');
    }
  }

  Future<ChatRoom> createOrGetChatRoom(
    String token,
    List<int> participantIds,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/chat/rooms/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(CreateChatRoomRequest(
        participantIds: participantIds,
      ).toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return ChatRoom.fromJson(data);
    } else {
      throw Exception('Failed to create chat room: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getMessages(
    String token,
    int roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/chat/rooms/$roomId/messages/?limit=$limit&offset=$offset',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      final messages = results.map((m) => ChatMessage.fromJson(m)).toList();
      
      return {
        'count': data['count'] as int,
        'messages': messages,
      };
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  Future<ChatMessage> sendMessage(
    String token,
    int chatRoomId,
    String content, {
    String? imagePath,
  }) async {
    try {
      if (imagePath != null) {
        // Send message with image using multipart
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/chat/messages/'),
        );

        request.headers['Authorization'] = 'Token $token';
        request.fields['chat_room'] = chatRoomId.toString();
        
        if (content.isNotEmpty) {
          request.fields['content'] = content;
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          return ChatMessage.fromJson(data);
        } else {
          throw Exception('Failed to send message with image: ${response.body}');
        }
      } else {
        // Send text-only message
        final response = await client.post(
          Uri.parse('${ApiConfig.baseUrl}/chat/messages/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: json.encode(SendMessageRequest(
            chatRoom: chatRoomId,
            content: content,
          ).toJson()),
        );

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          return ChatMessage.fromJson(data);
        } else {
          throw Exception('Failed to send message: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markAsRead(String token, int roomId) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/chat/rooms/$roomId/mark_as_read/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark messages as read: ${response.body}');
    }
  }
}
