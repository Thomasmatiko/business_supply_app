import 'package:flutter/material.dart';

import '../screens/notifications/notifications_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
  });

  @override
  State<NotificationBell> createState() =>
      _NotificationBellState();
}

class _NotificationBellState
    extends State<NotificationBell> {
  final NotificationService _notificationService =
      NotificationService.instance;

  final AuthService _authService =
      AuthService.instance;

  @override
  void initState() {
    super.initState();

    _notificationService.addListener(
      _onNotificationsChanged,
    );

    _loadNotifications();
  }

  @override
  void dispose() {
    _notificationService.removeListener(
      _onNotificationsChanged,
    );

    super.dispose();
  }

  // ============================================================
  // LOAD CURRENT USER NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotifications() async {
    final userId = _authService.currentUser?.id;

    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    try {
      await _notificationService
          .loadNotificationsForUser(userId);
    } catch (_) {
      // Dashboard notification loading should never
      // prevent the dashboard from opening.
    }
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
  // UNREAD COUNT
  // ============================================================

  int get _unreadCount {
    final userId = _authService.currentUser?.id;

    if (userId == null || userId.trim().isEmpty) {
      return 0;
    }

    return _notificationService
        .unreadCountForUser(userId);
  }

  // ============================================================
  // OPEN NOTIFICATIONS
  // ============================================================

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );

    // Reload after returning from NotificationsScreen.
    await _loadNotifications();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadCount;

    return IconButton(
      tooltip: unreadCount > 0
          ? '$unreadCount unread notifications'
          : 'Notifications',
      onPressed: _openNotifications,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
          ),

          if (unreadCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context)
                        .appBarTheme
                        .backgroundColor ??
                        Theme.of(context)
                            .colorScheme
                            .surface,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99
                        ? '99+'
                        : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}