import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/conversation.dart';
import 'api_service.dart';
import 'websocket_service.dart';

class ConversationService extends ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _webSocketService;

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  int _unreadMessageCount = 0;
  int get unreadMessageCount => _unreadMessageCount;

  // Map to store unread counts by conversation ID
  final Map<String, int> _unreadCounts = {};

  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // Callback for when a new message is received
  Function(Conversation)? onNewMessage;

  ConversationService(this._apiService, this._webSocketService) {
    _webSocketService.messages.listen(_handleWebSocketMessage);
  }

  void setInitialUnreadCount(String conversationId, int count) {
    _unreadCounts[conversationId] = count;
    _updateTotalUnreadCount();
  }

  void setActiveConversationId(String? id) {
    _activeConversationId = id;
    if (id != null) {
      markAsRead(id);
    }
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

      // Sync map with loaded conversations
      for (var c in _conversations) {
        _unreadCounts[c.id] = c.unreadMessages;
      }
      _updateTotalUnreadCount();
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

  Future<Map<String, dynamic>> uploadMedia(XFile file, String userId) async {
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

      // Extract common data
      final content = data['content'] as String?;
      final createdAt =
          data['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final role = data['role'] as String?;
      final displayName = data['displayName'] as String?;

      // Parse content to remove JSON block for preview
      String? preview = content;
      if (content != null) {
        final regex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```');
        final match = regex.firstMatch(content);
        if (match != null) {
          preview = content.replaceFirst(match.group(0)!, '').trim();
        }
      }

      if (index != -1) {
        var conversation = _conversations[index];

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
            _unreadCounts[conversationId] =
                (_unreadCounts[conversationId] ?? 0) + 1;
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
        _updateTotalUnreadCount();
        notifyListeners();

        // Trigger notification callback if not active conversation
        if (_activeConversationId != conversationId &&
            (role == 'assistant' || role == 'human')) {
          onNewMessage?.call(conversation);
        }
      } else {
        // Conversation not in list, but we should still notify if it's an assistant message
        if (role == 'assistant' || role == 'human') {
          // Create a temporary conversation object for notification
          // We use placeholders for required fields that aren't available
          final conversation = Conversation(
            id: conversationId,
            appId: '', // Placeholder
            status: 'active', // Placeholder
            autoReply: false,
            startedAt: createdAt,
            lastMessageAt: createdAt,
            displayName: displayName ?? 'Support',
            lastMessagePreview: preview,
            unreadMessages: 1,
          );

          if (_activeConversationId != conversationId) {
            onNewMessage?.call(conversation);
            // Update unread count map
            _unreadCounts[conversationId] =
                (_unreadCounts[conversationId] ?? 0) + 1;
            _updateTotalUnreadCount();
          }
        }
      }
    }
  }

  void markAsRead(String conversationId) {
    // Update map
    _unreadCounts[conversationId] = 0;
    _updateTotalUnreadCount();

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(unreadMessages: 0);
      notifyListeners();
    }
  }

  void sendReadReceipt(String conversationId) {
    _webSocketService.send({
      'type': 'read_receipt',
      'conversationId': conversationId,
    });
    debugPrint('Sent read receipt for conversation $conversationId');
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

  void _updateTotalUnreadCount() {
    final newCount = _unreadCounts.values.fold(0, (sum, count) => sum + count);
    if (_unreadMessageCount != newCount) {
      _unreadMessageCount = newCount;
      debugPrint(
          '🔔 ConversationService: Unread count updated to $_unreadMessageCount');
      _unreadCountController.add(_unreadMessageCount);
    }
  }

  void updateConversation(Conversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
      // Sort by lastMessageAt descending
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    }

    // Also update unread count map
    _unreadCounts[conversation.id] = conversation.unreadMessages;
    _updateTotalUnreadCount();

    notifyListeners();
  }
}
