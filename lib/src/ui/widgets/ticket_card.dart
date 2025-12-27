import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../theme/feeddo_theme.dart';
import 'ticket_details_sheet.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final FeeddoTheme theme;

  const TicketCard({
    Key? key,
    required this.ticket,
    this.onTap,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () => TicketDetailsSheet.show(context, ticket: ticket, theme: theme),
      borderRadius: BorderRadius.circular(12),
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
                const Icon(Icons.confirmation_number,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'TICKET',
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
                    color: ticket.isResolved
                        ? theme.colors.success.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: ticket.isResolved
                          ? theme.colors.success.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    ticket.isResolved ? 'RESOLVED' : 'OPEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: ticket.isResolved
                          ? theme.colors.success
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colors.cardText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: theme.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
