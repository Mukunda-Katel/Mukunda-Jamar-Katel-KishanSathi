import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final url = Uri.parse(AppConfig.getUrl(AppConfig.loginEndpoint));
      
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(AppConfig.timeout);

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final errorMessage = error['non_field_errors']?[0] ?? 
                            error['email']?[0] ?? 
                            error['password']?[0] ?? 
                            'Invalid credentials';
        throw Exception(errorMessage);
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Login Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Register new user (Farmer/Buyer)
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    try {
      final url = Uri.parse(AppConfig.getUrl(AppConfig.registerEndpoint));
      
      final requestBody = {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'role': role,
      };

      print('Register Request URL: $url');
      print('Register Request Body: $requestBody');

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(AppConfig.timeout);

      print('Register Response Status: ${response.statusCode}');
      print('Register Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Extract first error message from any field
        String errorMessage = 'Registration failed';
        
        if (error.containsKey('email')) {
          errorMessage = (error['email'] as List).first.toString();
        } else if (error.containsKey('phone_number')) {
          errorMessage = (error['phone_number'] as List).first.toString();
        } else if (error.containsKey('password')) {
          errorMessage = (error['password'] as List).first.toString();
        } else if (error.containsKey('role')) {
          errorMessage = (error['role'] as List).first.toString();
        } else if (error.containsKey('non_field_errors')) {
          errorMessage = (error['non_field_errors'] as List).first.toString();
        } else {
          // Get first error from any field
          final firstError = error.values.first;
          errorMessage = firstError is List ? firstError[0].toString() : firstError.toString();
        }
        
        throw Exception(errorMessage);
      } else {
        throw Exception('Registration failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Register Error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void dispose() {
    _client.close();
  }
}

