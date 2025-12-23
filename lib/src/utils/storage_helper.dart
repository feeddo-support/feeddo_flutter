import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Helper class for managing local storage using SharedPreferences
class StorageHelper {
  static const String _keyUserId = 'feeddo_user_id';
  static const String _keyExternalUserId = 'feeddo_external_user_id';
  static const String _keyUserName = 'feeddo_user_name';
  static const String _keyEmail = 'feeddo_email';
  static const String _keyUserSegment = 'feeddo_user_segment';
  static const String _keySubscriptionStatus = 'feeddo_subscription_status';
  static const String _keyCustomAttributes = 'feeddo_custom_attributes';

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

  /// Save all user data at once
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
      saveExternalUserId(externalUserId),
      saveUserName(userName),
      saveEmail(email),
      saveUserSegment(userSegment),
      saveSubscriptionStatus(subscriptionStatus),
      saveCustomAttributes(customAttributes),
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
    ]);
  }
}
