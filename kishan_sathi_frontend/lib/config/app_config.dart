class AppConfig {
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const String baseUrl = 'https://kishansathi.onrender.com/api';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String doctorRegisterEndpoint = 'auth/register/doctor/';
  
  
  // SharedPreferences Keys
  static const String authTokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';

  //timeout duration
  static const Duration timeout = Duration(seconds: 30);

  // for full URL for endpoints
  static String getUrl(String endpoint) => '$baseUrl$endpoint';

}

