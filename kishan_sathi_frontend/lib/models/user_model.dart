import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
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

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String,
      roleDisplay: json['role_display'] as String?,
      isDoctorVerified: json['is_doctor_verified'] as bool? ?? false,
      doctorStatus: json['doctor_status'] as String?,
      doctorStatusDisplay: json['doctor_status_display'] as String?,
      specialization: json['specialization'] as String?,
      experienceYears: json['experience_years'] as int?,
      licenseNumber: json['license_number'] as String?,
      dateJoined: json['date_joined'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'role_display': roleDisplay,
      'is_doctor_verified': isDoctorVerified,
      'doctor_status': doctorStatus,
      'doctor_status_display': doctorStatusDisplay,
      'specialization': specialization,
      'experience_years': experienceYears,
      'license_number': licenseNumber,
      'date_joined': dateJoined,
    };
  }

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

