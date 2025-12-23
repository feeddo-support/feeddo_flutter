import 'package:flutter/material.dart';
import '../../feeddo_client.dart';
import '../../models/task.dart';
import 'chat_input_area.dart';

class TaskDetailsSheet extends StatefulWidget {
  final String? taskId;
  final Task? task;
  final Function(Task)? onTaskUpdated;

  const TaskDetailsSheet({
    Key? key,
    this.taskId,
    this.task,
    this.onTaskUpdated,
  })  : assert(taskId != null || task != null,
            'Either taskId or task must be provided'),
        super(key: key);

  static Future<void> show(BuildContext context,
      {String? taskId, Task? task, Function(Task)? onTaskUpdated}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsSheet(
          taskId: taskId, task: task, onTaskUpdated: onTaskUpdated),
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

  @override
  void initState() {
    super.initState();
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

      final task = await Feeddo.instance.getTask(taskId);
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: Colors.grey.shade300,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load task',
                style: TextStyle(color: Colors.red.shade700)),
            TextButton(
              onPressed: _loadTask,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_task == null) {
      return const Center(child: Text('Task not found'));
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
            ),
            const SizedBox(width: 8),
            Text(
              task.type.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.status.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          task.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          task.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade800,
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
        const SizedBox(height: 32),
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (task.comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No comments yet',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ...task.comments.map((comment) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(comment.content),
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
      onAttachment: () {
        // TODO: Implement attachment
      },
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      await Feeddo.instance.addTaskComment(
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
      final result = await Feeddo.instance.voteTask(_task!.id, newMyVote);

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
}
