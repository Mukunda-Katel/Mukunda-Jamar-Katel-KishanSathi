import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthRepository({
    required ApiService apiService,
    required SharedPreferences prefs,
  })  : _apiService = apiService,
        _prefs = prefs;

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
      role: role,
    );

    // Save token and user data
    await _saveAuthData(
      token: response['token'] as String,
      userRole: (response['user'] as Map<String, dynamic>)['role'] as String,
    );

    return response;
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    final response = await _apiService.register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      role: role,
    );

    // Save token if available (for farmers/buyers)
    if (response.containsKey('token')) {
      await _saveAuthData(
        token: response['token'] as String,
        userRole: (response['user'] as Map<String, dynamic>)['role'] as String,
      );
    }

    return response;
  }

  /// Logout user
  Future<void> logout() async {
    await _clearAuthData();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = _prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Get saved token
  String? getToken() {
    return _prefs.getString('auth_token');
  }

  /// Get saved user role
  String? getUserRole() {
    return _prefs.getString('user_role');
  }

  /// Save auth data
  Future<void> _saveAuthData({
    required String token,
    required String userRole,
  }) async {
    await _prefs.setString('auth_token', token);
    await _prefs.setString('user_role', userRole);
  }

  /// Clear auth data
  Future<void> _clearAuthData() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_role');
  }

  void dispose() {
    _apiService.dispose();
  }
}

