import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'config/feeddo_config.dart';
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
          apiUrl: FeeddoConfig.apiUrl,
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
  static String _userId = '';
  Future<String>? _initLock;

  /// Ensure the user is initialized and synced with the backend database.
  /// Called lazily when user opens any Feeddo UI screen.
  Future<String> ensureUserInitialized() async {
    if (_initLock != null) {
      return await _initLock!;
    }

    _initLock = _performUserSync();
    try {
      final userId = await _initLock!;
      return userId;
    } finally {
      _initLock = null;
    }
  }

  Future<String> _performUserSync() async {
    final isSynced = await StorageHelper.isSyncedWithBackend();
    _cachedUserId ??= await StorageHelper.getUserId();

    // If already synced and we have a valid cached userId, avoid extra network calls
    if (isSynced && _cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }

    return await _upsertUser();
  }

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
    // 1. Record 1st app open timestamp locally (sets once, never overwritten)
    await StorageHelper.recordFirstAppOpenAt();

    // 2. Create singleton instance if not exists
    _instance ??= FeeddoInternal._(apiKey);

    // Store context and notification settings
    _instance!._notificationContext = context;
    _instance!._isInAppNotificationOn = isInAppNotificationOn;
    _instance!._notificationTheme = theme ?? FeeddoTheme.dark();
    if (notificationDuration != null) {
      _instance!._notificationDuration = notificationDuration;
    }

    // 3. Check if user identity or attributes changed
    final existingExternalId = await StorageHelper.getExternalUserId();
    final existingUserName = await StorageHelper.getUserName();
    final existingEmail = await StorageHelper.getEmail();
    final existingPushToken = await StorageHelper.getPendingPushToken();

    final hasChanges =
        (externalUserId != null && externalUserId != existingExternalId) ||
        (userName != null && userName != existingUserName) ||
        (email != null && email != existingEmail) ||
        (pushToken != null && pushToken != existingPushToken);

    if (hasChanges) {
      await StorageHelper.setSyncedWithBackend(false);
    }

    // Save user data to local storage without pushing to DB
    await StorageHelper.saveUserData(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
    );

    // Save push token locally if provided
    if (pushToken != null) {
      await StorageHelper.savePendingPushToken(
        pushToken: pushToken,
        pushProvider: pushProvider?.value,
      );
    }

    // 4. Retrieve existing user ID or generate persistent local user ID
    _userId = await StorageHelper.getOrCreateLocalUserId();
    _instance!._cachedUserId = _userId;

    // Setup real-time notification listener if enabled
    if (isInAppNotificationOn) {
      _instance!._setupNotificationListener();
    }

    // Only check for unread notifications if the user has an active conversation
    Conversation? recentConv;
    final hasActiveConv = await StorageHelper.hasActiveConversation();
    if (hasActiveConv && isInAppNotificationOn) {
      try {
        final unreadData = await _instance!._apiService
            .getUnreadData(_userId)
            .timeout(const Duration(seconds: 3));

        if (unreadData != null) {
          // Update active conversation flag if resolved on backend
          await StorageHelper.setHasActiveConversation(
              unreadData.hasActiveConversation);

          final conv = unreadData.recentConversation;
          if (conv != null) {
            recentConv = conv;
            _instance!._recentConversation = conv;
            _instance!._conversationService.updateConversation(conv);

            if (conv.unreadMessages > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  FeeddoNotificationManager.showNotification(
                    context,
                    conv,
                    theme: _instance!._notificationTheme,
                    duration: _instance!._notificationDuration,
                  );
                }
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Feeddo: Failed to check unread notifications: $e');
      }
    }

    return InitResult(
      userId: _userId,
      recentConversation: recentConv,
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

    // Load pending push token if not provided
    if (pushToken == null) {
      pushToken = await StorageHelper.getPendingPushToken();
      final provStr = await StorageHelper.getPendingPushProvider();
      if (provStr != null) {
        pushProvider = FeeddoPushProvider.fromString(provStr);
      }
    }

    // Load 1st app open timestamp
    final firstSeenAt = await StorageHelper.getFirstAppOpenAt();

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
      firstSeenAt: firstSeenAt,
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
          if (_recentConversation!.status != 'resolved') {
            await StorageHelper.setHasActiveConversation(true);
          }
        } catch (e) {
          debugPrint('Feeddo: Failed to parse recent conversation: $e');
        }
      }

      // Save to SharedPreferences and mark synced
      await StorageHelper.saveUserId(response.userId);
      await StorageHelper.saveUserData(
        externalUserId: externalUserId ?? response.externalUserId,
        userName: userName,
        email: email,
        userSegment: userSegment,
        subscriptionStatus: subscriptionStatus,
        customAttributes: customAttributes,
      );
      await StorageHelper.setSyncedWithBackend(true);

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
    // 1. Save data locally
    await StorageHelper.saveUserData(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
    );
    if (pushToken != null) {
      await StorageHelper.savePendingPushToken(
        pushToken: pushToken,
        pushProvider: pushProvider?.value,
      );
    }

    // 2. Only push to backend if user is already synced with backend
    final isSynced = await StorageHelper.isSyncedWithBackend();
    if (isSynced) {
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
    } else {
      _cachedUserId ??= await StorageHelper.getOrCreateLocalUserId();
      return _cachedUserId!;
    }
  }

  /// Register push token for the current user
  Future<void> registerPushToken({
    required String pushToken,
    required FeeddoPushProvider pushProvider,
  }) async {
    // 1. Save locally
    await StorageHelper.savePendingPushToken(
      pushToken: pushToken,
      pushProvider: pushProvider.value,
    );

    // 2. Only push to backend if user is already synced with backend
    final isSynced = await StorageHelper.isSyncedWithBackend();
    if (isSynced) {
      try {
        await _upsertUser(
          pushToken: pushToken,
          pushProvider: pushProvider,
        );
        debugPrint('Feeddo: Push token registered successfully');
      } catch (e) {
        debugPrint('Feeddo: Failed to register push token: $e');
      }
    } else {
      debugPrint('Feeddo: Push token saved locally, will sync when UI opens');
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
    await ensureUserInitialized();
    if (userId == null) {
      throw FeeddoApiException('User not identified');
    }
    final homeData = await _apiService.getHomeData(userId!);
    // Update chatbot name from home data
    _chatBotName = homeData.chatbotName;
    if (homeData.recentConversation != null &&
        homeData.recentConversation!.status != 'resolved') {
      await StorageHelper.setHasActiveConversation(true);
    } else if (homeData.recentConversation == null ||
        homeData.recentConversation!.status == 'resolved') {
      await StorageHelper.setHasActiveConversation(false);
    }
    return homeData;
  }

  /// Get conversations for the current user
  static Future<List<Conversation>> getConversations({String? userId}) async {
    if (_instance == null) {
      throw FeeddoApiException('Feeddo not initialized');
    }
    await _instance!.ensureUserInitialized();
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
    await _instance!.ensureUserInitialized();
    final userId = _instance!.userId;
    if (userId == null) {
      throw FeeddoApiException('User not identified');
    }
    final conv = await _instance!.conversationService
        .createConversation(userId, agentName: agentName);
    await StorageHelper.setHasActiveConversation(true);
    return conv;
  }

  /// Get a ticket by ID
  Future<Ticket> getTicket(String ticketId) async {
    await ensureUserInitialized();
    return await _apiService.getTicket(ticketId, userId: userId);
  }

  /// Get tickets for the current user
  Future<List<Ticket>> getTickets() async {
    await ensureUserInitialized();
    if (userId == null) {
      throw FeeddoApiException('User not identified');
    }
    return await _apiService.getTickets(userId!);
  }

  /// Add a comment to a task
  Future<TaskComment> addTaskComment(String taskId, String content,
      {List<Map<String, dynamic>>? attachments}) async {
    await ensureUserInitialized();
    return await _apiService.addTaskComment(taskId, content,
        userId: userId, attachments: attachments);
  }

  /// Vote on a task
  Future<Map<String, dynamic>> voteTask(String taskId, String voteType) async {
    await ensureUserInitialized();
    return await _apiService.voteTask(taskId, voteType, userId: userId);
  }

  /// Get the WebSocket service
  WebSocketService get webSocketService => _webSocketService;

  /// Get the Conversation service
  ConversationService get conversationService => _conversationService;

  /// Connect to WebSocket
  Future<void> connectWebSocket({String? conversationId}) async {
    await ensureUserInitialized();
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
    // Ensure user initialized and connect to WebSocket when opening the screen
    _instance?.ensureUserInitialized();
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
    _instance?.ensureUserInitialized();
    final effectiveTheme = theme ?? FeeddoTheme.dark();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeeddoTasksScreen(theme: effectiveTheme),
        fullscreenDialog: true,
      ),
    );
  }
}
