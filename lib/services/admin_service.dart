import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user.dart';
import 'activity_log_service.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int buyers;
  final int sellers;
  final int admins;

  final int products;
  final int lowStockProducts;

  final int orders;
  final int pendingOrders;
  final int confirmedOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;

  final double totalSales;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.buyers,
    required this.sellers,
    required this.admins,
    required this.products,
    required this.lowStockProducts,
    required this.orders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalSales,
  });
}

class AdminService {
  static final AdminService instance = AdminService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  final ActivityLogService _activityLogService =
      ActivityLogService.instance;

  AdminService._init();

  // ============================================================
  // PERMANENT LEADER ADMIN
  // ============================================================

  static const String leaderAdminId = 'ADMIN001';

  static const String leaderAdminEmail =
      'thomasmatiko021@gmail.com';

  static const String leaderAdminName = 'Thomas Matiko';

  static const String leaderAdminPhone = '0626615007';

  static const String leaderAdminPassword = 'Thomas@2023';

  // ============================================================
  // ADMIN CHECKS
  // ============================================================

  bool isLeaderAdmin(AppUser user) {
    return user.id == leaderAdminId &&
        user.role.trim().toLowerCase() == 'admin' &&
        user.adminLevel.trim().toLowerCase() == 'leader';
  }

  bool isNormalAdmin(AppUser user) {
    return user.role.trim().toLowerCase() == 'admin' &&
        user.adminLevel.trim().toLowerCase() == 'normal';
  }

  bool isAnyAdmin(AppUser user) {
    return user.role.trim().toLowerCase() == 'admin';
  }

  // ============================================================
  // AUTHORIZATION
  // ============================================================

  void _requireAdmin(AppUser currentUser) {
    if (!isAnyAdmin(currentUser)) {
      throw Exception(
        'Administrator permission is required.',
      );
    }
  }

  void _requireLeaderAdmin(AppUser currentUser) {
    if (!isLeaderAdmin(currentUser)) {
      throw Exception(
        'Only the Leader Admin can perform this action.',
      );
    }
  }

  void _preventSelfAction({
    required AppUser currentUser,
    required String targetUserId,
    required String message,
  }) {
    if (currentUser.id == targetUserId) {
      throw Exception(message);
    }
  }

  void _preventLeaderAction(String targetUserId) {
    if (targetUserId == leaderAdminId) {
      throw Exception(
        'The permanent Leader Admin is protected.',
      );
    }
  }

  // ============================================================
  // ADMIN ACTION LOGGER
  // ============================================================

  Future<void> _logAdminAction({
    required AppUser currentUser,
    required String action,
    required String description,
    String? entityType,
    String? entityId,
  }) async {
    try {
      await _activityLogService.logAction(
        userId: currentUser.id,
        userName: currentUser.name,
        action: action,
        description: description,
        type: 'admin',
        entityType: entityType,
        entityId: entityId,
        audit: true,
      );
    } catch (e) {
      debugPrint(
        'Admin action logging error: $e',
      );
    }
  }

  // ============================================================
  // GET ALL USERS
  // ============================================================

  Future<List<AppUser>> getAllUsers() async {
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
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [cleanId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  // ============================================================
  // GET ADMIN BY ID
  // ============================================================

  Future<AppUser?> getAdminById(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where:
          'id = ? AND LOWER(TRIM(role)) = ?',
      whereArgs: [
        cleanId,
        'admin',
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  // ============================================================
  // GET ALL ADMINS
  // ============================================================

  Future<List<AppUser>> getAdmins() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'LOWER(TRIM(role)) = ?',
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

  // ============================================================
  // GET BUYERS
  // ============================================================

  Future<List<AppUser>> getBuyers() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'LOWER(TRIM(role)) = ?',
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
      where: 'LOWER(TRIM(role)) = ?',
      whereArgs: ['seller'],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => AppUser.fromMap(map))
        .toList();
  }

  // ============================================================
  // DASHBOARD STATISTICS
  // ============================================================

  Future<AdminDashboardStats> getDashboardStats() async {
    final db = await _databaseHelper.database;

    try {
      final totalUsersResult = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM users',
      );

      final buyersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM users
        WHERE LOWER(TRIM(role)) = ?
        ''',
        ['buyer'],
      );

      final sellersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM users
        WHERE LOWER(TRIM(role)) = ?
        ''',
        ['seller'],
      );

      final adminsResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM users
        WHERE LOWER(TRIM(role)) = ?
        ''',
        ['admin'],
      );

      final productsResult = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM products',
      );

      final lowStockResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM products
        WHERE stock <= ?
        ''',
        [10],
      );

      final ordersResult = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM orders',
      );

