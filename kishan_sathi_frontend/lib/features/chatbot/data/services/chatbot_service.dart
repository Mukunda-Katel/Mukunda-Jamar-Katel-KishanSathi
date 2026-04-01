import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String chatUrl = 'https://mukunda-jamar-katel-kishansathi.onrender.com/api/ai/chat/';
  static const String historyUrl = 'https://mukunda-jamar-katel-kishansathi.onrender.com/api/ai/history/';
  static const String clearHistoryUrl = 'https://mukunda-jamar-katel-kishansathi.onrender.com/api/ai/history/clear/';

  Future<String> sendMessage(String message, List<Map<String, String>> conversationHistory) async {
    try {
      // Get authentication token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

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
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Backend error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in sendMessage: $e');
      throw Exception('Failed to communicate with AI: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

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
