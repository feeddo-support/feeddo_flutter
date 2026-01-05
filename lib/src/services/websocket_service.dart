import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String baseUrl;
  final String apiKey;
  String? _userId;
  bool _isDisposed = false;
  bool _isConnected = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  WebSocketService({
    required this.baseUrl,
    required this.apiKey,
  });

  String? _currentConversationId;

  Future<void> connect({required String userId, String? conversationId}) async {
    _isDisposed = false;
    _userId = userId;

    // If connected and conversationId matches (or both null), do nothing
    if (_isConnected) {
      if (_currentConversationId == conversationId) {
        return;
      }
      // If conversationId changed, close and reconnect
      debugPrint(
          'WebSocket: Switching conversation from $_currentConversationId to $conversationId');
      await _channel?.sink.close();
      _channel = null;
      _isConnected = false;
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
      _channel = WebSocketChannel.connect(uri);

      // Assume connected until error or done
      _isConnected = true;

      _channel!.stream.listen(
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
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          debugPrint('WebSocket: Connection closed');
          _isConnected = false;
          _reconnect();
        },
      );

      debugPrint('WebSocket: Connected');
    } catch (e) {
      debugPrint('WebSocket: Connection failed: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isDisposed || _userId == null) return;

    // Simple reconnection logic
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isDisposed && !_isConnected) {
        connect(userId: _userId!, conversationId: _currentConversationId);
      }
    });
  }

  Future<void> send(Map<String, dynamic> message) async {
    // If not connected, try to connect first
    if (!_isConnected) {
      if (_userId == null) {
        debugPrint('WebSocket: Cannot send message - userId not set');
        return;
      }

      debugPrint(
          'WebSocket: Not connected, connecting before sending message...');
      await connect(userId: _userId!, conversationId: _currentConversationId);

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Now try to send
    if (_isConnected && _channel != null) {
      final encoded = jsonEncode(message);
      debugPrint('WebSocket: Sending: $encoded');
      _channel!.sink.add(encoded);
    } else {
      debugPrint('WebSocket: Failed to connect, cannot send message');
    }
  }

  void disconnect() {
    _isDisposed = true;
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
