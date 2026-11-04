import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

/// Helper class for managing local storage using SharedPreferences
class StorageHelper {
  static const String _keyUserId = 'feeddo_user_id';
  static const String _keyExternalUserId = 'feeddo_external_user_id';
  static const String _keyUserName = 'feeddo_user_name';
  static const String _keyEmail = 'feeddo_email';
  static const String _keyUserSegment = 'feeddo_user_segment';
  static const String _keySubscriptionStatus = 'feeddo_subscription_status';
  static const String _keyCustomAttributes = 'feeddo_custom_attributes';
  static const String _keyFirstAppOpenAt = 'feeddo_first_app_open_at';
  static const String _keyIsSyncedWithBackend = 'feeddo_is_synced_with_backend';
  static const String _keyPendingPushToken = 'feeddo_pending_push_token';
  static const String _keyPendingPushProvider = 'feeddo_pending_push_provider';
  static const String _keyHasActiveConversation = 'feeddo_has_active_conversation';

  /// Generate a secure random UUID v4
  static String _generateUuidV4() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 10
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Get stored user ID or create and persist a new local UUID v4
  static Future<String> getOrCreateLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString(_keyUserId);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }
    final newId = _generateUuidV4();
    await prefs.setString(_keyUserId, newId);
    return newId;
  }

  /// Record 1st app open timestamp in local storage (only sets once)
  static Future<int> recordFirstAppOpenAt() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt(_keyFirstAppOpenAt);
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_keyFirstAppOpenAt, now);
    return now;
  }

  /// Get stored first app open timestamp
  static Future<int?> getFirstAppOpenAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFirstAppOpenAt);
  }

  /// Check if the user has an active conversation
  static Future<bool> hasActiveConversation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasActiveConversation) ?? false;
  }

  /// Set active conversation flag
  static Future<void> setHasActiveConversation(bool hasActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasActiveConversation, hasActive);
  }

  /// Check if local user data has been synchronized with the backend database
  static Future<bool> isSyncedWithBackend() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsSyncedWithBackend) ?? false;
  }

  /// Set synchronization status
  static Future<void> setSyncedWithBackend(bool synced) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsSyncedWithBackend, synced);
  }

  /// Save pending push token and provider locally
  static Future<void> savePendingPushToken({
    String? pushToken,
    String? pushProvider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (pushToken != null) {
      await prefs.setString(_keyPendingPushToken, pushToken);
    } else {
      await prefs.remove(_keyPendingPushToken);
    }
    if (pushProvider != null) {
      await prefs.setString(_keyPendingPushProvider, pushProvider);
    } else {
      await prefs.remove(_keyPendingPushProvider);
    }
  }

  /// Get pending push token
  static Future<String?> getPendingPushToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingPushToken);
  }

  /// Get pending push provider
  static Future<String?> getPendingPushProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingPushProvider);
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Save user ID (from backend response)
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  /// Get stored external user ID
  static Future<String?> getExternalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyExternalUserId);
  }

  /// Save external user ID
  static Future<void> saveExternalUserId(String? externalUserId) async {
    final prefs = await SharedPreferences.getInstance();
    if (externalUserId != null) {
      await prefs.setString(_keyExternalUserId, externalUserId);
    } else {
      await prefs.remove(_keyExternalUserId);
    }
  }

  /// Get stored user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// Save user name
  static Future<void> saveUserName(String? userName) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) {
      await prefs.setString(_keyUserName, userName);
    } else {
      await prefs.remove(_keyUserName);
    }
  }

  /// Get stored email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Save email
  static Future<void> saveEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(_keyEmail, email);
    } else {
      await prefs.remove(_keyEmail);
    }
  }

  /// Get stored user segment
  static Future<String?> getUserSegment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserSegment);
  }

  /// Save user segment
  static Future<void> saveUserSegment(String? userSegment) async {
    final prefs = await SharedPreferences.getInstance();
    if (userSegment != null) {
      await prefs.setString(_keyUserSegment, userSegment);
    } else {
      await prefs.remove(_keyUserSegment);
    }
  }

  /// Get stored subscription status
  static Future<String?> getSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubscriptionStatus);
  }

  /// Save subscription status
  static Future<void> saveSubscriptionStatus(String? subscriptionStatus) async {
    final prefs = await SharedPreferences.getInstance();
    if (subscriptionStatus != null) {
      await prefs.setString(_keySubscriptionStatus, subscriptionStatus);
    } else {
      await prefs.remove(_keySubscriptionStatus);
    }
  }

  /// Get stored custom attributes
  static Future<Map<String, dynamic>?> getCustomAttributes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyCustomAttributes);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Save custom attributes
  static Future<void> saveCustomAttributes(
      Map<String, dynamic>? customAttributes) async {
    final prefs = await SharedPreferences.getInstance();
    if (customAttributes != null) {
      await prefs.setString(_keyCustomAttributes, jsonEncode(customAttributes));
    } else {
      await prefs.remove(_keyCustomAttributes);
    }
  }

  /// Save all user data at once (only updates provided non-null values)
  static Future<void> saveUserData({
    String? userId,
    String? externalUserId,
    String? userName,
    String? email,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
  }) async {
    await Future.wait([
      if (userId != null) saveUserId(userId),
      if (externalUserId != null) saveExternalUserId(externalUserId),
      if (userName != null) saveUserName(userName),
      if (email != null) saveEmail(email),
      if (userSegment != null) saveUserSegment(userSegment),
      if (subscriptionStatus != null) saveSubscriptionStatus(subscriptionStatus),
      if (customAttributes != null) saveCustomAttributes(customAttributes),
    ]);
  }

  /// Clear all stored user data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyUserId),
      prefs.remove(_keyExternalUserId),
      prefs.remove(_keyUserName),
      prefs.remove(_keyEmail),
      prefs.remove(_keyUserSegment),
      prefs.remove(_keySubscriptionStatus),
      prefs.remove(_keyCustomAttributes),
      prefs.remove(_keyIsSyncedWithBackend),
      prefs.remove(_keyPendingPushToken),
      prefs.remove(_keyPendingPushProvider),
      prefs.remove(_keyHasActiveConversation),
    ]);
  }
}
