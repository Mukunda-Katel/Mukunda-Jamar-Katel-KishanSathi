import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    String? baseUrl,
    Duration? timeout,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        timeout = timeout ?? AppConfig.requestTimeout;

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };

      final response = await http
          .post(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException')) {
        throw 'Network error. Please check your connection and try again.';
      }
      throw _cleanErrorMessage(e.toString());
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    if (statusCode == 200 || statusCode == 201) {
      if (responseBody.isEmpty) {
        return {};
      }
      try {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (e) {
        throw 'Invalid response format from server.';
      }
    } else if (statusCode == 400) {
      try {
        final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
        
        // Try to extract error message from common Django REST Framework error formats
        if (errorData.containsKey('error')) {
          throw errorData['error'] as String;
        }
        if (errorData.containsKey('message')) {
          throw errorData['message'] as String;
        }
        if (errorData.containsKey('detail')) {
          throw errorData['detail'] as String;
        }
        
        // Handle field-specific errors
        final errors = <String>[];
        errorData.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors.add('${key}: ${value.first}');
          } else if (value is String) {
            errors.add('${key}: $value');
          }
        });
        
        if (errors.isNotEmpty) {
          throw errors.join(', ');
        }
        
        throw 'Invalid request. Please check your input.';
      } catch (e) {
        if (e is String) {
          throw e;
        }
        throw 'Invalid request. Please check your input.';
      }
    } else if (statusCode == 401) {
      throw 'Invalid credentials. Please try again.';
    } else if (statusCode == 403) {
      throw 'Access denied. Please contact support.';
    } else if (statusCode >= 500) {
      throw 'Server error. Please try again later.';
    } else {
      throw 'An error occurred. Please try again.';
    }
  }

  String _cleanErrorMessage(String error) {
    // Remove common exception prefixes
    String cleaned = error;
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length);
    }
    if (cleaned.startsWith('FormatException: ')) {
      cleaned = cleaned.substring('FormatException: '.length);
    }
    return cleaned.trim();
  }
}

