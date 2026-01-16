import 'task_comment.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String type;
  final int upvoteCount;
  final int commentCount;
  final String? myVote;
  final List<TaskComment> comments;
  final bool isOwner;
  final String? conversationId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.type,
    required this.upvoteCount,
    required this.commentCount,
    this.myVote,
    this.comments = const [],
    this.isOwner = false,
    this.conversationId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    var commentsList = <TaskComment>[];
    if (json['comments'] != null) {
      commentsList = (json['comments'] as List)
          .map((e) => TaskComment.fromJson(e))
          .toList();
    }

    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      type: json['type'] ?? 'feature',
      upvoteCount: json['upvoteCount'] ?? 0,
      commentCount: json['commentCount'] ?? commentsList.length,
      myVote: json['myVote'],
      comments: commentsList,
      isOwner: json['isOwner'] ?? false,
      conversationId: json['conversationId'],
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? type,
    int? upvoteCount,
    int? downvoteCount,
    int? commentCount,
    String? myVote,
    bool clearMyVote = false,
    List<TaskComment>? comments,
    bool? isOwner,
    String? conversationId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      commentCount: commentCount ?? this.commentCount,
      myVote: clearMyVote ? null : (myVote ?? this.myVote),
      comments: comments ?? this.comments,
      isOwner: isOwner ?? this.isOwner,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
