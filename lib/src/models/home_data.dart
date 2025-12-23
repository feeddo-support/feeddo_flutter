import 'task.dart';
import 'ticket.dart';

class HomeData {
  final bool hasConversation;
  final bool hasTicket;
  final bool hasTasks;
  final int unreadMessageCount;
  final String? chatbotName;
  final Ticket? recentTicket;
  final Task? recentTask;

  HomeData({
    required this.hasConversation,
    required this.hasTicket,
    required this.hasTasks,
    required this.unreadMessageCount,
    this.chatbotName,
    this.recentTicket,
    this.recentTask,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      hasConversation: json['hasConversation'] ?? false,
      hasTicket: json['hasTicket'] ?? false,
      hasTasks: json['hasTasks'] ?? false,
      unreadMessageCount: json['unreadMessageCount'] ?? 0,
      chatbotName: json['chatbotName'],
      recentTicket: json['recentTicket'] != null
          ? Ticket.fromJson(json['recentTicket'])
          : null,
      recentTask:
          json['recentTask'] != null ? Task.fromJson(json['recentTask']) : null,
    );
  }
}
