import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../feeddo_client.dart';
import 'feeddo_chat_screen.dart';

import '../../theme/feeddo_theme.dart';

class FeeddoMessagesScreen extends StatefulWidget {
  final FeeddoTheme? theme;

  const FeeddoMessagesScreen({
    super.key,
    this.theme,
  });

  @override
  State<FeeddoMessagesScreen> createState() => _FeeddoMessagesScreenState();
}

class _FeeddoMessagesScreenState extends State<FeeddoMessagesScreen> {
  late FeeddoTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? FeeddoTheme.light();
    _loadConversations();

    // Listen to conversation service updates
    Feeddo.instance.conversationService.addListener(_onConversationsUpdated);

    // Connect to WebSocket generally (no specific conversation) to receive updates
    Feeddo.instance.connectWebSocket();
  }

  @override
  void dispose() {
    Feeddo.instance.conversationService.removeListener(_onConversationsUpdated);
    super.dispose();
  }

  void _onConversationsUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadConversations() async {
    try {
      await Feeddo.getConversations();
    } catch (e) {
      // Error handled in service
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _createNewConversation() async {
    // Navigate to chat screen directly
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FeeddoChatScreen(
          conversation: null,
          theme: _theme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Feeddo.instance.conversationService;
    final conversations = service.conversations;
    final isLoading = service.isLoading;
    final error = service.error;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton(
          onPressed: _createNewConversation,
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      body: isLoading && conversations.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : error != null && conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: $error',
                        style: const TextStyle(color: Colors.black)),
                  ),
                )
              : conversations.isEmpty
                  ? const Center(
                      child: Text('No messages yet',
                          style: TextStyle(color: Colors.black)))
                  : ListView.separated(
                      itemCount: conversations.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 68,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        return _buildConversationItem(conversation);
                      },
                    ),
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    return InkWell(
      onTap: () async {
        // Mark as read locally
        Feeddo.instance.conversationService.markAsRead(conversation.id);

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FeeddoChatScreen(
              conversation: conversation,
              theme: _theme,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (conversation.displayName ?? conversation.title ?? '?')
                    .substring(0, 1)
                    .toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.displayName ??
                              conversation.title ??
                              'Conversation',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(conversation.lastMessageAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Message Preview and Badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessagePreview ?? 'No messages',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadMessages > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conversation.unreadMessages.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Status Indicators (Ticket/Task)
                  if (conversation.hasTicket || conversation.hasTask) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (conversation.hasTicket)
                          _buildStatusChip(
                            'Ticket: ${conversation.ticketStatus ?? "Open"}',
                            Colors.blue,
                            Icons.confirmation_number_outlined,
                          ),
                        if (conversation.hasTicket && conversation.hasTask)
                          const SizedBox(width: 8),
                        if (conversation.hasTask)
                          _buildStatusChip(
                            'Task',
                            Colors.orange,
                            Icons.task_alt,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
