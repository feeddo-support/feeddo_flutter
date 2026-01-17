import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../theme/feeddo_theme.dart';
import 'attachment_preview.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final FeeddoTheme theme;
  final Widget? taskCard;
  final Widget? ticketCard;

  const MessageBubble({
    super.key,
    required this.message,
    required this.theme,
    this.taskCard,
    this.ticketCard,
  });

  ({String content, String? taskId, String? ticketId}) _parseMessageContent(
      String content) {
    // This logic is duplicated from chat screen, ideally should be in a helper
    // But for now we just need to strip the JSON part for display
    final regex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```');
    final match = regex.firstMatch(content);

    if (match != null) {
      final newContent = content.replaceFirst(match.group(0)!, '').trim();
      return (content: newContent, taskId: null, ticketId: null);
    }
    return (content: content, taskId: null, ticketId: null);
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    // If message is from today, show only time
    if (messageDate == today) {
      return timeStr;
    }

    // If message is from yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDate == yesterday) {
      return 'Yesterday, $timeStr';
    }

    // If within last 7 days, show day name
    final diff = today.difference(messageDate).inDays;
    if (diff < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = weekdays[date.weekday - 1];
      return '$dayName, $timeStr';
    }

    // Otherwise show full date
    return '${date.day}/${date.month}/${date.year}, $timeStr';
  }

  Widget _buildRichText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Normal text
        spans.add(TextSpan(text: parts[i], style: baseStyle));
      } else {
        // Bold text
        spans.add(TextSpan(
          text: parts[i],
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    // Parse attachments
    List<dynamic> files = [];
    if (message.hasAttachments && message.attachments != null) {
      if (message.attachments is List) {
        files = message.attachments as List;
      } else if (message.attachments is Map) {
        final map = message.attachments as Map;
        if (map.containsKey('files') && map['files'] is List) {
          files = map['files'];
        }
      }
    }

    // Parse content to remove JSON block
    final parsedContent = _parseMessageContent(message.content ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? theme.colors.primary : theme.colors.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: theme.colors.border,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: message.role == 'human'
                                ? const Color.fromARGB(255, 100, 81, 244)
                                : theme.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            message.role == 'human'
                                ? Icons.code
                                : Icons.catching_pokemon,
                            color: message.role == 'human'
                                ? Colors.white
                                : theme.colors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.displayName ?? 'Feeddo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (parsedContent.content.isNotEmpty)
                    _buildRichText(
                      parsedContent.content,
                      TextStyle(
                        color: isUser
                            ? (theme.isDark ? Colors.black : Colors.white)
                            : theme.colors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  if (files.isNotEmpty) ...[
                    if (parsedContent.content.isNotEmpty)
                      const SizedBox(height: 8),
                    ...files.map((file) {
                      final fileUrl = file['url'] as String;
                      // No need to hardcode here, AttachmentPreview handles relative URLs now
                      // But just to be cleaner we can pass it raw

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: AttachmentPreview(
                          url: fileUrl,
                          contentType: file['contentType'],
                          fileName: file['fileName'],
                        ),
                      );
                    }),
                  ],
                  if (taskCard != null) taskCard!,
                  if (ticketCard != null) ticketCard!,
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color: isUser
                            ? (theme.isDark
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.7))
                            : theme.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
