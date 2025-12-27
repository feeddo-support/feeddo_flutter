import 'dart:async';
import 'package:flutter/material.dart';
import 'feeddo_client.dart';
import 'theme/feeddo_theme.dart';

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
  static Future<String> init({
    required String apiKey,
    BuildContext? context,
    bool isInAppNotificationOn = true,
    FeeddoTheme? theme,
    Duration? notificationDuration,
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
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
    );

    return result.userId;
  }

  /// Open the Feeddo support home screen
  static void show(BuildContext context, {FeeddoTheme? theme}) {
    FeeddoInternal.show(context, theme: theme);
  }

  /// Update user information (e.g., username, email, etc.)
  static Future<String> updateUser({
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
  }) async {
    return await FeeddoInternal.instance.updateUser(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
      userSegment: userSegment,
      subscriptionStatus: subscriptionStatus,
      customAttributes: customAttributes,
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
