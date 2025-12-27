import 'package:flutter/material.dart';
import '../../theme/feeddo_theme.dart';
import '../../models/conversation.dart';
import '../../feeddo_client.dart';
import '../screens/feeddo_chat_screen.dart';

/// Instagram-style in-app notification widget for Feeddo
///
/// Displays a dismissible notification banner when there are unread messages
/// in a conversation. Appears at the top of the screen with slide-in animation.
class FeeddoNotificationBadge extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback? onDismiss;
  final FeeddoTheme? theme;

  const FeeddoNotificationBadge({
    Key? key,
    required this.conversation,
    this.onDismiss,
    this.theme,
  }) : super(key: key);

  @override
  State<FeeddoNotificationBadge> createState() =>
      _FeeddoNotificationBadgeState();
}

class _FeeddoNotificationBadgeState extends State<FeeddoNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  void _onTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeeddoChatScreen(
          conversation: widget.conversation,
          theme: widget.theme ?? FeeddoTheme.dark(),
        ),
      ),
    );
    _dismiss();
  }

  String _formatTime(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? FeeddoTheme.dark();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
                  border: Border.all(
                    color: theme.colors.border.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: _onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar/Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: theme.colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.conversation.displayName ??
                                          FeeddoInternal.instance.chatBotName,
                                      style: TextStyle(
                                        color: theme.colors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(
                                        widget.conversation.lastMessageAt),
                                    style: TextStyle(
                                      color: theme.colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (widget.conversation.lastMessagePreview !=
                                  null)
                                Text(
                                  widget.conversation.lastMessagePreview!,
                                  style: TextStyle(
                                    color: theme.colors.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Close button
                        // Only show if there's enough space or maybe just rely on swipe/tap?
                        // Let's keep it but make it subtle
                        InkWell(
                          onTap: _dismiss,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              color:
                                  theme.colors.textSecondary.withOpacity(0.7),
                              size: 18,
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
        ),
      ),
    );
  }
}

/// Overlay entry manager for showing notifications
class FeeddoNotificationManager {
  static OverlayEntry? _currentOverlay;
  static final List<Conversation> _notificationQueue = [];
  static bool _isShowing = false;

  /// Show a notification for a conversation
  static void showNotification(
    BuildContext context,
    Conversation conversation, {
    FeeddoTheme? theme,
    Duration duration = const Duration(seconds: 10),
  }) {
    // Skip if no unread messages
    if (conversation.unreadMessages == 0) return;

    // Add to queue
    if (!_notificationQueue.any((c) => c.id == conversation.id)) {
      _notificationQueue.add(conversation);
    }

    // Show next notification if not already showing
    if (!_isShowing) {
      _showNext(context, theme: theme, duration: duration);
    }
  }

  static void _showNext(
    BuildContext context, {
    FeeddoTheme? theme,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (_notificationQueue.isEmpty) {
      _isShowing = false;
      return;
    }

    _isShowing = true;
    final conversation = _notificationQueue.removeAt(0);

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: FeeddoNotificationBadge(
          conversation: conversation,
          theme: theme,
          onDismiss: () {
            _dismiss();
            // Show next notification after a brief delay
            Future.delayed(const Duration(milliseconds: 300), () {
              _showNext(context, theme: theme, duration: duration);
            });
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (_currentOverlay != null) {
        _dismiss();
        // Show next notification
        Future.delayed(const Duration(milliseconds: 300), () {
          _showNext(context, theme: theme, duration: duration);
        });
      }
    });
  }

  static void _dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Clear all notifications
  static void clearAll() {
    _dismiss();
    _notificationQueue.clear();
    _isShowing = false;
  }
}
