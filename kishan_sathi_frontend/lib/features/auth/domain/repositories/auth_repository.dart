import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Auth Repository Interface (Contract)
/// Implementations should be in data layer
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, ({String token, User user})>> login({
    required String email,
    required String password,
    required String role,
  });

  /// Register new user (farmer/buyer)
  Future<Either<Failure, ({String token, User user})>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
  });

  /// Register new doctor
  Future<Either<Failure, ({String token, User user})>> registerDoctor({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String specialization,
    required int experienceYears,
    required String licenseNumber,
    required String certificatePath,
  });

  /// Logout current user
  Future<Either<Failure, void>> logout();

  /// Get current user from cache
  Future<Either<Failure, User?>> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
