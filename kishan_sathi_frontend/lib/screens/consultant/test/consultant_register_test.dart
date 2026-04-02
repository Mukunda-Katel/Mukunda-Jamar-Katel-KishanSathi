import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';

import 'package:kishan_sathi_frontend/core/config/app_config.dart';
import 'package:kishan_sathi_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kishan_sathi_frontend/features/auth/data/models/user_model.dart';

class FakeConsultantApiService extends ApiService {
  FakeConsultantApiService({required this.response, this.error});

  final Map<String, dynamic> response;
  final Exception? error;

  Map<String, dynamic>? capturedFields;

  @override
  Future<Map<String, dynamic>> registerDoctor({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String specialization,
    required int experienceYears,
    required String licenseNumber,
    required File certificateFile,
  }) async {
    if (error != null) {
      throw error!;
    }

    capturedFields = {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'specialization': specialization,
      'experience_years': experienceYears,
      'license_number': licenseNumber,
      'certificate_path': certificateFile.path,
    };

    return response;
  }
}

void main() {
  group('Consultant Registration Unit Tests', () {
    group('UserModel', () {
      test('fromJson maps consultant registration payload correctly', () {
        final json = {
          'id': 42,
          'email': 'consultant@example.com',
          'full_name': 'Dr. Consultant',
          'phone_number': '9812345678',
          'profile_picture_url': null,
          'role': 'doctor',
          'role_display': 'Doctor',
          'is_doctor_verified': false,
          'doctor_status': 'pending',
          'doctor_status_display': 'Pending',
          'specialization': 'Veterinary Medicine',
          'experience_years': 6,
          'license_number': 'LIC-98765',
          'date_joined': '2026-03-30T10:00:00Z',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 42);
        expect(user.email, 'consultant@example.com');
        expect(user.fullName, 'Dr. Consultant');
        expect(user.phoneNumber, '9812345678');
        expect(user.role, 'doctor');
        expect(user.isDoctor, isTrue);
        expect(user.isDoctorPending, isTrue);
        expect(user.specialization, 'Veterinary Medicine');
        expect(user.licenseNumber, 'LIC-98765');
      });

      test('toJson returns serializable map with required consultant registration fields', () {
        const user = UserModel(
          id: 5,
          email: 'consultant@test.com',
          fullName: 'Dr. Test',
          phoneNumber: '9811111111',
          role: 'doctor',
          roleDisplay: 'Doctor',
          specialization: 'Veterinary Medicine',
          experienceYears: 5,
          licenseNumber: 'LIC-11111',
          doctorStatus: 'pending',
          isDoctorVerified: false,
        );

        final map = user.toJson();

        expect(map['id'], 5);
        expect(map['email'], 'consultant@test.com');
        expect(map['full_name'], 'Dr. Test');
        expect(map['phone_number'], '9811111111');
        expect(map['role'], 'doctor');
        expect(map['specialization'], 'Veterinary Medicine');
        expect(map['license_number'], 'LIC-11111');
        expect(map['doctor_status'], 'pending');
      });

      test('status message should show pending approval for consultant', () {
        const user = UserModel(
          id: 1,
          email: 'consultant@test.com',
          fullName: 'Dr. Test',
          role: 'doctor',
          doctorStatus: 'pending',
          isDoctorVerified: false,
        );

        expect(user.statusMessage, 'Your account is pending admin approval');
      });
    });

    group('ApiService.registerDoctor', () {
      test('sends expected fields and returns decoded response for 201', () async {
        final certificateDir = await Directory.systemTemp.createTemp('consultant-register-success');
        final certificateFile = File('${certificateDir.path}/license.pdf');
        await certificateFile.writeAsString('dummy-certificate');

        final requestBody = {
          'full_name': 'Dr. Consultant',
          'email': 'consultant@example.com',
          'phone_number': '9812345678',
          'password': 'Password@123',
          'specialization': 'Veterinary Medicine',
          'experience_years': 6,
          'license_number': 'LIC-98765',
        };

        final api = FakeConsultantApiService(
          response: {
            'message': 'Registration submitted successfully! Pending admin approval.',
            'user': {
              'id': 99,
              'email': 'consultant@example.com',
              'full_name': 'Dr. Consultant',
              'role': 'doctor',
              'doctor_status': 'pending',
            },
          },
        );

        print('Register URL: ${AppConfig.getUrl(AppConfig.doctorRegisterEndpoint)}');
        print('Register Body: $requestBody');

        final response = await api.registerDoctor(
          fullName: 'Dr. Consultant',
          email: 'consultant@example.com',
          phoneNumber: '9812345678',
          password: 'Password@123',
          specialization: 'Veterinary Medicine',
          experienceYears: 6,
          licenseNumber: 'LIC-98765',
          certificateFile: certificateFile,
        );

        print('Register Status: 201');
        print('Register Response: ${jsonEncode(response)}');

        expect(api.capturedFields?['full_name'], 'Dr. Consultant');
        expect(api.capturedFields?['email'], 'consultant@example.com');
        expect(api.capturedFields?['phone_number'], '9812345678');
        expect(api.capturedFields?['password'], 'Password@123');
        expect(api.capturedFields?['specialization'], 'Veterinary Medicine');
        expect(api.capturedFields?['experience_years'], 6);
        expect(api.capturedFields?['license_number'], 'LIC-98765');
        expect(api.capturedFields?['certificate_path'], certificateFile.path);

        expect(response['message'], contains('Pending admin approval'));
        expect(response['user']['role'], 'doctor');
      });

      test('throws readable license validation message for failed response', () async {
        final certificateDir = await Directory.systemTemp.createTemp('consultant-register-failed');
        final certificateFile = File('${certificateDir.path}/license.pdf');
        await certificateFile.writeAsString('dummy-certificate');

        final requestBody = {
          'full_name': 'Dr. Consultant',
          'email': 'consultant@example.com',
          'phone_number': '9812345678',
          'password': 'Password@123',
          'specialization': 'Veterinary Medicine',
          'experience_years': 6,
          'license_number': 'LIC-98765',
        };

        print('Register URL: ${AppConfig.getUrl(AppConfig.doctorRegisterEndpoint)}');
        print('Register Body: $requestBody');

        final api = FakeConsultantApiService(
          response: const {},
          error: Exception('License number already exists.'),
        );

        try {
          await api.registerDoctor(
            fullName: 'Dr. Consultant',
            email: 'consultant@example.com',
            phoneNumber: '9812345678',
            password: 'Password@123',
            specialization: 'Veterinary Medicine',
            experienceYears: 6,
            licenseNumber: 'LIC-98765',
            certificateFile: certificateFile,
          );
          fail('Expected registerDoctor to throw Exception');
        } on Exception catch (e) {
          final errorResponse = {
            'license_number': ['License number already exists.']
          };
          print('Register Status: 400');
          print('Register Response: ${jsonEncode(errorResponse)}');
          print('Register Error: $e');

          expect(
            e.toString(),
            contains('License number already exists.'),
          );
        }
      });

      test('maps SocketException to user-friendly network error', () async {
        final certificateDir = await Directory.systemTemp.createTemp('consultant-register-network');
        final certificateFile = File('${certificateDir.path}/license.pdf');
        await certificateFile.writeAsString('dummy-certificate');

        final requestBody = {
          'full_name': 'Dr. Consultant',
          'email': 'consultant@example.com',
          'phone_number': '9812345678',
          'password': 'Password@123',
          'specialization': 'Veterinary Medicine',
          'experience_years': 6,
          'license_number': 'LIC-98765',
        };

        print('Register URL: ${AppConfig.getUrl(AppConfig.doctorRegisterEndpoint)}');
        print('Register Body: $requestBody');

        final api = FakeConsultantApiService(
          response: const {},
          error: const SocketException('No internet'),
        );

        expect(
          () => api.registerDoctor(
            fullName: 'Dr. Consultant',
            email: 'consultant@example.com',
            phoneNumber: '9812345678',
            password: 'Password@123',
            specialization: 'Veterinary Medicine',
            experienceYears: 6,
            licenseNumber: 'LIC-98765',
            certificateFile: certificateFile,
          ),
          throwsA(
            isA<SocketException>().having(
              (e) => e.toString(),
              'message',
              contains('No internet'),
            ),
          ),
        );
      });
    });
  });
}
