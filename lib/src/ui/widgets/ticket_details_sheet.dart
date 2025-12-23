import 'package:flutter/material.dart';
import '../../feeddo_client.dart';
import '../../models/ticket.dart';

class TicketDetailsSheet extends StatefulWidget {
  final String? ticketId;
  final Ticket? ticket;

  const TicketDetailsSheet({
    Key? key,
    this.ticketId,
    this.ticket,
  })  : assert(ticketId != null || ticket != null,
            'Either ticketId or ticket must be provided'),
        super(key: key);

  static Future<void> show(BuildContext context,
      {String? ticketId, Ticket? ticket}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TicketDetailsSheet(ticketId: ticketId, ticket: ticket),
    );
  }

  @override
  State<TicketDetailsSheet> createState() => _TicketDetailsSheetState();
}

class _TicketDetailsSheetState extends State<TicketDetailsSheet> {
  Ticket? _ticket;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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

      final ticket = await Feeddo.instance.getTicket(ticketId);
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
            Text('Failed to load ticket',
                style: TextStyle(color: Colors.red.shade700)),
            TextButton(
              onPressed: _loadTicket,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_ticket == null) {
      return const Center(child: Text('Ticket not found'));
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
              color: Colors.blue.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'SUPPORT TICKET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ticket.isResolved
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ticket.isResolved
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ticket.isResolved ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: ticket.isResolved ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.isResolved ? 'RESOLVED' : 'OPEN',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: ticket.isResolved ? Colors.green : Colors.orange,
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
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          ticket.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade800,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        // Priority Badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getPriorityColor(ticket.priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getPriorityColor(ticket.priority).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getPriorityIcon(ticket.priority),
                color: _getPriorityColor(ticket.priority),
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.priority.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(ticket.priority),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Info message
        if (!ticket.isResolved)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Our support team is working on your ticket and will respond soon.',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.label;
    }
  }
}
