import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:kishan_sathi_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kishan_sathi_frontend/features/auth/data/models/user_model.dart';

void main() {
  group('Buyer Registration Unit Tests', () {
    group('UserModel', () {
      test('fromJson maps buyer registration payload correctly', () {
        final json = {
          'id': 12,
          'email': 'buyer@example.com',
          'full_name': 'Kishan Buyer',
          'phone_number': '9800000000',
          'profile_picture_url': null,
          'role': 'buyer',
          'role_display': 'Buyer',
          'is_doctor_verified': false,
          'doctor_status': null,
          'doctor_status_display': null,
          'specialization': null,
          'experience_years': null,
          'license_number': null,
          'date_joined': '2026-03-30T10:00:00Z',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 12);
        expect(user.email, 'buyer@example.com');
        expect(user.fullName, 'Kishan Buyer');
        expect(user.phoneNumber, '9800000000');
        expect(user.role, 'buyer');
        expect(user.isBuyer, isTrue);
        expect(user.isFarmer, isFalse);
        expect(user.initials, 'KB');
      });

      test('toJson returns serializable map with required registration fields', () {
        const user = UserModel(
          id: 5,
          email: 'buyer@test.com',
          fullName: 'Buyer Test',
          phoneNumber: '9811111111',
          role: 'buyer',
          roleDisplay: 'Buyer',
        );

        final map = user.toJson();

        expect(map['id'], 5);
        expect(map['email'], 'buyer@test.com');
        expect(map['full_name'], 'Buyer Test');
        expect(map['phone_number'], '9811111111');
        expect(map['role'], 'buyer');
      });

      test('formattedJoinDate falls back to original value when date cannot be parsed', () {
        const user = UserModel(
          id: 1,
          email: 'buyer@test.com',
          fullName: 'Buyer Test',
          role: 'buyer',
          dateJoined: 'invalid-date',
        );

        expect(user.formattedJoinDate, 'invalid-date');
      });
    });

    group('ApiService.register', () {
      test('sends expected body and returns decoded response for 201', () async {
        late Uri capturedUri;
        late Map<String, dynamic> capturedBody;

        final client = MockClient((request) async {
          capturedUri = request.url;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          print("User registered Successfully: $capturedBody");

          return http.Response(
            jsonEncode({
              'token': 'token-123',
              'user': {
                'id': 10,
                'email': 'buyer@example.com',
                'full_name': 'Kishan Buyer',
                'role': 'buyer',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = ApiService(client: client);

        final response = await api.register(
          fullName: 'Kishan Buyer',
          email: 'buyer@example.com',
          phoneNumber: '9800000000',
          password: 'Password@123',
          role: 'buyer',
        );

        expect(capturedUri.path, contains('register'));
        expect(capturedBody['full_name'], 'Kishan Buyer');
        expect(capturedBody['email'], 'buyer@example.com');
        expect(capturedBody['phone_number'], '9800000000');
        expect(capturedBody['password'], 'Password@123');
        expect(capturedBody['role'], 'buyer');

        expect(response['token'], 'token-123');
        expect(response['user']['role'], 'buyer');

        api.dispose();
      });

      test('throws readable email validation message for 400 response', () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'email': ['User with this email already exists.']
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = ApiService(client: client);

        expect(
          () => api.register(
            fullName: 'Kishan Buyer',
            email: 'buyer@example.com',
            phoneNumber: '9800000000',
            password: 'Password@123',
            role: 'buyer',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('User with this email already exists.'),
            ),
          ),
        );

        api.dispose();
      });

      test('maps SocketException to user-friendly network error', () async {
        final client = MockClient((request) async {
          throw const SocketException('No internet');
        });

        final api = ApiService(client: client);

        expect(
          () => api.register(
            fullName: 'Kishan Buyer',
            email: 'buyer@example.com',
            phoneNumber: '9800000000',
            password: 'Password@123',
            role: 'buyer',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Network error. Please check your internet connection.'),
            ),
          ),
        );

        api.dispose();
      });
    });
  });
}
