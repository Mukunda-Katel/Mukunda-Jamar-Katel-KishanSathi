import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;

  const LoginRequested({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, role];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String role;

  const RegisterRequested({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [fullName, email, phoneNumber, password, role];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

