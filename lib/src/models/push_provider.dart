/// Supported push notification providers
enum FeeddoPushProvider {
  /// Firebase Cloud Messaging
  fcm,

  /// Apple Push Notification Service
  apns,

  /// OneSignal
  onesignal;

  /// Get the string value for the API
  String get value {
    switch (this) {
      case FeeddoPushProvider.fcm:
        return 'fcm';
      case FeeddoPushProvider.apns:
        return 'apns';
      case FeeddoPushProvider.onesignal:
        return 'onesignal';
    }
  }

  /// Create from string value
  static FeeddoPushProvider? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'fcm':
        return FeeddoPushProvider.fcm;
      case 'apns':
        return FeeddoPushProvider.apns;
      case 'onesignal':
        return FeeddoPushProvider.onesignal;
      default:
        return null;
    }
  }
}
