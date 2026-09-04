
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/notification_bell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService =
      DashboardService.instance;

  final AuthService _authService = AuthService.instance;

  DashboardStats? _stats;

  List<Product> _lowStockProducts = <Product>[];

  List<Order> _recentOrders = <Order>[];

  bool _isLoading = true;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final stats = await _dashboardService.getDashboardStats();

      final lowStockProducts =
          await _dashboardService.getLowStockProducts();

      final recentOrders =
          await _dashboardService.getRecentOrders();

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = stats;
        _lowStockProducts = lowStockProducts;
        _recentOrders = recentOrders;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Dashboard error: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    await _loadDashboard();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String get _userName {
    final user = _authService.currentUser;

    if (user == null || user.name.trim().isEmpty) {
      return 'User';
    }

    return user.name.trim();
  }

  String get _role {
    final user = _authService.currentUser;

    if (user == null) {
      return 'User';
    }

    if (user.isLeaderAdmin) {
      return 'Leader Admin';
    }

    if (user.isNormalAdmin) {
      return 'Normal Admin';
    }

    if (user.isSeller) {
      return 'Seller';
    }

    if (user.isBuyer) {
      return 'Buyer';
    }

    return user.role;
  }

  bool get _isSeller {
    return _authService.currentUser?.isSeller ?? false;
  }

  bool get _isBuyer {
    return _authService.currentUser?.isBuyer ?? false;
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String _formatCurrency(double amount) {
    final rounded = amount.round();

    final text = rounded.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return 'TZS ${buffer.toString()}';
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000000) {
      return 'TZS ${(amount / 1000000000).toStringAsFixed(1)}B';
    }

    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(1)}K';
    }

    return _formatCurrency(amount);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'Dashboard',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  actions: [
    const NotificationBell(),

    IconButton(
      tooltip: 'Refresh',
      onPressed: _isLoading ? null : _refresh,
      icon: const Icon(Icons.refresh),
    ),

    const SizedBox(width: 8),
  ],
),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(context),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 250),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          _buildErrorState(context),
        ],
      );
    }

    if (_stats == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          _buildErrorState(context),
        ],
      );
    }

    if (_isBuyer) {
      return _buildBuyerDashboard(context);
    }

    if (_isSeller) {
      return _buildSellerDashboard(context);
    }

    return _buildAdminDashboard(context);
  }

  // ============================================================
  // ADMIN DASHBOARD
  // ============================================================

  Widget _buildAdminDashboard(BuildContext context) {
    final stats = _stats!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreeting(context),

        const SizedBox(height: 24),

        _buildSalesSummary(
          context,
          title: "Today's Sales",
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'Business Overview',
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            _buildStatisticCard(
              context,
              icon: Icons.shopping_cart_outlined,
              title: 'Orders',
              value: stats.totalOrders.toString(),
              subtitle: '${stats.todayOrders} today',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Products',
              value: stats.totalProducts.toString(),
              subtitle: '${stats.lowStockCount} low stock',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Revenue',
              value: _formatCompactCurrency(
                stats.totalRevenue,
              ),
              subtitle: 'Total revenue',
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'Quick Actions',
        ),

        const SizedBox(height: 12),

        _buildAdminQuickActions(context),

        const SizedBox(height: 24),

        _buildSectionHeader(
          context,
          title: 'Low Stock',
          actionText: 'View all',
          onPressed: _openProducts,
        ),

        const SizedBox(height: 12),

        _buildLowStockSection(context),

        const SizedBox(height: 24),

        _buildSectionHeader(
          context,
          title: 'Recent Orders',
          actionText: 'View all',
          onPressed: _openOrders,
        ),

        const SizedBox(height: 12),

        _buildRecentOrdersSection(context),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // SELLER DASHBOARD
  // ============================================================

  Widget _buildSellerDashboard(BuildContext context) {
    final stats = _stats!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreeting(context),

        const SizedBox(height: 24),

        _buildSalesSummary(
          context,
          title: "Today's Sales",
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'My Business',
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            _buildStatisticCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'My Products',
              value: stats.totalProducts.toString(),
              subtitle: '${stats.lowStockCount} low stock',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.shopping_cart_outlined,
              title: 'My Orders',
              value: stats.totalOrders.toString(),
              subtitle: '${stats.todayOrders} today',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.payments_outlined,
              title: 'My Revenue',
              value: _formatCompactCurrency(
                stats.totalRevenue,
              ),
              subtitle: 'Total sales',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.trending_up,
              title: 'Today',
              value: _formatCompactCurrency(
                stats.todaySales,
              ),
              subtitle: 'Today sales',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ======================================================
        // SELLER REPORTS CARD
        // ======================================================

        _buildReportsCard(
          context,
          title: 'Reports',
          description:
              'View your sales, orders and business summary.',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'Quick Actions',
        ),

        const SizedBox(height: 12),

        _buildSellerQuickActions(context),

        const SizedBox(height: 24),

        _buildSectionHeader(
          context,
          title: 'Low Stock',
          actionText: 'View all',
          onPressed: _openProducts,
        ),

        const SizedBox(height: 12),

        _buildLowStockSection(context),

        const SizedBox(height: 24),

        _buildSectionHeader(
          context,
          title: 'My Recent Orders',
          actionText: 'View all',
          onPressed: _openOrders,
        ),

        const SizedBox(height: 12),

        _buildRecentOrdersSection(context),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // BUYER DASHBOARD
  // ============================================================

  Widget _buildBuyerDashboard(BuildContext context) {
    final stats = _stats!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreeting(context),

        const SizedBox(height: 24),

        _buildSalesSummary(
          context,
          title: 'My Spending',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'My Shopping',
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            _buildStatisticCard(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              value: stats.totalOrders.toString(),
              subtitle: '${stats.todayOrders} today',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.payments_outlined,
              title: 'My Spending',
              value: _formatCompactCurrency(
                stats.totalRevenue,
              ),
              subtitle: 'Total spending',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Products',
              value: stats.totalProducts.toString(),
              subtitle: 'Available products',
            ),
            _buildStatisticCard(
              context,
              icon: Icons.today_outlined,
              title: 'Today',
              value: _formatCompactCurrency(
                stats.todaySales,
              ),
              subtitle: 'Today spending',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ======================================================
        // BUYER REPORTS CARD
        // ======================================================

        _buildReportsCard(
          context,
          title: 'Reports',
          description:
              'View your orders, spending and shopping summary.',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'Quick Actions',
        ),

        const SizedBox(height: 12),

        _buildBuyerQuickActions(context),

        const SizedBox(height: 24),

        _buildSectionHeader(
          context,
          title: 'My Recent Orders',
          actionText: 'View all',
          onPressed: _openOrders,
        ),

        const SizedBox(height: 12),

        _buildRecentOrdersSection(context),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good day, $_userName 👋',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 6),

        Text(
          _isBuyer
              ? 'Welcome to your shopping dashboard.'
              : _isSeller
                  ? 'Here is your sales overview.'
                  : 'Here is your business overview.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 6),

        Text(
          _role,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SALES SUMMARY
  // ============================================================

  Widget _buildSalesSummary(
    BuildContext context, {
    required String title,
  }) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _formatCurrency(
              _stats?.todaySales ?? 0,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'Transactions recorded today',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ============================================================
  // STATISTIC CARD
  // ============================================================

  Widget _buildStatisticCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
            ),
          ),

          const Spacer(),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORTS CARD
  // ============================================================

  Widget _buildReportsCard(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openReports,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: primaryColor.withValues(
                alpha: 0.25,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: primaryColor,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'View reports',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADMIN QUICK ACTIONS
  // ============================================================

  Widget _buildAdminQuickActions(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Products',
            onPressed: _openProducts,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Orders',
            onPressed: _openOrders,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELLER QUICK ACTIONS
  // ============================================================

  Widget _buildSellerQuickActions(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'My Products',
            onPressed: _openProducts,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Orders',
            onPressed: _openOrders,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUYER QUICK ACTIONS
  // ============================================================

  Widget _buildBuyerQuickActions(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Shop Products',
            onPressed: _openProducts,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildQuickAction(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            onPressed: _openOrders,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context)
                .dividerColor
                .withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 28,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOW STOCK
  // ============================================================

  Widget _buildLowStockSection(
    BuildContext context,
  ) {
    if (_lowStockProducts.isEmpty) {
      return _buildEmptySection(
        context,
        icon: Icons.check_circle_outline,
        message: _isBuyer
            ? 'Stock information is not available for buyers.'
            : 'No low-stock products.',
      );
    }

    return Column(
      children: _lowStockProducts.map(
        (product) {
          return _buildLowStockCard(
            context,
            productName: product.name,
            quantity: product.stock,
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // LOW STOCK CARD
  // ============================================================

  Widget _buildLowStockCard(
    BuildContext context, {
    required String productName,
    required int quantity,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Only $quantity items remaining',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: 15,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT ORDERS
  // ============================================================

  Widget _buildRecentOrdersSection(
    BuildContext context,
  ) {
    if (_recentOrders.isEmpty) {
      return _buildEmptySection(
        context,
        icon: Icons.receipt_long_outlined,
        message: _isBuyer
            ? 'You have no orders yet.'
            : 'No orders have been created yet.',
      );
    }

    return Column(
      children: _recentOrders.map(
        (order) {
          return _buildOrderCard(
            context,
            orderNumber: order.id,
            buyer: order.buyerId,
            amount: _formatCurrency(
              order.totalAmount,
            ),
            status: order.status,
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    BuildContext context, {
    required String orderNumber,
    required String buyer,
    required String amount,
    required String status,
  }) {
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  buyer,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),

                const SizedBox(height: 3),

                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptySection(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: Colors.grey,
          ),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        TextButton(
          onPressed: onPressed,
          child: Text(actionText),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;

      case 'processing':
      case 'shipped':
        return Colors.orange;

      case 'confirmed':
        return Colors.indigo;

      case 'pending':
        return Colors.blue;

      case 'cancelled':
      case 'canceled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openProducts() {
    Navigator.pushNamed(
      context,
      AppRoutes.products,
    );
  }

  void _openOrders() {
    Navigator.pushNamed(
      context,
      AppRoutes.orders,
    );
  }

  void _openReports() {
    Navigator.pushNamed(
      context,
      AppRoutes.reports,
    );
  }
}

