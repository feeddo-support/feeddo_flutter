/// Model representing an end user in the Feeddo system
class EndUser {
  /// Unique identifier for the user (auto-generated if not provided)
  final String? userId;

  /// Your application's user ID
  final String? externalUserId;

  /// User's display name
  final String? userName;

  /// User's email address
  final String? email;

  /// Country code (e.g., "US")
  final String? country;

  /// Locale code (e.g., "en-US")
  final String? locale;

  /// Version of your app the user is using
  final String? appVersion;

  /// Platform: ios, android, web, desktop, other
  final String? platform;

  /// Device model (e.g., "iPhone 14", "Pixel 7")
  final String? deviceModel;

  /// Operating system version
  final String? osVersion;

  /// Custom user segment/category
  final String? userSegment;

  /// Subscription status (e.g., "premium", "free")
  final String? subscriptionStatus;

  /// Custom key-value pairs for additional data
  final Map<String, dynamic>? customAttributes;

  const EndUser({
    this.userId,
    this.externalUserId,
    this.userName,
    this.email,
    this.country,
    this.locale,
    this.appVersion,
    this.platform,
    this.deviceModel,
    this.osVersion,
    this.userSegment,
    this.subscriptionStatus,
    this.customAttributes,
  });

  /// Convert EndUser to JSON for API requests
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (userId != null) json['userId'] = userId;
    if (externalUserId != null) json['externalUserId'] = externalUserId;
    if (userName != null) json['userName'] = userName;
    if (email != null) json['email'] = email;
    if (country != null) json['country'] = country;
    if (locale != null) json['locale'] = locale;
    if (appVersion != null) json['appVersion'] = appVersion;
    if (platform != null) json['platform'] = platform;
    if (deviceModel != null) json['deviceModel'] = deviceModel;
    if (osVersion != null) json['osVersion'] = osVersion;
    if (userSegment != null) json['userSegment'] = userSegment;
    if (subscriptionStatus != null)
      json['subscriptionStatus'] = subscriptionStatus;
    if (customAttributes != null) json['customAttributes'] = customAttributes;

    return json;
  }

  /// Create EndUser from JSON
  factory EndUser.fromJson(Map<String, dynamic> json) {
    return EndUser(
      userId: json['userId'] as String?,
      externalUserId: json['externalUserId'] as String?,
      userName: json['userName'] as String?,
      email: json['email'] as String?,
      country: json['country'] as String?,
      locale: json['locale'] as String?,
      appVersion: json['appVersion'] as String?,
      platform: json['platform'] as String?,
      deviceModel: json['deviceModel'] as String?,
      osVersion: json['osVersion'] as String?,
      userSegment: json['userSegment'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      customAttributes: json['customAttributes'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with updated fields
  EndUser copyWith({
    String? userId,
    String? externalUserId,
    String? userName,
    String? email,
    String? country,
    String? locale,
    String? appVersion,
    String? platform,
    String? deviceModel,
    String? osVersion,
    String? userSegment,
    String? subscriptionStatus,
    Map<String, dynamic>? customAttributes,
  }) {
    return EndUser(
      userId: userId ?? this.userId,
      externalUserId: externalUserId ?? this.externalUserId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      country: country ?? this.country,
      locale: locale ?? this.locale,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      userSegment: userSegment ?? this.userSegment,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  @override
  String toString() {
    return 'EndUser(userId: $userId, userName: $userName, email: $email, platform: $platform)';
  }
}

/// Response from upsert end user API
class UpsertEndUserResponse {
  final bool success;
  final String userId;
  final String? externalUserId;
  final String action; // "created" or "updated"
  final Map<String, dynamic>? recentConversation;

  const UpsertEndUserResponse({
    required this.success,
    required this.userId,
    this.externalUserId,
    required this.action,
    this.recentConversation,
  });

  factory UpsertEndUserResponse.fromJson(Map<String, dynamic> json) {
    return UpsertEndUserResponse(
      success: json['success'] as bool,
      userId: json['userId'] as String,
      externalUserId: json['externalUserId'] as String?,
      action: json['action'] as String,
      recentConversation: json['recentConversation'] as Map<String, dynamic>?,
    );
  }
}
