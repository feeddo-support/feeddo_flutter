import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/feeddo_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final FeeddoTheme theme;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTap,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.type == 'bug' ? Icons.bug_report : Icons.lightbulb,
                  size: 16,
                  color: task.type == 'bug' ? Colors.red : Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  task.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colors.border),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colors.cardText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: theme.colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_upward,
                    size: 14, color: theme.colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${task.upvoteCount}',
                  style: TextStyle(
                      fontSize: 12, color: theme.colors.textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.comment_outlined,
                    size: 14, color: theme.colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${task.comments.length}',
                  style: TextStyle(
                      fontSize: 12, color: theme.colors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
