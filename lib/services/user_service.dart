import '../database/database_helper.dart';
import '../models/user.dart';

class UserService {
  static final UserService instance = UserService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  UserService._init();

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

  Future<AppUser?> getUserById(String id) async {
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

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
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

  Future<int> addUser(AppUser user) async {
    final db = await _databaseHelper.database;

    final normalizedUser = user.copyWith(
      email: user.email.trim().toLowerCase(),
    );

    return await db.insert(
      'users',
      normalizedUser.toMap(),
    );
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  Future<int> updateUser(AppUser user) async {
    final db = await _databaseHelper.database;

    final normalizedUser = user.copyWith(
      email: user.email.trim().toLowerCase(),
    );

    return await db.update(
      'users',
      normalizedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<int> deleteUser(String id) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // RESET USERS
  //
  // Deletes every user EXCEPT the specified Leader Admin.
  //
  // IMPORTANT:
  // This only deletes records from the users table.
  //
  // Products, customers and orders are NOT affected.
  // ============================================================

  Future<int> deleteAllUsersExceptLeader(
    String leaderEmail,
  ) async {
    final db = await _databaseHelper.database;

    final normalizedEmail =
        leaderEmail.trim().toLowerCase();

    return await db.delete(
      'users',
      where: 'LOWER(email) != ?',
      whereArgs: [normalizedEmail],
    );
  }

  // ============================================================
  // ENSURE LEADER ADMIN
  //
  // Makes sure the specified account is a Leader Admin.
  //
  // This does NOT create the account if it does not exist.
  // ============================================================

  Future<int> ensureLeaderAdmin(
    String email,
  ) async {
    final db = await _databaseHelper.database;

    final normalizedEmail =
        email.trim().toLowerCase();

    return await db.update(
      'users',
      {
        'role': 'admin',
        'admin_level': 'leader',
      },
      where: 'email = ?',
      whereArgs: [normalizedEmail],
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
      where: 'email = ? AND password = ?',
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
  // EMAIL EXISTS
  // ============================================================

  Future<bool> emailExists(String email) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
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
      where: 'role = ?',
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
      where: 'role = ?',
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
      where: 'role = ?',
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
      where: 'role = ? AND admin_level = ?',
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
      where: 'role = ? AND admin_level = ?',
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

  // ============================================================
  // PROMOTE USER TO NORMAL ADMIN
  // ============================================================

  Future<int> promoteToAdmin(String userId) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'role': 'admin',
        'admin_level': 'normal',
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // PROMOTE USER TO LEADER ADMIN
  // ============================================================

  Future<int> promoteToLeaderAdmin(
    String userId,
  ) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'role': 'admin',
        'admin_level': 'leader',
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // REMOVE ADMIN PRIVILEGES
  // ============================================================

  Future<int> removeAdminPrivileges(
    String userId,
  ) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'role': 'buyer',
        'admin_level': 'none',
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}