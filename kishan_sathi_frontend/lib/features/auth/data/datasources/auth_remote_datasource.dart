import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,  // Make role optional
  }) async {
    try {
      final url = Uri.parse(AppConfig.getUrl(AppConfig.loginEndpoint));
      
      // Build request body, only include role if provided
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
      };
      if (role != null) {
        requestBody['role'] = role;
      }
      
      print('Login URL: $url');
      print('Login Body: ${jsonEncode(requestBody)}');
      
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Login Status: ${response.statusCode}');
      print('Login Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        final error = jsonDecode(response.body);
        String errorMessage = 'Login failed';
        
        if (error.containsKey('non_field_errors')) {
          errorMessage = (error['non_field_errors'] as List).first.toString();
        } else if (error.containsKey('email')) {
          errorMessage = (error['email'] as List).first.toString();
        } else if (error.containsKey('password')) {
          errorMessage = (error['password'] as List).first.toString();
        }
        
        throw Exception(errorMessage);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      print('Login Error: $e');
      rethrow;
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

      print('Register URL: $url');
      print('Register Body: $requestBody');

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Register Status: ${response.statusCode}');
      print('Register Response: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        
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
          final firstError = error.values.first;
          errorMessage = firstError is List ? firstError[0].toString() : firstError.toString();
        }
        
        throw Exception(errorMessage);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      print('Register Error: $e');
      rethrow;
    }
  }

  /// UPDATED: Register doctor with certificate file upload
  Future<Map<String, dynamic>> registerDoctor({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String specialization,
    required int experienceYears,
    required String licenseNumber,
    required File certificateFile,
  }) async {
    try {
      final url = Uri.parse(AppConfig.getUrl(AppConfig.doctorRegisterEndpoint));
      
      print('Doctor Register URL: $url');

      // NEW: Create multipart request for file upload
      var request = http.MultipartRequest('POST', url);
      
      // Add text fields
      request.fields['full_name'] = fullName;
      request.fields['email'] = email;
      request.fields['phone_number'] = phoneNumber;
      request.fields['password'] = password;
      request.fields['specialization'] = specialization;
      request.fields['experience_years'] = experienceYears.toString();
      request.fields['license_number'] = licenseNumber;

      //Add certificate file
      request.files.add(
        await http.MultipartFile.fromPath(
          'certificate',
          certificateFile.path,
        ),
      );

      print('Doctor Register Fields: ${request.fields}');
      print('Certificate File: ${certificateFile.path}');

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print('Doctor Register Status: ${response.statusCode}');
      print('Doctor Register Response: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        
        String errorMessage = 'Registration failed';
        
        if (error.containsKey('email')) {
          errorMessage = (error['email'] as List).first.toString();
        } else if (error.containsKey('license_number')) {
          errorMessage = (error['license_number'] as List).first.toString();
        } else if (error.containsKey('certificate')) {
          errorMessage = (error['certificate'] as List).first.toString();
        } else if (error.containsKey('phone_number')) {
          errorMessage = (error['phone_number'] as List).first.toString();
        } else if (error.containsKey('password')) {
          errorMessage = (error['password'] as List).first.toString();
        } else if (error.containsKey('non_field_errors')) {
          errorMessage = (error['non_field_errors'] as List).first.toString();
        } else {
          final firstError = error.values.first;
          errorMessage = firstError is List ? firstError[0].toString() : firstError.toString();
        }
        
        throw Exception(errorMessage);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      print('Doctor Register Error: $e');
      rethrow;
    }
  }

  /// Get currently authenticated user profile
  Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    try {
      final url = Uri.parse(AppConfig.getUrl('/api/auth/profile/'));

      final response = await _client
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      throw Exception('Failed to fetch profile: ${response.body}');
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } catch (e) {
      print('Get Profile Error: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}