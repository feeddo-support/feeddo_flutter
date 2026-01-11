class TaskComment {
  final String id;
  final String content;
  final String userType;
  final String? authorName;
  final int createdAt;
  final bool hasAttachments;
  final List<Map<String, dynamic>>? attachments;

  TaskComment({
    required this.id,
    required this.content,
    required this.userType,
    this.authorName,
    required this.createdAt,
    this.hasAttachments = false,
    this.attachments,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? attachmentsList;
    if (json['attachments'] != null) {
      attachmentsList = (json['attachments'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    return TaskComment(
      id: json['id'],
      content: json['content'] ?? '',
      userType: json['userType'] ?? json['user_type'] ?? 'end_user',
      authorName: json['authorName'] ?? json['author_name'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? 0,
      hasAttachments:
          json['hasAttachments'] ?? json['has_attachments'] ?? false,
      attachments: attachmentsList,
    );
  }
}
