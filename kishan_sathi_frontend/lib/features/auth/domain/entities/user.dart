import 'package:equatable/equatable.dart';

/// User entity - Pure business object without JSON serialization
class User extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final String? roleDisplay;
  final bool isDoctorVerified;
  final String? doctorStatus;
  final String? doctorStatusDisplay;
  final String? specialization;
  final int? experienceYears;
  final String? licenseNumber;
  final String? dateJoined;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.roleDisplay,
    this.isDoctorVerified = false,
    this.doctorStatus,
    this.doctorStatusDisplay,
    this.specialization,
    this.experienceYears,
    this.licenseNumber,
    this.dateJoined,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phoneNumber,
        role,
        roleDisplay,
        isDoctorVerified,
        doctorStatus,
        doctorStatusDisplay,
        specialization,
        experienceYears,
        licenseNumber,
        dateJoined,
      ];
}
