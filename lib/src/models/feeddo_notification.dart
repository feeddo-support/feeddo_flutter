class FeeddoNotification {
  final String id;
  final String appId;
  final String endUserId;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final int createdAt;

  FeeddoNotification({
    required this.id,
    required this.appId,
    required this.endUserId,
    this.title,
    this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory FeeddoNotification.fromJson(Map<String, dynamic> json) {
    return FeeddoNotification(
      id: json['id'],
      appId: json['app_id'],
      endUserId: json['end_user_id'],
      title: json['title'],
      body: json['body'],
      data:
          json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] is int
          ? json['created_at']
          : int.tryParse(json['created_at'].toString()) ?? 0,
    );
  }
}

class GetNotificationsResponse {
  final List<FeeddoNotification> notifications;

  GetNotificationsResponse({required this.notifications});

  factory GetNotificationsResponse.fromJson(Map<String, dynamic> json) {
    return GetNotificationsResponse(
      notifications: (json['notifications'] as List)
          .map((e) => FeeddoNotification.fromJson(e))
          .toList(),
    );
  }
}
