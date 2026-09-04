import '../database/database_helper.dart';
import '../models/product.dart';
import '../services/activity_log_service.dart';
import '../services/auth_service.dart';
class ProductService {
  static final ProductService instance = ProductService._init();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final ActivityLogService _activityLogService =
    ActivityLogService.instance;

  ProductService._init();

  Future<void> _logProductAction({
  required String action,
  required String description,
  String type = 'product',
  String? entityId,
}) async {
  final user = AuthService.instance.currentUser;

  await _activityLogService.logAction(
    userId: user?.id,
    userName: user?.name,
    action: action,
    description: description,
    type: type,
    entityType: 'product',
    entityId: entityId,
  );
}

  // ============================================================
  // GET ALL PRODUCTS
  //
  // Used for the public marketplace and admin.
  // ============================================================

  Future<List<Product>> getProducts() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      orderBy: 'name ASC',
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }

  // ============================================================
  // GET PRODUCTS BY SELLER
  //
  // Used by sellers to see only products they own.
  // ============================================================

  Future<List<Product>> getProductsBySeller(
    String sellerId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      where: 'seller_id = ?',
      whereArgs: [sellerId],
      orderBy: 'name ASC',
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }

  // ============================================================
  // GET PRODUCT BY ID
  // ============================================================

  Future<Product?> getProductById(String id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Product.fromMap(result.first);
  }

  // ============================================================
  // ADD PRODUCT
  //
  // sellerId is optional so existing product creation code
  // does not immediately break.
  //
  // New seller-created products should provide sellerId.
  // ============================================================

  Future<int> addProduct(
  Product product, {
  String? sellerId,
}) async {
  final db = await _databaseHelper.database;

  final map = product.toMap();

  map['seller_id'] = sellerId;

  final result = await db.insert(
    'products',
    map,
  );

  if (result > 0) {
    await _logProductAction(
      action: 'product_created',
      description:
          'Created product "${product.name}" with stock ${product.stock}.',
      entityId: product.id,
    );
  }

  return result;
}

  // ============================================================
  // UPDATE PRODUCT
  //
  // Keeps the existing seller ownership unless a new sellerId
  // is explicitly provided.
  // ============================================================

  Future<int> updateProduct(
  Product product, {
  String? sellerId,
}) async {
  final db = await _databaseHelper.database;

  final map = product.toMap();

  if (sellerId != null) {
    map['seller_id'] = sellerId;
  }

  final result = await db.update(
    'products',
    map,
    where: 'id = ?',
    whereArgs: [product.id],
  );

  if (result > 0) {
    await _logProductAction(
      action: 'product_updated',
      description:
          'Updated product "${product.name}".',
      entityId: product.id,
    );
  }

  return result;
}
  // ============================================================
  // UPDATE PRODUCT OWNER
  //
  // Mainly useful for admin operations.
  // ============================================================

  Future<int> updateProductSeller(
  String productId,
  String sellerId,
) async {
  final db = await _databaseHelper.database;

  final product = await getProductById(productId);

  final result = await db.update(
    'products',
    {
      'seller_id': sellerId,
    },
    where: 'id = ?',
    whereArgs: [productId],
  );

  if (result > 0) {
    await _logProductAction(
      action: 'product_owner_updated',
      description: product != null
          ? 'Updated the seller ownership of product "${product.name}".'
          : 'Updated the seller ownership of product $productId.',
      entityId: productId,
    );
  }

  return result;
}

// DELETE PRODUCT

// ============================================================

