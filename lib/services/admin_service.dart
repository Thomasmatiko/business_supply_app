import '../database/database_helper.dart';
import '../models/user.dart';

class AdminService {
  static final AdminService instance = AdminService._init();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  AdminService._init();

  // ============================================================
  // GET ALL ADMINS
  // ============================================================

  Future<List<AppUser>> getAdmins() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['admin'],
      orderBy: 'name ASC',
    );

    return result.map((map) => AppUser.fromMap(map)).toList();
  }

  // ============================================================
  // GET ADMIN BY ID
  // ============================================================

  Future<AppUser?> getAdminById(String id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'id = ? AND role = ?',
      whereArgs: [id, 'admin'],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  // ============================================================
  // CHECK LEADER ADMIN
  // ============================================================

  bool isLeaderAdmin(AppUser user) {
    return user.role == 'admin' &&
        user.adminLevel == 'leader';
  }

  // ============================================================
  // CHECK NORMAL ADMIN
  // ============================================================

  bool isNormalAdmin(AppUser user) {
    return user.role == 'admin' &&
        user.adminLevel == 'admin';
  }

  // ============================================================
  // CREATE ADMIN
  //
  // ONLY LEADER ADMIN SHOULD CALL THIS METHOD.
  // ============================================================

  Future<int> createAdmin({
    required AppUser currentUser,
    required AppUser newAdmin,
  }) async {
    if (!isLeaderAdmin(currentUser)) {
      throw Exception(
        'Only the Leader Admin can create administrators.',
      );
    }

    if (newAdmin.role != 'admin') {
      throw Exception(
        'New administrator must have admin role.',
      );
    }

    final db = await _databaseHelper.database;

    final existingUser = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [newAdmin.email.trim().toLowerCase()],
      limit: 1,
    );

    if (existingUser.isNotEmpty) {
      throw Exception(
        'An account with this email already exists.',
      );
    }

    final admin = newAdmin.copyWith(
      role: 'admin',
      adminLevel: 'admin',
    );

    return await db.insert(
      'users',
      admin.toMap(),
    );
  }

  // ============================================================
  // PROMOTE TO LEADER ADMIN
  // ============================================================

  Future<int> promoteToLeader({
    required AppUser currentUser,
    required String adminId,
  }) async {
    if (!isLeaderAdmin(currentUser)) {
      throw Exception(
        'Only the Leader Admin can change administrator privileges.',
      );
    }

    final admin = await getAdminById(adminId);

    if (admin == null) {
      throw Exception(
        'Administrator not found.',
      );
    }

    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'admin_level': 'leader',
      },
      where: 'id = ?',
      whereArgs: [adminId],
    );
  }

  // ============================================================
  // CHANGE LEADER TO NORMAL ADMIN
  // ============================================================

  Future<int> demoteToNormalAdmin({
    required AppUser currentUser,
    required String adminId,
  }) async {
    if (!isLeaderAdmin(currentUser)) {
      throw Exception(
        'Only the Leader Admin can change administrator privileges.',
      );
    }

    if (currentUser.id == adminId) {
      throw Exception(
        'The current Leader Admin cannot demote themselves.',
      );
    }

    final admin = await getAdminById(adminId);

    if (admin == null) {
      throw Exception(
        'Administrator not found.',
      );
    }

    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'admin_level': 'admin',
      },
      where: 'id = ?',
      whereArgs: [adminId],
    );
  }

  // ============================================================
  // DELETE ADMIN
  // ============================================================

  Future<int> deleteAdmin({
    required AppUser currentUser,
    required String adminId,
  }) async {
    if (!isLeaderAdmin(currentUser)) {
      throw Exception(
        'Only the Leader Admin can remove administrators.',
      );
    }

    if (currentUser.id == adminId) {
      throw Exception(
        'The Leader Admin cannot delete themselves.',
      );
    }

    final admin = await getAdminById(adminId);

    if (admin == null) {
      throw Exception(
        'Administrator not found.',
      );
    }

    final db = await _databaseHelper.database;

    return await db.delete(
      'users',
      where: 'id = ? AND role = ?',
      whereArgs: [adminId, 'admin'],
    );
  }

  // ============================================================
  // COUNT ADMINS
  // ============================================================

  Future<int> getAdminCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE role = ?
      ''',
      ['admin'],
    );

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  // ============================================================
  // COUNT LEADER ADMINS
  // ============================================================

  Future<int> getLeaderAdminCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE role = ?
      AND admin_level = ?
      ''',
      ['admin', 'leader'],
    );

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }
}