import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';

/// AI Chatbot Service using Django Backend
/// 
/// This service provides an AI-powered agricultural assistant for farmers.
/// Backend endpoint: /api/ai/chat/
/// Model: Google Gemma 3 4B (free) via OpenRouter
/// 
/// Features:
/// - Crop cultivation advice
/// - Pest and disease management
/// - Soil health recommendations
/// - Weather-based farming tips
/// - Market information
/// - Government schemes guidance
/// - Supports English and Nepali languages
class ChatbotService {
  static const String chatUrl = '${ApiConstants.apiBaseUrl}/ai/chat/';
  static const String historyUrl = '${ApiConstants.apiBaseUrl}/ai/history/';
  static const String clearHistoryUrl = '${ApiConstants.apiBaseUrl}/ai/history/clear/';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> _readAuthToken() {
    return _secureStorage.read(key: 'auth_token');
  }

  String _extractBackendError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final error = data['error']?.toString();
        final details = data['details']?.toString();

        if (response.statusCode == 429 || response.statusCode == 503) {
          return 'AI assistant is temporarily busy due to provider limits. Please wait about a minute and try again.';
        }

        if (error != null && error.isNotEmpty) {
          if (details != null && details.isNotEmpty) {
            return '$error\n$details';
          }
          return error;
        }
      }
    } catch (_) {
      // Fall through to generic status message when response is not JSON.
    }

    if (response.statusCode == 429 || response.statusCode == 503) {
      return 'AI assistant is temporarily busy due to provider limits. Please wait about a minute and try again.';
    }

    return 'Backend error: ${response.statusCode}';
  }

  Future<String> sendMessage(String message, List<Map<String, String>> conversationHistory) async {
    try {
      // Get authentication token
      final token = await _readAuthToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(chatUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'message': message,
          'conversation_history': conversationHistory,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Backend Response Status: ${response.statusCode}');
      print('Backend Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['response'];
        } else {
          throw Exception(data['error'] ?? 'Unknown error from backend');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(_extractBackendError(response));
      }
    } on TimeoutException {
      throw Exception('AI request timed out. Please try again.');
    } on Exception catch (e) {
      final cleanMessage = e.toString().replaceFirst('Exception: ', '').trim();
      throw Exception(cleanMessage);
    } catch (e) {
      print('Exception in sendMessage: $e');
      throw Exception('Failed to communicate with AI service. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    try {
      final token = await _readAuthToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$historyUrl?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['messages']);
        } else {
          throw Exception(data['error'] ?? 'Failed to load history');
        }
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (e) {
      print('Exception in getChatHistory: $e');
      return []; // Return empty list on error
    }
  }

  Future<void> clearChatHistory() async {
    try {
      final token = await _readAuthToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      await http.delete(
        Uri.parse(clearHistoryUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Exception in clearChatHistory: $e');
      throw Exception('Failed to clear chat history: $e');
    }
  }
}
