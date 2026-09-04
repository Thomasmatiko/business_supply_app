
import 'package:flutter/material.dart';

import '../../models/notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final NotificationService _notificationService =
      NotificationService.instance;

  final AuthService _authService =
      AuthService.instance;

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _notificationService.addListener(
      _onNotificationsChanged,
    );
  }

  @override
  void dispose() {
    _notificationService.removeListener(
      _onNotificationsChanged,
    );

    super.dispose();
  }

  // ============================================================
  // NOTIFICATION CHANGE LISTENER
  // ============================================================

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get _userId {
    return _authService.currentUser?.id;
  }

  // ============================================================
  // USER NOTIFICATIONS
  // ============================================================

  List<AppNotification> get _notifications {
    final userId = _userId;

    if (userId == null) {
      return <AppNotification>[];
    }

    return _notificationService
        .notificationsForUser(userId);
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  int get _unreadCount {
    final userId = _userId;

    if (userId == null) {
      return 0;
    }

    return _notificationService
        .unreadCountForUser(userId);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
              ),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(BuildContext context) {
    // ----------------------------------------------------------
    // LOGIN REQUIRED
    // ----------------------------------------------------------

    if (_userId == null) {
      return _buildEmptyState(
        context,
        icon: Icons.lock_outline,
        title: 'Login Required',
        message:
            'Please login to view your notifications.',
      );
    }

    // ----------------------------------------------------------
    // NOTIFICATIONS DISABLED
    // ----------------------------------------------------------

    if (!_notificationService
        .notificationsEnabled(_userId!)) {
      return _buildNotificationsDisabled(
        context,
      );
    }

    // ----------------------------------------------------------
    // NO NOTIFICATIONS
    // ----------------------------------------------------------

    if (_notifications.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.notifications_none_outlined,
        title: 'No Notifications',
        message:
            'You do not have any notifications yet.',
      );
    }

    // ----------------------------------------------------------
    // NOTIFICATION LIST
    // ----------------------------------------------------------

    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) {
          setState(() {});
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (
          context,
          index,
        ) {
          final notification =
              _notifications[index];

          return _NotificationCard(
            notification: notification,
            onTap: () {
              _markAsRead(
                notification.id,
              );
            },
            onDelete: () {
              _deleteNotification(
                notification.id,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS DISABLED
  // ============================================================

  Widget _buildNotificationsDisabled(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 46,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Notifications are off',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'You have turned off notifications. '
              'You will not receive new notification alerts.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: () {
                _notificationService
                    .setNotificationsEnabled(
                  _userId!,
                  true,
                );
              },
              icon: const Icon(
                Icons.notifications_active_outlined,
              ),
              label: const Text(
                'Turn Notifications On',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  void _markAsRead(
    String notificationId,
  ) {
    _notificationService.markAsRead(
      notificationId,
    );
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  void _markAllAsRead() {
    final userId = _userId;

    if (userId == null) {
      return;
    }

    _notificationService.markAllAsRead(
      userId,
    );
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  void _deleteNotification(
    String notificationId,
  ) {
    _notificationService.deleteNotification(
      notificationId,
    );
  }
}

// ============================================================
// NOTIFICATION CARD
// ============================================================

class _NotificationCard
    extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getNotificationColor(
      context,
      notification.type,
    );

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        onDelete();
      },
      background: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.only(
          right: 20,
        ),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context)
                  .colorScheme
                  .surface
              : color.withValues(
                  alpha: 0.08,
                ),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Theme.of(context)
                    .dividerColor
                    .withValues(
                      alpha: 0.35,
                    )
                : color.withValues(
                    alpha: 0.30,
                  ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildIcon(
                  context,
                  color,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight:
                                    notification
                                            .isRead
                                        ? FontWeight
                                            .w600
                                        : FontWeight
                                            .bold,
                                fontSize: 15,
                              ),
                            ),
                          ),

                          if (!notification.isRead)
                            Container(
                              width: 9,
                              height: 9,
                              decoration:
                                  BoxDecoration(
                                color: color,
                                shape:
                                    BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        notification.message,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _formatTime(
                          notification.createdAt,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  Widget _buildIcon(
    BuildContext context,
    Color color,
  ) {
    IconData icon;

    switch (notification.type) {
      case 'order':
        icon = Icons.receipt_long_outlined;
        break;

      case 'payment':
        icon = Icons.payments_outlined;
        break;

      case 'seller':
        icon = Icons.storefront_outlined;
        break;

      case 'account':
        icon = Icons.person_outline;
        break;

      default:
        icon = Icons.notifications_outlined;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
      ),
    );
  }

  // ============================================================
  // NOTIFICATION COLOR
  // ============================================================

  Color _getNotificationColor(
    BuildContext context,
    String type,
  ) {
    switch (type) {
      case 'order':
        return Theme.of(context)
            .colorScheme
            .primary;

      case 'payment':
        return Colors.green;

      case 'seller':
        return Colors.orange;

      case 'account':
        return Colors.indigo;

      default:
        return Theme.of(context)
            .colorScheme
            .primary;
    }
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();

    final difference =
        now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes =
          difference.inMinutes;

      return '$minutes '
          '${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final hours =
          difference.inHours;

      return '$hours '
          '${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays < 7) {
      final days =
          difference.inDays;

      return '$days '
          '${days == 1 ? 'day' : 'days'} ago';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }
}
