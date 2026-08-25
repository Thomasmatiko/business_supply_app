import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/order_details_result.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import 'create_order_screen.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() =>
      _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService =
      OrderService.instance;

  final ProductService _productService =
      ProductService.instance;

  final AuthService _authService =
      AuthService.instance;

  List<Order> _orders = [];

  List<Product> _products = [];

  bool _isLoading = true;

  String? _errorMessage;

  // ============================================================
  // CURRENT USER ROLE
  // ============================================================

  bool get _isBuyer {
    return _authService.isBuyer;
  }

  bool get _isSeller {
    return _authService.isSeller;
  }

  bool get _isAdmin {
    return _authService.isAdmin;
  }

  bool get _canCreateOrders {
    return _authService.canCreateOrders;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser =
          _authService.currentUser;

      if (currentUser == null) {
        throw Exception(
          'No logged-in user.',
        );
      }

      List<Order> orders;

      // ========================================================
      // BUYER
      //
      // Buyer sees only their own orders.
      // ========================================================

      if (currentUser.isBuyer) {
        orders =
            await _orderService.getOrdersByUser(
          currentUser.id,
        );
      }

      // ========================================================
      // SELLER
      //
      // Seller sees orders containing their products.
      // ========================================================

      else if (currentUser.isSeller) {
        orders =
            await _orderService.getOrdersBySeller(
          currentUser.id,
        );
      }

      // ========================================================
      // ADMIN
      //
      // Admin sees all orders.
      // ========================================================

      else if (currentUser.isAnyAdmin) {
        orders =
            await _orderService.getOrders();
      }

      // ========================================================
      // OTHER USERS
      // ========================================================

      else {
        orders = [];
      }

      // ========================================================
      // LOAD PRODUCTS
      // ========================================================

      final products =
          await _productService.getProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load orders.';
      });

      debugPrint(
        'Orders loading error: $e',
      );
    }
  }

  // ============================================================
  // GET PRODUCT
  // ============================================================

  Product? _getProduct(
    String productId,
  ) {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // AMOUNT FORMAT
  // ============================================================

  String _formatAmount(
    double amount,
  ) {
    final amountString =
        amount.toStringAsFixed(0);

    final reversed =
        amountString
            .split('')
            .reversed
            .toList();

    final formatted = <String>[];

    for (
      int i = 0;
      i < reversed.length;
      i++
    ) {
      if (i > 0 && i % 3 == 0) {
        formatted.add(',');
      }

      formatted.add(
        reversed[i],
      );
    }

    return 'TZS ${formatted.reversed.join()}';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;

      case 'processing':
        return Colors.orange;

      case 'shipped':
        return Colors.indigo;

      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'pending':
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabel(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'CONFIRMED';

      case 'processing':
        return 'PROCESSING';

      case 'shipped':
        return 'SHIPPED';

      case 'delivered':
        return 'DELIVERED';

      case 'cancelled':
        return 'CANCELLED';

      case 'pending':
      default:
        return 'PENDING';
    }
  }

  // ============================================================
  // OPEN ORDER DETAILS
  // ============================================================

  Future<void> _openOrderDetails(
    Order order,
    Product? product,
  ) async {
    final result =
        await Navigator.of(context)
            .push<OrderDetailsResult>(
      MaterialPageRoute(
        builder: (context) =>
            OrderDetailsScreen(
          order: order,
          product: product,
        ),
      ),
    );

    if (!mounted ||
        result == null) {
      return;
    }

    // ==========================================================
    // ORDER DELETED
    // ==========================================================

    if (result.action ==
        OrderDetailsAction.deleted) {
      setState(() {
        _orders.removeWhere(
          (item) =>
              item.id == result.order.id,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Order deleted and stock restored.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // ORDER UPDATED
    // ==========================================================

    setState(() {
      final index =
          _orders.indexWhere(
        (item) =>
            item.id == result.order.id,
      );

      if (index != -1) {
        _orders[index] =
            result.order;
      }
    });
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================

  Future<void> _openCreateOrder() async {
    if (!_canCreateOrders) {
      return;
    }

    final result =
        await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const CreateOrderScreen(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // APP BAR TITLE
  // ============================================================

  String get _screenTitle {
    if (_isBuyer) {
      return 'My Orders';
    }

    if (_isSeller) {
      return 'Seller Orders';
    }

    if (_isAdmin) {
      return 'All Orders';
    }

    return 'Orders';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _screenTitle,
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),

      // ========================================================
      // CREATE ORDER BUTTON
      // ========================================================

      floatingActionButton:
          _canCreateOrders
              ? FloatingActionButton(
                  onPressed:
                      _openCreateOrder,
                  tooltip:
                      'Create Order',
                  child: const Icon(
                    Icons.add,
                  ),
                )
              : null,

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              ElevatedButton(
                onPressed:
                    _loadData,
                child:
                    const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(
              height: 160,
            ),

            const Center(
              child: Icon(
                Icons.receipt_long_outlined,
                size: 70,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Center(
              child: Text(
                _emptyTitle,
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  _emptyMessage,
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // ORDER LIST
    // ==========================================================

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding:
            const EdgeInsets.all(12),
        itemCount:
            _orders.length,
        itemBuilder:
            (context, index) {
          final order =
              _orders[index];

          final product =
              _getProduct(
            order.productId,
          );

          return _buildOrderCard(
            order,
            product,
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE TITLE
  // ============================================================

  String get _emptyTitle {
    if (_isBuyer) {
      return 'No orders yet';
    }

    if (_isSeller) {
      return 'No seller orders';
    }

    return 'No orders yet';
  }

  // ============================================================
  // EMPTY STATE MESSAGE
  // ============================================================

  String get _emptyMessage {
    if (_isBuyer) {
      return 'Your orders will appear here when you place an order.';
    }

    if (_isSeller) {
      return 'Orders containing your products will appear here.';
    }

    if (_isAdmin) {
      return 'Orders created in the system will appear here.';
    }

    return 'Orders will appear here when they are created.';
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    Order order,
    Product? product,
  ) {
    final productName =
        product?.name ??
        order.productId;

    final statusColor =
        _statusColor(
      order.status,
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        onTap: () {
          _openOrderDetails(
            order,
            product,
          );
        },

        contentPadding:
            const EdgeInsets.all(16),

        // ======================================================
        // QUANTITY
        // ======================================================

        leading: CircleAvatar(
          child: Text(
            '${order.quantity}',
          ),
        ),

        // ======================================================
        // ORDER ID
        // ======================================================

        title: Text(
          'Order ${order.id}',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        // ======================================================
        // DETAILS
        // ======================================================

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 8,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // BUYER
              // ==================================================

              Text(
                'Buyer: ${order.buyerId}',
              ),

              // ==================================================
              // SELLER
              // ==================================================

              Text(
                'Seller: ${order.sellerId}',
              ),

              // ==================================================
              // PRODUCT
              // ==================================================

              Text(
                'Product: $productName',
              ),

              // ==================================================
              // QUANTITY
              // ==================================================

              Text(
                'Quantity: ${order.quantity}',
              ),

              // ==================================================
              // DATE
              // ==================================================

              Text(
                'Date: '
                '${_formatDate(order.createdAt)}',
              ),

              const SizedBox(
                height: 6,
              ),

              // ==================================================
              // TOTAL
              // ==================================================

              Text(
                'Total: '
                '${_formatAmount(order.totalAmount)}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // STATUS
              // ==================================================

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      statusColor
                          .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  _statusLabel(
                    order.status,
                  ),
                  style:
                      TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        trailing:
            const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}