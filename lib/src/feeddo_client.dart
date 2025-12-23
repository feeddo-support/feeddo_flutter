import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/conversation_service.dart';
import 'models/home_data.dart';
import 'models/end_user.dart';
import 'models/conversation.dart';
import 'models/task.dart';
import 'models/ticket.dart';
import 'models/task_comment.dart';
import 'utils/device_info_helper.dart';
import 'utils/storage_helper.dart';
import 'ui/screens/feeddo_home_screen.dart';
import 'ui/screens/feeddo_messages_screen.dart';
import 'ui/screens/feeddo_tickets_screen.dart';
import 'ui/screens/feeddo_tasks_screen.dart';
import 'theme/feeddo_theme.dart';

/// Feeddo SDK - AI-powered customer support and feedback
class Feeddo {
  static Feeddo? _instance;
  final ApiService _apiService;
  WebSocketService? _webSocketService;
  ConversationService? _conversationService;
  String? _cachedUserId;
  String? _chatBotName;

  // Private constructor
  Feeddo._(String apiKey)
      : _apiService = ApiService(
          apiUrl: 'https://feeddo-backend.neloy-nr2.workers.dev/api',
          apiKey: apiKey,
        );

  /// Get the singleton instance
  static Feeddo get instance {
    if (_instance == null) {
      throw Exception('Feeddo not initialized. Call Feeddo.init() first.');
    }
    return _instance!;
  }

  /// Get the API service
  ApiService get apiService => _apiService;

  /// Get the current user ID
  String? get userId => instance._cachedUserId;

  /// Get the chatbot name
  String get chatBotName => instance._chatBotName ?? 'Feeddo';

  /// Initialize Feeddo SDK and create/update user
  ///
  /// Call this method at app startup or when user data changes.
  /// Automatically handles user ID management and device info collection.
  ///
  /// [apiKey]: Your Feeddo API key (required)
  /// [externalUserId]: Your system's user ID (optional)
  /// [userName]: User's display name (optional)
  /// [email]: User's email (optional)
  /// [userSegment]: Custom user segment (optional)
  /// [subscriptionStatus]: User's subscription status (optional)
  /// [customAttributes]: Custom key-value data (optional)
  ///
  /// Example:
  /// ```dart
  /// await Feeddo.init(
  ///   apiKey: 'your-api-key',
  ///   externalUserId: 'user-123',
  ///   userName: 'John Doe',
  ///   email: 'john@example.com',
  ///   subscriptionStatus: 'premium',
  ///   customAttributes: {'plan': 'pro'},
  /// );
  /// ```
  static Future<String> init({
    required String apiKey,
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
  }) async {
    // Create singleton instance if not exists
    _instance ??= Feeddo._(apiKey);

    // Call instance method to upsert user
    return await _instance!._upsertUser(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
    );
  }

