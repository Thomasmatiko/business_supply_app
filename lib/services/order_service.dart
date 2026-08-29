import '../database/database_helper.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../models/cart_item.dart';

class OrderService {
  static final OrderService instance = OrderService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  OrderService._init();

  // ============================================================
  // VALID ORDER STATUSES
  // ============================================================

  static const Set<String> validStatuses = {
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  };

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
  // GET ALL ORDERS FOR ADMIN
  // ============================================================

  Future<List<Order>> getOrdersForAdmin(
    AppUser currentUser,
  ) async {
    if (!currentUser.isAnyAdmin) {
      throw Exception(
        'Only administrators can view all orders.',
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
  // GET ADMIN ORDERS BY STATUS
  // ============================================================

  Future<List<Order>> getAdminOrdersByStatus(
    AppUser currentUser,
    String status,
  ) async {
    if (!currentUser.isAnyAdmin) {
      throw Exception(
        'Only administrators can view orders.',
      );
    }

    final normalizedStatus =
        status.trim().toLowerCase();

    if (!validStatuses.contains(normalizedStatus)) {
      throw Exception(
        'Invalid order status.',
      );
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'LOWER(status) = ?',
      whereArgs: [normalizedStatus],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ADMIN ORDER BY ID
  // ============================================================

  Future<Order?> getOrderByIdForAdmin(
    AppUser currentUser,
    String orderId,
  ) async {
    if (!currentUser.isAnyAdmin) {
      throw Exception(
        'Only administrators can view order details.',
      );
    }

    final normalizedOrderId =
        orderId.trim();

    if (normalizedOrderId.isEmpty) {
      return null;
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [normalizedOrderId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Order.fromMap(
      result.first,
    );
  }

  // ============================================================
  // CREATE ORDERS FROM CART
  //
  // BUYER CHECKOUT
  //
  // Every cart item becomes a separate order.
  //
  // Stock is checked and reduced inside one transaction.
  //
  // If anything fails, the complete transaction is rolled back.
  // ============================================================

  Future<List<Order>> createOrderFromCart({
    required String buyerId,
    required List<CartItem> cartItems,
  }) async {
    final normalizedBuyerId =
        buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      return [];
    }

    if (cartItems.isEmpty) {
      return [];
    }

    final db = await _databaseHelper.database;

    return await db.transaction<List<Order>>(
      (txn) async {
        final createdOrders = <Order>[];

        // ------------------------------------------------------
        // PROCESS EACH CART ITEM
        // ------------------------------------------------------

        for (final cartItem in cartItems) {
          // ----------------------------------------------------
          // VALIDATE QUANTITY
          // ----------------------------------------------------

          if (cartItem.quantity <= 0) {
            throw Exception(
              'Invalid quantity for "${cartItem.productName}".',
            );
          }

          // ----------------------------------------------------
          // VERIFY CART OWNERSHIP
          // ----------------------------------------------------

          if (cartItem.buyerId != normalizedBuyerId) {
            throw Exception(
              'Invalid cart item ownership.',
            );
          }

          // ----------------------------------------------------
          // GET CURRENT PRODUCT
          // ----------------------------------------------------

          final productResult = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [cartItem.productId],
            limit: 1,
          );

          if (productResult.isEmpty) {
            throw Exception(
              'Product "${cartItem.productName}" no longer exists.',
            );
          }

          final product = productResult.first;

          // ----------------------------------------------------
          // GET CURRENT STOCK
          // ----------------------------------------------------

          final currentStock =
              (product['stock'] as num?)?.toInt() ?? 0;

          if (cartItem.quantity > currentStock) {
            throw Exception(
              'Not enough stock for '
              '"${cartItem.productName}". '
              'Available: $currentStock.',
            );
          }

          // ----------------------------------------------------
          // GET SELLER FROM PRODUCT
          // ----------------------------------------------------

          final sellerId =
              product['seller_id']?.toString() ?? '';

          if (sellerId.isEmpty) {
            throw Exception(
              'Product "${cartItem.productName}" has no seller.',
            );
          }

          // ----------------------------------------------------
          // GET CURRENT SELLING PRICE
          // ----------------------------------------------------

          final sellingPrice =
              (product['selling_price'] as num?)
                      ?.toDouble() ??
                  0.0;

          if (sellingPrice < 0) {
            throw Exception(
              'Invalid product price.',
            );
          }

          // ----------------------------------------------------
          // CREATE ORDER ID
          // ----------------------------------------------------

          final orderId =
              'ORD_${DateTime.now().microsecondsSinceEpoch}_${createdOrders.length}';

          // ----------------------------------------------------
          // CREATE ORDER
          // ----------------------------------------------------

          final order = Order(
            id: orderId,
            buyerId: normalizedBuyerId,
            sellerId: sellerId,
            productId: cartItem.productId,
            quantity: cartItem.quantity,
            unitPrice: sellingPrice,
            totalAmount:
                sellingPrice * cartItem.quantity,
            status: 'pending',
            createdBy: normalizedBuyerId,

            // IMPORTANT:
            // Order model requires createdAt.
            createdAt: DateTime.now(),
          );

          // ----------------------------------------------------
          // REDUCE STOCK
          // ----------------------------------------------------

          final updatedStockRows =
              await txn.update(
            'products',
            {
              'stock':
                  currentStock -
                      cartItem.quantity,
            },
            where: 'id = ?',
            whereArgs: [
              cartItem.productId,
            ],
          );

          if (updatedStockRows <= 0) {
            throw Exception(
              'Could not update stock for '
              '"${cartItem.productName}".',
            );
          }

          // ----------------------------------------------------
          // INSERT ORDER
          // ----------------------------------------------------

          final insertedRows =
              await txn.insert(
            'orders',
            order.toMap(),
          );

          if (insertedRows <= 0) {
            throw Exception(
              'Could not create order for '
              '"${cartItem.productName}".',
            );
          }

          createdOrders.add(order);
        }

        // ------------------------------------------------------
        // CLEAR BUYER CART
        // ------------------------------------------------------

        final deletedRows = await txn.delete(
          'cart_items',
          where: 'buyer_id = ?',
          whereArgs: [normalizedBuyerId],
        );

        if (deletedRows < cartItems.length) {
          throw Exception(
            'Could not completely clear the shopping cart.',
          );
        }

        return createdOrders;
      },
    );
  }

  // ============================================================
  // GET ORDER BY ID
  // ============================================================

  Future<Order?> getOrderById(
    String id,
  ) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [normalizedId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Order.fromMap(
      result.first,
    );
  }

  // ============================================================
  // GET ORDERS BY BUYER
  // ============================================================

  Future<List<Order>> getOrdersByBuyer(
    String buyerId,
  ) async {
    final normalizedBuyerId =
        buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      return [];
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'buyer_id = ?',
      whereArgs: [normalizedBuyerId],
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
    final normalizedSellerId =
        sellerId.trim();

    if (normalizedSellerId.isEmpty) {
      return [];
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'seller_id = ?',
      whereArgs: [normalizedSellerId],
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
    final normalizedUserId =
        userId.trim();

    if (normalizedUserId.isEmpty) {
      return [];
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'created_by = ?',
      whereArgs: [normalizedUserId],
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
    final normalizedStatus =
        status.trim().toLowerCase();

    if (!validStatuses.contains(normalizedStatus)) {
      return [];
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      where: 'LOWER(status) = ?',
      whereArgs: [normalizedStatus],
      orderBy: 'created_at DESC',
    );

    return result
        .map((map) => Order.fromMap(map))
        .toList();
  }

  // ============================================================
  // GET ADMIN ORDER COUNT BY STATUS
  // ============================================================

  Future<int> getAdminOrderCountByStatus(
    AppUser currentUser,
    String status,
  ) async {
    if (!currentUser.isAnyAdmin) {
      throw Exception(
        'Only administrators can view order statistics.',
      );
    }

    final normalizedStatus =
        status.trim().toLowerCase();

    if (!validStatuses.contains(normalizedStatus)) {
      return 0;
    }

    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM orders
      WHERE LOWER(status) = ?
      ''',
      [normalizedStatus],
    );

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)
            ?.toInt() ??
        0;
  }

  // ============================================================
  // ADD ORDER
  // ============================================================

  Future<int> addOrder(
    Order order,
  ) async {
    final db = await _databaseHelper.database;

    return await db.transaction<int>(
      (txn) async {
        // ------------------------------------------------------
        // VALIDATE QUANTITY
        // ------------------------------------------------------

        if (order.quantity <= 0) {
          return 0;
        }

        // ------------------------------------------------------
        // VALIDATE BUYER
        // ------------------------------------------------------

        if (order.buyerId.trim().isEmpty) {
          return 0;
        }

        // ------------------------------------------------------
        // GET PRODUCT
        // ------------------------------------------------------

        final productResult =
            await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [order.productId],
          limit: 1,
        );

        if (productResult.isEmpty) {
          return 0;
        }

        final product =
            productResult.first;

        // ------------------------------------------------------
        // CHECK STOCK
        // ------------------------------------------------------

        final currentStock =
            (product['stock'] as num?)
                    ?.toInt() ??
                0;

        if (order.quantity > currentStock) {
          return 0;
        }

        // ------------------------------------------------------
        // SELLER FROM PRODUCT
        // ------------------------------------------------------

        final sellerId =
            product['seller_id']
                    ?.toString() ??
                '';

        if (sellerId.isEmpty) {
          return 0;
        }

        // ------------------------------------------------------
        // CURRENT SELLING PRICE
        // ------------------------------------------------------

        final sellingPrice =
            (product['selling_price'] as num?)
                    ?.toDouble() ??
                0.0;

        if (sellingPrice < 0) {
          return 0;
        }

        final totalAmount =
            sellingPrice * order.quantity;

        // ------------------------------------------------------
        // CREATE SAFE ORDER
        // ------------------------------------------------------

        final orderToSave =
            order.copyWith(
          sellerId: sellerId,
          unitPrice: sellingPrice,
          totalAmount: totalAmount,
          status: 'pending',
          createdAt: order.createdAt,
        );

        // ------------------------------------------------------
        // REDUCE STOCK
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
          whereArgs: [
            order.productId,
          ],
        );

        if (updatedStockRows <= 0) {
          return 0;
        }

        // ------------------------------------------------------
        // INSERT ORDER
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
  // System-controlled fields cannot be changed.
  // ============================================================

  Future<int> updateOrder(
    Order updatedOrder,
  ) async {
    final db = await _databaseHelper.database;

    final existingResult =
        await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [updatedOrder.id],
      limit: 1,
    );

    if (existingResult.isEmpty) {
      return 0;
    }

    final existingOrder =
        Order.fromMap(
      existingResult.first,
    );

    final safeOrder =
        updatedOrder.copyWith(
      buyerId: existingOrder.buyerId,
      sellerId: existingOrder.sellerId,
      createdBy: existingOrder.createdBy,
      status: existingOrder.status,
      createdAt: existingOrder.createdAt,
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
  // BUYER:
  // pending -> cancelled
  // shipped -> delivered
  //
  // SELLER:
  // pending -> confirmed
  // confirmed -> processing
  // processing -> shipped
  //
  // ADMIN:
  // Not allowed through this method.
  // ============================================================

  Future<int> updateOrderStatus(
    String orderId,
    String newStatus,
    String userId,
  ) async {
    final normalizedOrderId =
        orderId.trim();

    final normalizedStatus =
        newStatus.trim().toLowerCase();

    final normalizedUserId =
        userId.trim();

    if (normalizedOrderId.isEmpty ||
        normalizedUserId.isEmpty) {
      return 0;
    }

    if (!validStatuses.contains(normalizedStatus)) {
      return 0;
    }

    final db = await _databaseHelper.database;

    return await db.transaction<int>(
      (txn) async {
        // ------------------------------------------------------
        // GET ORDER
        // ------------------------------------------------------

        final result =
            await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [normalizedOrderId],
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
        // FINAL STATES
        // ------------------------------------------------------

        if (currentStatus == 'delivered' ||
            currentStatus == 'cancelled') {
          return 0;
        }

        // ------------------------------------------------------
        // IDENTIFY USER
        // ------------------------------------------------------

        final isBuyer =
            order.buyerId ==
                normalizedUserId;

        final isSeller =
            order.sellerId ==
                normalizedUserId;

        if (!isBuyer && !isSeller) {
          return 0;
        }

        // ------------------------------------------------------
        // BUYER PERMISSIONS
        // ------------------------------------------------------

        if (isBuyer) {
          final buyerAllowed =
              (currentStatus == 'pending' &&
                  normalizedStatus ==
                      'cancelled') ||
              (currentStatus == 'shipped' &&
                  normalizedStatus ==
                      'delivered');

          if (!buyerAllowed) {
            return 0;
          }
        }

        // ------------------------------------------------------
        // SELLER PERMISSIONS
        // ------------------------------------------------------

        if (isSeller) {
          final sellerAllowed =
              (currentStatus == 'pending' &&
                  normalizedStatus ==
                      'confirmed') ||
              (currentStatus == 'confirmed' &&
                  normalizedStatus ==
                      'processing') ||
              (currentStatus == 'processing' &&
                  normalizedStatus ==
                      'shipped');

          if (!sellerAllowed) {
            return 0;
          }
        }

        // ------------------------------------------------------
        // CANCEL ORDER
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
              (productResult.first['stock']
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
        // UPDATE STATUS
        // ------------------------------------------------------

        return await txn.update(
          'orders',
          {
            'status':
                normalizedStatus,
          },
          where: 'id = ?',
          whereArgs: [
            normalizedOrderId,
          ],
        );
      },
    );
  }

  // ============================================================
  // CANCEL ORDER
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
  // ============================================================

  Future<bool> deleteOrderWithStock(
    String orderId,
  ) async {
    final normalizedOrderId =
        orderId.trim();

    if (normalizedOrderId.isEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        final orderResult =
            await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [
            normalizedOrderId,
          ],
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
                .trim()
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
          whereArgs: [
            normalizedOrderId,
          ],
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
    final normalizedOrderId =
        orderId.trim();

    if (normalizedOrderId.isEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        final orderResult =
            await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [
            normalizedOrderId,
          ],
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
                .trim()
                .toLowerCase() !=
            'cancelled') {
          return false;
        }

        final deletedRows =
            await txn.delete(
          'orders',
          where: 'id = ?',
          whereArgs: [
            normalizedOrderId,
          ],
        );

        return deletedRows > 0;
      },
    );
  }

  // ============================================================
  // UPDATE ORDER WITH STOCK
  //
  // Used when changing:
  // - product
  // - quantity
  //
  // Protected:
  // - buyer
  // - seller
  // - creator
  // - status
  // - createdAt
  // ============================================================

  Future<bool> updateOrderWithStock(
    Order updatedOrder,
  ) async {
    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        // ------------------------------------------------------
        // GET ORIGINAL ORDER
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
                .trim()
                .toLowerCase();

        // ------------------------------------------------------
        // COMPLETED ORDERS CANNOT BE EDITED
        // ------------------------------------------------------

        if (oldStatus == 'cancelled' ||
            oldStatus == 'delivered') {
          return false;
        }

        // ------------------------------------------------------
        // VALIDATE QUANTITY
        // ------------------------------------------------------

        if (updatedOrder.quantity <= 0) {
          return false;
        }

        // ------------------------------------------------------
        // GET NEW PRODUCT
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
        // SELLER FROM PRODUCT
        // ------------------------------------------------------

        final newSellerId =
            newProduct['seller_id']
                    ?.toString() ??
                '';

        if (newSellerId.isEmpty) {
          return false;
        }

        // ------------------------------------------------------
        // CURRENT PRICE
        // ------------------------------------------------------

        final newSellingPrice =
            (newProduct['selling_price']
                        as num?)
                    ?.toDouble() ??
                0.0;

        if (newSellingPrice < 0) {
          return false;
        }

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
              (oldProductResult.first['stock']
                          as num?)
                      ?.toInt() ??
                  0;

          final newProductStock =
              (newProduct['stock'] as num?)
                      ?.toInt() ??
                  0;

          // ----------------------------------------------------
          // CHECK NEW PRODUCT STOCK
          // ----------------------------------------------------

          if (updatedOrder.quantity >
              newProductStock) {
            return false;
          }

          // ----------------------------------------------------
          // RETURN OLD STOCK
          // ----------------------------------------------------

          final oldStockRows =
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

          if (oldStockRows <= 0) {
            return false;
          }

          // ----------------------------------------------------
          // RESERVE NEW STOCK
          // ----------------------------------------------------

          final newStockRows =
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

          if (newStockRows <= 0) {
            return false;
          }
        }

        // ------------------------------------------------------
        // SAME PRODUCT
        // ------------------------------------------------------

        else {
          final currentStock =
              (newProduct['stock'] as num?)
                      ?.toInt() ??
                  0;

          final quantityDifference =
              updatedOrder.quantity -
                  oldOrder.quantity;

          // ----------------------------------------------------
          // QUANTITY INCREASE
          // ----------------------------------------------------

          if (quantityDifference > 0) {
            if (quantityDifference >
                currentStock) {
              return false;
            }

            final rows =
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

            if (rows <= 0) {
              return false;
            }
          }

          // ----------------------------------------------------
          // QUANTITY DECREASE
          // ----------------------------------------------------

          else if (quantityDifference < 0) {
            final rows =
                await txn.update(
              'products',
              {
                'stock':
                    currentStock +
                        quantityDifference.abs(),
              },
              where: 'id = ?',
              whereArgs: [
                updatedOrder.productId,
              ],
            );

            if (rows <= 0) {
              return false;
            }
          }
        }

        // ------------------------------------------------------
        // CREATE SAFE UPDATED ORDER
        // ------------------------------------------------------

        final orderToSave =
            updatedOrder.copyWith(
          buyerId: oldOrder.buyerId,
          sellerId: newSellerId,
          createdBy: oldOrder.createdBy,
          status: oldOrder.status,
          unitPrice: newSellingPrice,
          totalAmount:
              newSellingPrice *
                  updatedOrder.quantity,
          createdAt: oldOrder.createdAt,
        );

        // ------------------------------------------------------
        // SAVE ORDER
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
    final normalizedProductId =
        productId.trim();

    if (normalizedProductId.isEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'orders',
      columns: ['id'],
      where: 'product_id = ?',
      whereArgs: [
        normalizedProductId,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}