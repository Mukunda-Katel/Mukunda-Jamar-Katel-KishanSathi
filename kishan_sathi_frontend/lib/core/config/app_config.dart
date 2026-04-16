import '../constants/api_constants.dart';

class AppConfig {
  static const String baseUrl = ApiConstants.serverBaseUrl;
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login/';
  static const String registerEndpoint = '/api/auth/register/';
  static const String doctorRegisterEndpoint = '/api/auth/register/doctor/';
  static const String logoutEndpoint = '/api/auth/logout/';
  
  static const Duration timeout = ApiConstants.timeout;
  
  // Get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}