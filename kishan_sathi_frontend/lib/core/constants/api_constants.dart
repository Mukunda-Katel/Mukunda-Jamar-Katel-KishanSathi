class ApiConstants {
  // Root server URLs (without /api)
  // Android emulator cannot reach host localhost directly.
  // Use 10.0.2.2 for Android emulator local backend access.
  // For iOS simulator use localhost, and for physical device use your PC LAN IP.
  // static const String localServerBaseUrl = 'http://10.0.2.2:8000';
  static const String localServerBaseUrl = 'https://mukunda-jamar-katel-kishansathi.onrender.com';
  // static const String productionServerBaseUrl =
  //     'https://mukunda-jamar-katel-kishansathi.onrender.com';

  // Single source of truth for base URLs.
  static const String serverBaseUrl = localServerBaseUrl;
  static const String apiBaseUrl = '$serverBaseUrl/api';

  // Auto-switches between ws:// and wss:// based on serverBaseUrl.
  static String get wsBaseUrl {
    if (serverBaseUrl.startsWith('https')) {
      return serverBaseUrl.replaceFirst('https', 'wss');
    }
    return serverBaseUrl.replaceFirst('http', 'ws');
  }

  // Backward-compatible alias used by existing services.
  static const String baseUrl = apiBaseUrl;
  
  // Auth Endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String doctorRegisterEndpoint = '/auth/register/doctor/';
  
  // Product Endpoints
  static const String productsEndpoint = '/farmer/products/';
  static const String categoriesEndpoint = '/farmer/categories/';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> headers({String? token}) {
    final Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      defaultHeaders['Authorization'] = 'Token $token';
    }
    
    return defaultHeaders;
  }
  
  static Map<String, String> multipartHeaders({String? token}) {
    final Map<String, String> defaultHeaders = {};
    
    if (token != null) {
      defaultHeaders['Authorization'] = 'Token $token';
    }
    
    return defaultHeaders;
  }
}
