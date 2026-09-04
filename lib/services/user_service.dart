import '../database/database_helper.dart';
import '../models/user.dart';
import 'activity_log_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class UserService {
  static final UserService instance =
      UserService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  final ActivityLogService _activityLogService =
      ActivityLogService.instance;

  UserService._init();

  // ============================================================
  // PERMANENT LEADER ADMIN
  // ============================================================

  static const String leaderAdminId =
      'ADMIN001';

  static const String leaderAdminEmail =
      'thomasmatiko021@gmail.com';

  // ============================================================
  // ACTIVITY / AUDIT LOGGING
  // ============================================================

  Future<void> _logUserAction({
    String? userId,
    String? userName,
    required String action,
    required String description,
    String? entityId,
  }) async {
    try {
      await _activityLogService.logAction(
        userId: userId,
        userName: userName,
        action: action,
        description: description,
        type: 'user',
        entityType: 'user',
        entityId: entityId,
        audit: true,
      );
    } catch (_) {
      // Logging failure must never break the user operation.
    }
  }

  // ============================================================
  // GET ALL USERS
  // ============================================================

  Future<List<AppUser>> getUsers() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      orderBy: 'name ASC',
    );

    return result
        .map((map) => AppUser.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET USER BY ID
  // ============================================================

  Future<AppUser?> getUserById(
    String id,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  // ============================================================
  // GET USER BY EMAIL
  // ============================================================

  Future<AppUser?> getUserByEmail(
    String email,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [
        email.trim().toLowerCase(),
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  // ============================================================
  // ADD USER
  // ============================================================

  Future<int> addUser(
    AppUser user,
  ) async {
    final db = await _databaseHelper.database;

    final normalizedUser = user.copyWith(
      email: user.email.trim().toLowerCase(),
    );

    final result = await db.insert(
      'users',
      normalizedUser.toMap(),
    );

    // ----------------------------------------------------------
    // ACTIVITY / AUDIT
    // ----------------------------------------------------------

    await _logUserAction(
      userId: normalizedUser.id,
      userName: normalizedUser.name,
      action: 'CREATE_USER',
      description:
          '${normalizedUser.name} was registered as a '
          '${normalizedUser.role}.',
      entityId: normalizedUser.id,
    );

    // ----------------------------------------------------------
    // NOTIFY LEADER ADMIN
    // ----------------------------------------------------------

    try {
      await NotificationService.instance.notifyAccount(
        userId: leaderAdminId,
        title: 'New User Registered',
        message:
            '${normalizedUser.name} has been registered as a '
            '${normalizedUser.role}.',
      );
    } catch (_) {
      // Notification failure must not break user creation.
    }

    return result;
  }

  // ============================================================
  // UPDATE USER
  //
  // NOTE:
  // Administrator management should use AdminService.
  // ============================================================

  Future<int> updateUser(
    AppUser user,
  ) async {
    if (user.id == leaderAdminId) {
      throw Exception(
        'The permanent Leader Admin cannot be modified.',
      );
    }

    final db = await _databaseHelper.database;

    // ----------------------------------------------------------
    // GET EXISTING USER BEFORE UPDATE
    // ----------------------------------------------------------

    final existingUser =
        await getUserById(user.id);

    final normalizedUser = user.copyWith(
      email: user.email.trim().toLowerCase(),
    );

    final result = await db.update(
      'users',
      normalizedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );

    // ----------------------------------------------------------
    // ACTIVITY / AUDIT
    // ----------------------------------------------------------

    if (result > 0) {
      await _logUserAction(
        userId: normalizedUser.id,
        userName: normalizedUser.name,
        action: 'UPDATE_USER',
        description:
            '${normalizedUser.name} account information was updated.',
        entityId: normalizedUser.id,
      );
    }

    // ----------------------------------------------------------
    // NOTIFY UPDATED USER
    // ----------------------------------------------------------

    if (result > 0) {
      try {
        await NotificationService.instance.notifyAccount(
          userId: normalizedUser.id,
          title: 'Account Updated',
          message:
              'Your account information has been updated.',
        );
      } catch (_) {
        // Notification failure must not break user update.
      }
    }

    // Prevent unused variable warning while preserving the
    // existing-user lookup for future audit comparison.
    if (existingUser != null) {
      // Existing user successfully loaded before update.
    }

    return result;
  }

  // ============================================================
  // DELETE USER
  //
  // Generic deletion.
  //
  // Administrator-controlled deletion should use AdminService.
  // ============================================================

  Future<int> deleteUser(
    String id,
  ) async {
    if (id == leaderAdminId) {
      throw Exception(
        'The permanent Leader Admin cannot be deleted.',
      );
    }

    final db = await _databaseHelper.database;

    // ----------------------------------------------------------
    // GET USER BEFORE DELETION
    // ----------------------------------------------------------

    final user = await getUserById(id);

    final result = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    // ----------------------------------------------------------
    // AUDIT
    //
    // AdminService normally handles administrator-controlled
    // deletion logging. This generic method logs the deletion
    // only when it is used directly.
    // ----------------------------------------------------------

    if (result > 0 && user != null) {
      final currentUser =
          AuthService.instance.currentUser;

      await _logUserAction(
        userId: currentUser?.id ?? user.id,
        userName: currentUser?.name ?? user.name,
        action: 'DELETE_USER',
        description:
            '${user.name} (${user.email}) was deleted from '
            'the system.',
        entityId: user.id,
      );
    }

    // ----------------------------------------------------------
    // NOTIFY LEADER ADMIN
    //
    // The user is already deleted, so notification is sent
    // to the Leader Admin rather than the deleted user.
    // ----------------------------------------------------------

    if (result > 0 && user != null) {
      try {
        await NotificationService.instance.notifyAccount(
          userId: leaderAdminId,
          title: 'User Deleted',
          message:
              '${user.name} (${user.email}) has been deleted '
              'from the system.',
        );
      } catch (_) {
        // Notification failure must not break user deletion.
      }
    }

    return result;
  }

  // ============================================================
  // RESET USERS
  // ============================================================

  Future<int> deleteAllUsersExceptLeader(
    String leaderEmail,
  ) async {
    final db = await _databaseHelper.database;

    final normalizedEmail =
        leaderEmail.trim().toLowerCase();

    final result = await db.delete(
      'users',
      where:
          'LOWER(TRIM(email)) != ? AND id != ?',
      whereArgs: [
        normalizedEmail,
        leaderAdminId,
      ],
    );

    // ----------------------------------------------------------
    // ACTIVITY / AUDIT
    // ----------------------------------------------------------

    if (result > 0) {
      final currentUser =
          AuthService.instance.currentUser;

      await _logUserAction(
        userId: currentUser?.id ?? leaderAdminId,
        userName:
            currentUser?.name ?? 'Leader Admin',
        action: 'DELETE_ALL_USERS_EXCEPT_LEADER',
        description:
            '$result user account(s) were removed from '
            'the system, excluding the permanent Leader Admin.',
        entityId: leaderAdminId,
      );
    }

    // ----------------------------------------------------------
    // NOTIFY LEADER ADMIN
    // ----------------------------------------------------------

    if (result > 0) {
      try {
        await NotificationService.instance.notifyAccount(
          userId: leaderAdminId,
          title: 'Users Reset',
          message:
              '$result user account(s) were removed from '
              'the system.',
        );
      } catch (_) {
        // Notification failure must not break reset operation.
      }
    }

    return result;
  }

  // ============================================================
  // ENSURE LEADER ADMIN
  // ============================================================

  Future<int> ensureLeaderAdmin(
    String email,
  ) async {
    final db = await _databaseHelper.database;

    final normalizedEmail =
        email.trim().toLowerCase();

    final result = await db.update(
      'users',
      {
        'role': 'admin',
        'admin_level': 'leader',
      },
      where:
          'id = ? AND LOWER(TRIM(email)) = ?',
      whereArgs: [
        leaderAdminId,
        normalizedEmail,
      ],
    );

    // ----------------------------------------------------------
    // NOTIFY LEADER ADMIN
    //
    // This operation is intentionally not written to the
    // activity/audit log because it may run automatically during
    // application initialization.
    // ----------------------------------------------------------

    if (result > 0) {
      try {
        await NotificationService.instance.notifyAccount(
          userId: leaderAdminId,
          title: 'Leader Admin Verified',
          message:
              'Your Leader Admin account has been verified '
              'and remains active.',
        );
      } catch (_) {
        // Notification failure must not break verification.
      }
    }

    return result;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<AppUser?> login(
    String email,
    String password,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'LOWER(TRIM(email)) = ? AND password = ?',
      whereArgs: [
        email.trim().toLowerCase(),
        password,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  // ============================================================
  // CHANGE PASSWORD
  //
  // Used when the logged-in user knows their current password.
  // ============================================================

  Future<bool> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await _databaseHelper.database;

    // ----------------------------------------------------------
    // VERIFY CURRENT PASSWORD
    // ----------------------------------------------------------

    final result = await db.query(
      'users',
      columns: [
        'id',
        'name',
      ],
      where:
          'id = ? AND password = ?',
      whereArgs: [
        userId,
        currentPassword,
      ],
      limit: 1,
    );

    // Current password is incorrect.
    if (result.isEmpty) {
      return false;
    }

    final userName =
        result.first['name'] as String? ?? 'User';

    // ----------------------------------------------------------
    // UPDATE PASSWORD
    // ----------------------------------------------------------

    final updated = await db.update(
      'users',
      {
        'password': newPassword,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    // ----------------------------------------------------------
    // ACTIVITY / AUDIT
    // ----------------------------------------------------------

    if (updated > 0) {
      await _logUserAction(
        userId: userId,
        userName: userName,
        action: 'CHANGE_PASSWORD',
        description:
            '$userName changed the account password.',
        entityId: userId,
      );
    }

    // ----------------------------------------------------------
    // NOTIFY USER
    // ----------------------------------------------------------

    if (updated > 0) {
      try {
        await NotificationService.instance.notifyAccount(
          userId: userId,
          title: 'Password Changed',
          message:
              'Your account password has been changed successfully.',
        );
      } catch (_) {
        // Notification failure must not break password change.
      }
    }

    return updated > 0;
  }

  // ============================================================
  // RESET PASSWORD BY EMAIL
  //
  // Used by Forgot Password.
  //
  // Unlike changePassword(), this method does not require the
  // old/current password.
  // ============================================================

  Future<bool> resetPasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    final db = await _databaseHelper.database;

    final normalizedEmail =
        email.trim().toLowerCase();

    // ----------------------------------------------------------
    // VERIFY ACCOUNT EXISTS
    // ----------------------------------------------------------

    final userResult = await db.query(
      'users',
      columns: [
        'id',
        'name',
      ],
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (userResult.isEmpty) {
      return false;
    }

    final userId =
        userResult.first['id'] as String;

    final userName =
        userResult.first['name'] as String? ??
            'User';

    // ----------------------------------------------------------
    // UPDATE PASSWORD
    // ----------------------------------------------------------

    final updated = await db.update(
      'users',
      {
        'password': newPassword,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    // ----------------------------------------------------------
    // ACTIVITY / AUDIT
    // ----------------------------------------------------------

    if (updated > 0) {
      await _logUserAction(
        userId: userId,
        userName: userName,
        action: 'RESET_PASSWORD',
        description:
            '$userName password was reset through the '
            'password recovery process.',
        entityId: userId,
      );
    }

    // ----------------------------------------------------------
    // NOTIFY USER
    // ----------------------------------------------------------

    if (updated > 0) {
      try {
        await NotificationService.instance.notifyAccount(
          userId: userId,
          title: 'Password Reset',
          message:
              'Your account password has been reset successfully.',
        );
      } catch (_) {
        // Notification failure must not break password reset.
      }
    }

    return updated > 0;
  }

  // ============================================================
  // EMAIL EXISTS
  // ============================================================

  Future<bool> emailExists(
    String email,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      columns: ['id'],
      where:
          'LOWER(TRIM(email)) = ?',
      whereArgs: [
        email.trim().toLowerCase(),
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // GET BUYERS
  // ============================================================

  Future<List<AppUser>> getBuyers() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'LOWER(TRIM(role)) = ?',
      whereArgs: ['buyer'],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => AppUser.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET SELLERS
  // ============================================================

  Future<List<AppUser>> getSellers() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'LOWER(TRIM(role)) = ?',
      whereArgs: ['seller'],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => AppUser.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ADMINS
  // ============================================================

  Future<List<AppUser>> getAdmins() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'LOWER(TRIM(role)) = ?',
      whereArgs: ['admin'],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => AppUser.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET NORMAL ADMINS
  // ============================================================

  Future<List<AppUser>> getNormalAdmins() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'LOWER(TRIM(role)) = ? '
          'AND LOWER(TRIM(admin_level)) = ?',
      whereArgs: [
        'admin',
        'normal',
      ],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => AppUser.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET LEADER ADMINS
  // ============================================================

  Future<List<AppUser>> getLeaderAdmins() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'LOWER(TRIM(role)) = ? '
          'AND LOWER(TRIM(admin_level)) = ?',
      whereArgs: [
        'admin',
        'leader',
      ],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => AppUser.fromMap(map))
        .toList();
  }
}