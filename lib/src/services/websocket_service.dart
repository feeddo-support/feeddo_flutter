import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocket? _webSocket;
  final String baseUrl;
  final String apiKey;
  final String userId;
  bool _isDisposed = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  WebSocketService({
    required this.baseUrl,
    required this.apiKey,
    required this.userId,
  });

  String? _currentConversationId;

  Future<void> connect({String? conversationId}) async {
    if (_isDisposed) return;

    // If connected and conversationId matches (or both null), do nothing
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      if (_currentConversationId == conversationId) {
        return;
      }
      // If conversationId changed, close and reconnect
      debugPrint(
          'WebSocket: Switching conversation from $_currentConversationId to $conversationId');
      await _webSocket!.close();
      _webSocket = null;
    }

    _currentConversationId = conversationId;

    try {
      // Convert https://.../api to wss://.../api
      final wsUrl = baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      final queryParams = {
        'apiKey': apiKey,
        'userId': userId,
      };
      if (conversationId != null) {
        queryParams['conversationId'] = conversationId;
      }

      final uri =
          Uri.parse('$wsUrl/chat/ws').replace(queryParameters: queryParams);

      debugPrint('WebSocket: Connecting to $uri');
      _webSocket = await WebSocket.connect(uri.toString());

      _webSocket!.listen(
        (data) {
          try {
            debugPrint('WebSocket: Received: $data');
            final decoded = jsonDecode(data);
            _messageController.add(decoded);
          } catch (e) {
            debugPrint('WebSocket: Error decoding message: $e');
          }
        },
        onError: (e) {
          debugPrint('WebSocket: Error: $e');
          _reconnect();
        },
        onDone: () {
          debugPrint('WebSocket: Connection closed');
          _reconnect();
        },
      );

      debugPrint('WebSocket: Connected');
    } catch (e) {
      debugPrint('WebSocket: Connection failed: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isDisposed) return;

    // Simple reconnection logic
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isDisposed &&
          (_webSocket == null || _webSocket!.readyState != WebSocket.open)) {
        connect();
      }
    });
  }

  void send(Map<String, dynamic> message) {
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      final encoded = jsonEncode(message);
      debugPrint('WebSocket: Sending: $encoded');
      _webSocket!.add(encoded);
    } else {
      debugPrint('WebSocket: Not connected, cannot send message');
    }
  }

  void disconnect() {
    _isDisposed = true;
    _webSocket?.close();
    _webSocket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
