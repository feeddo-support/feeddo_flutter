import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/conversation_service.dart';
import 'models/home_data.dart';
import 'models/end_user.dart';
import 'models/conversation.dart';
import 'models/push_provider.dart';

import 'models/ticket.dart';
import 'models/task_comment.dart';
import 'utils/device_info_helper.dart';
import 'utils/storage_helper.dart';
import 'ui/screens/feeddo_home_screen.dart';
import 'ui/screens/feeddo_messages_screen.dart';
import 'ui/screens/feeddo_tickets_screen.dart';
import 'ui/screens/feeddo_tasks_screen.dart';
import 'ui/widgets/feeddo_notification_badge.dart';
import 'theme/feeddo_theme.dart';

/// Result from Feeddo initialization
class InitResult {
  final String userId;
  final Conversation? recentConversation;

  const InitResult({
    required this.userId,
    this.recentConversation,
  });

  /// Check if there are unread messages
  bool get hasUnreadMessages =>
      recentConversation != null && recentConversation!.unreadMessages > 0;
}

/// Internal Feeddo SDK implementation
class FeeddoInternal {
  static FeeddoInternal? _instance;
  final ApiService _apiService;
  late final WebSocketService _webSocketService;
  late final ConversationService _conversationService;
  String? _cachedUserId;
  String? _chatBotName;
  Conversation? _recentConversation;
  BuildContext? _notificationContext;
  bool _isInAppNotificationOn = false;
  FeeddoTheme? _notificationTheme;
  Duration _notificationDuration = const Duration(seconds: 10);

  // Private constructor
  FeeddoInternal._(String apiKey)
      : _apiService = ApiService(
          apiUrl: 'https://feeddo-backend.tithipal699.workers.dev/api',
          apiKey: apiKey,
        ) {
    _webSocketService = WebSocketService(
      baseUrl: _apiService.apiUrl,
      apiKey: _apiService.apiKey,
    );
    _conversationService = ConversationService(_apiService, _webSocketService);
  }

  /// Get the singleton instance
  static FeeddoInternal get instance {
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

  /// Get the recent conversation with unread messages (if any)
  Conversation? get recentConversation => instance._recentConversation;

  /// Initialize Feeddo SDK and create/update user
  ///
  /// Call this method at app startup or when user data changes.
  /// Automatically handles user ID management, device info collection,
  /// and in-app notifications.
  ///
  /// Returns an [InitResult] containing the user ID and recent conversation (if any).
  ///
  /// [apiKey]: Your Feeddo API key (required)
  /// [context]: BuildContext for showing notifications (optional)
  /// [isInAppNotificationOn]: Enable/disable in-app notifications (default: true)
  /// [theme]: Theme for notifications (optional, defaults to dark theme)
  /// [externalUserId]: Your system's user ID (optional)
  /// [userName]: User's display name (optional)
  /// [email]: User's email (optional)
  /// [userSegment]: Custom user segment (optional)
  /// [subscriptionStatus]: User's subscription status (optional)
  /// [customAttributes]: Custom key-value data (optional)
  ///
  /// Example:
  /// ```dart
  /// // With notifications
  /// final result = await Feeddo.init(
  ///   apiKey: 'your-api-key',
  ///   context: context,
  ///   userName: 'John Doe',
  ///   email: 'john@example.com',
  ///   isInAppNotificationOn: true, // Automatically shows notifications
  /// );
  ///
  /// // Without notifications
  /// final result = await Feeddo.init(
  ///   apiKey: 'your-api-key',
  ///   userName: 'John Doe',
  /// );
  /// ```
  static Future<InitResult> init({
    required String apiKey,
    required BuildContext context,
    bool isInAppNotificationOn = true,
    FeeddoTheme? theme,
    Duration? notificationDuration,
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
    String? pushToken,
    FeeddoPushProvider? pushProvider,
  }) async {
    // Create singleton instance if not exists
    _instance ??= FeeddoInternal._(apiKey);

    // Store context and notification settings
    _instance!._notificationContext = context;
    _instance!._isInAppNotificationOn =
        isInAppNotificationOn;
    _instance!._notificationTheme = theme ?? FeeddoTheme.dark();
    if (notificationDuration != null) {
      _instance!._notificationDuration = notificationDuration;
    }

    // Call instance method to upsert user
    final userId = await _instance!._upsertUser(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
      pushToken: pushToken,
      pushProvider: pushProvider,
    );

    // Automatically show notification if there are unread messages
    if (isInAppNotificationOn &&
        _instance!._recentConversation != null) {
      final recentConv = _instance!._recentConversation!;
      if (recentConv.unreadMessages > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FeeddoNotificationManager.showNotification(
            context,
            recentConv,
            theme: _instance!._notificationTheme,
            duration: _instance!._notificationDuration,
          );
        });
      }
    }

