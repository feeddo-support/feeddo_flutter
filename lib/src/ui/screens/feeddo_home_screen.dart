import 'package:feeddo_flutter/feeddo_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../feeddo_client.dart';
import '../../theme/feeddo_theme.dart';
import '../../models/home_data.dart';
import '../../models/conversation.dart';
import '../../utils/storage_helper.dart';
import '../widgets/task_card.dart';
import '../widgets/ticket_card.dart';
import '../widgets/task_details_sheet.dart';
import '../widgets/ticket_details_sheet.dart';
import '../widgets/feeddo_notifications_sheet.dart';
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
    _checkAndPromptUsername();
    _loadHomeData();
    FeeddoInternal.instance.conversationService
        .addListener(_onConversationUpdated);
  }

  @override
  void dispose() {
    FeeddoInternal.instance.conversationService
        .removeListener(_onConversationUpdated);
    super.dispose();
  }

  void _onConversationUpdated() {
    if (mounted) {
      setState(() {
        // Trigger rebuild to update unread count from conversation service
      });
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: FeeddoNotificationsSheet(theme: widget.theme),
      ),
    ).then((_) {
      // Refresh home data when sheet is closed to update unread count
      _loadHomeData();
    });
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
      final data = await FeeddoInternal.instance.getHomeData();

      // Sync recent conversation with service so it receives updates
      if (data.recentConversation != null) {
        FeeddoInternal.instance.conversationService
            .updateConversation(data.recentConversation!);
      }

      if (mounted) {
        setState(() {
          _homeData = data;
        });
      }
    } catch (e) {
      debugPrint('Feeddo: Failed to load home data: $e');
    }
  }

  Future<void> _checkAndPromptUsername() async {
    final userName = await StorageHelper.getUserName();
    if (userName == null || userName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUsernameDialog();
      });
    }
  }

  Future<void> _showUsernameDialog() async {
    final TextEditingController nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.colors.surface,
        title: Text(
          'Welcome!',
          style: TextStyle(color: widget.theme.colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your name to get started',
              style: TextStyle(color: widget.theme.colors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: TextStyle(color: widget.theme.colors.textSecondary),
                filled: true,
                fillColor: widget.theme.colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.theme.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.theme.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.theme.colors.primary),
                ),
              ),
              style: TextStyle(color: widget.theme.colors.textPrimary),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: Text(
              'Continue',
              style: TextStyle(color: widget.theme.colors.primary),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _saveUsername(result);
    }
  }

  Future<void> _saveUsername(String userName) async {
    try {
      await StorageHelper.saveUserData(userName: userName);
      // Re-initialize with the new username
      final externalUserId = await StorageHelper.getExternalUserId();
      final email = await StorageHelper.getEmail();
      final userSegment = await StorageHelper.getUserSegment();
      final subscriptionStatus = await StorageHelper.getSubscriptionStatus();
      final customAttributes = await StorageHelper.getCustomAttributes();

      await FeeddoInternal.instance.updateUser(
        externalUserId: externalUserId,
        userName: userName,
        email: email,
        userSegment: userSegment,
        subscriptionStatus: subscriptionStatus,
        customAttributes: customAttributes,
      );

      debugPrint('Feeddo: Username saved: $userName');
    } catch (e) {
      debugPrint('Feeddo: Failed to save username: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the conversation to display: prefer from conversation service if available, otherwise use home data
    Conversation? displayConversation;

    if (_homeData?.recentConversation != null) {
      final homeConvId = _homeData!.recentConversation!.id;
      // Check if this conversation exists in conversation service (with updates)
      final updatedConv = FeeddoInternal
          .instance.conversationService.conversations
          .where((c) => c.id == homeConvId)
          .firstOrNull;

      // Use updated version from service if available, otherwise use from home data
      displayConversation = updatedConv ?? _homeData!.recentConversation;

      // Only show if not resolved
      if (displayConversation?.status == 'resolved') {
        displayConversation = null;
      }
    }

    final hasRecentActivity = _homeData?.recentTask != null ||
        _homeData?.recentTicket != null ||
        displayConversation != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: widget.theme.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: widget.theme.colors.background,
        floatingActionButton: hasRecentActivity
            ? SizedBox(
                width: 48,
                height: 48,
                child: FloatingActionButton(
                  onPressed: _createNewConversation,
                  backgroundColor: widget.theme.colors.primary,
                  elevation: 4,
                  child: Icon(Icons.edit,
                      size: 20,
                      color: widget.theme.isDark ? Colors.black : Colors.white),
                ),
              )
            : null,
        body: Container(
          color: widget.theme.colors.background,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting
                            const SizedBox(height: 20),
                            Text(
                              'Hi there 👋',
                              style: TextStyle(
                                color: widget.theme.colors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'How can we help you today?',
                              style: TextStyle(
                                color: widget.theme.colors.textPrimary
                                    .withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Menu Grid
                            Text(
                              'MENU',
                              style: TextStyle(
                                color: widget.theme.colors.textSecondary
                                    .withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildMenuCard(
                              title: 'Messages',
                              subtitle: 'View your conversations',
                              icon: Icons.chat_bubble_outline,
                              color: Colors.blue,
                              onTap: widget.onMessagesTap,
                              badgeCount: FeeddoInternal.instance
                                  .conversationService.unreadMessageCount,
                            ),
                            const SizedBox(height: 12),
                            _buildMenuCard(
                              title: 'Feature Requests',
                              subtitle: 'Suggest features or report bugs',
                              icon: Icons.lightbulb_outline,
                              color: Colors.amber,
                              onTap: widget.onFeatureRequestTap,
                            ),
                            const SizedBox(height: 12),
                            _buildMenuCard(
                              title: 'Tickets',
                              subtitle: 'Track your support tickets',
                              icon: Icons.confirmation_number_outlined,
                              color: Colors.purple,
                              onTap: widget.onTicketsTap,
                            ),

                            if (!hasRecentActivity) const SizedBox(height: 24),

                            // Primary Action: Send Message
                            if (!hasRecentActivity) _buildPrimaryActionCard(),

                            // Recent Activity Section
                            if (hasRecentActivity) ...[
                              const SizedBox(height: 32),
                              Text(
                                'RECENT ACTIVITY',
                                style: TextStyle(
                                  color: widget.theme.colors.textSecondary
                                      .withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (displayConversation != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildConversationCard(
                                      displayConversation),
                                ),
                              if (_homeData?.recentTicket != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TicketCard(
                                    ticket: _homeData!.recentTicket!,
                                    theme: widget.theme,
                                    onTap: () {
                                      TicketDetailsSheet.show(
                                        context,
                                        ticket: _homeData!.recentTicket!,
                                        theme: widget.theme,
                                      );
                                    },
                                  ),
                                ),
                              if (_homeData?.recentTask != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskCard(
                                    task: _homeData!.recentTask!,
                                    theme: widget.theme,
                                    onTap: () {
                                      TaskDetailsSheet.show(
                                        context,
                                        task: _homeData!.recentTask!,
                                        theme: widget.theme,
                                        onTaskUpdated: (updatedTask) {
                                          _loadHomeData();
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],

                            const SizedBox(height: 40),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Powered by ',
                                    style: TextStyle(
                                      color: widget.theme.colors.textSecondary
                                          .withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    FeeddoInternal.instance.chatBotName,
                                    style: TextStyle(
                                      color: widget.theme.colors.textSecondary
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 74,
                  top: 16,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              widget.theme.colors.textPrimary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.notifications_outlined,
                              color: widget.theme.colors.textPrimary, size: 20),
                          onPressed: _showNotifications,
                        ),
                      ),
                      if (_homeData != null &&
                          _homeData!.unreadNotificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _homeData!.unreadNotificationCount > 99
                                  ? '99+'
                                  : _homeData!.unreadNotificationCount
                                      .toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.theme.colors.textPrimary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close,
                          color: widget.theme.colors.closeButtonColor,
                          size: 20),
                      onPressed:
                          widget.onClose ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionCard() {
    final onPrimaryColor = widget.theme.isDark ? Colors.black : Colors.white;
    final iconBackgroundColor = widget.theme.isDark
        ? Colors.black.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);

    return InkWell(
      onTap: _createNewConversation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.theme.colors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.theme.colors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.send_rounded, color: onPrimaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send us a message',
                    style: TextStyle(
                      color: onPrimaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: onPrimaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    int? badgeCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.theme.colors.divider.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: widget.theme.colors.cardText,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (badgeCount != null && badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: widget.theme.colors.cardText.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: widget.theme.colors.cardText.withOpacity(0.2),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    final timeAgo = _formatTimeAgo(conversation.lastMessageAt);

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.theme.colors.divider.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => FeeddoChatScreen(
                  conversation: conversation,
                  theme: widget.theme,
                ),
              ),
            );
            _loadHomeData();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  conversation.displayName ??
                                      conversation.title ??
                                      'Recent Conversation',
                                  style: TextStyle(
                                    color: widget.theme.colors.cardText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conversation.unreadMessages > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    conversation.unreadMessages.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color:
                                  widget.theme.colors.cardText.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: widget.theme.colors.cardText.withOpacity(0.2),
                      size: 20,
                    ),
                  ],
                ),
                if (conversation.lastMessagePreview != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    conversation.lastMessagePreview!,
                    style: TextStyle(
                      color: widget.theme.colors.cardText.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(int timestamp) {
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
  }
}
