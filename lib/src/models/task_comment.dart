class TaskComment {
  final String id;
  final String content;
  final String userType;
  final String? authorName;
  final int createdAt;

  TaskComment({
    required this.id,
    required this.content,
    required this.userType,
    this.authorName,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'],
      content: json['content'],
      userType: json['userType'] ?? json['user_type'] ?? 'end_user',
      authorName: json['authorName'] ?? json['author_name'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? 0,
    );
  }
}