    // Setup real-time notification listener if enabled
    if (isInAppNotificationOn) {
      _instance!._setupNotificationListener();
    }

    return InitResult(
      userId: userId,
      recentConversation: _instance!._recentConversation,
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
    String? pushToken,
    FeeddoPushProvider? pushProvider,
  }) async {
    // Load cached user ID from SharedPreferences
    _cachedUserId ??= await StorageHelper.getUserId();

    // Load saved user data from preferences if attributes are null
    externalUserId ??= await StorageHelper.getExternalUserId();
    userName ??= await StorageHelper.getUserName();
    email ??= await StorageHelper.getEmail();
    userSegment ??= await StorageHelper.getUserSegment();
    subscriptionStatus ??= await StorageHelper.getSubscriptionStatus();
    customAttributes ??= await StorageHelper.getCustomAttributes();

    // If push token is not provided, try to get it from storage
    // Note: We don't have storage methods for push token yet, but we can add them later if needed.
    // For now, we rely on the caller passing it.

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
      pushToken: pushToken,
      pushProvider: pushProvider,
    );

    try {
      final response = await _apiService.upsertEndUser(endUser);

      // Cache the user ID
      _cachedUserId = response.userId;

      // Parse and store recent conversation if available
      if (response.recentConversation != null) {
        try {
          _recentConversation =
              Conversation.fromJson(response.recentConversation!);
          _conversationService.updateConversation(_recentConversation!);
        } catch (e) {
          debugPrint('Feeddo: Failed to parse recent conversation: $e');
        }
      }

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

  /// Update user information (e.g., username, email, etc.)
  ///
  /// This method allows you to update user information after initialization.
  /// Useful for updating username when user enters it for the first time.
  ///
  /// Example:
  /// ```dart
  /// await Feeddo.instance.updateUser(userName: 'John Doe');
  /// ```
  Future<String> updateUser({
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
    String? pushToken,
    FeeddoPushProvider? pushProvider,
  }) async {
    return await _upsertUser(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
      pushToken: pushToken,
      pushProvider: pushProvider,
    );
  }

  /// Register push token for the current user
  Future<void> registerPushToken({
    required String pushToken,
    required FeeddoPushProvider pushProvider,
  }) async {
    // If user is not initialized, we can't register token yet
    // But we can store it for later initialization?
    // For now, we assume init() has been called.

    if (_cachedUserId == null) {
      // Try to get from storage
      _cachedUserId = await StorageHelper.getUserId();
      if (_cachedUserId == null) {
        debugPrint('Feeddo: Cannot register push token. User not initialized.');
        return;
      }
    }

    try {
      // We can use upsertUser to update just the push token
      // Or we could add a specific endpoint in ApiService
      // Since we updated upsertUser to handle push tokens, let's use that.
      await _upsertUser(
        pushToken: pushToken,
        pushProvider: pushProvider,
      );
      debugPrint('Feeddo: Push token registered successfully');
    } catch (e) {
      debugPrint('Feeddo: Failed to register push token: $e');
    }
  }

  /// Internal method to setup notification listener for WebSocket messages
  void _setupNotificationListener() {
    conversationService.onNewMessage = (conversation) {
      // Don't show notification if we are currently viewing this conversation
      if (conversationService.activeConversationId == conversation.id) {
        return;
      }

      if (_notificationContext != null && _isInAppNotificationOn) {
        FeeddoNotificationManager.showNotification(
          _notificationContext!,
          conversation,
          theme: _notificationTheme,
          duration: _notificationDuration,
        );
      }
    };
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
  Future<TaskComment> addTaskComment(String taskId, String content,
      {List<Map<String, dynamic>>? attachments}) async {
    return await _apiService.addTaskComment(taskId, content,
        userId: userId, attachments: attachments);
  }

  /// Vote on a task
  Future<Map<String, dynamic>> voteTask(String taskId, String voteType) async {
    return await _apiService.voteTask(taskId, voteType, userId: userId);
  }

  /// Get the WebSocket service
  WebSocketService get webSocketService => _webSocketService;

  /// Get the Conversation service
  ConversationService get conversationService => _conversationService;

  /// Connect to WebSocket
  Future<void> connectWebSocket({String? conversationId}) async {
    if (userId == null) {
      debugPrint('Feeddo: Cannot connect to WebSocket, userId is null');
      return;
    }

    await _webSocketService.connect(
        userId: userId!, conversationId: conversationId);
  }

  /// Disconnect from WebSocket
  void disconnectWebSocket() {
    _webSocketService.disconnect();
  }

  /// Dispose and cleanup Feeddo instance
  ///
  /// Call this when you want to completely reset Feeddo state,
  /// typically when user logs out.
  static void dispose() {
    if (_instance != null) {
      _instance!.conversationService.onNewMessage = null;
      _instance!.disconnectWebSocket();
      _instance!._webSocketService.dispose();
      FeeddoNotificationManager.clearAll();
      _instance = null;
    }
  }

  /// Open the Feeddo support home screen
  static void show(
    BuildContext context, {
    FeeddoTheme? theme,
    bool useSmallWindowOnDesktop = true,
    BoxConstraints? desktopConstraints,
  }) {
    // Connect to WebSocket when opening the screen
    _instance?.connectWebSocket();

    final effectiveTheme = theme ?? FeeddoTheme.dark();
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    // Check if we are on desktop or web to reduce font size
    final isDesktopOrWeb = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    // Helper to wrap with text scaler if needed
    Widget wrapWithTextScaler(Widget child, BuildContext ctx) {
      if (isDesktopOrWeb) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: const TextScaler.linear(0.85),
          ),
          child: child,
        );
      }
      return child;
    }

    if (isLargeScreen && useSmallWindowOnDesktop) {
      final nestedNavigatorKey = GlobalKey<NavigatorState>();
      final constraints = desktopConstraints ??
          const BoxConstraints(maxWidth: 400, maxHeight: 600);

      showDialog(
        context: context,
        barrierColor: Colors.transparent, // No dimming for chat widget feel
        builder: (dialogContext) => Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: constraints,
                decoration: BoxDecoration(
                  color: effectiveTheme.colors.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: wrapWithTextScaler(
                    Navigator(
                      key: nestedNavigatorKey,
                      onGenerateRoute: (settings) {
                        return MaterialPageRoute(
                          builder: (innerContext) => FeeddoHomeScreen(
                            theme: effectiveTheme,
                            onClose: () {
                              Navigator.of(dialogContext).pop();
                            },
                            onMessagesTap: () {
                              nestedNavigatorKey.currentState?.push(
                                MaterialPageRoute(
                                  builder: (context) => FeeddoMessagesScreen(
                                      theme: effectiveTheme),
                                ),
                              );
                            },
                            onTicketsTap: () {
                              nestedNavigatorKey.currentState?.push(
                                MaterialPageRoute(
                                  builder: (context) => FeeddoTicketsScreen(
                                      theme: effectiveTheme),
                                ),
                              );
                            },
                            onFeatureRequestTap: () {
                              nestedNavigatorKey.currentState?.push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FeeddoTasksScreen(theme: effectiveTheme),
                                ),
                              );
                            },
                            onSendMessageTap: () {
                              // TODO: Navigate to new message
                              debugPrint('Send message tapped');
                            },
                          ),
                        );
                      },
                    ),
                    context,
                  ),
                ),
              ),
            ),
          ),
        ),
      ).then((_) {
        // Reconnect with no conversation ID to ensure we receive all notifications
        _instance?.connectWebSocket(conversationId: null);
      });
    } else {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => wrapWithTextScaler(
            FeeddoHomeScreen(
              theme: effectiveTheme,
              onClose: () {
                Navigator.of(context).pop();
              },
              onMessagesTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        FeeddoMessagesScreen(theme: effectiveTheme),
                  ),
                );
              },
              onTicketsTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        FeeddoTicketsScreen(theme: effectiveTheme),
                  ),
                );
              },
              onFeatureRequestTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        FeeddoTasksScreen(theme: effectiveTheme),
                  ),
                );
              },
              onSendMessageTap: () {
                // TODO: Navigate to new message
                debugPrint('Send message tapped');
              },
            ),
            context,
          ),
          fullscreenDialog: true,
        ),
      )
          .then((_) {
        // Do not disconnect when the screen is popped to keep receiving notifications
        // _instance?.disconnectWebSocket();

        // Reconnect with no conversation ID to ensure we receive all notifications
        _instance?.connectWebSocket(conversationId: null);
      });
    }
  }

  /// Open the Community Board screen (Feature Requests & Bug Reports)
  static void showCommunityBoard(
    BuildContext context, {
    FeeddoTheme? theme,
  }) {
    final effectiveTheme = theme ?? FeeddoTheme.dark();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeeddoTasksScreen(theme: effectiveTheme),
        fullscreenDialog: true,
      ),
    );
  }
}
