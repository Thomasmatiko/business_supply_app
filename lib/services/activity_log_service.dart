
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

class ActivityLogService extends ChangeNotifier {
  ActivityLogService._();

  static final ActivityLogService instance =
      ActivityLogService._();

  final DatabaseHelper _database =
      DatabaseHelper.instance;

  // ============================================================
  // RECORD ACTIVITY
  // ============================================================

  Future<void> logActivity({
    String? userId,
    String? userName,
    required String action,
    required String description,
    String type = 'general',
  }) async {
    try {
      await _database.insertActivityLog(
        userId: userId,
        userName: userName,
        action: action,
        description: description,
        type: type,
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Activity log error: $e',
      );
    }
  }

  // ============================================================
  // RECORD AUDIT
  // ============================================================

  Future<void> logAudit({
    String? userId,
    String? userName,
    required String action,
    String? entityType,
    String? entityId,
    required String description,
  }) async {
    try {
      await _database.insertAuditLog(
        userId: userId,
        userName: userName,
        action: action,
        entityType: entityType,
        entityId: entityId,
        description: description,
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Audit log error: $e',
      );
    }
  }

  // ============================================================
  // RECORD BOTH ACTIVITY AND AUDIT
  // ============================================================

  Future<void> logAction({
    String? userId,
    String? userName,
    required String action,
    required String description,
    String type = 'general',
    String? entityType,
    String? entityId,
    bool audit = true,
  }) async {
    await logActivity(
      userId: userId,
      userName: userName,
      action: action,
      description: description,
      type: type,
    );

    if (audit) {
      await logAudit(
        userId: userId,
        userName: userName,
        action: action,
        entityType: entityType,
        entityId: entityId,
        description: description,
      );
    }
  }

  // ============================================================
  // GET ACTIVITY LOGS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getActivityLogs({
    int? limit,
    String? userId,
  }) async {
    try {
      if (userId != null &&
          userId.trim().isNotEmpty) {
        return await _database.query(
          'activity_logs',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'created_at DESC',
          limit: limit,
        );
      }

      return await _database.getActivityLogs(
        limit: limit,
      );
    } catch (e) {
      debugPrint(
        'Error loading activity logs: $e',
      );

      return [];
    }
  }

  // ============================================================
  // GET AUDIT LOGS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getAuditLogs({
    int? limit,
    String? userId,
  }) async {
    try {
      if (userId != null &&
          userId.trim().isNotEmpty) {
        return await _database.query(
          'audit_logs',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'created_at DESC',
          limit: limit,
        );
      }

      return await _database.getAuditLogs(
        limit: limit,
      );
    } catch (e) {
      debugPrint(
        'Error loading audit logs: $e',
      );

      return [];
    }
  }

  // ============================================================
  // DELETE ACTIVITY LOGS
  // ============================================================

  Future<void> clearActivityLogs() async {
    try {
      await _database.delete(
        'activity_logs',
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error clearing activity logs: $e',
      );
    }
  }

  // ============================================================
  // DELETE AUDIT LOGS
  // ============================================================

  Future<void> clearAuditLogs() async {
    try {
      await _database.delete(
        'audit_logs',
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error clearing audit logs: $e',
      );
    }
  }

  // ============================================================
  // DEVELOPMENT / TEST
  // ============================================================

  Future<void> clearAllLogs() async {
    try {
      await _database.delete(
        'activity_logs',
      );

      await _database.delete(
        'audit_logs',
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error clearing activity and audit logs: $e',
      );
    }
  }
}

