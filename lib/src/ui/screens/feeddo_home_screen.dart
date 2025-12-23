import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../feeddo_client.dart';
import '../../theme/feeddo_theme.dart';
import '../../models/home_data.dart';
import '../widgets/task_card.dart';
import '../widgets/ticket_card.dart';
import '../widgets/task_details_sheet.dart';
import '../widgets/ticket_details_sheet.dart';
import 'feeddo_chat_screen.dart';

class FeeddoHomeScreen extends StatefulWidget {
  final FeeddoTheme theme;
  final VoidCallback? onClose;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onTicketsTap;
  final VoidCallback? onFeatureRequestTap;
  final VoidCallback? onSendMessageTap;

  const FeeddoHomeScreen({
    super.key,
    required this.theme,
    this.onClose,
    this.onMessagesTap,
    this.onTicketsTap,
    this.onFeatureRequestTap,
    this.onSendMessageTap,
  });

  @override
  State<FeeddoHomeScreen> createState() => _FeeddoHomeScreenState();
}

class _FeeddoHomeScreenState extends State<FeeddoHomeScreen> {
  HomeData? _homeData;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    Feeddo.instance.conversationService.addListener(_onConversationUpdated);
  }

  @override
  void dispose() {
    Feeddo.instance.conversationService.removeListener(_onConversationUpdated);
    super.dispose();
  }

  void _onConversationUpdated() {
    if (mounted) {
      setState(() {
        // Trigger rebuild to update unread count from conversation service
      });
    }
  }

  Future<void> _createNewConversation() async {
    // Navigate to chat screen directly
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FeeddoChatScreen(
          conversation: null,
          theme: widget.theme,
        ),
      ),
    );
  }

  Future<void> _loadHomeData() async {
    try {
      final data = await Feeddo.instance.getHomeData();
      if (mounted) {
        setState(() {
          _homeData = data;
        });
      }
    } catch (e) {
      debugPrint('Feeddo: Failed to load home data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRecentActivity =
        _homeData?.recentTask != null || _homeData?.recentTicket != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        floatingActionButton: hasRecentActivity
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: _createNewConversation,
                  backgroundColor: Colors.black,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
              )
            : null,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: widget.theme.colors.background,
            gradient: widget.theme.colors.backgroundGradient != null
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.theme.colors.backgroundGradient!,
                    stops: widget.theme.colors.backgroundGradientStops,
                  )
                : null,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.close,
                            color: widget.theme.colors.closeButtonColor),
                        onPressed:
                            widget.onClose ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Greeting
                    Text(
                      'Hi there 👋',
                      style: TextStyle(
                        color: widget.theme.colors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How can we help?',
                      style: TextStyle(
                        color: widget.theme.colors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Menu Options
                    Container(
                      decoration: BoxDecoration(
                        color: widget.theme.colors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            title: 'Feature Request / Bug Report',
                            icon: Icons.lightbulb_outline,
                            onTap: widget.onFeatureRequestTap,
                            isFirst: true,
                          ),
                          Divider(
                              height: 1, color: Colors.grey.withOpacity(0.2)),
                          _buildMenuItem(
                            title: 'Messages',
                            icon: Icons.chat_bubble_outline,
                            onTap: widget.onMessagesTap,
                            badgeCount: Feeddo.instance.conversationService
                                .unreadMessageCount,
                          ),
                          Divider(
                              height: 1, color: Colors.grey.withOpacity(0.2)),
                          _buildMenuItem(
                            title: 'Tickets',
                            icon: Icons.confirmation_number_outlined,
                            onTap: widget.onTicketsTap,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    // Recent Activity
                    if (_homeData?.recentTask != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TaskCard(
                          task: _homeData!.recentTask!,
                          onTap: () {
                            TaskDetailsSheet.show(
                              context,
                              task: _homeData!.recentTask!,
                              onTaskUpdated: (updatedTask) {
                                // Refresh home data if task is updated
                                _loadHomeData();
                              },
                            );
                          },
                        ),
                      ),

                    if (_homeData?.recentTicket != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TicketCard(
                          ticket: _homeData!.recentTicket!,
                          onTap: () {
                            TicketDetailsSheet.show(
                              context,
                              ticket: _homeData!.recentTicket!,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),
                    // Send Message Button (only if no recent activity)
                    if (!hasRecentActivity)
                      InkWell(
                        onTap: _createNewConversation,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: widget.theme.colors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Send us a message',
                                style: TextStyle(
                                  color: widget.theme.colors.cardText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 16,
                                  color: widget.theme.colors.iconColor),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: widget.theme.colors.cardText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (badgeCount != null && badgeCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Icon(icon, size: 20, color: widget.theme.colors.iconColor),
          ],
        ),
      ),
    );
  }
}
