import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';

class KhaltiRemoteDataSource {
  final http.Client _client;
  final String _baseUrl = '${ApiConfig.baseUrl}/payments/khalti';

  KhaltiRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  String _normalizeToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('Token ')) {
      return trimmed.substring(6).trim();
    }

    if (trimmed.startsWith('Bearer ')) {
      return trimmed.substring(7).trim();
    }

    return trimmed;
  }

  Map<String, String> _headers(String token) {
    final normalized = _normalizeToken(token);
    return {
      'Authorization': 'Token $normalized',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  String _extractMessage(Map<String, dynamic> payload, {String fallback = 'Request failed'}) {
    return (payload['message'] as String?) ??
        (payload['detail'] as String?) ??
        (payload['error'] as String?) ??
        ((payload['non_field_errors'] is List && (payload['non_field_errors'] as List).isNotEmpty)
            ? (payload['non_field_errors'] as List).first.toString()
            : null) ??
        fallback;
  }

  Future<Map<String, dynamic>?> getBusinessKhaltiAccount(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/account/'),
      headers: _headers(token),
    );
    final data = _decode(response);

    if (response.statusCode == 200) {
      return data['data'] as Map<String, dynamic>?;
    }
    throw Exception(_extractMessage(data, fallback: 'Failed to load Khalti account'));
  }

  Future<Map<String, dynamic>> linkKhaltiAccount({
    required String token,
    required String khaltiId,
    required String accountName,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/account/'),
      headers: _headers(token),
      body: json.encode({'khalti_id': khaltiId, 'account_name': accountName}),
    );
    final data = _decode(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return (data['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    throw Exception(_extractMessage(data, fallback: 'Failed to link Khalti account'));
  }

  Future<Map<String, dynamic>> updateKhaltiAccount({
    required String token,
    String? khaltiId,
    String? accountName,
  }) async {
    final body = <String, dynamic>{};
    if (khaltiId != null) body['khalti_id'] = khaltiId;
    if (accountName != null) body['account_name'] = accountName;

    final response = await _client.patch(
      Uri.parse('$_baseUrl/account/'),
      headers: _headers(token),
      body: json.encode(body),
    );
    final data = _decode(response);

    if (response.statusCode == 200) {
      return (data['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    throw Exception(_extractMessage(data, fallback: 'Failed to update Khalti account'));
  }

  Future<void> unlinkKhaltiAccount(String token) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/account/'),
      headers: _headers(token),
    );
    final data = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(data, fallback: 'Failed to unlink Khalti account'));
    }
  }

  Future<Map<String, dynamic>> checkBusinessKhaltiStatus({
    required String token,
    required int relationshipId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/status/$relationshipId/'),
      headers: _headers(token),
    );
    final data = _decode(response);

    if (response.statusCode == 200) {
      return (data['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    throw Exception(_extractMessage(data, fallback: 'Failed to check Khalti status'));
  }

  Future<Map<String, dynamic>> initiateKhaltiPayment({
    required String token,
    required int relationshipId,
    required double amount,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'relationship_id': relationshipId,
      'amount': amount.toStringAsFixed(2),
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/initiate/'),
      headers: _headers(token),
      body: json.encode(body),
    );
    final data = _decode(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return (data['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    throw Exception(_extractMessage(data, fallback: 'Failed to initiate Khalti payment'));
  }

  Future<Map<String, dynamic>> verifyKhaltiPayment({
    required String token,
    required int paymentRecordId,
    required String pidx,
    String? transactionId,
    String? totalAmount,
    String? status,
    Map<String, dynamic>? khaltiResponse,
  }) async {
    final body = <String, dynamic>{
      'payment_record_id': paymentRecordId,
      'pidx': pidx,
      'transaction_id': transactionId ?? '',
      'total_amount': totalAmount ?? '',
      'status': status ?? '',
    };
    if (khaltiResponse != null) {
      body['khalti_response'] = khaltiResponse;
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/verify/'),
      headers: _headers(token),
      body: json.encode(body),
    );

    return _decode(response);
  }
}
