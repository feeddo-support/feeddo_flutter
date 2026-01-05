import 'package:flutter/material.dart';
import '../../feeddo_client.dart';
import '../../models/ticket.dart';
import '../../theme/feeddo_theme.dart';
import '../screens/feeddo_chat_screen.dart';

class TicketDetailsSheet extends StatefulWidget {
  final String? ticketId;
  final Ticket? ticket;
  final FeeddoTheme? theme;

  const TicketDetailsSheet({
    Key? key,
    this.ticketId,
    this.ticket,
    this.theme,
  })  : assert(ticketId != null || ticket != null,
            'Either ticketId or ticket must be provided'),
        super(key: key);

  static Future<void> show(BuildContext context,
      {String? ticketId, Ticket? ticket, FeeddoTheme? theme}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TicketDetailsSheet(ticketId: ticketId, ticket: ticket, theme: theme),
    );
  }

  @override
  State<TicketDetailsSheet> createState() => _TicketDetailsSheetState();
}

class _TicketDetailsSheetState extends State<TicketDetailsSheet> {
  Ticket? _ticket;
  bool _isLoading = true;
  String? _error;
  late FeeddoTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? FeeddoTheme.light();
    if (widget.ticket != null) {
      _ticket = widget.ticket;
      _isLoading = false;
    } else {
      _loadTicket();
    }
  }

  Future<void> _loadTicket() async {
    final ticketId = _ticket?.id ?? widget.ticketId;
    if (ticketId == null) return;

    try {
      // Only show loading if we don't have data yet
      if (_ticket == null) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final ticket = await FeeddoInternal.instance.getTicket(ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
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
            Text('Failed to load ticket',
                style: TextStyle(color: _theme.colors.error)),
            TextButton(
              onPressed: _loadTicket,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_ticket == null) {
      return Center(
          child: Text('Ticket not found',
              style: TextStyle(color: _theme.colors.textPrimary)));
    }

    final ticket = _ticket!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.confirmation_number,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'SUPPORT TICKET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _theme.colors.textSecondary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ticket.isResolved
                    ? _theme.colors.success.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ticket.isResolved
                      ? _theme.colors.success.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ticket.isResolved ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: ticket.isResolved
                        ? _theme.colors.success
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.isResolved ? 'RESOLVED' : 'OPEN',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: ticket.isResolved
                          ? _theme.colors.success
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          ticket.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _theme.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          ticket.description,
          style: TextStyle(
            fontSize: 16,
            color: _theme.colors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        // Info message
        if (!ticket.isResolved)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Our support team is working on your ticket and will respond soon.',
                    style: TextStyle(
                      color: _theme.colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (ticket.isOwner && ticket.conversationId != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openConversation(ticket.conversationId!),
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
      ],
    );
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
