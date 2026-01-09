import 'package:equatable/equatable.dart';
import 'dart:io'; 

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String? role;  // Make role optional

  const LoginRequested({
    required this.email,
    required this.password,
    this.role,  // No longer required
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

// UPDATED: Doctor Registration Event with certificate file
class DoctorRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String specialization;
  final int experienceYears;
  final String licenseNumber;
  final File certificateFile; 

  const DoctorRegisterRequested({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.specialization,
    required this.experienceYears,
    required this.licenseNumber,
    required this.certificateFile, 
  });

  @override
  List<Object?> get props => [
        fullName,
        email,
        phoneNumber,
        password,
        specialization,
        experienceYears,
        licenseNumber,
        certificateFile, 
      ];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

