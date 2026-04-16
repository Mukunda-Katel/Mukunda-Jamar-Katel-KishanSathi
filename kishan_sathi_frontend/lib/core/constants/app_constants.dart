class AppConstants {
  // App Info
  static const String appName = 'Kishan Sathi';
  static const String appVersion = '1.0.0';
  
  // SharedPreferences Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String favoriteProductIdsKey = 'favorite_product_ids';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Upload
  static const int maxImageSizeMB = 10;
  static const int maxCertificateSizeMB = 10;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedCertificateExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  
  // Snackbar Duration
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration snackbarLongDuration = Duration(seconds: 5);
  
  // Navigation Delay
  static const Duration navigationDelay = Duration(milliseconds: 1500);
}
