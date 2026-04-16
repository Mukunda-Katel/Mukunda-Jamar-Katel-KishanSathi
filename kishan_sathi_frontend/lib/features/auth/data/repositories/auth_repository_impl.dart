import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io'; 
import 'dart:convert';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final ApiService _apiService;
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _cachedUserKey = 'cached_user';

  AuthRepositoryImpl({
    required ApiService apiService,
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  })  : _apiService = apiService,
        _prefs = prefs,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,  // Make role optional
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
      role: role,
    );

    await _saveAuthData(
      token: response['token'] as String,
      userRole: (response['user'] as Map<String, dynamic>)['role'] as String,
      userData: response['user'] as Map<String, dynamic>,
    );

    return response;
  }

  /// Register new user (Farmer/Buyer)
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

    if (response.containsKey('token')) {
      await _saveAuthData(
        token: response['token'] as String,
        userRole: (response['user'] as Map<String, dynamic>)['role'] as String,
        userData: response['user'] as Map<String, dynamic>,
      );
    }

    return response;
  }

  /// UPDATED: Register doctor with certificate file
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
    final response = await _apiService.registerDoctor(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      specialization: specialization,
      experienceYears: experienceYears,
      licenseNumber: licenseNumber,
      certificateFile: certificateFile,
    );

    return response;
  }

  /// Logout user
  Future<void> logout() async {
    await _clearAuthData();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get saved token
  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    // Migrate legacy token from SharedPreferences if present.
    final legacyToken = _prefs.getString(_tokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await _prefs.remove(_tokenKey);
      return legacyToken;
    }

    return null;
  }

  /// Get saved user role
  String? getUserRole() {
    return _prefs.getString(_userRoleKey);
  }

  /// Get currently authenticated user from backend using stored token
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final profile = await _apiService.getProfile(token: token);
    await _prefs.setString(_cachedUserKey, jsonEncode(profile));
    return profile;
  }

  /// Fallback cached user profile for offline/session restore edge cases
  Map<String, dynamic>? getCachedUserProfile() {
    final rawUser = _prefs.getString(_cachedUserKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawUser) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save auth data
  Future<void> _saveAuthData({
    required String token,
    required String userRole,
    Map<String, dynamic>? userData,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _prefs.setString(_userRoleKey, userRole);
    if (userData != null) {
      await _prefs.setString(_cachedUserKey, jsonEncode(userData));
    }

    // Remove any stale plaintext token.
    await _prefs.remove(_tokenKey);
  }

  /// Clear auth data
  Future<void> _clearAuthData() async {
    await _secureStorage.delete(key: _tokenKey);
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userRoleKey);
    await _prefs.remove(_cachedUserKey);
  }

  void dispose() {
    _apiService.dispose();
  }
}

