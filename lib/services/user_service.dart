
import '../database/database_helper.dart';
import '../models/user.dart';

class UserService {
  static final UserService instance =
      UserService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  UserService._init();

  // ============================================================
  // PERMANENT LEADER ADMIN
  // ============================================================

  static const String leaderAdminId =
      'ADMIN001';

  static const String leaderAdminEmail =
      'thomasmatiko021@gmail.com';

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

    return db.insert(
      'users',
      normalizedUser.toMap(),
    );
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

    final normalizedUser = user.copyWith(
      email: user.email.trim().toLowerCase(),
    );

    return db.update(
      'users',
      normalizedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
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

    return db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
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

    return db.delete(
      'users',
      where:
          'LOWER(TRIM(email)) != ? AND id != ?',
      whereArgs: [
        normalizedEmail,
        leaderAdminId,
      ],
    );
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

    return db.update(
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
  // ============================================================

  Future<bool> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await _databaseHelper.database;

    // Verify the current password first.
    final result = await db.query(
      'users',
      columns: ['id'],
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

    // Update the password.
    final updated = await db.update(
      'users',
      {
        'password': newPassword,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

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

