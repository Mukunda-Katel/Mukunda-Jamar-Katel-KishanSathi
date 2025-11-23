import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService apiService;
  final SharedPreferences prefs;

  AuthRepository({
    required this.apiService,
    required this.prefs,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await apiService.post(
      AppConfig.loginEndpoint,
      {
        'email': email,
        'password': password,
        'role': role,
      },
    );

    if (response.containsKey('token') && response.containsKey('user')) {
      final token = response['token'] as String;
      
      // Save token and role
      await prefs.setString(AppConfig.authTokenKey, token);
      await prefs.setString(AppConfig.userRoleKey, role);
      
      return response;
    }
    
    throw 'Invalid response from server.';
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    final response = await apiService.post(
      AppConfig.registerEndpoint,
      {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'role': role,
      },
    );

    if (response.containsKey('token') && response.containsKey('user')) {
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final userRole = userData['role'] as String? ?? role;
      
      // Save token and role
      await prefs.setString(AppConfig.authTokenKey, token);
      await prefs.setString(AppConfig.userRoleKey, userRole);
      
      return response;
    }
    
    throw 'Invalid response from server.';
  }

  Future<void> logout() async {
    await prefs.remove(AppConfig.authTokenKey);
    await prefs.remove(AppConfig.userRoleKey);
  }

  String? getStoredToken() {
    return prefs.getString(AppConfig.authTokenKey);
  }

  String? getStoredRole() {
    return prefs.getString(AppConfig.userRoleKey);
  }
}

