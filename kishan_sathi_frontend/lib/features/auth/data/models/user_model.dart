import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profilePictureUrl;
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
    this.profilePictureUrl,
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
      profilePictureUrl: json['profile_picture_url'] as String?,
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
      'profile_picture_url': profilePictureUrl,
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

  // Checking if the user is farmer, buyer, doctor or admin
  bool get isFarmer => role == 'farmer';
  bool get isBuyer => role == 'buyer';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';

  // As the doctor cannot login directly until verified by admin 
  bool get isDoctorApproved => isDoctor && doctorStatus == 'approved' && isDoctorVerified;
  bool get isDoctorPending => isDoctor && doctorStatus == 'pending';
  bool get isDoctorRejected => isDoctor && doctorStatus == 'rejected';

  // for formated join date
  String get formattedJoinDate {
    if (dateJoined == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateJoined!);
      return '${date.day}-${date.month}-${date.year}';
    } catch (e) {
      return dateJoined!;
    }
  }

  // for getting name with role
  String get displayNameWithRole => '$fullName ($roleDisplay)';

  // For getting initials such as MK for Mukunda Katel
  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  // Creating copy of UserModel with updated fields
  UserModel copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profilePictureUrl,
    String? role,
    String? roleDisplay,
    bool? isDoctorVerified,
    String? doctorStatus,
    String? doctorStatusDisplay,
    String? specialization,
    int? experienceYears,
    String? licenseNumber,
    String? dateJoined,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      roleDisplay: roleDisplay ?? this.roleDisplay,
      isDoctorVerified: isDoctorVerified ?? this.isDoctorVerified,
      doctorStatus: doctorStatus ?? this.doctorStatus,
      doctorStatusDisplay: doctorStatusDisplay ?? this.doctorStatusDisplay,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }

  // Creating empty user
  factory UserModel.empty() {
    return const UserModel(
      id: 0,
      email: '',
      fullName: '',
      role: '',
    );
  }

  bool get isEmpty => id == 0 || email.isEmpty;
  bool get isNotEmpty => !isEmpty;
  // For user status message like for users such as doctors
  String get statusMessage {
    if (isDoctor) {
      if (isDoctorApproved) {
        return 'Your account is verified and active';
      } else if (isDoctorPending) {
        return 'Your account is pending admin approval';
      } else if (isDoctorRejected) {
        return 'Your account has been rejected';
      }
    }
    return 'Active';
  }

  // For experience level 
  String get experienceLevel{
    if (experienceYears == null) return 'Not specified';
    if (experienceYears! < 2) return 'Junior';
    if (experienceYears! < 5) return 'Intermediate';
    if (experienceYears! < 10) return 'Senior';
    return 'Expert';
  }


  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phoneNumber,
        profilePictureUrl,
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
    
  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, role: $role, isDoctorVerified: $isDoctorVerified)';
  }
}

