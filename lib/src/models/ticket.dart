class Ticket {
  final String id;
  final String title;
  final String description;
  final String priority;
  final bool isResolved;
  final int createdAt;
  final int updatedAt;
  final bool isOwner;
  final String? conversationId;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isResolved,
    required this.createdAt,
    required this.updatedAt,
    this.isOwner = false,
    this.conversationId,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'] ?? 'medium',
      isResolved: json['isResolved'] ?? false,
      createdAt: json['createdAt'] ?? 0,
      updatedAt: json['updatedAt'] ?? 0,
      isOwner: json['isOwner'] ?? false,
      conversationId: json['conversationId'],
    );
  }
}
