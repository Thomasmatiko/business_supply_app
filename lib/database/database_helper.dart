
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  // ============================================================
  // DATABASE INSTANCE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e, stackTrace) {
      debugPrint(
        '========== DATABASE OPEN ERROR ==========',
      );
      debugPrint(e.toString());

      debugPrint(
        '========== STACK TRACE ==========',
      );
      debugPrint(stackTrace.toString());

      debugPrint(
        '=========================================',
      );

      rethrow;
    }
  }

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'business_supply_v3.db',
    );

    debugPrint(
      'Database path: $path',
    );

    return openDatabase(
      path,
      version: 20,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onOpen: (db) async {
        debugPrint(
          'Database opened successfully.',
        );

        await _ensureImagePathColumn(db);
        await _ensurePaymentColumns(db);
        await _ensureUserProfileImageColumn(db);
      },
    );
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    // ==========================================================
    // PRODUCTS
    // ==========================================================

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        selling_price REAL NOT NULL,
        cost_price REAL NOT NULL,
        stock INTEGER NOT NULL,
        description TEXT,
        seller_id TEXT,
        image_path TEXT
      )
    ''');

    // ==========================================================
    // USERS
    // ==========================================================

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        admin_level TEXT NOT NULL DEFAULT 'none',
        profile_image TEXT
      )
    ''');

    // ==========================================================
    // ORDERS
    // ==========================================================

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        payment_id TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        buyer_id TEXT NOT NULL,
        seller_id TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // CART ITEMS
    // ==========================================================

    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        buyer_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        seller_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        image_path TEXT
      )
    ''');

    // ==========================================================
    // PAYMENTS
    // ==========================================================

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        buyer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        transaction_reference TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        paid_at TEXT
      )
    ''');


    // ==========================================================
    // NOTIFICATIONS
    // ==========================================================

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'general',
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // USER SETTINGS
    // ==========================================================

    await db.execute('''
      CREATE TABLE user_settings (
        user_id TEXT PRIMARY KEY,
        notifications_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');


        // ==========================================================
    // ACTIVITY LOGS
    // ==========================================================

    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT,
        action TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'general',
        created_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // AUDIT LOGS
    // ==========================================================

    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT,
        action TEXT NOT NULL,
        entity_type TEXT,
        entity_id TEXT,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    // ==========================================================
    // INITIAL PRODUCTS
    // ==========================================================

    await _insertMissingInitialProducts(db);

    // ==========================================================
    // LEADER ADMIN
    // ==========================================================

    await _insertLeaderAdmin(db);
  }

  // ============================================================
  // DATABASE UPGRADES
  // ============================================================

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint(
      'Database upgrade: $oldVersion -> $newVersion',
    );

    // ==========================================================
    // VERSION 2
    // ==========================================================

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE products_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          selling_price REAL NOT NULL,
          cost_price REAL NOT NULL,
          stock INTEGER NOT NULL,
          description TEXT
        )
      ''');

      await db.execute('''
        INSERT INTO products_new (
          id,
          name,
          category,
          selling_price,
          cost_price,
          stock,
          description
        )
        SELECT
          id,
          name,
          category,
          selling_price,
          cost_price,
          stock,
          description
        FROM products
      ''');

      await db.execute(
        'DROP TABLE products',
      );

      await db.execute('''
        ALTER TABLE products_new
        RENAME TO products
      ''');

      debugPrint(
        'Version 2 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 3
    // ==========================================================

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE customers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT NOT NULL,
          address TEXT NOT NULL,
          business_name TEXT NOT NULL
        )
      ''');

      debugPrint(
        'Version 3 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 4
    // ==========================================================

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          phone TEXT NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL
        )
      ''');

      debugPrint(
        'Version 4 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 5
    // ==========================================================

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE orders (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          total_amount REAL NOT NULL,
          status TEXT NOT NULL,
          created_by TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      debugPrint(
        'Version 5 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 6
    // ==========================================================

    if (oldVersion < 6) {
      await db.execute('''
        ALTER TABLE products
        ADD COLUMN seller_id TEXT
      ''');

      await db.execute('''
        ALTER TABLE orders
        ADD COLUMN buyer_id TEXT
      ''');

      await db.execute('''
        ALTER TABLE orders
        ADD COLUMN seller_id TEXT
      ''');

      debugPrint(
        'Version 6 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 7
    // ==========================================================

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE users
        ADD COLUMN admin_level TEXT NOT NULL DEFAULT 'none'
      ''');

      debugPrint(
        'Version 7 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 8
    // ==========================================================

    if (oldVersion < 8) {
      await _insertLeaderAdmin(db);

      debugPrint(
        'Version 8 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 9
    // ==========================================================

    if (oldVersion < 9) {
      await db.update(
        'products',
        {
          'seller_id': 'ADMIN001',
        },
        where: 'seller_id IS NULL',
      );

      debugPrint(
        'Existing products assigned to Leader Admin.',
      );

      debugPrint(
        'Version 9 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 10
    // ==========================================================

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE orders_new (
          id TEXT PRIMARY KEY,
          product_id TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          total_amount REAL NOT NULL,
          status TEXT NOT NULL,
          created_by TEXT NOT NULL,
          created_at TEXT NOT NULL,
          buyer_id TEXT NOT NULL,
          seller_id TEXT NOT NULL
        )
      ''');

      await db.execute('''
        INSERT INTO orders_new (
          id,
          product_id,
          quantity,
          unit_price,
          total_amount,
          status,
          created_by,
          created_at,
          buyer_id,
          seller_id
        )
        SELECT
          id,
          product_id,
          quantity,
          unit_price,
          total_amount,
          status,
          created_by,
          created_at,
          COALESCE(
            NULLIF(buyer_id, ''),
            created_by
          ),
          COALESCE(
            seller_id,
            ''
          )
        FROM orders
      ''');

      await db.execute(
        'DROP TABLE orders',
      );

      await db.execute('''
        ALTER TABLE orders_new
        RENAME TO orders
      ''');

      await db.execute(
        'DROP TABLE IF EXISTS customers',
      );

      await db.execute('''
        UPDATE orders
        SET seller_id = (
          SELECT products.seller_id
          FROM products
          WHERE products.id = orders.product_id
        )
        WHERE seller_id IS NULL
           OR seller_id = ''
      ''');

      debugPrint(
        'Customer system removed from database.',
      );

      debugPrint(
        'Version 10 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 11
    // ==========================================================

    if (oldVersion < 11) {
      await _insertMissingInitialProducts(db);
      await _insertLeaderAdmin(db);

      await db.update(
        'products',
        {
          'seller_id': 'ADMIN001',
        },
        where: '''
          seller_id IS NULL
          OR seller_id = ''
        ''',
      );

      debugPrint(
        'Version 11 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 12
    // ==========================================================

    if (oldVersion < 12) {
      await _ensureImagePathColumn(db);

      debugPrint(
        'Version 12 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 13
    // ==========================================================

    if (oldVersion < 13) {
      await _ensureImagePathColumn(db);

      debugPrint(
        'Version 13 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 14
    // ==========================================================

    if (oldVersion < 14) {
      final cartExists = await _tableExists(
        db,
        'cart_items',
      );

      if (!cartExists) {
        await db.execute('''
          CREATE TABLE cart_items (
            id TEXT PRIMARY KEY,
            buyer_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            seller_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            unit_price REAL NOT NULL,
            quantity INTEGER NOT NULL,
            image_path TEXT
          )
        ''');
      }

      debugPrint(
        'Version 14 migration completed.',
      );
    }

    // ==========================================================
    // VERSION 15
    // PAYMENT SYSTEM
    // ==========================================================

    if (oldVersion < 15) {
      await _ensureOrderPaymentColumns(db);

      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          buyer_id TEXT NOT NULL,
          amount REAL NOT NULL,
          method TEXT NOT NULL,
          status TEXT NOT NULL,
          transaction_reference TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      debugPrint(
        'Version 15 payment migration completed.',
      );
    }

    // ==========================================================
    // VERSION 16
    // PAYMENT MANAGEMENT
    // ==========================================================

    if (oldVersion < 16) {
      await _migratePaymentsToVersion16(db);

      debugPrint(
        'Version 16 payment management migration completed.',
      );
    }

    // ==========================================================
    // VERSION 17
    // USER PROFILE IMAGE PATH
    // ==========================================================

    if (oldVersion < 17) {
      await _ensureUserProfileImagePathColumn(db);

      debugPrint(
        'Version 17 profile image path migration completed.',
      );
    }

    // ==========================================================
    // VERSION 18
    // STANDARDIZE PROFILE IMAGE COLUMN
    // ==========================================================

    if (oldVersion < 18) {
      await _migrateProfileImageToStandardColumn(db);

      debugPrint(
        'Version 18 profile image migration completed.',
      );
    }

        // ==========================================================
    // VERSION 19
    // NOTIFICATION SYSTEM
    // ==========================================================

    if (oldVersion < 19) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'general',
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          user_id TEXT PRIMARY KEY,
          notifications_enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      debugPrint(
        'Version 19 notification migration completed.',
      );
    }

        // ==========================================================
    // VERSION 20
    // ACTIVITY & AUDIT LOG SYSTEM
    // ==========================================================

    if (oldVersion < 20) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          user_name TEXT,
          action TEXT NOT NULL,
          description TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'general',
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          user_name TEXT,
          action TEXT NOT NULL,
          entity_type TEXT,
          entity_id TEXT,
          description TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      debugPrint(
        'Version 20 activity and audit log migration completed.',
      );
    }
  }

  // ============================================================
  // ENSURE ORDER PAYMENT COLUMNS
  // ============================================================

  Future<void> _ensureOrderPaymentColumns(
    Database db,
  ) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(orders)',
    );

    final names = columns
        .map(
          (column) => column['name']?.toString(),
        )
        .whereType<String>()
        .toSet();

    if (!names.contains('payment_status')) {
      await db.execute('''
        ALTER TABLE orders
        ADD COLUMN payment_status TEXT NOT NULL
        DEFAULT 'pending'
      ''');
    }

    if (!names.contains('payment_id')) {
      await db.execute('''
        ALTER TABLE orders
        ADD COLUMN payment_id TEXT
      ''');
    }
  }

  // ============================================================
  // VERSION 16 PAYMENT MIGRATION
  // ============================================================

  Future<void> _migratePaymentsToVersion16(
    Database db,
  ) async {
    final exists = await _tableExists(
      db,
      'payments',
    );

    if (!exists) {
      await db.execute('''
        CREATE TABLE payments (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          buyer_id TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL,
          status TEXT NOT NULL,
          transaction_reference TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          paid_at TEXT
        )
      ''');

      return;
    }

    final columns = await db.rawQuery(
      'PRAGMA table_info(payments)',
    );

    final names = columns
        .map(
          (column) => column['name']?.toString(),
        )
        .whereType<String>()
        .toSet();

    final hasPaymentMethod =
        names.contains('payment_method');

    final hasMethod =
        names.contains('method');

    if (!hasPaymentMethod && hasMethod) {
      await db.execute('''
        ALTER TABLE payments
        RENAME TO payments_old
      ''');

      await db.execute('''
        CREATE TABLE payments (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          buyer_id TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL,
          status TEXT NOT NULL,
          transaction_reference TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          paid_at TEXT
        )
      ''');

      await db.execute('''
        INSERT INTO payments (
          id,
          order_id,
          buyer_id,
          amount,
          payment_method,
          status,
          transaction_reference,
          created_at,
          updated_at,
          paid_at
        )
        SELECT
          id,
          order_id,
          buyer_id,
          amount,
          method,
          status,
          transaction_reference,
          created_at,
          updated_at,
          CASE
            WHEN LOWER(TRIM(status)) = 'completed'
            THEN updated_at
            ELSE NULL
          END
        FROM payments_old
      ''');

      await db.execute(
        'DROP TABLE payments_old',
      );

      return;
    }

    if (!hasPaymentMethod && !hasMethod) {
      await db.execute('''
        ALTER TABLE payments
        ADD COLUMN payment_method TEXT NOT NULL
        DEFAULT 'cash'
      ''');
    }

    if (!names.contains('paid_at')) {
      await db.execute('''
        ALTER TABLE payments
        ADD COLUMN paid_at TEXT
      ''');
    }
  }

  // ============================================================
  // ENSURE PAYMENT COLUMNS
  // ============================================================

  Future<void> _ensurePaymentColumns(
    Database db,
  ) async {
    if (!await _tableExists(db, 'payments')) {
      return;
    }

    final columns = await db.rawQuery(
      'PRAGMA table_info(payments)',
    );

    final names = columns
        .map(
          (column) => column['name']?.toString(),
        )
        .whereType<String>()
        .toSet();

    if (!names.contains('payment_method')) {
      if (names.contains('method')) {
        await db.execute('''
          ALTER TABLE payments
          ADD COLUMN payment_method TEXT
        ''');

        await db.execute('''
          UPDATE payments
          SET payment_method = method
          WHERE payment_method IS NULL
        ''');
      } else {
        await db.execute('''
          ALTER TABLE payments
          ADD COLUMN payment_method TEXT NOT NULL
          DEFAULT 'cash'
        ''');
      }
    }

    if (!names.contains('paid_at')) {
      await db.execute('''
        ALTER TABLE payments
        ADD COLUMN paid_at TEXT
      ''');
    }
  }

  // ============================================================
  // TABLE EXISTS
  // ============================================================

  Future<bool> _tableExists(
    Database db,
    String table,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name = ?
      LIMIT 1
      ''',
      [table],
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // ENSURE PRODUCT IMAGE PATH COLUMN
  // ============================================================

  Future<void> _ensureImagePathColumn(
    Database db,
  ) async {
    try {
      if (!await _tableExists(db, 'products')) {
        return;
      }

      final columns = await db.rawQuery(
        'PRAGMA table_info(products)',
      );

      bool imagePathExists = false;

      for (final column in columns) {
        final name = column['name']?.toString();

        if (name == 'image_path') {
          imagePathExists = true;
          break;
        }
      }

      if (!imagePathExists) {
        await db.execute('''
          ALTER TABLE products
          ADD COLUMN image_path TEXT
        ''');

        debugPrint(
          'image_path column added successfully.',
        );
      }
    } catch (e) {
      debugPrint(
        'Error ensuring image_path column: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // VERSION 17
  // ENSURE OLD PROFILE IMAGE PATH COLUMN
  // ============================================================

  Future<void> _ensureUserProfileImagePathColumn(
    Database db,
  ) async {
    try {
      if (!await _tableExists(db, 'users')) {
        return;
      }

      final columns = await db.rawQuery(
        'PRAGMA table_info(users)',
      );

      final names = columns
          .map(
            (column) => column['name']?.toString(),
          )
          .whereType<String>()
          .toSet();

      if (!names.contains('profile_image_path')) {
        await db.execute('''
          ALTER TABLE users
          ADD COLUMN profile_image_path TEXT
        ''');

        debugPrint(
          'profile_image_path column added successfully.',
        );
      }
    } catch (e) {
      debugPrint(
        'Error ensuring profile_image_path column: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // VERSION 18
  // STANDARDIZE TO profile_image
  // ============================================================

  Future<void> _migrateProfileImageToStandardColumn(
    Database db,
  ) async {
    try {
      if (!await _tableExists(db, 'users')) {
        return;
      }

      final columns = await db.rawQuery(
        'PRAGMA table_info(users)',
      );

      final names = columns
          .map(
            (column) => column['name']?.toString(),
          )
          .whereType<String>()
          .toSet();

      // ----------------------------------------------------------
      // Add the correct column if it does not exist.
      // ----------------------------------------------------------

      if (!names.contains('profile_image')) {
        await db.execute('''
          ALTER TABLE users
          ADD COLUMN profile_image TEXT
        ''');

        debugPrint(
          'profile_image column added successfully.',
        );
      }

      // ----------------------------------------------------------
      // Copy old profile_image_path values if that column exists.
      // ----------------------------------------------------------

      if (names.contains('profile_image_path')) {
        await db.execute('''
          UPDATE users
          SET profile_image = profile_image_path
          WHERE (
            profile_image IS NULL
            OR TRIM(profile_image) = ''
          )
          AND profile_image_path IS NOT NULL
          AND TRIM(profile_image_path) != ''
        ''');

        debugPrint(
          'Existing profile images migrated successfully.',
        );
      }
    } catch (e) {
      debugPrint(
        'Error migrating profile image: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // ENSURE CURRENT PROFILE IMAGE COLUMN
  // ============================================================

  Future<void> _ensureUserProfileImageColumn(
    Database db,
  ) async {
    try {
      if (!await _tableExists(db, 'users')) {
        return;
      }

      final columns = await db.rawQuery(
        'PRAGMA table_info(users)',
      );

      final names = columns
          .map(
            (column) => column['name']?.toString(),
          )
          .whereType<String>()
          .toSet();

      if (!names.contains('profile_image')) {
        await db.execute('''
          ALTER TABLE users
          ADD COLUMN profile_image TEXT
        ''');

        debugPrint(
          'profile_image column added successfully.',
        );
      }

      // If an older installation has profile_image_path,
      // preserve the existing image path.
      if (names.contains('profile_image_path')) {
        await db.execute('''
          UPDATE users
          SET profile_image = profile_image_path
          WHERE (
            profile_image IS NULL
            OR TRIM(profile_image) = ''
          )
          AND profile_image_path IS NOT NULL
          AND TRIM(profile_image_path) != ''
        ''');
      }
    } catch (e) {
      debugPrint(
        'Error ensuring profile_image column: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // INSERT LEADER ADMIN
  // ============================================================

  Future<void> _insertLeaderAdmin(
    Database db,
  ) async {
    const leaderAdminId = 'ADMIN001';

    const leaderAdminEmail =
        'thomasmatiko021@gmail.com';

    final existingById = await db.query(
      'users',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [leaderAdminId],
      limit: 1,
    );

    if (existingById.isNotEmpty) {
      await db.update(
        'users',
        {
          'role': 'admin',
          'admin_level': 'leader',
        },
        where: 'id = ?',
        whereArgs: [leaderAdminId],
      );

      return;
    }

    final existingByEmail = await db.query(
      'users',
      columns: ['id'],
      where: 'LOWER(email) = ?',
      whereArgs: [
        leaderAdminEmail.toLowerCase(),
      ],
      limit: 1,
    );

    if (existingByEmail.isNotEmpty) {
      return;
    }

    await db.insert(
      'users',
      {
        'id': leaderAdminId,
        'name': 'Thomas Matiko',
        'email': leaderAdminEmail,
        'phone': '0626615007',
        'password': 'Thomas@2023',
        'role': 'admin',
        'admin_level': 'leader',
        'profile_image': null,
      },
    );
  }

  // ============================================================
  // INITIAL PRODUCTS
  // ============================================================

  Future<void> _insertMissingInitialProducts(
    Database db,
  ) async {
    final initialProducts = [
      Product(
        id: 'PRD001',
        name: 'Cooking Oil 5L',
        category: 'Food & Beverage',
        sellingPrice: 18500,
        costPrice: 16000,
        stock: 8,
        description:
            'Cooking oil for wholesale customers.',
      ),
      Product(
        id: 'PRD002',
        name: 'Sugar 25kg',
        category: 'Food & Beverage',
        sellingPrice: 72000,
        costPrice: 65000,
        stock: 5,
        description:
            '25kg bag of sugar.',
      ),
      Product(
        id: 'PRD003',
        name: 'Rice 25kg',
        category: 'Food & Beverage',
        sellingPrice: 65000,
        costPrice: 58000,
        stock: 35,
        description:
            '25kg bag of rice.',
      ),
      Product(
        id: 'PRD004',
        name: 'Washing Powder 2kg',
        category: 'Cleaning',
        sellingPrice: 12500,
        costPrice: 10000,
        stock: 22,
        description:
            'Washing powder 2kg pack.',
      ),
      Product(
        id: 'PRD005',
        name: 'Mineral Water 1.5L',
        category: 'Beverages',
        sellingPrice: 1200,
        costPrice: 900,
        stock: 60,
        description:
            'Mineral water 1.5 litre bottle.',
      ),
      Product(
        id: 'PRD006',
        name: 'Office Paper A4',
        category: 'Stationery',
        sellingPrice: 14500,
        costPrice: 12000,
        stock: 12,
        description:
            'A4 office printing paper.',
      ),
    ];

    for (final product in initialProducts) {
      final existing = await db.query(
        'products',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [product.id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        continue;
      }

      await db.insert(
        'products',
        {
          'id': product.id,
          'name': product.name,
          'category': product.category,
          'selling_price': product.sellingPrice,
          'cost_price': product.costPrice,
          'stock': product.stock,
          'description': product.description,
          'seller_id': 'ADMIN001',
          'image_path': null,
        },
      );
    }
  }

  // ============================================================
  // GENERIC DATABASE INSERT
  // ============================================================

  Future<int> insert(
    String table,
    Map<String, dynamic> values,
  ) async {
    final db = await database;

    return db.insert(
      table,
      values,
    );
  }

  // ============================================================
  // GENERIC DATABASE QUERY
  // ============================================================

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  // ============================================================
  // GENERIC DATABASE UPDATE
  // ============================================================

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;

    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // ============================================================
  // GENERIC DATABASE DELETE
  // ============================================================

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;

    return db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // ============================================================
  // RAW QUERY
  // ============================================================

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;

    return db.rawQuery(
      sql,
      arguments,
    );
  }

    // ============================================================
  // ACTIVITY LOG
  // ============================================================

  Future<int> insertActivityLog({
    String? userId,
    String? userName,
    required String action,
    required String description,
    String type = 'general',
  }) async {
    final db = await database;

    return db.insert(
      'activity_logs',
      {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'user_id': userId,
        'user_name': userName,
        'action': action,
        'description': description,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getActivityLogs({
    int? limit,
  }) async {
    final db = await database;

    return db.query(
      'activity_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }


    // ============================================================
  // AUDIT LOG
  // ============================================================

  Future<int> insertAuditLog({
    String? userId,
    String? userName,
    required String action,
    String? entityType,
    String? entityId,
    required String description,
  }) async {
    final db = await database;

    return db.insert(
      'audit_logs',
      {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'user_id': userId,
        'user_name': userName,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    int? limit,
  }) async {
    final db = await database;

    return db.query(
      'audit_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }
}