      final pendingOrdersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM orders
        WHERE LOWER(TRIM(status)) = ?
        ''',
        ['pending'],
      );

      final confirmedOrdersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM orders
        WHERE LOWER(TRIM(status)) = ?
        ''',
        ['confirmed'],
      );

      final processingOrdersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM orders
        WHERE LOWER(TRIM(status)) = ?
        ''',
        ['processing'],
      );

      final shippedOrdersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM orders
        WHERE LOWER(TRIM(status)) = ?
        ''',
        ['shipped'],
      );

      final deliveredOrdersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM orders
        WHERE LOWER(TRIM(status)) = ?
        ''',
        ['delivered'],
      );

      final cancelledOrdersResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM orders
        WHERE LOWER(TRIM(status)) = ?
        ''',
        ['cancelled'],
      );

      final salesResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(total_amount), 0) AS total
        FROM orders
        WHERE LOWER(TRIM(status)) != ?
        ''',
        ['cancelled'],
      );

      return AdminDashboardStats(
        totalUsers: _getCount(totalUsersResult),
        buyers: _getCount(buyersResult),
        sellers: _getCount(sellersResult),
        admins: _getCount(adminsResult),
        products: _getCount(productsResult),
        lowStockProducts: _getCount(lowStockResult),
        orders: _getCount(ordersResult),
        pendingOrders: _getCount(pendingOrdersResult),
        confirmedOrders: _getCount(confirmedOrdersResult),
        processingOrders: _getCount(processingOrdersResult),
        shippedOrders: _getCount(shippedOrdersResult),
        deliveredOrders: _getCount(deliveredOrdersResult),
        cancelledOrders: _getCount(cancelledOrdersResult),
        totalSales: _getTotal(salesResult),
      );
    } catch (e, stackTrace) {
      debugPrint(
        '==============================================',
      );
      debugPrint(
        'ADMIN DASHBOARD DATABASE ERROR',
      );
      debugPrint(
        '==============================================',
      );
      debugPrint(e.toString());
      debugPrint(
        '----------------------------------------------',
      );
      debugPrint(stackTrace.toString());
      debugPrint(
        '==============================================',
      );

      rethrow;
    }
  }

  // ============================================================
  // CREATE NORMAL ADMIN
  // ============================================================

  Future<int> createAdmin({
    required AppUser currentUser,
    required AppUser newAdmin,
  }) async {
    _requireLeaderAdmin(currentUser);

    if (newAdmin.id == leaderAdminId) {
      throw Exception(
        'The permanent Leader Admin cannot be recreated.',
      );
    }

    final name = newAdmin.name.trim();
    final email =
        newAdmin.email.trim().toLowerCase();
    final phone = newAdmin.phone.trim();
    final password = newAdmin.password;

    if (name.isEmpty) {
      throw Exception('Name is required.');
    }

    if (email.isEmpty) {
      throw Exception('Email is required.');
    }

    if (phone.isEmpty) {
      throw Exception(
        'Phone number is required.',
      );
    }

    if (password.isEmpty) {
      throw Exception('Password is required.');
    }

    final db = await _databaseHelper.database;

    final existingUser = await db.query(
      'users',
      columns: ['id'],
      where:
          'LOWER(TRIM(email)) = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (existingUser.isNotEmpty) {
      throw Exception(
        'An account with this email already exists.',
      );
    }

    final adminId =
        await _generateNextAdminId(db);

    final inserted = await db.insert(
      'users',
      {
        'id': adminId,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'admin',
        'admin_level': 'normal',
      },
    );

    if (inserted > 0) {
      await _logAdminAction(
        currentUser: currentUser,
        action: 'CREATE_ADMIN',
        entityType: 'user',
        entityId: adminId,
        description:
            'Leader Admin created Normal Admin '
            '$adminId ($name).',
      );
    }

    return inserted;
  }

  // ============================================================
  // GENERATE NEXT ADMIN ID
  // ============================================================

  Future<String> _generateNextAdminId(
    Database db,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT id
      FROM users
      WHERE id LIKE 'ADMIN%'
      ''',
    );

    int highestNumber = 1;

    for (final row in result) {
      final id =
          row['id']?.toString() ?? '';

      final match = RegExp(
        r'^ADMIN(\d+)$',
      ).firstMatch(id);

      if (match == null) {
        continue;
      }

      final number =
          int.tryParse(match.group(1)!) ?? 0;

      if (number > highestNumber) {
        highestNumber = number;
      }
    }

    final nextNumber =
        highestNumber + 1;

    return 'ADMIN${nextNumber.toString().padLeft(3, '0')}';
  }

  // ============================================================
  // PROMOTE USER TO NORMAL ADMIN
  // ============================================================

  Future<int> promoteUserToAdmin({
    required AppUser currentUser,
    required String userId,
  }) async {
    _requireLeaderAdmin(currentUser);

    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      throw Exception('User ID is required.');
    }

    _preventLeaderAction(cleanUserId);

    _preventSelfAction(
      currentUser: currentUser,
      targetUserId: cleanUserId,
      message: 'You cannot promote yourself.',
    );

    final user =
        await getUserById(cleanUserId);

    if (user == null) {
      throw Exception('User not found.');
    }

    if (user.isAnyAdmin) {
      throw Exception(
        'This user is already an administrator.',
      );
    }

    final db =
        await _databaseHelper.database;

    final updated = await db.update(
      'users',
      {
        'role': 'admin',
        'admin_level': 'normal',
      },
      where: 'id = ?',
      whereArgs: [cleanUserId],
    );

    if (updated > 0) {
      await _logAdminAction(
        currentUser: currentUser,
        action: 'PROMOTE_USER_TO_ADMIN',
        entityType: 'user',
        entityId: cleanUserId,
        description:
            'Leader Admin promoted user '
            '$cleanUserId (${user.name}) to Normal Admin.',
      );
    }

    return updated;
  }

  // ============================================================
  // EDIT NORMAL ADMIN
  // ============================================================

  Future<int> updateAdmin({
    required AppUser currentUser,
    required AppUser updatedAdmin,
  }) async {
    _requireLeaderAdmin(currentUser);

    _preventLeaderAction(
      updatedAdmin.id,
    );

    _preventSelfAction(
      currentUser: currentUser,
      targetUserId: updatedAdmin.id,
      message:
          'You cannot edit your own administrator account here.',
    );

    if (!updatedAdmin.isNormalAdmin) {
      throw Exception(
        'Only Normal Admin accounts can be edited here.',
      );
    }

    final name = updatedAdmin.name.trim();
    final email =
        updatedAdmin.email.trim().toLowerCase();
    final phone = updatedAdmin.phone.trim();

    if (name.isEmpty) {
      throw Exception('Name is required.');
    }

    if (email.isEmpty) {
      throw Exception('Email is required.');
    }

    if (phone.isEmpty) {
      throw Exception(
        'Phone number is required.',
      );
    }

    final existing =
        await getUserById(updatedAdmin.id);

    if (existing == null) {
      throw Exception(
        'Administrator not found.',
      );
    }

    if (!existing.isNormalAdmin) {
      throw Exception(
        'Only Normal Admin accounts can be edited here.',
      );
    }

    final db =
        await _databaseHelper.database;

    final duplicateEmail = await db.query(
      'users',
      columns: ['id'],
      where:
          'LOWER(TRIM(email)) = ? AND id != ?',
      whereArgs: [
        email,
        updatedAdmin.id,
      ],
      limit: 1,
    );

    if (duplicateEmail.isNotEmpty) {
      throw Exception(
        'An account with this email already exists.',
      );
    }

    final updated = await db.update(
      'users',
      {
        'name': name,
        'email': email,
        'phone': phone,
      },
      where: 'id = ?',
      whereArgs: [updatedAdmin.id],
    );

    if (updated > 0) {
      await _logAdminAction(
        currentUser: currentUser,
        action: 'UPDATE_ADMIN',
        entityType: 'user',
        entityId: updatedAdmin.id,
        description:
            'Leader Admin updated Normal Admin '
            '${updatedAdmin.id}. '
            'Name: $name, Email: $email, Phone: $phone.',
      );
    }

    return updated;
  }

  // ============================================================
  // REMOVE ADMIN PRIVILEGES
  // ============================================================

  Future<int> removeAdminPrivileges({
    required AppUser currentUser,
    required String adminId,
  }) async {
    _requireLeaderAdmin(currentUser);

    final cleanAdminId = adminId.trim();

    if (cleanAdminId.isEmpty) {
      throw Exception(
        'Admin ID is required.',
      );
    }

    _preventLeaderAction(cleanAdminId);

    _preventSelfAction(
      currentUser: currentUser,
      targetUserId: cleanAdminId,
      message:
          'You cannot remove your own administrator privileges.',
    );

    final admin =
        await getAdminById(cleanAdminId);

    if (admin == null) {
      throw Exception(
        'Administrator not found.',
      );
    }

    if (!isNormalAdmin(admin)) {
      throw Exception(
        'Only a Normal Admin can have administrator '
        'privileges removed.',
      );
    }

    final db =
        await _databaseHelper.database;

    final updated = await db.update(
      'users',
      {
        'role': 'buyer',
        'admin_level': 'none',
      },
      where: 'id = ?',
      whereArgs: [cleanAdminId],
    );

    if (updated > 0) {
      await _logAdminAction(
        currentUser: currentUser,
        action: 'REMOVE_ADMIN_PRIVILEGES',
        entityType: 'user',
        entityId: cleanAdminId,
        description:
            'Leader Admin removed administrator '
            'privileges from ${admin.name} '
            '($cleanAdminId). User role changed to buyer.',
      );
    }

    return updated;
  }

  // ============================================================
  // DELETE USER AS ADMIN
  // ============================================================

  Future<int> deleteUserAsAdmin({
    required AppUser currentUser,
    required String targetUserId,
  }) async {
    _requireAdmin(currentUser);

    final cleanTargetUserId =
        targetUserId.trim();

    if (cleanTargetUserId.isEmpty) {
      throw Exception(
        'Target user ID is required.',
      );
    }

    _preventLeaderAction(
      cleanTargetUserId,
    );

    _preventSelfAction(
      currentUser: currentUser,
      targetUserId: cleanTargetUserId,
      message:
          'You cannot delete your own account.',
    );

    final targetUser =
        await getUserById(cleanTargetUserId);

    if (targetUser == null) {
      throw Exception(
        'User not found.',
      );
    }

    if (targetUser.isLeaderAdmin) {
      throw Exception(
        'The Leader Admin cannot be deleted.',
      );
    }

    if (currentUser.isNormalAdmin &&
        targetUser.isAnyAdmin) {
      throw Exception(
        'Normal Admins cannot remove administrators.',
      );
    }

    final db =
        await _databaseHelper.database;

    final deleted = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [cleanTargetUserId],
    );

    if (deleted > 0) {
      await _logAdminAction(
        currentUser: currentUser,
        action: 'DELETE_USER',
        entityType: 'user',
        entityId: cleanTargetUserId,
        description:
            '${currentUser.name} deleted user '
            '${targetUser.name} '
            '($cleanTargetUserId). '
            'Deleted user role: ${targetUser.role}.',
      );
    }

    return deleted;
  }

  // ============================================================
  // DELETE ADMIN
  // ============================================================

  Future<int> deleteAdmin({
    required AppUser currentUser,
    required String adminId,
  }) async {
    _requireLeaderAdmin(currentUser);

    final cleanAdminId = adminId.trim();

    if (cleanAdminId.isEmpty) {
      throw Exception(
        'Admin ID is required.',
      );
    }

    _preventLeaderAction(cleanAdminId);

    _preventSelfAction(
      currentUser: currentUser,
      targetUserId: cleanAdminId,
      message:
          'You cannot delete your own account.',
    );

    final admin =
        await getAdminById(cleanAdminId);

    if (admin == null) {
      throw Exception(
        'Administrator not found.',
      );
    }

    if (!isNormalAdmin(admin)) {
      throw Exception(
        'Only a Normal Admin can be deleted here.',
      );
    }

    final db =
        await _databaseHelper.database;

    final deleted = await db.delete(
      'users',
      where:
          'id = ? AND LOWER(TRIM(role)) = ?',
      whereArgs: [
        cleanAdminId,
        'admin',
      ],
    );

    if (deleted > 0) {
      await _logAdminAction(
        currentUser: currentUser,
        action: 'DELETE_ADMIN',
        entityType: 'user',
        entityId: cleanAdminId,
        description:
            'Leader Admin deleted Normal Admin '
            '${admin.name} ($cleanAdminId).',
      );
    }

    return deleted;
  }

  // ============================================================
  // COUNT ADMINS
  // ============================================================

  Future<int> getAdminCount() async {
    final db =
        await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE LOWER(TRIM(role)) = ?
      ''',
      ['admin'],
    );

    return _getCount(result);
  }

  // ============================================================
  // COUNT LEADER ADMINS
  // ============================================================

  Future<int> getLeaderAdminCount() async {
    final db =
        await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE LOWER(TRIM(role)) = ?
      AND LOWER(TRIM(admin_level)) = ?
      ''',
      [
        'admin',
        'leader',
      ],
    );

    return _getCount(result);
  }

  // ============================================================
  // COUNT NORMAL ADMINS
  // ============================================================

  Future<int> getNormalAdminCount() async {
    final db =
        await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE LOWER(TRIM(role)) = ?
      AND LOWER(TRIM(admin_level)) = ?
      ''',
      [
        'admin',
        'normal',
      ],
    );

    return _getCount(result);
  }

  // ============================================================
  // USER COUNTS
  // ============================================================

  Future<Map<String, int>> getUserCounts() async {
    final db =
        await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(
          CASE
            WHEN LOWER(TRIM(role)) = 'buyer'
            THEN 1 ELSE 0
          END
        ) AS buyers,
        SUM(
          CASE
            WHEN LOWER(TRIM(role)) = 'seller'
            THEN 1 ELSE 0
          END
        ) AS sellers,
        SUM(
          CASE
            WHEN LOWER(TRIM(role)) = 'admin'
            THEN 1 ELSE 0
          END
        ) AS admins
      FROM users
      ''',
    );

    if (result.isEmpty) {
      return {
        'total': 0,
        'buyers': 0,
        'sellers': 0,
        'admins': 0,
      };
    }

    final row = result.first;

    return {
      'total':
          (row['total'] as num?)?.toInt() ?? 0,
      'buyers':
          (row['buyers'] as num?)?.toInt() ?? 0,
      'sellers':
          (row['sellers'] as num?)?.toInt() ?? 0,
      'admins':
          (row['admins'] as num?)?.toInt() ?? 0,
    };
  }

  // ============================================================
  // ENSURE PERMANENT LEADER ADMIN
  // ============================================================

  Future<void> ensureLeaderAdmin() async {
    final db =
        await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [leaderAdminId],
      limit: 1,
    );

    if (result.isEmpty) {
      await db.insert(
        'users',
        {
          'id': leaderAdminId,
          'name': leaderAdminName,
          'email': leaderAdminEmail,
          'phone': leaderAdminPhone,
          'password': leaderAdminPassword,
          'role': 'admin',
          'admin_level': 'leader',
        },
        conflictAlgorithm:
            ConflictAlgorithm.ignore,
      );

      return;
    }

    await db.update(
      'users',
      {
        'name': leaderAdminName,
        'email': leaderAdminEmail,
        'phone': leaderAdminPhone,
        'role': 'admin',
        'admin_level': 'leader',
      },
      where: 'id = ?',
      whereArgs: [leaderAdminId],
    );
  }

  // ============================================================
  // DELETE ALL USERS EXCEPT LEADER
  // ============================================================

  Future<int> deleteAllUsersExceptLeader(
  String leaderEmail,
) async {
  final db =
      await _databaseHelper.database;

  final normalizedEmail =
      leaderEmail.trim().toLowerCase();

  if (normalizedEmail.isEmpty) {
    throw Exception(
      'Leader email is required.',
    );
  }

  final deleted = await db.delete(
    'users',
    where:
        'LOWER(TRIM(email)) != ? AND id != ?',
    whereArgs: [
      normalizedEmail,
      leaderAdminId,
    ],
  );

  if (deleted > 0) {
    await _logAdminAction(
      currentUser: AppUser(
        id: leaderAdminId,
        name: leaderAdminName,
        email: leaderAdminEmail,
        phone: leaderAdminPhone,
        password: leaderAdminPassword,
        role: 'admin',
        adminLevel: 'leader',
      ),
      action: 'DELETE_ALL_USERS_EXCEPT_LEADER',
      entityType: 'users',
      entityId: leaderAdminId,
      description:
          'All users except the permanent Leader Admin '
          'were deleted. Deleted records: $deleted.',
    );
  }

  return deleted;

  }

  // ============================================================
  // COUNT HELPER
  // ============================================================

  int _getCount(
    List<Map<String, Object?>> result,
  ) {
    if (result.isEmpty) {
      return 0;
    }

    final value = result.first['count'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // TOTAL HELPER
  // ============================================================

  double _getTotal(
    List<Map<String, Object?>> result,
  ) {
    if (result.isEmpty) {
      return 0;
    }

    final value = result.first['total'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}