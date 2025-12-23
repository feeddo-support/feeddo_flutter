class Message {
  final String id;
  final String conversationId;
  final String role; // 'user', 'assistant', 'human', 'function'
  final String? content;
  final bool hasAttachments;
  final dynamic attachments; // JSON string or null
  final int createdAt;
  final String? displayName;

  Message({
    required this.id,
    required this.conversationId,
    required this.role,
    this.content,
    required this.hasAttachments,
    this.attachments,
    required this.createdAt,
    this.displayName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversationId'] ?? json['conversation_id'],
      role: json['role'],
      content: json['content'],
      hasAttachments: json['hasAttachments'] == true ||
          json['has_attachments'] == 1 ||
          json['has_attachments'] == true,
      attachments: json['attachments'],
      createdAt: json['createdAt'] ?? json['created_at'],
      displayName: json['displayName'] ?? json['display_name'],
    );
  }

  bool get isUser => role == 'user';
}
