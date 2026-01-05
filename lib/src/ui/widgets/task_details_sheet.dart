import 'package:flutter/material.dart';
import '../../feeddo_client.dart';
import '../../models/task.dart';
import '../../theme/feeddo_theme.dart';
import '../screens/feeddo_chat_screen.dart';
import 'chat_input_area.dart';

class TaskDetailsSheet extends StatefulWidget {
  final String? taskId;
  final Task? task;
  final Function(Task)? onTaskUpdated;
  final FeeddoTheme? theme;

  const TaskDetailsSheet({
    Key? key,
    this.taskId,
    this.task,
    this.onTaskUpdated,
    this.theme,
  })  : assert(taskId != null || task != null,
            'Either taskId or task must be provided'),
        super(key: key);

  static Future<void> show(BuildContext context,
      {String? taskId,
      Task? task,
      Function(Task)? onTaskUpdated,
      FeeddoTheme? theme}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsSheet(
          taskId: taskId,
          task: task,
          onTaskUpdated: onTaskUpdated,
          theme: theme),
    );
  }

  @override
  State<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<TaskDetailsSheet> {
  Task? _task;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  late FeeddoTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? FeeddoTheme.light();
    if (widget.task != null) {
      _task = widget.task;
      _isLoading = false;
    } else {
      _loadTask();
    }
  }

  Future<void> _loadTask() async {
    final taskId = _task?.id ?? widget.taskId;
    if (taskId == null) return;

    try {
      // Only show loading if we don't have data yet
      if (_task == null) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final task = await FeeddoInternal.instance.apiService
          .getTask(taskId, userId: FeeddoInternal.instance.userId);
      if (mounted) {
        setState(() {
          _task = task;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: _theme.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _theme.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
          // Add Comment Input (only show if task is loaded)
          if (_task != null) _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: _theme.colors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load task',
                style: TextStyle(color: _theme.colors.error)),
            TextButton(
              onPressed: _loadTask,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_task == null) {
      return Center(
          child: Text('Task not found',
              style: TextStyle(color: _theme.colors.textPrimary)));
    }

    final task = _task!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Row(
          children: [
            Icon(
              task.type == 'bug' ? Icons.bug_report : Icons.lightbulb,
              color: task.type == 'bug' ? Colors.red : Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              task.type.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _theme.colors.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _theme.colors.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.status.toUpperCase(),
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _theme.colors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          task.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _theme.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          task.description,
          style: TextStyle(
            fontSize: 16,
            color: _theme.colors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        // Stats
        Row(
          children: [
            _buildVoteButton(
              icon: Icons.arrow_upward,
              label: '${task.upvoteCount}',
              isActive: task.myVote == 'up',
              onTap: () => _voteTask('up'),
              activeColor: Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildVoteButton(
              icon: Icons.arrow_downward,
              label: '',
              isActive: task.myVote == 'down',
              onTap: () => _voteTask('down'),
              activeColor: Colors.red,
            ),
          ],
        ),
        if (task.isOwner && task.conversationId != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openConversation(task.conversationId!),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('View Conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.colors.primary,
                foregroundColor: _theme.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        Text(
          'Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _theme.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (task.comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No comments yet',
                style: TextStyle(color: _theme.colors.textSecondary),
              ),
            ),
          )
        else
          ...task.comments.map((comment) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _theme.colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _theme.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: comment.userType == 'developer'
                              ? Colors.purple.shade100
                              : Colors.blue.shade100,
                          child: Icon(
                            comment.userType == 'developer'
                                ? Icons.code
                                : Icons.person,
                            size: 14,
                            color: comment.userType == 'developer'
                                ? Colors.purple.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.authorName ??
                              (comment.userType == 'developer'
                                  ? 'Developer'
                                  : 'User'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _theme.colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            color: _theme.colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(comment.content,
                        style: TextStyle(color: _theme.colors.textPrimary)),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildCommentInput() {
    return ChatInputArea(
      controller: _commentController,
      onSend: _submitComment,
      isSending: _isSubmittingComment,
      hintText: 'Add a comment...',
      withShadow: true,
      theme: _theme,
      onAttachment: () {
        // TODO: Implement attachment
      },
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      await FeeddoInternal.instance.addTaskComment(
        _task!.id,
        _commentController.text.trim(),
      );
      if (!mounted) return;

      _commentController.clear();

      // Reload task to show new comment
      // If we were passed a task object, we need to reload it from API to get the new comment
      // Or we could optimistically add it, but reloading is safer for now
      await _loadTask();

      if (_task != null) {
        widget.onTaskUpdated?.call(_task!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Widget _buildVoteButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : Colors.grey.shade600,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _voteTask(String voteType) async {
    if (_task == null) return;

    // Optimistic update
    final oldTask = _task!;
    final oldMyVote = oldTask.myVote;

    // Calculate new counts
    int newUpvoteCount = oldTask.upvoteCount;

    // Remove old vote
    if (oldMyVote == 'up') newUpvoteCount--;

    // Add new vote (if not toggling off)
    String newMyVote = voteType;
    if (oldMyVote == voteType) {
      newMyVote = 'none'; // Toggle off
    } else {
      if (voteType == 'up') newUpvoteCount++;
    }

    final optimisticTask = oldTask.copyWith(
      upvoteCount: newUpvoteCount,
      myVote: newMyVote == 'none' ? null : newMyVote,
    );

    setState(() {
      _task = optimisticTask;
    });

    // Notify parent immediately for optimistic UI update
    widget.onTaskUpdated?.call(optimisticTask);

    try {
      final result =
          await FeeddoInternal.instance.voteTask(_task!.id, newMyVote);

      // Update with server response if needed
      final serverUpvoteCount = result['upvoteCount'] as int?;

      if (serverUpvoteCount != null) {
        final updatedTask = _task!.copyWith(
          upvoteCount: serverUpvoteCount,
        );
        if (mounted) {
          setState(() {
            _task = updatedTask;
          });
        }
        widget.onTaskUpdated?.call(updatedTask);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _task = oldTask;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to vote: $e')),
        );
        widget.onTaskUpdated?.call(oldTask);
      }
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openConversation(String conversationId) async {
    try {
      // Fetch the conversation
      final conversations =
          FeeddoInternal.instance.conversationService.conversations;
      final conversation = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FeeddoChatScreen(
            conversation: conversation,
            theme: _theme,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open conversation: $e')),
      );
    }
  }
}
