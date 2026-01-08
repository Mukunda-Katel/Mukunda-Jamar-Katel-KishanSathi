import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

class Doctor {
  final int id;
  final String fullName;
  final String email;
  final String? specialization;
  final int? experienceYears;
  final String? phoneNumber;

  Doctor({
    required this.id,
    required this.fullName,
    required this.email,
    this.specialization,
    this.experienceYears,
    this.phoneNumber,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      specialization: json['specialization'] as String?,
      experienceYears: json['experience_years'] as int?,
      phoneNumber: json['phone_number'] as String?,
    );
  }
}

class ConsultationRequest {
  final int id;
  final String status;
  final String? message;
  final int? chatRoomId;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final Doctor? doctor;
  final Doctor? farmer;

  ConsultationRequest({
    required this.id,
    required this.status,
    this.message,
    this.chatRoomId,
    required this.createdAt,
    this.approvedAt,
    this.doctor,
    this.farmer,
  });

  factory ConsultationRequest.fromJson(Map<String, dynamic> json) {
    return ConsultationRequest(
      id: json['id'] as int,
      status: json['status'] as String,
      message: json['message'] as String?,
      chatRoomId: json['chat_room'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      doctor: json['doctor'] != null
          ? Doctor.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      farmer: json['farmer'] != null
          ? Doctor.fromJson(json['farmer'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ConsultationService {
  final http.Client client;

  ConsultationService({required this.client});

  Future<List<Doctor>> getApprovedDoctors(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/consultation/doctors/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((doctor) => Doctor.fromJson(doctor)).toList();
      } else {
        throw Exception('Failed to load doctors: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get doctors: $e');
    }
  }

  Future<List<ConsultationRequest>> getMyRequests(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/consultation/requests/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((request) => ConsultationRequest.fromJson(request))
            .toList();
      } else {
        throw Exception('Failed to load requests: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get requests: $e');
    }
  }

  Future<ConsultationRequest> requestConsultation(
    String token,
    int doctorId,
    String? message,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/consultation/requests/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'doctor_id': doctorId,
          if (message != null && message.isNotEmpty) 'message': message,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConsultationRequest.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to request consultation');
      }
    } catch (e) {
      throw Exception('Failed to request consultation: $e');
    }
  }

  Future<ConsultationRequest> approveRequest(String token, int requestId) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/consultation/requests/$requestId/approve/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ConsultationRequest.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to approve request');
      }
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  Future<ConsultationRequest> rejectRequest(String token, int requestId) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/consultation/requests/$requestId/reject/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ConsultationRequest.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to reject request');
      }
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }
}
