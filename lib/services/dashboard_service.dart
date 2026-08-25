import '../models/order.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';

class DashboardStats {
  final double todaySales;
  final int totalOrders;
  final int totalProducts;
  final double totalRevenue;
  final int lowStockCount;
  final int todayOrders;

  const DashboardStats({
    required this.todaySales,
    required this.totalOrders,
    required this.totalProducts,
    required this.totalRevenue,
    required this.lowStockCount,
    required this.todayOrders,
  });
}

class DashboardService {
  static final DashboardService instance =
      DashboardService._init();

  final AuthService _authService = AuthService.instance;
  final OrderService _orderService = OrderService.instance;
  final ProductService _productService = ProductService.instance;

  DashboardService._init();

  // ============================================================
  // DASHBOARD STATISTICS
  // ============================================================

  Future<DashboardStats> getDashboardStats() async {
    final user = _authService.currentUser;

    if (user == null) {
      return const DashboardStats(
        todaySales: 0,
        totalOrders: 0,
        totalProducts: 0,
        totalRevenue: 0,
        lowStockCount: 0,
        todayOrders: 0,
      );
    }

    final products = await _productService.getProducts();

    final allOrders = await _orderService.getOrders();

    // ==========================================================
    // ADMIN DASHBOARD
    //
    // Leader Admin and Normal Admin can see the whole business.
    // ==========================================================

    if (user.isAnyAdmin) {
      return _calculateStats(
        products: products,
        orders: allOrders,
      );
    }

    // ==========================================================
    // SELLER DASHBOARD
    //
    // Seller only sees products belonging to that seller.
    // Orders are connected to products through productId.
    // ==========================================================

    if (user.isSeller) {
      final sellerProducts = products
          .where(
            (product) => product.sellerId == user.id,
          )
          .toList();

      final sellerProductIds = sellerProducts
          .map((product) => product.id)
          .toSet();

      final sellerOrders = allOrders
          .where(
            (order) =>
                sellerProductIds.contains(order.productId),
          )
          .toList();

      return _calculateStats(
        products: sellerProducts,
        orders: sellerOrders,
      );
    }

    // ==========================================================
    // BUYER DASHBOARD
    //
    // Buyer only sees orders created by that buyer.
    // Products remain available for browsing.
    // ==========================================================

    if (user.isBuyer) {
      final buyerOrders = allOrders
          .where(
            (order) => order.createdBy == user.id,
          )
          .toList();

      return _calculateStats(
        products: products,
        orders: buyerOrders,
      );
    }

    return const DashboardStats(
      todaySales: 0,
      totalOrders: 0,
      totalProducts: 0,
      totalRevenue: 0,
      lowStockCount: 0,
      todayOrders: 0,
    );
  }

  // ============================================================
  // CALCULATE STATISTICS
  // ============================================================

  DashboardStats _calculateStats({
    required List<Product> products,
    required List<Order> orders,
  }) {
    final now = DateTime.now();

    double todaySales = 0;
    double totalRevenue = 0;
    int todayOrders = 0;

    for (final order in orders) {
      totalRevenue += order.totalAmount;

      final createdAt = order.createdAt;

      if (createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day) {
        todaySales += order.totalAmount;
        todayOrders++;
      }
    }

    final lowStockCount = products
        .where(
          (product) => product.stock <= 10,
        )
        .length;

    return DashboardStats(
      todaySales: todaySales,
      totalOrders: orders.length,
      totalProducts: products.length,
      totalRevenue: totalRevenue,
      lowStockCount: lowStockCount,
      todayOrders: todayOrders,
    );
  }

  // ============================================================
  // LOW STOCK PRODUCTS
  // ============================================================

  Future<List<Product>> getLowStockProducts() async {
    final user = _authService.currentUser;

    if (user == null) {
      return <Product>[];
    }

    final products = await _productService.getProducts();

    if (user.isAnyAdmin) {
      return products
          .where(
            (product) => product.stock <= 10,
          )
          .toList();
    }

    if (user.isSeller) {
      return products
          .where(
            (product) =>
                product.sellerId == user.id &&
                product.stock <= 10,
          )
          .toList();
    }

    // Buyers do not manage stock.
    return <Product>[];
  }

  // ============================================================
  // RECENT ORDERS
  // ============================================================

  Future<List<Order>> getRecentOrders({
    int limit = 5,
  }) async {
    final user = _authService.currentUser;

    if (user == null) {
      return <Order>[];
    }

    final allOrders = await _orderService.getOrders();

    List<Order> orders;

    if (user.isAnyAdmin) {
      orders = allOrders;
    } else if (user.isBuyer) {
      orders = allOrders
          .where(
            (order) => order.createdBy == user.id,
          )
          .toList();
    } else if (user.isSeller) {
      final products = await _productService.getProducts();

      final sellerProductIds = products
          .where(
            (product) => product.sellerId == user.id,
          )
          .map(
            (product) => product.id,
          )
          .toSet();

      orders = allOrders
          .where(
            (order) =>
                sellerProductIds.contains(order.productId),
          )
          .toList();
    } else {
      orders = <Order>[];
    }

    orders.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    if (orders.length <= limit) {
      return orders;
    }

    return orders.take(limit).toList();
  }
}