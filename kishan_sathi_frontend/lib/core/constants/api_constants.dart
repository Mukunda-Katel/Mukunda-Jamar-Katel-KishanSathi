class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
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
