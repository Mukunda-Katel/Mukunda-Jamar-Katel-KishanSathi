class ServerException implements Exception {
  final String message;
  
  ServerException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  
  CacheException(this.message);
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  
  ValidationException(this.message);
  
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  
  AuthenticationException(this.message);
  
  @override
  String toString() => message;
}

class AuthorizationException implements Exception {
  final String message;
  
  AuthorizationException(this.message);
  
  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  
  NotFoundException(this.message);
  
  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
