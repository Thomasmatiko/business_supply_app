import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/cart_item.dart';

class CartService {
  static final CartService instance = CartService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  CartService._init();

  // ============================================================
  // ADD TO CART
  //
  // BUYER ONLY
  //
  // Important:
  // Adding to cart does NOT reduce product stock.
  // Stock is checked and reduced during checkout/order creation.
  // ============================================================

  Future<bool> addToCart({
    required String buyerId,
    required String productId,
    int quantity = 1,
  }) async {
    final normalizedBuyerId = buyerId.trim();
    final normalizedProductId = productId.trim();

    if (normalizedBuyerId.isEmpty ||
        normalizedProductId.isEmpty ||
        quantity <= 0) {
      return false;
    }

    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        // ------------------------------------------------------
        // Get product
        // ------------------------------------------------------

        final productResult = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [normalizedProductId],
          limit: 1,
        );

        if (productResult.isEmpty) {
          return false;
        }

        final product = productResult.first;

        // ------------------------------------------------------
        // Product stock
        // ------------------------------------------------------

        final stock =
            (product['stock'] as num?)?.toInt() ?? 0;

        if (stock <= 0) {
          return false;
        }

        // ------------------------------------------------------
        // Seller comes from product.
        //
        // Never trust seller ID from the UI.
        // ------------------------------------------------------

        final sellerId =
            product['seller_id']?.toString() ?? '';

        if (sellerId.isEmpty) {
          return false;
        }

        // ------------------------------------------------------
        // Product information
        // ------------------------------------------------------

        final productName =
            product['name']?.toString() ?? '';

        final sellingPrice =
            (product['selling_price'] as num?)
                    ?.toDouble() ??
                0.0;

        final imagePath =
            product['image_path']?.toString();

        // ------------------------------------------------------
        // Check whether buyer already has this product
        // in their cart.
        // ------------------------------------------------------

        final existingResult = await txn.query(
          'cart_items',
          where: '''
            buyer_id = ?
            AND product_id = ?
          ''',
          whereArgs: [
            normalizedBuyerId,
            normalizedProductId,
          ],
          limit: 1,
        );

        // ------------------------------------------------------
        // EXISTING CART ITEM
        // ------------------------------------------------------

        if (existingResult.isNotEmpty) {
          final existing =
              CartItem.fromMap(existingResult.first);

          final newQuantity =
              existing.quantity + quantity;

          // Never allow cart quantity above current stock.
          if (newQuantity > stock) {
            return false;
          }

          final updatedRows = await txn.update(
            'cart_items',
            {
              'seller_id': sellerId,
              'product_name': productName,
              'unit_price': sellingPrice,
              'quantity': newQuantity,
              'image_path': imagePath,
            },
            where: 'id = ?',
            whereArgs: [existing.id],
          );

          return updatedRows > 0;
        }

        // ------------------------------------------------------
        // NEW CART ITEM
        // ------------------------------------------------------

        if (quantity > stock) {
          return false;
        }

        final cartItemId =
            'CART_${DateTime.now().microsecondsSinceEpoch}';

        final cartItem = CartItem(
          id: cartItemId,
          buyerId: normalizedBuyerId,
          productId: normalizedProductId,
          sellerId: sellerId,
          productName: productName,
          unitPrice: sellingPrice,
          quantity: quantity,
          imagePath: imagePath,
        );

        final insertedRows = await txn.insert(
          'cart_items',
          cartItem.toMap(),
          conflictAlgorithm:
              ConflictAlgorithm.abort,
        );

