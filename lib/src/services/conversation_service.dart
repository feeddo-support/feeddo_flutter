import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/conversation.dart';
import 'api_service.dart';
import 'websocket_service.dart';

class ConversationService extends ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService? _webSocketService;

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _activeConversationId;

  int _unreadMessageCount = 0;
  int get unreadMessageCount => _unreadMessageCount;

  ConversationService(this._apiService, this._webSocketService) {
    _webSocketService?.messages.listen(_handleWebSocketMessage);
  }

  void setActiveConversationId(String? id) {
    _activeConversationId = id;
    if (id != null) {
      markAsRead(id);
    }
  }

  void updateWebSocketService(WebSocketService wsService) {
    // If we were already listening to a different service (unlikely but possible), we might want to cancel subscription
    // But for now, just listen to the new one
    wsService.messages.listen(_handleWebSocketMessage);
  }

  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    _error = null;
    // notifyListeners(); // Avoid notifying here to prevent build during build if called from build

    try {
      final convs = await _apiService.getConversations(userId);
      // Sort by lastMessageAt descending
      convs.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      _conversations = convs;
      _updateUnreadCount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Conversation> createConversation(String userId,
      {String agentName = 'support_agent'}) async {
    final conversation =
        await _apiService.createConversation(userId, agentName: agentName);
    _conversations.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  Future<Map<String, dynamic>> uploadMedia(File file, String userId) async {
    return await _apiService.uploadMedia(file, userId);
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    // Check if it's a message
    if (data['role'] == 'assistant' ||
        data['role'] == 'human' ||
        data['role'] == 'user') {
      final conversationId = data['conversationId'];
      if (conversationId == null) return;

      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        var conversation = _conversations[index];

        // Update fields
        final content = data['content'] as String?;
        final createdAt =
            data['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
        final role = data['role'] as String?;
        final displayName = data['displayName'] as String?;

        // Update display name if assistant or human
        String? newDisplayName = conversation.displayName;
        int unreadCount = conversation.unreadMessages;

        if (role == 'assistant' || role == 'human') {
          if (displayName != null) {
            newDisplayName = displayName;
          }
          // Increment unread count if not currently active
          if (_activeConversationId != conversationId) {
            unreadCount++;
          }
        }

        // Parse content to remove JSON block for preview
        String? preview = content;
        if (content != null) {
          final regex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```');
          final match = regex.firstMatch(content);
          if (match != null) {
            preview = content.replaceFirst(match.group(0)!, '').trim();
          }
        }

        conversation = conversation.copyWith(
          lastMessagePreview: preview,
          lastMessageAt: createdAt,
          displayName: newDisplayName,
          unreadMessages: unreadCount,
        );

        // Move to top
        _conversations.removeAt(index);
        _conversations.insert(0, conversation);
        _updateUnreadCount();
        notifyListeners();
      }
    }
  }

  void markAsRead(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(unreadMessages: 0);
      _updateUnreadCount();
      notifyListeners();
    }
  }

  void sendReadReceipt(String conversationId) {
    if (_webSocketService != null) {
      _webSocketService.send({
        'type': 'read_receipt',
        'conversationId': conversationId,
      });
    }
    markAsRead(conversationId);
  }

  Future<void> rateConversation(String conversationId, int rating) async {
    await _apiService.rateConversation(conversationId, rating);

    // Update local state
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] =
          _conversations[index].copyWith(userSatisfaction: rating);
      notifyListeners();
    }
  }

  void _updateUnreadCount() {
    _unreadMessageCount = _conversations.fold<int>(
      0,
      (sum, conversation) => sum + conversation.unreadMessages,
    );
  }

  void updateConversation(Conversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
      notifyListeners();
    }
  }
}
