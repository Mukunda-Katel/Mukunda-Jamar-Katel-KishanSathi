class AppConfig {
  // For Android Emulator (10.0.2.2 maps to localhost)
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login/';
  static const String registerEndpoint = '/api/auth/register/';
  static const String doctorRegisterEndpoint = '/api/auth/register/doctor/';
  static const String logoutEndpoint = '/api/auth/logout/';
  
  // NEW: Add timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  // Get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