        return insertedRows > 0;
      },
    );
  }

  // ============================================================
  // GET BUYER CART
  // ============================================================

  Future<List<CartItem>> getCartItems(
    String buyerId,
  ) async {
    final normalizedBuyerId = buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      return [];
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'cart_items',
      where: 'buyer_id = ?',
      whereArgs: [normalizedBuyerId],
      orderBy: 'rowid ASC',
    );

    return result
        .map(
          (map) => CartItem.fromMap(map),
        )
        .toList();
  }

  // ============================================================
  // GET CART ITEM COUNT
  //
  // Returns total quantity, not number of products.
  //
  // Example:
  //
  // Rice x 2
  // Sugar x 3
  //
  // Count = 5
  // ============================================================

  Future<int> getCartItemCount(
    String buyerId,
  ) async {
    final normalizedBuyerId = buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      return 0;
    }

    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(quantity),
        0
      ) AS total
      FROM cart_items
      WHERE buyer_id = ?
      ''',
      [normalizedBuyerId],
    );

    return (result.first['total'] as num?)
            ?.toInt() ??
        0;
  }

  // ============================================================
  // GET NUMBER OF DIFFERENT PRODUCTS
  // ============================================================

  Future<int> getCartProductCount(
    String buyerId,
  ) async {
    final normalizedBuyerId = buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      return 0;
    }

    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM cart_items
      WHERE buyer_id = ?
      ''',
      [normalizedBuyerId],
    );

    return (result.first['count'] as num?)
            ?.toInt() ??
        0;
  }

  // ============================================================
  // GET CART TOTAL
  // ============================================================

  Future<double> getCartTotal(
    String buyerId,
  ) async {
    final normalizedBuyerId = buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      return 0.0;
    }

    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(quantity * unit_price),
        0
      ) AS total
      FROM cart_items
      WHERE buyer_id = ?
      ''',
      [normalizedBuyerId],
    );

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0.0;
  }

  // ============================================================
  // INCREASE QUANTITY
  // ============================================================

  Future<bool> increaseQuantity(
    String buyerId,
    String cartItemId,
  ) async {
    return await _changeQuantity(
      buyerId: buyerId,
      cartItemId: cartItemId,
      increase: true,
    );
  }

  // ============================================================
  // DECREASE QUANTITY
  // ============================================================

  Future<bool> decreaseQuantity(
    String buyerId,
    String cartItemId,
  ) async {
    return await _changeQuantity(
      buyerId: buyerId,
      cartItemId: cartItemId,
      increase: false,
    );
  }

  // ============================================================
  // CHANGE QUANTITY
  // ============================================================

  Future<bool> _changeQuantity({
    required String buyerId,
    required String cartItemId,
    required bool increase,
  }) async {
    final normalizedBuyerId = buyerId.trim();
    final normalizedCartItemId = cartItemId.trim();

    if (normalizedBuyerId.isEmpty ||
        normalizedCartItemId.isEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;

    return await db.transaction<bool>(
      (txn) async {
        // ------------------------------------------------------
        // Find item belonging to THIS buyer.
        // ------------------------------------------------------

        final result = await txn.query(
          'cart_items',
          where: '''
            id = ?
            AND buyer_id = ?
          ''',
          whereArgs: [
            normalizedCartItemId,
            normalizedBuyerId,
          ],
          limit: 1,
        );

        if (result.isEmpty) {
          return false;
        }

        final item =
            CartItem.fromMap(result.first);

        // ------------------------------------------------------
        // DECREASE
        // ------------------------------------------------------

        if (!increase) {
          if (item.quantity <= 1) {
            // Remove item instead of going to zero.
            final deletedRows = await txn.delete(
              'cart_items',
              where: '''
                id = ?
                AND buyer_id = ?
              ''',
              whereArgs: [
                normalizedCartItemId,
                normalizedBuyerId,
              ],
            );

            return deletedRows > 0;
          }

          final updatedRows = await txn.update(
            'cart_items',
            {
              'quantity': item.quantity - 1,
            },
            where: '''
              id = ?
              AND buyer_id = ?
            ''',
            whereArgs: [
              normalizedCartItemId,
              normalizedBuyerId,
            ],
          );

          return updatedRows > 0;
        }

        // ------------------------------------------------------
        // INCREASE
        // ------------------------------------------------------

        final productResult = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );

        if (productResult.isEmpty) {
          return false;
        }

        final currentStock =
            (productResult.first['stock'] as num?)
                    ?.toInt() ??
                0;

        if (item.quantity + 1 > currentStock) {
          return false;
        }

        final updatedRows = await txn.update(
          'cart_items',
          {
            'quantity': item.quantity + 1,
          },
          where: '''
            id = ?
            AND buyer_id = ?
          ''',
          whereArgs: [
            normalizedCartItemId,
            normalizedBuyerId,
          ],
        );

        return updatedRows > 0;
      },
    );
  }

  // ============================================================
  // REMOVE FROM CART
  // ============================================================

  Future<bool> removeFromCart(
    String buyerId,
    String cartItemId,
  ) async {
    final normalizedBuyerId = buyerId.trim();
    final normalizedCartItemId = cartItemId.trim();

    if (normalizedBuyerId.isEmpty ||
        normalizedCartItemId.isEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;

    final deletedRows = await db.delete(
      'cart_items',
      where: '''
        id = ?
        AND buyer_id = ?
      ''',
      whereArgs: [
        normalizedCartItemId,
        normalizedBuyerId,
      ],
    );

    return deletedRows > 0;
  }

  // ============================================================
  // CLEAR BUYER CART
  // ============================================================

  Future<bool> clearCart(
    String buyerId,
  ) async {
    final normalizedBuyerId = buyerId.trim();

    if (normalizedBuyerId.isEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;

    final deletedRows = await db.delete(
      'cart_items',
      where: 'buyer_id = ?',
      whereArgs: [normalizedBuyerId],
    );

    return deletedRows > 0;
  }

  // ============================================================
  // CHECK WHETHER PRODUCT IS IN CART
  // ============================================================

  Future<bool> isProductInCart({
    required String buyerId,
    required String productId,
  }) async {
    final normalizedBuyerId = buyerId.trim();
    final normalizedProductId = productId.trim();

    if (normalizedBuyerId.isEmpty ||
        normalizedProductId.isEmpty) {
      return false;
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'cart_items',
      columns: ['id'],
      where: '''
        buyer_id = ?
        AND product_id = ?
      ''',
      whereArgs: [
        normalizedBuyerId,
        normalizedProductId,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // REMOVE CART ITEMS FOR A PRODUCT
  //
  // Useful if a seller/product is deleted or disabled later.
  // ============================================================

  Future<int> removeProductFromAllCarts(
    String productId,
  ) async {
    final normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) {
      return 0;
    }

    final db = await _databaseHelper.database;

    return await db.delete(
      'cart_items',
      where: 'product_id = ?',
      whereArgs: [normalizedProductId],
    );
  }

  // ============================================================
  // DEBUG CART
  // ============================================================

  Future<void> debugCart(
    String buyerId,
  ) async {
    final items = await getCartItems(buyerId);

    debugPrint(
      '========== BUYER CART ==========',
    );

    for (final item in items) {
      debugPrint(
        '${item.productName} | '
        'Qty: ${item.quantity} | '
        'Price: ${item.unitPrice} | '
        'Seller: ${item.sellerId}',
      );
    }

    debugPrint(
      'Cart total: ${await getCartTotal(buyerId)}',
    );

    debugPrint(
      '================================',
    );
  }
}