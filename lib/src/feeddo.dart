import 'dart:async';
import 'package:feeddo_flutter/src/ui/widgets/feeddo_notification_badge.dart';
import 'package:flutter/material.dart';
import 'feeddo_client.dart';
import 'theme/feeddo_theme.dart';
import 'models/push_provider.dart';
import 'ui/widgets/task_details_sheet.dart';
import 'ui/screens/feeddo_chat_screen.dart';

export 'models/push_provider.dart';

/// Feeddo SDK - AI-powered customer support and feedback
class Feeddo {
  /// Initialize Feeddo SDK and create/update user
  ///
  /// Call this method at app startup or when user data changes.
  /// Automatically handles user ID management, device info collection,
  /// and in-app notifications.
  ///
  /// Returns the user ID.
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
  /// [pushToken]: Push notification token (optional)
  /// [pushProvider]: Push notification provider (fcm, apns, onesignal) (optional)
  static Future<String> init({
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
    final result = await FeeddoInternal.init(
      apiKey: apiKey,
      context: context,
      isInAppNotificationOn: isInAppNotificationOn,
      theme: theme,
      notificationDuration: notificationDuration,
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
      pushToken: pushToken,
      pushProvider: pushProvider,
    );

    return result.userId;
  }

  /// Open the Feeddo support home screen
  static void show(
    BuildContext context, {
    FeeddoTheme? theme,
    bool useSmallWindowOnDesktop = true,
    BoxConstraints? desktopConstraints,
  }) {
    FeeddoInternal.show(
      context,
      theme: theme,
      useSmallWindowOnDesktop: useSmallWindowOnDesktop,
      desktopConstraints: desktopConstraints,
    );
  }

  static void showInappNotification({
    required BuildContext context,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    FeeddoTheme? theme,
    Duration duration = const Duration(seconds: 10),
  }) {
    // Check if we should suppress this notification
    if (data != null && data['type'] == 'chat_message') {
      final conversationId = data['conversationId'];
      if (conversationId != null) {
        try {
          if (FeeddoInternal
                  .instance.conversationService.activeConversationId ==
              conversationId) {
            return;
          }
        } catch (_) {}
      }
    }

    FeeddoNotificationManager.showSimpleNotification(
      context,
      title: title,
      body: message,
      theme: theme,
      duration: duration,
      onTap: () {
        if (data != null) {
          handleNotificationTap(context, data, theme: theme);
        }
      },
    );
  }

  /// Handle notification tap action based on payload data
  static Future<void> handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> data, {
    FeeddoTheme? theme,
  }) async {
    final type = data['type'];
    final effectiveTheme = theme ?? FeeddoTheme.dark();

    if (type == 'task_released' || type == 'task_comment') {
      final taskId = data['taskId'];
      if (taskId != null) {
        TaskDetailsSheet.show(
          context,
          taskId: taskId,
          theme: effectiveTheme,
        );
      }
    } else if (type == 'chat_message') {
      final conversationId = data['conversationId'];
      if (conversationId != null) {
        // Check if already on this conversation
        final activeId =
            FeeddoInternal.instance.conversationService.activeConversationId;
        if (activeId == conversationId) {
          debugPrint('Feeddo: Already on conversation $conversationId');
          return;
        }

        try {
          final conversation = await FeeddoInternal.instance.apiService
              .getConversation(conversationId);

          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FeeddoChatScreen(
                  conversation: conversation,
                  theme: effectiveTheme,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Feeddo: Failed to load conversation: $e');
        }
      }
    }
  }

  /// Update user information (e.g., username, email, etc.)
  static Future<String> updateUser({
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
    String? pushToken,
    FeeddoPushProvider? pushProvider,
  }) async {
    return await FeeddoInternal.instance.updateUser(
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
  static Future<void> registerPushToken({
    required String pushToken,
    required FeeddoPushProvider pushProvider,
  }) async {
    await FeeddoInternal.instance.registerPushToken(
      pushToken: pushToken,
      pushProvider: pushProvider,
    );
  }

  /// Get current unread message count
  static int get unreadMessageCount {
    try {
      return FeeddoInternal.instance.conversationService.unreadMessageCount;
    } catch (_) {
      return 0;
    }
  }

  /// Dispose and cleanup Feeddo instance
  static void dispose() {
    FeeddoInternal.dispose();
  }
}
