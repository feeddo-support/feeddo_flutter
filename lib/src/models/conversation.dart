class Conversation {
  final String id;
  final String appId;
  final String status;
  final String? title;
  final String? displayName;
  final String? lastMessagePreview;
  final bool autoReply;
  final int startedAt;
  final int lastMessageAt;
  final int? resolvedAt;
  final String? resolvedBy;
  final int? userSatisfaction;
  final List<String> tags;
  final Map<String, dynamic> customData;
  final int unreadMessages;
  final bool hasTicket;
  final String? ticketStatus;
  final bool hasTask;
  final String? taskStatus;

  Conversation({
    required this.id,
    required this.appId,
    required this.status,
    this.title,
    this.displayName,
    this.lastMessagePreview,
    required this.autoReply,
    required this.startedAt,
    required this.lastMessageAt,
    this.resolvedAt,
    this.resolvedBy,
    this.userSatisfaction,
    this.tags = const [],
    this.customData = const {},
    this.unreadMessages = 0,
    this.hasTicket = false,
    this.ticketStatus,
    this.hasTask = false,
    this.taskStatus,
  });

  Conversation copyWith({
    String? id,
    String? appId,
    String? status,
    String? title,
    String? displayName,
    String? lastMessagePreview,
    bool? autoReply,
    int? startedAt,
    int? lastMessageAt,
    int? resolvedAt,
    String? resolvedBy,
    int? userSatisfaction,
    List<String>? tags,
    Map<String, dynamic>? customData,
    int? unreadMessages,
    bool? hasTicket,
    String? ticketStatus,
    bool? hasTask,
    String? taskStatus,
  }) {
    return Conversation(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      status: status ?? this.status,
      title: title ?? this.title,
      displayName: displayName ?? this.displayName,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      autoReply: autoReply ?? this.autoReply,
      startedAt: startedAt ?? this.startedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      userSatisfaction: userSatisfaction ?? this.userSatisfaction,
      tags: tags ?? this.tags,
      customData: customData ?? this.customData,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      hasTicket: hasTicket ?? this.hasTicket,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      hasTask: hasTask ?? this.hasTask,
      taskStatus: taskStatus ?? this.taskStatus,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      appId: json['appId'] ?? json['app_id'],
      status: json['status'],
      title: json['title'],
      displayName: json['displayName'],
      lastMessagePreview:
          json['lastMessagePreview'] ?? json['last_message_preview'],
      autoReply: json['autoReply'] ?? (json['auto_reply'] == 1),
      startedAt: json['startedAt'] ?? json['started_at'],
      lastMessageAt: json['lastMessageAt'] ?? json['last_message_at'],
      resolvedAt: json['resolvedAt'] ?? json['resolved_at'],
      resolvedBy: json['resolvedBy'] ?? json['resolved_by'],
      userSatisfaction: json['userSatisfaction'] ?? json['user_satisfaction'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      customData: json['customData'] ?? json['custom_data'] ?? {},
      unreadMessages: json['unreadMessages'] ?? 0,
      hasTicket: json['hasTicket'] ?? false,
      ticketStatus: json['ticketStatus'],
      hasTask: json['hasTask'] ?? false,
      taskStatus: json['taskStatus'],
    );
  }
}

class GetConversationsResponse {
  final bool success;
  final List<Conversation> conversations;

  GetConversationsResponse({
    required this.success,
    required this.conversations,
  });

  factory GetConversationsResponse.fromJson(Map<String, dynamic> json) {
    return GetConversationsResponse(
      success: json['success'] ?? false,
      conversations: (json['conversations'] as List?)
              ?.map((e) => Conversation.fromJson(e))
              .toList() ??
          [],
    );
  }
}
