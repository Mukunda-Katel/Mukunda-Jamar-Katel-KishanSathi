import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

// Server Failure
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Network Failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

// Cache Failure
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Validation Failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Authentication Failure
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

// Authorization Failure
class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message);
}

// Not Found Failure
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

// Timeout Failure
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

// Unknown Failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
