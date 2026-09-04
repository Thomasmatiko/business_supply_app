import 'package:flutter/foundation.dart';

import '../models/notification.dart';
import '../database/database_helper.dart';
import '../services/activity_log_service.dart';
import '../services/auth_service.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final DatabaseHelper _database =
      DatabaseHelper.instance;

  final ActivityLogService _activityLogService =
      ActivityLogService.instance;

  final List<AppNotification> _notifications =
      <AppNotification>[];

  // Cache of notification settings.
  // The actual persistent value is stored in user_settings.
  final Map<String, bool> _notificationSettings =
      <String, bool>{};

  // ============================================================
  // NOTIFICATION ACTION LOGGING
  // ============================================================

  Future<void> _logNotificationAction({
    required String action,
    required String description,
    String? userId,
    String? entityId,
  }) async {
    try {
      final currentUser =
          AuthService.instance.currentUser;

      await _activityLogService.logAction(
        userId: userId ?? currentUser?.id,
        userName: currentUser?.name,
        action: action,
        description: description,
        type: 'notification',
        entityType: 'notification',
        entityId: entityId,
        audit: true,
      );
    } catch (e) {
      debugPrint(
        'Notification action logging error: $e',
      );
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  // ============================================================
  // GET USER NOTIFICATIONS
  // ============================================================

  List<AppNotification> notificationsForUser(
    String userId,
  ) {
    return _notifications
        .where(
          (notification) =>
              notification.userId == userId,
        )
        .toList();
  }

  List<AppNotification> unreadNotificationsForUser(
    String userId,
  ) {
    return _notifications
        .where(
          (notification) =>
              notification.userId == userId &&
              !notification.isRead,
        )
        .toList();
  }

  int unreadCountForUser(String userId) {
    return _notifications
        .where(
          (notification) =>
              notification.userId == userId &&
              !notification.isRead,
        )
        .length;
  }

  // ============================================================
  // LOAD NOTIFICATIONS FROM DATABASE
  // ============================================================

  Future<void> loadNotificationsForUser(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    final rows = await _database.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      orderBy: 'created_at DESC',
    );

    final loadedNotifications = rows
        .map(
          (row) => AppNotification.fromMap(row),
        )
        .toList();

    // Remove old cached notifications for this user.
    _notifications.removeWhere(
      (notification) =>
          notification.userId == normalizedUserId,
    );

    // Add notifications loaded from database.
    _notifications.addAll(
      loadedNotifications,
    );

    // Keep newest notifications first.
    _notifications.sort(
      (a, b) => b.createdAt.compareTo(
        a.createdAt,
      ),
    );

    notifyListeners();
  }

  // ============================================================
  // LOAD NOTIFICATION SETTING FROM DATABASE
  // ============================================================

  Future<void> loadNotificationsEnabled(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    final rows = await _database.query(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      limit: 1,
    );

    if (rows.isEmpty) {
      // First time for this user.
      // Default setting = enabled.
      _notificationSettings[
        normalizedUserId
      ] = true;

      await _database.insert(
        'user_settings',
        {
          'user_id': normalizedUserId,
          'notifications_enabled': 1,
        },
      );

      return;
    }

    final value =
        rows.first['notifications_enabled'];

    _notificationSettings[
        normalizedUserId] =
        _boolFromDatabase(value);

    notifyListeners();
  }

  // ============================================================
  // NOTIFICATION SETTING
  // ============================================================

  bool notificationsEnabled(String userId) {
    return _notificationSettings[userId] ?? true;
  }

  Future<void> setNotificationsEnabled(
    String userId,
    bool enabled,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    final existing = await _database.query(
      'user_settings',
      columns: ['user_id'],
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      limit: 1,
    );

    int changedRows;

    if (existing.isEmpty) {
      changedRows = await _database.insert(
        'user_settings',
        {
          'user_id': normalizedUserId,
          'notifications_enabled':
              enabled ? 1 : 0,
        },
      );
    } else {
      changedRows = await _database.update(
        'user_settings',
        {
          'notifications_enabled':
              enabled ? 1 : 0,
        },
        where: 'user_id = ?',
        whereArgs: [normalizedUserId],
      );
    }

    if (changedRows <= 0) {
      return;
    }

    _notificationSettings[
        normalizedUserId] = enabled;

    await _logNotificationAction(
      action: enabled
          ? 'notifications_enabled'
          : 'notifications_disabled',
      description: enabled
          ? 'Notifications were enabled for user $normalizedUserId.'
          : 'Notifications were disabled for user $normalizedUserId.',
      userId: normalizedUserId,
      entityId: normalizedUserId,
    );

    notifyListeners();
  }

  // ============================================================
  // CREATE NOTIFICATION
  // ============================================================

  Future<AppNotification?> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // If notifications are disabled, do not create notification.
    // ----------------------------------------------------------

    if (!notificationsEnabled(normalizedUserId)) {
      return null;
    }

    final now = DateTime.now();

    final notification = AppNotification(
      id: now.microsecondsSinceEpoch.toString(),
      userId: normalizedUserId,
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: now,
    );

    // ----------------------------------------------------------
    // SAVE TO DATABASE
    // ----------------------------------------------------------

    final insertedRows = await _database.insert(
      'notifications',
      notification.toMap(),
    );

    if (insertedRows <= 0) {
      return null;
    }

    // ----------------------------------------------------------
    // UPDATE MEMORY CACHE
    // ----------------------------------------------------------

    _notifications.insert(
      0,
      notification,
    );

    await _logNotificationAction(
      action: 'notification_created',
      description:
          'Created notification "$title" for user $normalizedUserId.',
      userId: normalizedUserId,
      entityId: notification.id,
    );

    notifyListeners();

    return notification;
  }

  // ============================================================
  // ORDER NOTIFICATIONS
  // ============================================================

  Future<AppNotification?> notifyOrderPlaced({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Order Placed',
      message:
          'Your order #$orderId has been placed successfully.',
      type: 'order',
    );
  }

  Future<AppNotification?> notifyOrderConfirmed({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Order Confirmed',
      message:
          'Your order #$orderId has been confirmed.',
      type: 'order',
    );
  }

  Future<AppNotification?> notifyOrderProcessing({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Order Processing',
      message:
          'Your order #$orderId is now being processed.',
      type: 'order',
    );
  }

  Future<AppNotification?> notifyOrderShipped({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Order Shipped',
      message:
          'Your order #$orderId has been shipped.',
      type: 'order',
    );
  }

  Future<AppNotification?> notifyOrderDelivered({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Order Delivered',
      message:
          'Your order #$orderId has been delivered.',
      type: 'order',
    );
  }

  Future<AppNotification?> notifyOrderCancelled({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Order Cancelled',
      message:
          'Your order #$orderId has been cancelled.',
      type: 'order',
    );
  }

  // ============================================================
  // SELLER NOTIFICATIONS
  // ============================================================

  Future<AppNotification?> notifySellerNewOrder({
    required String sellerId,
    required String orderId,
  }) {
    return createNotification(
      userId: sellerId,
      title: 'New Order Received',
      message:
          'You have received a new order #$orderId.',
      type: 'seller',
    );
  }

  Future<AppNotification?> notifySellerPaymentReceived({
    required String sellerId,
    required String orderId,
  }) {
    return createNotification(
      userId: sellerId,
      title: 'Payment Received',
      message:
          'Payment for order #$orderId has been received.',
      type: 'payment',
    );
  }

  // ============================================================
  // BUYER PAYMENT NOTIFICATIONS
  // ============================================================

  Future<AppNotification?> notifyPaymentSuccessful({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Payment Successful',
      message:
          'Your payment for order #$orderId was successful.',
      type: 'payment',
    );
  }

  Future<AppNotification?> notifyPaymentFailed({
    required String userId,
    required String orderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Payment Failed',
      message:
          'Your payment for order #$orderId could not be completed.',
      type: 'payment',
    );
  }

  // ============================================================
  // ACCOUNT NOTIFICATIONS
  // ============================================================

  Future<AppNotification?> notifyAccount({
    required String userId,
    required String title,
    required String message,
  }) {
    return createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'account',
    );
  }

  // ============================================================
  // MARK SINGLE NOTIFICATION AS READ
  // ============================================================

  Future<void> markAsRead(
    String notificationId, {
    String? userId,
  }) async {
    final normalizedNotificationId =
        notificationId.trim();

    if (normalizedNotificationId.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Find cached notification first.
    // ----------------------------------------------------------

    final index = _notifications.indexWhere(
      (notification) =>
          notification.id ==
          normalizedNotificationId,
    );

    AppNotification? notification;

    if (index != -1) {
      notification = _notifications[index];
    } else {
      final rows = await _database.query(
        'notifications',
        where: 'id = ?',
        whereArgs: [normalizedNotificationId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        notification =
            AppNotification.fromMap(rows.first);
      }
    }

    if (notification == null) {
      return;
    }

    // ----------------------------------------------------------
    // Ownership check when userId is supplied.
    // ----------------------------------------------------------

    final normalizedUserId =
        userId?.trim();

    if (normalizedUserId != null &&
        normalizedUserId.isNotEmpty &&
        notification.userId != normalizedUserId) {
      return;
    }

    if (notification.isRead) {
      return;
    }

    final changedRows = await _database.update(
      'notifications',
      {
        'is_read': 1,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [
        normalizedNotificationId,
        notification.userId,
      ],
    );

    if (changedRows <= 0) {
      return;
    }

    if (index != -1) {
      _notifications[index] =
          notification.copyWith(
        isRead: true,
      );
    }

    await _logNotificationAction(
      action: 'notification_marked_read',
      description:
          'Marked notification ${notification.id} as read.',
      userId: notification.userId,
      entityId: notification.id,
    );

    notifyListeners();
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    final changed =
        await _database.update(
      'notifications',
      {
        'is_read': 1,
      },
      where: '''
        user_id = ?
        AND is_read = 0
      ''',
      whereArgs: [normalizedUserId],
    );

    if (changed == 0) {
      return;
    }

    for (int i = 0;
        i < _notifications.length;
        i++) {
      final notification =
          _notifications[i];

      if (notification.userId ==
              normalizedUserId &&
          !notification.isRead) {
        _notifications[i] =
            notification.copyWith(
          isRead: true,
        );
      }
    }

    await _logNotificationAction(
      action: 'notifications_marked_all_read',
      description:
          'Marked $changed notification(s) as read for user $normalizedUserId.',
      userId: normalizedUserId,
      entityId: normalizedUserId,
    );

    notifyListeners();
  }

  // ============================================================
  // DELETE SINGLE NOTIFICATION
  // ============================================================

  Future<void> deleteNotification(
    String notificationId, {
    String? userId,
  }) async {
    final normalizedNotificationId =
        notificationId.trim();

    if (normalizedNotificationId.isEmpty) {
      return;
    }

    final index = _notifications.indexWhere(
      (notification) =>
          notification.id ==
          normalizedNotificationId,
    );

    AppNotification? notification;

    if (index != -1) {
      notification = _notifications[index];
    } else {
      final rows = await _database.query(
        'notifications',
        where: 'id = ?',
        whereArgs: [normalizedNotificationId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        notification =
            AppNotification.fromMap(rows.first);
      }
    }

    if (notification == null) {
      return;
    }

    final normalizedUserId =
        userId?.trim();

    if (normalizedUserId != null &&
        normalizedUserId.isNotEmpty &&
        notification.userId != normalizedUserId) {
      return;
    }

    final deletedRows = await _database.delete(
      'notifications',
      where: '''
        id = ?
        AND user_id = ?
      ''',
      whereArgs: [
        normalizedNotificationId,
        notification.userId,
      ],
    );

    if (deletedRows <= 0) {
      return;
    }

    _notifications.removeWhere(
      (cachedNotification) =>
          cachedNotification.id ==
          normalizedNotificationId,
    );

    await _logNotificationAction(
      action: 'notification_deleted',
      description:
          'Deleted notification ${notification.id}.',
      userId: notification.userId,
      entityId: notification.id,
    );

    notifyListeners();
  }

  // ============================================================
  // CLEAR USER NOTIFICATIONS
  // ============================================================

  Future<void> clearUserNotifications(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    final existing = await _database.query(
      'notifications',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
    );

    if (existing.isEmpty) {
      return;
    }

    final deletedRows = await _database.delete(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
    );

    if (deletedRows <= 0) {
      return;
    }

    _notifications.removeWhere(
      (notification) =>
          notification.userId ==
          normalizedUserId,
    );

    await _logNotificationAction(
      action: 'notifications_cleared',
      description:
          'Cleared $deletedRows notification(s) for user $normalizedUserId.',
      userId: normalizedUserId,
      entityId: normalizedUserId,
    );

    notifyListeners();
  }

  // ============================================================
  // DEVELOPMENT / TEST
  //
  // This method is intentionally kept as a development helper.
  // It should not be exposed as a normal user operation.
  // ============================================================

  Future<void> clearAll() async {
    final deletedRows =
        await _database.delete(
      'notifications',
    );

    _notifications.clear();

    if (deletedRows > 0) {
      await _logNotificationAction(
        action: 'all_notifications_cleared',
        description:
            'Cleared all notifications from the database.',
        userId: 'SYSTEM',
        entityId: 'notifications',
      );
    }

    notifyListeners();
  }

  // ============================================================
  // DATABASE BOOLEAN CONVERSION
  // ============================================================

  bool _boolFromDatabase(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized =
          value.trim().toLowerCase();

      return normalized == '1' ||
          normalized == 'true';
    }

    return false;
  }
}