  /// Internal method to upsert user
  Future<String> _upsertUser({
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
  }) async {
    // Load cached user ID from SharedPreferences
    _cachedUserId ??= await StorageHelper.getUserId();

    // Collect device info
    String? platform;
    String? deviceModel;
    String? osVersion;
    String? appVersion;

    try {
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      platform = deviceInfo.platform;
      deviceModel = deviceInfo.deviceModel;
      osVersion = deviceInfo.osVersion;
      appVersion = deviceInfo.appVersion;
    } catch (e) {
      debugPrint('Feeddo: Failed to collect device info: $e');
    }

    // Create EndUser object
    final endUser = EndUser(
      userId: _cachedUserId,
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      appVersion: appVersion,
      platform: platform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
    );

    try {
      final response = await _apiService.upsertEndUser(endUser);

      // Cache the user ID
      _cachedUserId = response.userId;

      // Save to SharedPreferences
      await StorageHelper.saveUserId(response.userId);
      await StorageHelper.saveUserData(
        externalUserId: externalUserId ?? response.externalUserId,
        userName: userName,
        email: email,
        userSegment: userSegment,
        subscriptionStatus: subscriptionStatus,
        customAttributes: customAttributes,
      );

      debugPrint('Feeddo: User ${response.action} - ID: ${response.userId}');
      return response.userId;
    } catch (e) {
      debugPrint('Feeddo: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Get home data for the current user
  Future<HomeData> getHomeData() async {
    if (userId == null) {
      throw FeeddoApiException('User not identified');
    }
    final homeData = await _apiService.getHomeData(userId!);
    // Update chatbot name from home data
    _chatBotName = homeData.chatbotName;
    return homeData;
  }

  /// Get conversations for the current user
  static Future<List<Conversation>> getConversations({String? userId}) async {
    if (_instance == null) {
      throw FeeddoApiException('Feeddo not initialized');
    }
    final targetUserId = userId ?? _instance!.userId;
    if (targetUserId == null) {
      throw FeeddoApiException('User not identified');
    }
    // Use conversation service to load and return conversations
    await _instance!.conversationService.loadConversations(targetUserId);
    return _instance!.conversationService.conversations;
  }

  /// Create a new conversation
  static Future<Conversation> createConversation(
      {String agentName = 'support_agent'}) async {
    if (_instance == null) {
      throw FeeddoApiException('Feeddo not initialized');
    }
    final userId = _instance!.userId;
    if (userId == null) {
      throw FeeddoApiException('User not identified');
    }
    return await _instance!.conversationService
        .createConversation(userId, agentName: agentName);
  }

  /// Get a task by ID
  Future<Task> getTask(String taskId) async {
    return await _apiService.getTask(taskId, userId: userId);
  }

  /// Get tasks
  Future<List<Task>> getTasks({
    String? type,
    String? priority,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
    bool? createdByMe,
  }) async {
    return await _apiService.getTasks(
      userId: userId,
      type: type,
      priority: priority,
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: page,
      limit: limit,
      createdByMe: createdByMe,
    );
  }

  /// Get a ticket by ID
  Future<Ticket> getTicket(String ticketId) async {
    return await _apiService.getTicket(ticketId, userId: userId);
  }

  /// Get tickets for the current user
  Future<List<Ticket>> getTickets() async {
    if (userId == null) {
      throw FeeddoApiException('User not identified');
    }
    return await _apiService.getTickets(userId!);
  }

  /// Add a comment to a task
  Future<TaskComment> addTaskComment(String taskId, String content) async {
    return await _apiService.addTaskComment(taskId, content, userId: userId);
  }

  /// Vote on a task
  Future<Map<String, dynamic>> voteTask(String taskId, String voteType) async {
    return await _apiService.voteTask(taskId, voteType, userId: userId);
  }

  /// Get the WebSocket service
  WebSocketService? get webSocketService => _webSocketService;

  /// Get the Conversation service
  ConversationService get conversationService {
    if (_conversationService == null) {
      _conversationService =
          ConversationService(_apiService, _webSocketService);
    }
    return _conversationService!;
  }

  /// Connect to WebSocket
  Future<void> connectWebSocket({String? conversationId}) async {
    if (userId == null) {
      debugPrint('Feeddo: Cannot connect to WebSocket, userId is null');
      return;
    }

    if (_webSocketService == null) {
      _webSocketService = WebSocketService(
        baseUrl: _apiService.apiUrl,
        apiKey: _apiService.apiKey,
        userId: userId!,
      );
      // If conversation service was already created, update it with the new websocket service
      _conversationService?.updateWebSocketService(_webSocketService!);
    }

    // If we are already connected, we might want to reconnect if the conversationId is different?
    // For now, let's just pass it to connect.
    await _webSocketService!.connect(conversationId: conversationId);
  }

  /// Disconnect from WebSocket
  void disconnectWebSocket() {
    _webSocketService?.disconnect();
    _webSocketService = null;
  }

  /// Open the Feeddo support home screen
  static void show(BuildContext context, {FeeddoTheme? theme}) {
    // Connect to WebSocket when opening the screen
    _instance?.connectWebSocket();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => FeeddoHomeScreen(
          theme: theme ?? FeeddoTheme.dark(),
          onClose: () {
            // Disconnect when closing via custom close button if any
            _instance?.disconnectWebSocket();
            Navigator.of(context).pop();
          },
          onMessagesTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    FeeddoMessagesScreen(theme: theme ?? FeeddoTheme.dark()),
              ),
            );
          },
          onTicketsTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    FeeddoTicketsScreen(theme: theme ?? FeeddoTheme.dark()),
              ),
            );
          },
          onFeatureRequestTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    FeeddoTasksScreen(theme: theme ?? FeeddoTheme.dark()),
              ),
            );
          },
          onSendMessageTap: () {
            // TODO: Navigate to new message
            debugPrint('Send message tapped');
          },
        ),
        fullscreenDialog: true,
      ),
    )
        .then((_) {
      // Disconnect when the screen is popped (app exit context)
      _instance?.disconnectWebSocket();
    });
  }
}
