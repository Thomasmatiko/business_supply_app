import '../database/database_helper.dart';
import '../models/order.dart';

class OrderService {
  static final OrderService instance = OrderService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  OrderService._init();

  // ============================================================
  // GET ALL ORDERS
  // ============================================================

  Future<List<Order>> getOrders() async {
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
  // GET ORDER BY ID
  // ============================================================

  Future<Order?> getOrderById(
    String id,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Order.fromMap(result.first);
  }

  // ============================================================
  // GET ORDERS BY BUYER
  // ============================================================

  Future<List<Order>> getOrdersByBuyer(
    String buyerId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'buyer_id = ?',
      whereArgs: [buyerId],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ORDERS BY SELLER
  // ============================================================

  Future<List<Order>> getOrdersBySeller(
    String sellerId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'seller_id = ?',
      whereArgs: [sellerId],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ORDERS BY CUSTOMER
  //
  // Kept for compatibility with existing database records.
  // Customer is no longer required by the Create Order screen.
  // ============================================================

  Future<List<Order>> getOrdersByCustomer(
    String customerId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ORDERS CREATED BY USER
  // ============================================================

  Future<List<Order>> getOrdersByUser(
    String userId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'created_by = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ORDERS BY STATUS
  // ============================================================

  Future<List<Order>> getOrdersByStatus(
    String status,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // ADD ORDER
  //
  // IMPORTANT:
  //
  // seller_id comes from the product.
  // buyer_id comes from the logged-in user.
  //
  // The service does NOT trust sellerId supplied by the screen.
  //
  // New orders always start as:
  //
  // pending
  //
  // Stock is reserved immediately.
  // ============================================================

  Future<int> addOrder(
    Order order,
  ) async {
    final db = await _databaseHelper.database;

    return await db.transaction<int>(
      (txn) async {
        // ------------------------------------------------------
        // Validate quantity
        // ------------------------------------------------------

        if (order.quantity <= 0) {
          return 0;
        }

        // ------------------------------------------------------
        // Validate buyer
        // ------------------------------------------------------

        if (order.buyerId.trim().isEmpty) {
          return 0;
        }

        // ------------------------------------------------------
        // Get product
        // ------------------------------------------------------

        final productResult = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [order.productId],
          limit: 1,
        );

        if (productResult.isEmpty) {
          return 0;
        }

        final product = productResult.first;

        // ------------------------------------------------------
        // Check stock
        // ------------------------------------------------------

        final currentStock =
            (product['stock'] as num?)
                    ?.toInt() ??
                0;

        if (order.quantity > currentStock) {
          return 0;
        }

        // ------------------------------------------------------
        // Get seller from product
        // ------------------------------------------------------

        final sellerId =
            product['seller_id']
                    ?.toString() ??
                '';

        if (sellerId.isEmpty) {
          return 0;
        }

        // ------------------------------------------------------
        // Get current selling price
        // ------------------------------------------------------

        final sellingPrice =
            (product['selling_price'] as num?)
                    ?.toDouble() ??
                0.0;

        final totalAmount =
            sellingPrice * order.quantity;

        // ------------------------------------------------------
        // Create trusted order
        //
        // customerId is preserved only for database
        // compatibility. It is no longer required by the
        // marketplace order process.
        // ------------------------------------------------------

        final orderToSave =
            order.copyWith(
          sellerId: sellerId,
          unitPrice: sellingPrice,
          totalAmount: totalAmount,
          status: 'pending',
        );

        // ------------------------------------------------------
        // Reserve stock
        // ------------------------------------------------------

        final updatedStockRows =
            await txn.update(
          'products',
          {
            'stock':
                currentStock -
                    order.quantity,
          },
          where: 'id = ?',
          whereArgs: [order.productId],
        );

        if (updatedStockRows <= 0) {
          return 0;
        }

        // ------------------------------------------------------
        // Insert order
        // ------------------------------------------------------

        return await txn.insert(
          'orders',
          orderToSave.toMap(),
        );
      },
    );
  }

  // ============================================================
  // UPDATE ORDER
  //
  // IMPORTANT:
  //
  // This method does NOT allow the caller to change:
  //
  // - buyer
  // - seller
  // - creator
  // - status
  //
  // Those values are controlled by the system.
  //
  // For quantity/product changes use updateOrderWithStock().
  // ============================================================

  Future<int> updateOrder(
    Order updatedOrder,
  ) async {
    final db = await _databaseHelper.database;

    final existingResult = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [updatedOrder.id],
      limit: 1,
    );

    if (existingResult.isEmpty) {
      return 0;
    }

    final existingOrder =
        Order.fromMap(existingResult.first);

    final safeOrder =
        updatedOrder.copyWith(
      buyerId: existingOrder.buyerId,
      sellerId: existingOrder.sellerId,
      createdBy: existingOrder.createdBy,
      status: existingOrder.status,
    );

    return await db.update(
      'orders',
      safeOrder.toMap(),
      where: 'id = ?',
      whereArgs: [updatedOrder.id],
    );
  }

  // ============================================================
  // UPDATE ORDER STATUS
  //
  // ROLE-BASED SECURITY
  //
  // BUYER:
  //
  // pending -> cancelled
  // shipped -> delivered
  //
  // SELLER:
  //
  // pending -> confirmed
  // confirmed -> processing
  // processing -> shipped
  //
  // ADMIN:
  //
  // Cannot change order status through this method.
  //
  // userId is REQUIRED so we know who is requesting the change.
  // ============================================================

  Future<int> updateOrderStatus(
    String orderId,
    String newStatus,
    String userId,
  ) async {
    final db = await _databaseHelper.database;

    final normalizedStatus =
        newStatus.trim().toLowerCase();

    final normalizedUserId =
        userId.trim();

    // ----------------------------------------------------------
    // Validate user
    // ----------------------------------------------------------

    if (normalizedUserId.isEmpty) {
      return 0;
    }

    // ----------------------------------------------------------
    // Validate status
    // ----------------------------------------------------------

    const validStatuses = {
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    };

    if (!validStatuses.contains(
      normalizedStatus,
    )) {
      return 0;
    }

    return await db.transaction<int>(
      (txn) async {
        // ------------------------------------------------------
        // Get order
        // ------------------------------------------------------

        final result = await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
          limit: 1,
        );

        if (result.isEmpty) {
          return 0;
        }

        final order =
            Order.fromMap(result.first);

        final currentStatus =
            order.status
                .trim()
                .toLowerCase();

        // ------------------------------------------------------
        // Final states
        //
        // Nobody can change these.
        // ------------------------------------------------------

        if (currentStatus == 'delivered' ||
            currentStatus == 'cancelled') {
          return 0;
        }

        // ------------------------------------------------------
        // Identify requester
        // ------------------------------------------------------

        final isBuyer =
            order.buyerId ==
                normalizedUserId;

        final isSeller =
            order.sellerId ==
                normalizedUserId;

        // ------------------------------------------------------
        // User must be either the buyer or seller.
        //
        // Admins and unrelated users are rejected.
        // ------------------------------------------------------

        if (!isBuyer && !isSeller) {
          return 0;
        }

        // ------------------------------------------------------
        // BUYER PERMISSIONS
        //
        // pending -> cancelled
        // shipped -> delivered
        // ------------------------------------------------------

        if (isBuyer) {
          final buyerAllowed =
              (currentStatus ==
                          'pending' &&
                      normalizedStatus ==
                          'cancelled') ||
                  (currentStatus ==
                          'shipped' &&
                      normalizedStatus ==
                          'delivered');

          if (!buyerAllowed) {
            return 0;
          }
        }

        // ------------------------------------------------------
        // SELLER PERMISSIONS
        //
        // pending -> confirmed
        // confirmed -> processing
        // processing -> shipped
        // ------------------------------------------------------

        if (isSeller) {
          final sellerAllowed =
              (currentStatus ==
                          'pending' &&
                      normalizedStatus ==
                          'confirmed') ||
                  (currentStatus ==
                          'confirmed' &&
                      normalizedStatus ==
                          'processing') ||
                  (currentStatus ==
                          'processing' &&
                      normalizedStatus ==
                          'shipped');

          if (!sellerAllowed) {
            return 0;
          }
        }

        // ------------------------------------------------------
        // CANCEL ORDER
        //
        // Only buyer can cancel pending order.
        //
        // Restore reserved stock.
        // ------------------------------------------------------

        if (normalizedStatus ==
            'cancelled') {
          final productResult =
              await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [
              order.productId,
            ],
            limit: 1,
          );

          if (productResult.isEmpty) {
            return 0;
          }

          final currentStock =
              (productResult.first[
                              'stock']
                          as num?)
                      ?.toInt() ??
                  0;

          final updatedStockRows =
              await txn.update(
            'products',
            {
              'stock':
                  currentStock +
                      order.quantity,
            },
            where: 'id = ?',
            whereArgs: [
              order.productId,
            ],
          );

          if (updatedStockRows <= 0) {
            return 0;
          }
        }

        // ------------------------------------------------------
        // Update status
        // ------------------------------------------------------

        return await txn.update(
          'orders',
          {
            'status':
                normalizedStatus,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );
      },
    );
  }

  // ============================================================
  // CANCEL ORDER
  //
  // IMPORTANT:
  // userId is required.
  //
  // Only the buyer who owns the order can cancel it.
  // ============================================================

  Future<bool> cancelOrder(
    String orderId,
    String userId,
  ) async {
    final result =
        await updateOrderStatus(
      orderId,
      'cancelled',
      userId,
    );

    return result > 0;
  }

  // ============================================================
  // DELETE PENDING ORDER WITH STOCK
  //
  // Permanently removes a pending order.
  //
  // Stock is restored first.
  // ============================================================

  Future<bool> deleteOrderWithStock(
    String orderId,
  ) async {
    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        final orderResult =
            await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
          limit: 1,
        );

        if (orderResult.isEmpty) {
          return false;
        }

        final order =
            Order.fromMap(
          orderResult.first,
        );

        if (order.status
                .toLowerCase() !=
            'pending') {
          return false;
        }

        final productResult =
            await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [
            order.productId,
          ],
          limit: 1,
        );

        if (productResult.isEmpty) {
          return false;
        }

        final currentStock =
            (productResult.first['stock']
                        as num?)
                    ?.toInt() ??
                0;

        final restoredStock =
            currentStock +
                order.quantity;

        final stockRows =
            await txn.update(
          'products',
          {
            'stock':
                restoredStock,
          },
          where: 'id = ?',
          whereArgs: [
            order.productId,
          ],
        );

        if (stockRows <= 0) {
          return false;
        }

        final deletedRows =
            await txn.delete(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );

        return deletedRows > 0;
      },
    );
  }

  // ============================================================
  // DELETE CANCELLED ORDER
  //
  // Stock is NOT restored here because it was already restored
  // when the order was cancelled.
  // ============================================================

  Future<bool> deleteCancelledOrder(
    String orderId,
  ) async {
    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        final orderResult =
            await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
          limit: 1,
        );

        if (orderResult.isEmpty) {
          return false;
        }

        final order =
            Order.fromMap(
          orderResult.first,
        );

        if (order.status
                .toLowerCase() !=
            'cancelled') {
          return false;
        }

        final deletedRows =
            await txn.delete(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );

        return deletedRows > 0;
      },
    );
  }

  // ============================================================
  // UPDATE ORDER WITH STOCK
  //
  // Used when changing:
  //
  // - product
  // - quantity
  //
  // System-controlled fields remain protected:
  //
  // - buyer
  // - seller
  // - creator
  // - status
  // ============================================================

  Future<bool> updateOrderWithStock(
    Order updatedOrder,
  ) async {
    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        // ------------------------------------------------------
        // Get original order
        // ------------------------------------------------------

        final oldOrderResult =
            await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [
            updatedOrder.id,
          ],
          limit: 1,
        );

        if (oldOrderResult.isEmpty) {
          return false;
        }

        final oldOrder =
            Order.fromMap(
          oldOrderResult.first,
        );

        final oldStatus =
            oldOrder.status
                .toLowerCase();

        // ------------------------------------------------------
        // Cannot edit completed/cancelled order
        // ------------------------------------------------------

        if (oldStatus == 'cancelled' ||
            oldStatus == 'delivered') {
          return false;
        }

        // ------------------------------------------------------
        // Validate quantity
        // ------------------------------------------------------

        if (updatedOrder.quantity <= 0) {
          return false;
        }

        // ------------------------------------------------------
        // Get new product
        // ------------------------------------------------------

        final newProductResult =
            await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [
            updatedOrder.productId,
          ],
          limit: 1,
        );

        if (newProductResult.isEmpty) {
          return false;
        }

        final newProduct =
            newProductResult.first;

        // ------------------------------------------------------
        // Seller always comes from product
        // ------------------------------------------------------

        final newSellerId =
            newProduct['seller_id']
                    ?.toString() ??
                '';

        if (newSellerId.isEmpty) {
          return false;
        }

        // ------------------------------------------------------
        // Current product selling price
        // ------------------------------------------------------

        final newSellingPrice =
            (newProduct[
                        'selling_price']
                    as num?)
                ?.toDouble() ??
            0.0;

        // ------------------------------------------------------
        // PRODUCT CHANGED
        // ------------------------------------------------------

        if (oldOrder.productId !=
            updatedOrder.productId) {
          final oldProductResult =
              await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [
              oldOrder.productId,
            ],
            limit: 1,
          );

          if (oldProductResult.isEmpty) {
            return false;
          }

          final oldProductStock =
              (oldProductResult.first[
                              'stock']
                          as num?)
                      ?.toInt() ??
                  0;

          final newProductStock =
              (newProduct[
                              'stock']
                          as num?)
                      ?.toInt() ??
                  0;

          // New product must have enough stock.
          if (updatedOrder.quantity >
              newProductStock) {
            return false;
          }

          // Return old quantity.
          await txn.update(
            'products',
            {
              'stock':
                  oldProductStock +
                      oldOrder.quantity,
            },
            where: 'id = ?',
            whereArgs: [
              oldOrder.productId,
            ],
          );

          // Reserve new quantity.
          await txn.update(
            'products',
            {
              'stock':
                  newProductStock -
                      updatedOrder.quantity,
            },
            where: 'id = ?',
            whereArgs: [
              updatedOrder.productId,
            ],
          );
        }

        // ------------------------------------------------------
        // SAME PRODUCT
        // ------------------------------------------------------

        else {
          final currentStock =
              (newProduct['stock']
                          as num?)
                      ?.toInt() ??
                  0;

          final quantityDifference =
              updatedOrder.quantity -
                  oldOrder.quantity;

          // Increase quantity.
          if (quantityDifference > 0) {
            if (quantityDifference >
                currentStock) {
              return false;
            }

            await txn.update(
              'products',
              {
                'stock':
                    currentStock -
                        quantityDifference,
              },
              where: 'id = ?',
              whereArgs: [
                updatedOrder.productId,
              ],
            );
          }

          // Decrease quantity.
          else if (quantityDifference <
              0) {
            await txn.update(
              'products',
              {
                'stock':
                    currentStock +
                        quantityDifference
                            .abs(),
              },
              where: 'id = ?',
              whereArgs: [
                updatedOrder.productId,
              ],
            );
          }
        }

        // ------------------------------------------------------
        // CREATE SAFE UPDATED ORDER
        //
        // Buyer and creator remain original.
        // Seller comes from current product.
        // Status remains original.
        // Price comes from current product.
        // ------------------------------------------------------

        final orderToSave =
            updatedOrder.copyWith(
          buyerId: oldOrder.buyerId,
          sellerId: newSellerId,
          createdBy: oldOrder.createdBy,
          status: oldOrder.status,
          unitPrice:
              newSellingPrice,
          totalAmount:
              newSellingPrice *
                  updatedOrder.quantity,
        );

        // ------------------------------------------------------
        // Save
        // ------------------------------------------------------

        final updatedRows =
            await txn.update(
          'orders',
          orderToSave.toMap(),
          where: 'id = ?',
          whereArgs: [
            updatedOrder.id,
          ],
        );

        return updatedRows > 0;
      },
    );
  }

  // ============================================================
  // CHECK WHETHER PRODUCT HAS ORDERS
  // ============================================================

  Future<bool> hasOrdersForProduct(
    String productId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      columns: ['id'],
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}