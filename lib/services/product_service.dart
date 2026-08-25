import '../database/database_helper.dart';
import '../models/product.dart';

class ProductService {
  static final ProductService instance = ProductService._init();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  ProductService._init();

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

    return await db.insert(
      'products',
      map,
    );
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

    return await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
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

    return await db.update(
      'products',
      {
        'seller_id': sellerId,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<int> deleteProduct(String id) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
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
      return 0;
    }

    if (quantity <= 0 || quantity > product.stock) {
      return 0;
    }

    final newStock = product.stock - quantity;

    return await db.update(
      'products',
      {
        'stock': newStock,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
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
      return 0;
    }

    if (quantity <= 0) {
      return 0;
    }

    final newStock = product.stock + quantity;

    return await db.update(
      'products',
      {
        'stock': newStock,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
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