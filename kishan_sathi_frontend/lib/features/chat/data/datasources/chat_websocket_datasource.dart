import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../../../../core/constants/api_constants.dart';

class ChatWebSocketDataSource {
  WebSocket? _socket;
  StreamSubscription? _socketSubscription;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isConnected => _socket != null;

  Future<void> connect({
    required int roomId,
    required String token,
  }) async {
    await disconnect();

    final normalizedToken = _normalizeToken(token);
    if (normalizedToken.isEmpty) {
      throw Exception('Missing auth token for websocket connection.');
    }

    final wsUri = _buildWsUri(
      roomId: roomId,
      token: normalizedToken,
    );

    final wsUrl = wsUri.toString();
    developer.log(
      'Connecting chat websocket to: $wsUrl',
      name: 'ChatWebSocketDataSource',
    );

    _socket = await WebSocket.connect(wsUrl);
    _socketSubscription = _socket!.listen(
      _handleSocketData,
      onError: _handleSocketError,
      onDone: _handleSocketDone,
      cancelOnError: false,
    );
  }

  Uri _buildWsUri({
    required int roomId,
    required String token,
  }) {
    final wsBase = ApiConstants.wsBaseUrl;

    return Uri.parse('$wsBase/ws/chat/$roomId/?token=$token');
  }

  String _normalizeToken(String token) {
    final normalized = token.trim();
    if (normalized.startsWith('Token ')) {
      return normalized.substring(6).trim();
    }
    if (normalized.startsWith('Bearer ')) {
      return normalized.substring(7).trim();
    }
    return normalized;
  }

  void _handleSocketData(dynamic rawData) {
    try {
      if (rawData is! String || rawData.isEmpty) {
        return;
      }

      final decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) {
        _eventController.add(decoded);
      }
    } catch (error) {
      _eventController.add({
        'type': 'error',
        'message': 'Invalid websocket payload: $error',
      });
    }
  }

  void _handleSocketError(Object error) {
    _eventController.add({
      'type': 'error',
      'message': 'WebSocket error: $error',
    });
  }

  void _handleSocketDone() {
    _eventController.add({'type': 'socket_closed'});
    _cleanupSocket();
  }

  void sendTyping(bool isTyping) {
    _sendJson({
      'type': 'typing',
      'is_typing': isTyping,
    });
  }

  void sendReadReceipt() {
    _sendJson({'type': 'read_receipt'});
  }

  void _sendJson(Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    socket.add(jsonEncode(payload));
  }

  Future<void> disconnect() async {
    await _socketSubscription?.cancel();
    await _socket?.close();
    _cleanupSocket();
  }

  void _cleanupSocket() {
    _socketSubscription = null;
    _socket = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
