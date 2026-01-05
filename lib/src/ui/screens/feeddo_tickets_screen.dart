import 'package:flutter/material.dart';
import '../../feeddo_client.dart';
import '../../models/ticket.dart';
import '../../theme/feeddo_theme.dart';
import '../widgets/ticket_card.dart';
import '../widgets/ticket_details_sheet.dart';

class FeeddoTicketsScreen extends StatefulWidget {
  final FeeddoTheme? theme;

  const FeeddoTicketsScreen({
    super.key,
    this.theme,
  });

  @override
  State<FeeddoTicketsScreen> createState() => _FeeddoTicketsScreenState();
}

class _FeeddoTicketsScreenState extends State<FeeddoTicketsScreen> {
  late FeeddoTheme _theme;
  bool _isLoading = true;
  String? _error;
  List<Ticket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _theme = widget.theme ?? FeeddoTheme.light();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final tickets = await FeeddoInternal.instance.getTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
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
    return Scaffold(
      backgroundColor: _theme.colors.background,
      appBar: AppBar(
        backgroundColor: _theme.colors.appBarBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: _theme.colors.iconColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tickets',
          style: TextStyle(
            color: _theme.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: _theme.colors.divider.withOpacity(0.1),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _theme.colors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error',
                            style: TextStyle(color: _theme.colors.textPrimary)),
                        TextButton(
                          onPressed: _loadTickets,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Text('No tickets yet',
                          style: TextStyle(color: _theme.colors.textPrimary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return TicketCard(
                          ticket: ticket,
                          theme: _theme,
                          onTap: () {
                            TicketDetailsSheet.show(
                              context,
                              ticket: ticket,
                              theme: _theme,
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
