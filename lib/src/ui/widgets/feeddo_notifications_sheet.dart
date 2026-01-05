import 'package:flutter/material.dart';
import '../../feeddo_client.dart';
import '../../feeddo.dart';
import '../../theme/feeddo_theme.dart';
import '../../models/feeddo_notification.dart';
import 'package:intl/intl.dart';

class FeeddoNotificationsSheet extends StatefulWidget {
  final FeeddoTheme theme;

  const FeeddoNotificationsSheet({
    Key? key,
    required this.theme,
  }) : super(key: key);

  @override
  State<FeeddoNotificationsSheet> createState() =>
      _FeeddoNotificationsSheetState();
}

class _FeeddoNotificationsSheetState extends State<FeeddoNotificationsSheet> {
  List<FeeddoNotification>? _notifications;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = FeeddoInternal.instance.userId;
      if (userId == null) {
        throw Exception('User not initialized');
      }

      final notifications =
          await FeeddoInternal.instance.apiService.getNotifications(userId);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Feeddo: Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.colors.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: widget.theme.colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close,
                      color: widget.theme.colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
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
        child: CircularProgressIndicator(
          color: widget.theme.colors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: widget.theme.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.theme.colors.textPrimary,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: _loadNotifications,
              child: Text(
                'Retry',
                style: TextStyle(color: widget.theme.colors.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications == null || _notifications!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: widget.theme.colors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: widget.theme.colors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = _notifications![index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(FeeddoNotification notification) {
    return InkWell(
      onTap: () {
        if (notification.data != null) {
          Feeddo.handleNotificationTap(
            context,
            notification.data!,
            theme: widget.theme,
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.theme.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.theme.colors.border.withOpacity(0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.theme.colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: widget.theme.colors.primary,
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
                      Expanded(
                        child: Text(
                          notification.title ?? 'Notification',
                          style: TextStyle(
                            color: widget.theme.colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          color: widget.theme.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body ?? '',
                    style: TextStyle(
                      color: widget.theme.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
