import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:kishan_sathi_frontend/features/auth/data/datasources/auth_remote_datasource.dart';

void main() {
	group('Buyer Login Unit Tests', () {
		test('sends expected body without role and returns decoded response for 200', () async {
			late Uri capturedUri;
			late Map<String, dynamic> capturedBody;

			final client = MockClient((request) async {
				capturedUri = request.url;
				capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

				return http.Response(
					jsonEncode({
						'token': 'login-token-123',
						'user': {
							'id': 20,
							'email': 'buyer@example.com',
							'full_name': 'Buyer Login',
							'role': 'buyer',
						}
					}),
					200,
					headers: {'content-type': 'application/json'},
				);
			});

			final api = ApiService(client: client);

			final response = await api.login(
				email: 'buyer@example.com',
				password: 'Password@123',
			);

			expect(capturedUri.path, contains('login'));
			expect(capturedBody['email'], 'buyer@example.com');
			expect(capturedBody['password'], 'Password@123');
			expect(capturedBody.containsKey('role'), isFalse);
			expect(response['token'], 'login-token-123');
			expect(response['user']['role'], 'buyer');

			api.dispose();
		});
    

		test('includes role in request body when provided', () async {
			late Map<String, dynamic> capturedBody;

			final client = MockClient((request) async {
				capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
				return http.Response(
					jsonEncode({
						'token': 'token-xyz',
						'user': {
							'id': 1,
							'email': 'buyer@example.com',
							'full_name': 'Buyer Login',
							'role': 'buyer',
						}
            
					}),
          
					200,
					headers: {'content-type': 'application/json'},
          
				);
			});

			final api = ApiService(client: client);

			await api.login(
				email: 'buyer@example.com',
				password: 'Password@123',
				role: 'buyer',
			);

			expect(capturedBody['role'], 'buyer');
      

			api.dispose();
		});

		test('throws readable message from non_field_errors for 403 response', () async {
			final client = MockClient((request) async {
				return http.Response(
					jsonEncode({'non_field_errors': ['Invalid credentials']}),
					403,
					headers: {'content-type': 'application/json'},
				);
			});

			final api = ApiService(client: client);

			expect(
				() => api.login(
					email: 'buyer@example.com',
					password: 'WrongPassword',
				),
				throwsA(
					isA<Exception>().having(
						(e) => e.toString(),
						'message',
						contains('Invalid credentials'),
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
				() => api.login(
					email: 'buyer@example.com',
					password: 'Password@123',
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
}