Future<int> deleteProduct(String id) async {
  final productId = id.trim();

  if (productId.isEmpty) {
    await _logProductAction(
      action: 'product_delete_failed',
      description:
          'Product deletion failed because the product ID was empty.',
    );

    return 0;
  }

  final db = await _databaseHelper.database;

  final product = await getProductById(productId);

  // ----------------------------------------------------------
  // CHECK ORDER HISTORY
  // ----------------------------------------------------------

  final existingOrders = await db.query(
    'orders',
    columns: ['id'],
    where: 'product_id = ?',
    whereArgs: [productId],
    limit: 1,
  );

  if (existingOrders.isNotEmpty) {
    await _logProductAction(
      action: 'product_delete_failed',
      description: product != null
          ? 'Could not delete product "${product.name}" because it is referenced by an existing order.'
          : 'Could not delete product $productId because it is referenced by an existing order.',
      entityId: productId,
    );

    return 0;
  }

  // ----------------------------------------------------------
  // DELETE PRODUCT
  // ----------------------------------------------------------

  final result = await db.delete(
    'products',
    where: 'id = ?',
    whereArgs: [productId],
  );

  if (result > 0) {
    await _logProductAction(
      action: 'product_deleted',
      description: product != null
          ? 'Deleted product "${product.name}".'
          : 'Deleted product $productId.',
      entityId: productId,
    );
  }

  return result;
}
  // ============================================================
  // REDUCE STOCK
  //
  // Kept because your existing order system uses it.
  //
  // IMPORTANT:
  // Later we will move stock reduction into the proper order
  // lifecycle so that placing an order does not automatically
  // mean the order is completed.
  // ============================================================

  Future<int> reduceStock(
  String productId,
  int quantity,
) async {
  final db = await _databaseHelper.database;

  final product = await getProductById(productId);

  if (product == null) {
    await _logProductAction(
      action: 'stock_reduction_failed',
      description:
          'Stock reduction failed because product $productId was not found.',
      entityId: productId,
    );

    return 0;
  }

  if (quantity <= 0 || quantity > product.stock) {
    await _logProductAction(
      action: 'stock_reduction_failed',
      description:
          'Stock reduction failed for product "${product.name}" because the requested quantity was invalid.',
      entityId: productId,
    );

    return 0;
  }

  final newStock = product.stock - quantity;

  final result = await db.update(
    'products',
    {
      'stock': newStock,
    },
    where: 'id = ?',
    whereArgs: [productId],
  );

  if (result > 0) {
    await _logProductAction(
      action: 'stock_reduced',
      description:
          'Reduced stock of "${product.name}" by $quantity. New stock: $newStock.',
      entityId: productId,
    );
  }

  return result;
}
  // ============================================================
  // INCREASE STOCK
  //
  // Useful for cancelled/rejected orders or stock adjustments.
  // ============================================================

  Future<int> increaseStock(
  String productId,
  int quantity,
) async {
  final db = await _databaseHelper.database;

  final product = await getProductById(productId);

  if (product == null) {
    await _logProductAction(
      action: 'stock_increase_failed',
      description:
          'Stock increase failed because product $productId was not found.',
      entityId: productId,
    );

    return 0;
  }

  if (quantity <= 0) {
    await _logProductAction(
      action: 'stock_increase_failed',
      description:
          'Stock increase failed for product "${product.name}" because the requested quantity was invalid.',
      entityId: productId,
    );

    return 0;
  }

  final newStock = product.stock + quantity;

  final result = await db.update(
    'products',
    {
      'stock': newStock,
    },
    where: 'id = ?',
    whereArgs: [productId],
  );

  if (result > 0) {
    await _logProductAction(
      action: 'stock_increased',
      description:
          'Increased stock of "${product.name}" by $quantity. New stock: $newStock.',
      entityId: productId,
    );
  }

  return result;
}

  // ============================================================
  // SEARCH PRODUCTS
  //
  // Public marketplace search.
  // ============================================================

  Future<List<Product>> searchProducts(
    String query,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      where: '''
        id LIKE ?
        OR name LIKE ?
        OR category LIKE ?
      ''',
      whereArgs: [
        '%$query%',
        '%$query%',
        '%$query%',
      ],
      orderBy: 'name ASC',
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }

  // ============================================================
  // SEARCH PRODUCTS BY SELLER
  // ============================================================

  Future<List<Product>> searchProductsBySeller(
    String sellerId,
    String query,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'products',
      where: '''
        seller_id = ?
        AND (
          id LIKE ?
          OR name LIKE ?
          OR category LIKE ?
        )
      ''',
      whereArgs: [
        sellerId,
        '%$query%',
        '%$query%',
        '%$query%',
      ],
      orderBy: 'name ASC',
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }
}