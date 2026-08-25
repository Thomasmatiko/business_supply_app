import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance =
      DatabaseHelper._();

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
      debugPrint('=========================================');
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

    debugPrint('Database path: $path');

    return openDatabase(
      path,
      version: 10,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onOpen: (db) {
        debugPrint(
          'Database opened successfully.',
        );
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
        seller_id TEXT
      )
    ''');

    // ==========================================================
    // USERS
    //
    // role:
    // buyer
    // seller
    // admin
    //
    // admin_level:
    // none
    // normal
    // leader
    // ==========================================================

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        admin_level TEXT NOT NULL DEFAULT 'none'
      )
    ''');

    // ==========================================================
    // ORDERS
    //
    // Customer relationship has been removed.
    //
    // buyer_id  = user who buys
    // seller_id = owner of the product
    // ==========================================================

    await db.execute('''
      CREATE TABLE orders (
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

    // ==========================================================
    // INITIAL PRODUCTS
    // ==========================================================

    await _insertInitialProducts(db);

    // ==========================================================
    // PERMANENT LEADER ADMIN
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
    // ==========================================================
    // VERSION 2
    // Standardize products table
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
    }

    // ==========================================================
    // VERSION 3
    // Customers
    //
    // Kept here only for upgrading very old databases.
    // The customer table is removed in VERSION 10.
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
    }

    // ==========================================================
    // VERSION 4
    // Users
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
    }

    // ==========================================================
    // VERSION 5
    // Orders
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
    }

    // ==========================================================
    // VERSION 6
    // Product seller + order buyer/seller
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
    }

    // ==========================================================
    // VERSION 7
    // Admin levels
    // ==========================================================

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE users
        ADD COLUMN admin_level TEXT NOT NULL DEFAULT 'none'
      ''');
    }

    // ==========================================================
    // VERSION 8
    // Permanent Leader Admin
    // ==========================================================

    if (oldVersion < 8) {
      await _insertLeaderAdmin(db);
    }

    // ==========================================================
    // VERSION 9
    // Assign existing products to Leader Admin
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
    }

    // ==========================================================
    // VERSION 10
    //
    // REMOVE CUSTOMER SYSTEM FROM DATABASE
    //
    // Old orders had:
    //
    // customer_id
    //
    // New orders no longer have customer_id.
    //
    // We rebuild the orders table because SQLite does not provide
    // a simple DROP COLUMN approach that is safe for all versions.
    //
    // Existing order information is preserved.
    // ==========================================================

    if (oldVersion < 10) {
      // --------------------------------------------------------
      // Create new orders table
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // Copy existing orders.
      //
      // Existing buyer_id/seller_id were introduced in version 6.
      //
      // If an old order does not have buyer_id or seller_id,
      // we use created_by for buyer_id and an empty string for
      // seller_id.
      //
      // Seller ownership can then be corrected from the product
      // when necessary.
      // --------------------------------------------------------

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
          COALESCE(NULLIF(buyer_id, ''), created_by),
          COALESCE(seller_id, '')
        FROM orders
      ''');

      // --------------------------------------------------------
      // Remove old orders table
      // --------------------------------------------------------

      await db.execute(
        'DROP TABLE orders',
      );

      // --------------------------------------------------------
      // Rename new table
      // --------------------------------------------------------

      await db.execute('''
        ALTER TABLE orders_new
        RENAME TO orders
      ''');

      // --------------------------------------------------------
      // Remove customers table
      // --------------------------------------------------------

      await db.execute(
        'DROP TABLE IF EXISTS customers',
      );

      // --------------------------------------------------------
      // Make sure existing orders know their seller.
      //
      // seller_id comes from the product.
      // --------------------------------------------------------

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
    }
  }

  // ============================================================
  // INSERT PERMANENT LEADER ADMIN
  // ============================================================

  Future<void> _insertLeaderAdmin(
    Database db,
  ) async {
    const leaderAdminId = 'ADMIN001';
    const leaderAdminEmail =
        'thomasmatiko021@gmail.com';

    final existingAdmin = await db.query(
      'users',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [leaderAdminId],
      limit: 1,
    );

    // ==========================================================
    // ADMIN ALREADY EXISTS
    // ==========================================================

    if (existingAdmin.isNotEmpty) {
      debugPrint(
        'Leader Admin already exists: '
        '$leaderAdminEmail',
      );
      return;
    }

    // ==========================================================
    // CREATE LEADER ADMIN
    // ==========================================================

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
      },
    );

    debugPrint(
      'Permanent Leader Admin created: '
      '$leaderAdminEmail',
    );
  }

  // ============================================================
  // INITIAL PRODUCTS
  // ============================================================

  Future<void> _insertInitialProducts(
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
        description: '25kg bag of sugar.',
      ),
      Product(
        id: 'PRD003',
        name: 'Rice 25kg',
        category: 'Food & Beverage',
        sellingPrice: 65000,
        costPrice: 58000,
        stock: 35,
        description: '25kg bag of rice.',
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
      await db.insert(
        'products',
        {
          'id': product.id,
          'name': product.name,
          'category': product.category,
          'selling_price':
              product.sellingPrice,
          'cost_price':
              product.costPrice,
          'stock': product.stock,
          'description':
              product.description,
          'seller_id': 'ADMIN001',
        },
      );
    }
  }
}