
import '../database/database_helper.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';

class ReportService {
  static final ReportService instance = ReportService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  ReportService._init();

  // ============================================================
  // ADMIN REPORT
  // ============================================================

  Future<Map<String, dynamic>> getAdminReport(
    AppUser currentUser,
  ) async {
    if (!currentUser.isAnyAdmin) {
      throw Exception(
        'Only administrators can view the admin report.',
      );
    }

    final db = await _databaseHelper.database;

    // ----------------------------------------------------------
    // TOTAL USERS
    // ----------------------------------------------------------

    final buyerResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE role = ?
      ''',
      ['buyer'],
    );

    final sellerResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE role = ?
      ''',
      ['seller'],
    );

    final adminResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE role = ?
      ''',
      ['admin'],
    );

    // ----------------------------------------------------------
    // TOTAL PRODUCTS
    // ----------------------------------------------------------

    final productResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM products
      ''',
    );

    // ----------------------------------------------------------
    // ORDER COUNTS
    // ----------------------------------------------------------

    final orderResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      ''',
    );

    final pendingResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      ['pending'],
    );

    final confirmedResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      ['confirmed'],
    );

    final processingResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      ['processing'],
    );

    final shippedResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      ['shipped'],
    );

    final deliveredResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      ['delivered'],
    );

    final cancelledResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      ['cancelled'],
    );

    // ----------------------------------------------------------
    // SALES
    //
    // Delivered orders are treated as completed sales.
    // Cancelled orders are excluded.
    // ----------------------------------------------------------

    final salesResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      ['delivered'],
    );

    // ----------------------------------------------------------
    // RETURN REPORT
    // ----------------------------------------------------------

    return {
      'buyers': _count(buyerResult),
      'sellers': _count(sellerResult),
      'admins': _count(adminResult),
      'products': _count(productResult),
      'orders': _count(orderResult),
      'pending': _count(pendingResult),
      'confirmed': _count(confirmedResult),
      'processing': _count(processingResult),
      'shipped': _count(shippedResult),
      'delivered': _count(deliveredResult),
      'cancelled': _count(cancelledResult),
      'totalSales': _amount(salesResult),
    };
  }

  // ============================================================
  // SELLER REPORT
  // ============================================================

  Future<Map<String, dynamic>> getSellerReport(
    AppUser currentUser,
  ) async {
    if (!currentUser.isSeller) {
      throw Exception(
        'Only sellers can view the seller report.',
      );
    }

    return await getSellerReportById(
      currentUser.id,
    );
  }

  // ============================================================
  // SELLER REPORT BY ID
  // ============================================================

  Future<Map<String, dynamic>> getSellerReportById(
    String sellerId,
  ) async {
    final normalizedSellerId =
        sellerId.trim();

    if (normalizedSellerId.isEmpty) {
      throw Exception(
        'Seller ID is required.',
      );
    }

    final db = await _databaseHelper.database;

    // ----------------------------------------------------------
    // PRODUCTS
    // ----------------------------------------------------------

    final productsResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM products
      WHERE seller_id = ?
      ''',
      [normalizedSellerId],
    );

    // ----------------------------------------------------------
    // TOTAL ORDERS
    // ----------------------------------------------------------

    final ordersResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE seller_id = ?
      ''',
      [normalizedSellerId],
    );

    // ----------------------------------------------------------
    // ORDER STATUS COUNTS
    // ----------------------------------------------------------

    final pendingResult = await _countOrdersBySellerAndStatus(
      normalizedSellerId,
      'pending',
    );

    final confirmedResult = await _countOrdersBySellerAndStatus(
      normalizedSellerId,
      'confirmed',
    );

    final processingResult = await _countOrdersBySellerAndStatus(
      normalizedSellerId,
      'processing',
    );

    final shippedResult = await _countOrdersBySellerAndStatus(
      normalizedSellerId,
      'shipped',
    );

    final deliveredResult = await _countOrdersBySellerAndStatus(
      normalizedSellerId,
      'delivered',
    );

    final cancelledResult = await _countOrdersBySellerAndStatus(
      normalizedSellerId,
      'cancelled',
    );

    // ----------------------------------------------------------
    // SALES
    // ----------------------------------------------------------

    final salesResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM orders
      WHERE seller_id = ?
      AND LOWER(status) = ?
      ''',
      [
        normalizedSellerId,
        'delivered',
      ],
    );

    // ----------------------------------------------------------
    // TOTAL UNITS SOLD
    // ----------------------------------------------------------

    final quantityResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity), 0) AS total
      FROM orders
      WHERE seller_id = ?
      AND LOWER(status) = ?
      ''',
      [
        normalizedSellerId,
        'delivered',
      ],
    );

    // ----------------------------------------------------------
    // RETURN REPORT
    // ----------------------------------------------------------

    return {
      'products': _count(productsResult),
      'orders': _count(ordersResult),
      'pending': pendingResult,
      'confirmed': confirmedResult,
      'processing': processingResult,
      'shipped': shippedResult,
      'delivered': deliveredResult,
      'cancelled': cancelledResult,
      'totalSales': _amount(salesResult),
      'unitsSold': _amount(quantityResult),
    };
  }

  // ============================================================
  // BUYER REPORT
  // ============================================================

  Future<Map<String, dynamic>> getBuyerReport(
    AppUser currentUser,
  ) async {
    if (!currentUser.isBuyer) {
      throw Exception(
        'Only buyers can view the buyer report.',
      );
    }

    return await getBuyerReportById(
      currentUser.id,
    );
  }

  // ============================================================
  // BUYER REPORT BY ID
  // ============================================================

  Future<Map<String, dynamic>> getBuyerReportById(
    String buyerId,
  ) async {
    final normalizedBuyerId =
        buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      throw Exception(
        'Buyer ID is required.',
      );
    }

    final db = await _databaseHelper.database;

    // ----------------------------------------------------------
    // TOTAL ORDERS
    // ----------------------------------------------------------

    final ordersResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE buyer_id = ?
      ''',
      [normalizedBuyerId],
    );

    // ----------------------------------------------------------
    // ORDER STATUS COUNTS
    // ----------------------------------------------------------

    final pendingResult = await _countOrdersByBuyerAndStatus(
      normalizedBuyerId,
      'pending',
    );

    final confirmedResult = await _countOrdersByBuyerAndStatus(
      normalizedBuyerId,
      'confirmed',
    );

    final processingResult = await _countOrdersByBuyerAndStatus(
      normalizedBuyerId,
      'processing',
    );

    final shippedResult = await _countOrdersByBuyerAndStatus(
      normalizedBuyerId,
      'shipped',
    );

    final deliveredResult = await _countOrdersByBuyerAndStatus(
      normalizedBuyerId,
      'delivered',
    );

    final cancelledResult = await _countOrdersByBuyerAndStatus(
      normalizedBuyerId,
      'cancelled',
    );

    // ----------------------------------------------------------
    // TOTAL SPENT
    //
    // Only delivered orders count as completed purchases.
    // ----------------------------------------------------------

    final spentResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM orders
      WHERE buyer_id = ?
      AND LOWER(status) = ?
      ''',
      [
        normalizedBuyerId,
        'delivered',
      ],
    );

    // ----------------------------------------------------------
    // TOTAL ITEMS PURCHASED
    // ----------------------------------------------------------

    final quantityResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity), 0) AS total
      FROM orders
      WHERE buyer_id = ?
      AND LOWER(status) = ?
      ''',
      [
        normalizedBuyerId,
        'delivered',
      ],
    );

    // ----------------------------------------------------------
    // RETURN REPORT
    // ----------------------------------------------------------

    return {
      'orders': _count(ordersResult),
      'pending': pendingResult,
      'confirmed': confirmedResult,
      'processing': processingResult,
      'shipped': shippedResult,
      'delivered': deliveredResult,
      'cancelled': cancelledResult,
      'totalSpent': _amount(spentResult),
      'itemsPurchased': _amount(quantityResult),
    };
  }

  // ============================================================
  // GET SELLER ORDERS FOR REPORT
  // ============================================================

  Future<List<Order>> getSellerReportOrders(
    AppUser currentUser,
  ) async {
    if (!currentUser.isSeller) {
      throw Exception(
        'Only sellers can view seller order reports.',
      );
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'seller_id = ?',
      whereArgs: [currentUser.id],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET BUYER ORDERS FOR REPORT
  // ============================================================

  Future<List<Order>> getBuyerReportOrders(
    AppUser currentUser,
  ) async {
    if (!currentUser.isBuyer) {
      throw Exception(
        'Only buyers can view buyer order reports.',
      );
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'buyer_id = ?',
      whereArgs: [currentUser.id],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ADMIN ORDERS FOR REPORT
  // ============================================================

  Future<List<Order>> getAdminReportOrders(
    AppUser currentUser,
  ) async {
    if (!currentUser.isAnyAdmin) {
      throw Exception(
        'Only administrators can view admin order reports.',
      );
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET SELLER PRODUCTS FOR REPORT
  // ============================================================

  Future<List<Product>> getSellerReportProducts(
    AppUser currentUser,
  ) async {
    if (!currentUser.isSeller) {
      throw Exception(
        'Only sellers can view seller product reports.',
      );
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      where: 'seller_id = ?',
      whereArgs: [currentUser.id],
      orderBy: 'name ASC',
    );

    return result
        .map((map) => Product.fromMap(map))
        .toList();
  }

  // ============================================================
  // PRIVATE: COUNT
  // ============================================================

  int _count(
    List<Map<String, Object?>> result,
  ) {
    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)
            ?.toInt() ??
        0;
  }

  // ============================================================
  // PRIVATE: AMOUNT
  // ============================================================

  double _amount(
    List<Map<String, Object?>> result,
  ) {
    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0.0;
  }

  // ============================================================
  // PRIVATE: SELLER STATUS COUNT
  // ============================================================

  Future<int> _countOrdersBySellerAndStatus(
    String sellerId,
    String status,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE seller_id = ?
      AND LOWER(status) = ?
      ''',
      [
        sellerId,
        status,
      ],
    );

    return _count(result);
  }

  // ============================================================
  // PRIVATE: BUYER STATUS COUNT
  // ============================================================

  Future<int> _countOrdersByBuyerAndStatus(
    String buyerId,
    String status,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE buyer_id = ?
      AND LOWER(status) = ?
      ''',
      [
        buyerId,
        status,
      ],
    );

    return _count(result);
  }
}
