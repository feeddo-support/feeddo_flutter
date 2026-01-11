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
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.colors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    onPressed: _createNewConversation,
                    backgroundColor: widget.theme.colors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.edit_rounded,
                        size: 24,
                        color:
                            widget.theme.isDark ? Colors.black : Colors.white),
                  ),
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
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting Section
                            const SizedBox(height: 32),
                            Text(
                              'Hi there 👋',
                              style: TextStyle(
                                color: widget.theme.colors.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'How can we help you today?',
                              style: TextStyle(
                                color: widget.theme.colors.textSecondary,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Primary Action Card
                            if (!hasRecentActivity) ...[
                              _buildPrimaryActionCard(),
                              const SizedBox(height: 32),
                            ],

                            // Quick Actions Section
                            Row(
                              children: [
                                Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    color: widget.theme.colors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _buildMenuCard(
                              title: 'Messages',
                              subtitle: 'View your conversations',
                              icon: Icons.chat_bubble_outline,
                              color: Colors.blue,
                              onTap: widget.onMessagesTap,
                              badgeCount: FeeddoInternal.instance
                                  .conversationService.unreadMessageCount,
                            ),
                            const SizedBox(height: 14),
                            _buildMenuCard(
                              title: 'Request a feature',
                              subtitle: 'Suggest features or report bugs',
                              icon: Icons.lightbulb_outline,
                              color: Colors.amber,
                              onTap: widget.onFeatureRequestTap,
                            ),
                            const SizedBox(height: 14),
                            _buildMenuCard(
                              title: 'Tickets',
                              subtitle: 'Track your support tickets',
                              icon: Icons.confirmation_number_outlined,
                              color: Colors.purple,
                              onTap: widget.onTicketsTap,
                            ),

                            // Recent Activity Section
                            if (hasRecentActivity) ...[
                              const SizedBox(height: 36),
                              Row(
                                children: [
                                  Text(
                                    'Recent Activity',
                                    style: TextStyle(
                                      color: widget.theme.colors.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (displayConversation != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildConversationCard(
                                      displayConversation),
                                ),
                              if (_homeData?.recentTicket != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
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
                                  padding: const EdgeInsets.only(bottom: 14),
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

                            const SizedBox(height: 48),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Powered by ',
                                    style: TextStyle(
                                      color: widget.theme.colors.textSecondary
                                          .withOpacity(0.4),
                                      fontSize: 13,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  Text(
                                    FeeddoInternal.instance.chatBotName,
                                    style: TextStyle(
                                      color: widget.theme.colors.textSecondary
                                          .withOpacity(0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 74,
                  top: 12,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: widget.theme.colors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.theme.isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: widget.theme.colors.divider.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.notifications_outlined,
                              color: widget.theme.colors.textPrimary, size: 22),
                          onPressed: _showNotifications,
                        ),
                      ),
                      if (_homeData != null &&
                          _homeData!.unreadNotificationCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                _homeData!.unreadNotificationCount > 99
                                    ? '99+'
                                    : _homeData!.unreadNotificationCount
                                        .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.theme.colors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.theme.isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: widget.theme.colors.divider.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: widget.theme.colors.closeButtonColor, size: 22),
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

    return Container(
      decoration: BoxDecoration(
        color: widget.theme.colors.primary,
        borderRadius: BorderRadius.circular(16),
        
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _createNewConversation,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: onPrimaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.send_rounded,
                      color: onPrimaryColor, size: 24),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'We\'re here to help',
                        style: TextStyle(
                          color: onPrimaryColor.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    color: onPrimaryColor, size: 22),
              ],
            ),
          ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.theme.isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: widget.theme.colors.divider.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (badgeCount != null && badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: widget.theme.colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.theme.colors.textSecondary.withOpacity(0.3),
                  size: 24,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.theme.isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: widget.theme.colors.divider.withOpacity(0.3),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                                      'Conversation',
                                  style: TextStyle(
                                    color: widget.theme.colors.cardText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conversation.unreadMessages > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    conversation.unreadMessages > 99
                                        ? '99+'
                                        : conversation.unreadMessages.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: widget.theme.colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.theme.colors.textSecondary.withOpacity(0.3),
                      size: 24,
                    ),
                  ],
                ),
                if (conversation.lastMessagePreview != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    conversation.lastMessagePreview!,
                    style: TextStyle(
                      color: widget.theme.colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.1,
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
