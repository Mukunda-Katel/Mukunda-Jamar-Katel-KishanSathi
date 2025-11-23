class AppConfig {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  
  // SharedPreferences Keys
  static const String authTokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
}

