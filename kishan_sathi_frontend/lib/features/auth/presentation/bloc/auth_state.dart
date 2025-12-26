import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final String token;
  final UserModel user;
  final String message;

  const AuthSuccess({
    required this.token,
    required this.user,
    required this.message,
  });

  @override
  List<Object?> get props => [token, user, message];
}

// NEW: Doctor Registration Pending State
class DoctorRegistrationPending extends AuthState {
  final UserModel user;
  final String message;

  const DoctorRegistrationPending({
    required this.user,
    required this.message,
  });

  @override
  List<Object?> get props => [user, message];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

