import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/feeddo_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(String voteType)? onVote;
  final FeeddoTheme theme;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onVote,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        decoration: BoxDecoration(
          color: theme.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voting Column
              _buildVoteColumn(context),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Type + Status
                    Row(
                      children: [
                        _buildTypeBadge(),
                        const Spacer(),
                        _buildStatusBadge(statusColor),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colors.cardText,
                        height: 1.3,
                      ),
                    ),

                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Footer: Comments + Date (optional, implied simple implementation)
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 14, color: theme.colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${task.commentCount} comments',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteColumn(BuildContext context) {
    // Assuming myVote being non-null implies an upvote for now
    final isUpvoted = task.myVote != null;

    return GestureDetector(
      onTap: onVote != null
          ? () => onVote!(isUpvoted && task.myVote == 'up' ? 'remove' : 'up')
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color:
                  isUpvoted ? theme.colors.primary : theme.colors.textSecondary,
              size: 24,
            ),
            Text(
              _formatCount(task.upvoteCount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isUpvoted ? theme.colors.primary : theme.colors.cardText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isBug = task.type == 'bug';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            (isBug ? theme.colors.error : Colors.amber).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBug ? Icons.bug_report_rounded : Icons.lightbulb_rounded,
            size: 12,
            color: isBug ? theme.colors.error : Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            isBug ? 'Bug Report' : 'Feature',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isBug
                  ? theme.colors.error
                  : Colors.amber[700], // Adjust for contrast
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatStatus(task.status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return theme.colors.success;
      case 'in_progress':
      case 'progress':
        return theme.colors.primary;
      case 'closed':
        return theme.colors.textSecondary;
      default:
        return Colors.orange; // Open/Pending
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
