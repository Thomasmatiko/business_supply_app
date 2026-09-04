import 'package:flutter/material.dart';

import '../../services/activity_log_service.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/notification_bell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final AdminService _adminService =
      AdminService.instance;

  final AuthService _authService =
      AuthService.instance;

  final PaymentService _paymentService =
      PaymentService.instance;

  final ActivityLogService _activityLogService =
      ActivityLogService.instance;

  AdminDashboardStats? _stats;

  List<Map<String, dynamic>> _payments = [];

  List<Map<String, dynamic>> _activityLogs = [];

  List<Map<String, dynamic>> _auditLogs = [];

  bool _isLoading = true;
  bool _isPaymentsLoading = false;
  bool _isLogsLoading = false;

  String? _errorMessage;

  String _paymentFilter = 'all';

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
      await _authService.refreshCurrentUser();

      if (!_authService.isAdmin) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'You do not have permission to access the '
              'Admin Dashboard.';
        });

        return;
      }

      final stats =
          await _adminService.getDashboardStats();

      await _loadPayments();

      await _loadLogs();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load dashboard: $e';
      });
    }
  }

  // ============================================================
  // LOAD PAYMENTS
  // ============================================================

  Future<void> _loadPayments() async {
    if (mounted) {
      setState(() {
        _isPaymentsLoading = true;
      });
    }

    try {
      List<Map<String, dynamic>> payments;

      if (_paymentFilter == 'all') {
        payments =
            await _paymentService
                .getAllPaymentsWithPeople();
      } else {
        payments =
            await _paymentService
                .getPaymentsByStatus(
          _paymentFilter,
        );
      }

      if (!mounted) return;

      setState(() {
        _payments = payments;
        _isPaymentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPaymentsLoading = false;
      });

      _showMessage(
        'Failed to load payments: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // LOAD ACTIVITY + AUDIT LOGS
  // ============================================================

  Future<void> _loadLogs() async {
    if (mounted) {
      setState(() {
        _isLogsLoading = true;
      });
    }

    try {
      final activityLogs =
          await _activityLogService.getActivityLogs(
        limit: 10,
      );

      final auditLogs =
          await _activityLogService.getAuditLogs(
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _activityLogs = activityLogs;
        _auditLogs = auditLogs;
        _isLogsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLogsLoading = false;
      });

      _showMessage(
        'Failed to load activity logs: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // CHANGE PAYMENT FILTER
  // ============================================================

  Future<void> _changePaymentFilter(
    String filter,
  ) async {
    setState(() {
      _paymentFilter = filter;
    });

    await _loadPayments();
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================

  Future<void> _updatePaymentStatus({
    required String paymentId,
    required String status,
  }) async {
    final confirmed = await _confirmStatusChange(
      status,
    );

    if (!confirmed) return;

    try {
      await _paymentService.updatePaymentStatus(
        paymentId: paymentId,
        status: status,
      );

      await _loadPayments();

      await _loadLogs();

      if (!mounted) return;

      _showMessage(
        'Payment status updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to update payment: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // CONFIRM STATUS CHANGE
  // ============================================================

  Future<bool> _confirmStatusChange(
    String status,
  ) async {
    String title;

    switch (status) {
      case PaymentService.completed:
        title = 'Mark Payment Completed?';
        break;

      case PaymentService.failed:
        title = 'Mark Payment Failed?';
        break;

      case PaymentService.cancelled:
        title = 'Cancel Payment?';
        break;

      default:
        title = 'Change Payment Status?';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            'Are you sure you want to change the '
            'payment status to '
            '"${_statusDisplayName(status)}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentUser =
        _authService.currentUser;

    if (currentUser == null ||
        !currentUser.isAnyAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to access '
              'the Admin Dashboard.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final stats = _stats;

    if (stats == null) {
      return _buildErrorState(
        message:
            'Dashboard statistics are unavailable.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          40,
        ),
        children: [
          _buildWelcomeHeader(context),

          const SizedBox(height: 24),

          _buildSectionTitle(
            context,
            'Users',
          ),

          const SizedBox(height: 12),

          _buildTwoColumnCards(
            context,
            [
              _DashboardCardData(
                title: 'Total Users',
                value:
                    stats.totalUsers.toString(),
                icon: Icons.people_outline,
              ),
              _DashboardCardData(
                title: 'Buyers',
                value:
                    stats.buyers.toString(),
                icon: Icons.person_outline,
              ),
              _DashboardCardData(
                title: 'Sellers',
                value:
                    stats.sellers.toString(),
                icon:
                    Icons.storefront_outlined,
              ),
              _DashboardCardData(
                title: 'Administrators',
                value:
                    stats.admins.toString(),
                icon:
                    Icons.admin_panel_settings_outlined,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(
            context,
            'Products & Inventory',
          ),

          const SizedBox(height: 12),

          _buildTwoColumnCards(
            context,
            [
              _DashboardCardData(
                title: 'Total Products',
                value:
                    stats.products.toString(),
                icon:
                    Icons.inventory_2_outlined,
              ),
              _DashboardCardData(
                title: 'Low Stock',
                value:
                    stats.lowStockProducts
                        .toString(),
                icon:
                    Icons.warning_amber_outlined,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(
            context,
            'Orders & Sales',
          ),

          const SizedBox(height: 12),

          _buildTwoColumnCards(
            context,
            [
              _DashboardCardData(
                title: 'Total Orders',
                value:
                    stats.orders.toString(),
                icon:
                    Icons.shopping_cart_outlined,
              ),
              _DashboardCardData(
                title: 'Pending Orders',
                value:
                    stats.pendingOrders
                        .toString(),
                icon:
                    Icons.pending_actions_outlined,
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildSalesCard(
            context,
            stats.totalSales,
          ),

          const SizedBox(height: 28),

          _buildReportsAnalysis(
            context,
            stats,
          ),

          const SizedBox(height: 28),

          _buildPaymentManagement(
            context,
          ),

          const SizedBox(height: 28),

          _buildRecentActivity(
            context,
          ),

          const SizedBox(height: 28),

          _buildAuditLogs(
            context,
          ),

          const SizedBox(height: 28),

          _buildQuickOverview(
            context,
            stats,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME HEADER
  // ============================================================

  Widget _buildWelcomeHeader(
    BuildContext context,
  ) {
    final user =
        _authService.currentUser;

    final isLeader =
        user?.isLeaderAdmin ?? false;

    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        color:
            colorScheme.primaryContainer,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                colorScheme.primary,
            child: Icon(
              isLeader
                  ? Icons.verified_user_outlined
                  : Icons
                      .admin_panel_settings_outlined,
              color:
                  colorScheme.onPrimary,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ??
                      'Administrator',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 6),

                Text(
                  isLeader
                      ? 'Leader Admin'
                      : 'Normal Admin',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  'Monitor business activity and payments.',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall,
                ),
              ],
            ),
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
          .titleMedium
          ?.copyWith(
            fontWeight:
                FontWeight.bold,
          ),
    );
  }

  // ============================================================
  // TWO COLUMN CARDS
  // ============================================================

  Widget _buildTwoColumnCards(
    BuildContext context,
    List<_DashboardCardData> cards,
  ) {
    final rows = <Widget>[];

    for (int i = 0;
        i < cards.length;
        i += 2) {
      final first = cards[i];

      final second =
          i + 1 < cards.length
              ? cards[i + 1]
              : null;

      rows.add(
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                first,
              ),
            ),
            if (second != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  second,
                ),
              ),
            ],
          ],
        ),
      );

      if (i + 2 < cards.length) {
        rows.add(
          const SizedBox(height: 12),
        );
      }
    }

    return Column(
      children: rows,
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard(
    BuildContext context,
    _DashboardCardData data,
  ) {
    final color =
        Theme.of(context)
            .colorScheme
            .primary;

    return Container(
      height: 130,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color:
            color.withValues(alpha: 0.08),
        border: Border.all(
          color:
              color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            color: color,
            size: 28,
          ),

          const SizedBox(height: 14),

          Text(
            data.value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(height: 3),

          Text(
            data.title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SALES CARD
  // ============================================================

  Widget _buildSalesCard(
    BuildContext context,
    double totalSales,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color:
            colorScheme.secondaryContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            size: 34,
            color: colorScheme
                .onSecondaryContainer,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Sales',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  _formatMoney(
                    totalSales,
                  ),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORTS & ANALYSIS
  // ============================================================

  Widget _buildReportsAnalysis(
    BuildContext context,
    AdminDashboardStats stats,
  ) {
    final totalOrders =
        stats.orders;

    final pendingOrders =
        stats.pendingOrders;

    final completedOrders =
        totalOrders > pendingOrders
            ? totalOrders - pendingOrders
            : 0;

    final lowStock =
        stats.lowStockProducts;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                ),

                const SizedBox(width: 10),

                Text(
                  'Reports & Analysis',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildAnalysisRow(
              context,
              icon:
                  Icons.shopping_cart_outlined,
              title: 'Orders',
              value:
                  '$totalOrders total orders',
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon:
                  Icons.pending_actions_outlined,
              title: 'Pending Orders',
              value:
                  '$pendingOrders pending',
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon:
                  Icons.check_circle_outline,
              title: 'Other Orders',
              value:
                  '$completedOrders orders',
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon:
                  Icons.warning_amber_outlined,
              title: 'Inventory Risk',
              value:
                  '$lowStock low-stock products',
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon:
                  Icons.payments_outlined,
              title: 'Sales',
              value:
                  _formatMoney(
                stats.totalSales,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANALYSIS ROW
  // ============================================================

  Widget _buildAnalysisRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final color =
        Theme.of(context)
            .colorScheme
            .primary;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.end,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT MANAGEMENT
  // ============================================================

  Widget _buildPaymentManagement(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                  ),
                  child: Icon(
                    Icons
                        .account_balance_wallet_outlined,
                    color:
                        Theme.of(context)
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
                        'Payment Management',
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Review and manage customer payments.',
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodySmall,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip:
                      'Refresh payments',
                  onPressed:
                      _isPaymentsLoading
                          ? null
                          : _loadPayments,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildPaymentFilters(
              context,
            ),

            const SizedBox(height: 18),

            if (_isPaymentsLoading)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 30,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_payments.isEmpty)
              _buildEmptyPayments(
                context,
              )
            else
              ..._payments.map(
                (payment) =>
                    _buildPaymentCard(
                  context,
                  payment,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT FILTERS
  // ============================================================

  Widget _buildPaymentFilters(
    BuildContext context,
  ) {
    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children: [
          _paymentFilterChip(
            label: 'All',
            value: 'all',
          ),

          const SizedBox(width: 8),

          _paymentFilterChip(
            label: 'Pending',
            value:
                PaymentService.pending,
          ),

          const SizedBox(width: 8),

          _paymentFilterChip(
            label: 'Completed',
            value:
                PaymentService.completed,
          ),

          const SizedBox(width: 8),

          _paymentFilterChip(
            label: 'Failed',
            value:
                PaymentService.failed,
          ),

          const SizedBox(width: 8),

          _paymentFilterChip(
            label: 'Cancelled',
            value:
                PaymentService.cancelled,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT FILTER CHIP
  // ============================================================

  Widget _paymentFilterChip({
    required String label,
    required String value,
  }) {
    return FilterChip(
      label: Text(label),
      selected:
          _paymentFilter == value,
      onSelected: (_) {
        _changePaymentFilter(
          value,
        );
      },
    );
  }

  // ============================================================
  // EMPTY PAYMENTS
  // ============================================================

  Widget _buildEmptyPayments(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Column(
        children: [
          Icon(
            Icons.payments_outlined,
            size: 52,
            color:
                Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
          ),

          const SizedBox(height: 12),

          Text(
            'No payments found.',
            style:
                Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
          ),

          const SizedBox(height: 6),

          Text(
            _paymentFilter == 'all'
                ? 'There are no payments in the system yet.'
                : 'There are no ${_statusDisplayName(_paymentFilter).toLowerCase()} payments.',
            textAlign:
                TextAlign.center,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    final paymentId =
        payment['payment_id']
                ?.toString() ??
            '';

    final orderId =
        payment['order_id']
                ?.toString() ??
            '';

    final amount =
        _toDouble(
      payment['amount'],
    );

    final method =
        payment['payment_method']
                ?.toString() ??
            'cash';

    final status =
        payment['payment_status']
                ?.toString() ??
            PaymentService.pending;

    final reference =
        payment['transaction_reference']
            ?.toString();

    final buyerName =
        payment['buyer_name']
                ?.toString() ??
            'Unknown buyer';

    final sellerName =
        payment['seller_name']
                ?.toString() ??
            'Unknown seller';

    final productName =
        payment['product_name']
                ?.toString() ??
            'Unknown product';

    final createdAt =
        payment['payment_created_at']
            ?.toString();

    final statusColor =
        _paymentStatusColor(
      context,
      status,
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  color: statusColor
                      .withValues(
                    alpha: 0.10,
                  ),
                ),
                child: Icon(
                  _paymentMethodIcon(
                    method,
                  ),
                  color:
                      statusColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentMethodDisplayName(
                        method,
                      ),
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      productName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  color: statusColor
                      .withValues(
                    alpha: 0.10,
                  ),
                ),
                child: Text(
                  _statusDisplayName(
                    status,
                  ),
                  style: TextStyle(
                    color:
                        statusColor,
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              color:
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Text(
                  'Amount',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium,
                ),

                const Spacer(),

                Text(
                  _formatMoney(amount),
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildPaymentInfoRow(
            context,
            'Payment ID',
            paymentId,
          ),

          const SizedBox(height: 8),

          _buildPaymentInfoRow(
            context,
            'Order ID',
            orderId,
          ),

          const SizedBox(height: 8),

          _buildPaymentInfoRow(
            context,
            'Buyer',
            buyerName,
          ),

          const SizedBox(height: 8),

          _buildPaymentInfoRow(
            context,
            'Seller',
            sellerName,
          ),

          const SizedBox(height: 8),

          _buildPaymentInfoRow(
            context,
            'Reference',
            reference == null ||
                    reference.trim().isEmpty
                ? 'Not provided'
                : reference,
          ),

          if (createdAt != null &&
              createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),

            _buildPaymentInfoRow(
              context,
              'Created',
              _formatDateTime(
                createdAt,
              ),
            ),
          ],

          if (status ==
              PaymentService.pending) ...[
            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _updatePaymentStatus(
                      paymentId:
                          paymentId,
                      status:
                          PaymentService
                              .completed,
                    );
                  },
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label:
                      const Text(
                    'Complete',
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    _updatePaymentStatus(
                      paymentId:
                          paymentId,
                      status:
                          PaymentService
                              .failed,
                    );
                  },
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label:
                      const Text(
                    'Failed',
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    _updatePaymentStatus(
                      paymentId:
                          paymentId,
                      status:
                          PaymentService
                              .cancelled,
                    );
                  },
                  icon: const Icon(
                    Icons.block_outlined,
                  ),
                  label:
                      const Text(
                    'Cancel',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT INFO ROW
  // ============================================================

  Widget _buildPaymentInfoRow(
    BuildContext context,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            title,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.end,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  Widget _buildRecentActivity(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                  ),
                  child: Icon(
                    Icons.history,
                    color:
                        Theme.of(context)
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
                        'Recent Activity',
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latest actions performed in the system.',
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodySmall,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Refresh activity',
                  onPressed:
                      _isLogsLoading
                          ? null
                          : _loadLogs,
                  icon:
                      const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (_isLogsLoading)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 30,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_activityLogs.isEmpty)
              _buildEmptyActivityLogs(
                context,
              )
            else
              ..._activityLogs.map(
                (log) =>
                    _buildActivityLogCard(
                  context,
                  log,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVITY LOG CARD
  // ============================================================

  Widget _buildActivityLogCard(
    BuildContext context,
    Map<String, dynamic> log,
  ) {
    final userName =
        log['user_name']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? log['user_name'].toString()
        : 'System';

    final action =
        log['action']
                ?.toString() ??
            'Unknown action';

    final description =
        log['description']
                ?.toString() ??
            '';

    final type =
        log['type']
                ?.toString() ??
            'general';

    final createdAt =
        log['created_at']
            ?.toString();

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        color:
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor:
                Theme.of(context)
                    .colorScheme
                    .primaryContainer,
            child: Icon(
              _activityIcon(type),
              size: 21,
              color:
                  Theme.of(context)
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
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _displayAction(action),
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                      ),
                    ),

                    if (createdAt != null &&
                        createdAt.isNotEmpty)
                      const SizedBox(width: 8),

                    if (createdAt != null &&
                        createdAt.isNotEmpty)
                      Text(
                        _formatDateTime(
                          createdAt,
                        ),
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodySmall,
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  userName,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w600,
                          ),
                ),

                if (description
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall,
                  ),
                ],

                const SizedBox(height: 7),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(
                              alpha: 0.08,
                            ),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY ACTIVITY LOGS
  // ============================================================

  Widget _buildEmptyActivityLogs(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 25,
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 52,
            color:
                Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
          ),

          const SizedBox(height: 12),

          Text(
            'No activity recorded yet.',
            style:
                Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
          ),

          const SizedBox(height: 6),

          Text(
            'System activity will appear here as users perform actions.',
            textAlign:
                TextAlign.center,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AUDIT LOGS
  // ============================================================

  Widget _buildAuditLogs(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    color:
                        Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                  ),
                  child: Icon(
                    Icons
                        .admin_panel_settings_outlined,
                    color:
                        Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit Log',
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tracked changes and important system operations.',
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodySmall,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Refresh audit log',
                  onPressed:
                      _isLogsLoading
                          ? null
                          : _loadLogs,
                  icon:
                      const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (_isLogsLoading)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 30,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_auditLogs.isEmpty)
              _buildEmptyAuditLogs(
                context,
              )
            else
              ..._auditLogs.map(
                (log) =>
                    _buildAuditLogCard(
                  context,
                  log,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AUDIT LOG CARD
  // ============================================================

  Widget _buildAuditLogCard(
    BuildContext context,
    Map<String, dynamic> log,
  ) {
    final userName =
        log['user_name']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? log['user_name'].toString()
        : 'System';

    final action =
        log['action']
                ?.toString() ??
            'Unknown action';

    final entityType =
        log['entity_type']
                ?.toString()
                .trim();

    final entityId =
        log['entity_id']
                ?.toString()
                .trim();

    final description =
        log['description']
                ?.toString() ??
            '';

    final createdAt =
        log['created_at']
            ?.toString();

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Theme.of(context)
                  .colorScheme
                  .outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons
                    .verified_user_outlined,
                size: 22,
                color:
                    Theme.of(context)
                        .colorScheme
                        .primary,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _displayAction(action),
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),
              ),

              if (createdAt != null &&
                  createdAt.isNotEmpty)
                Text(
                  _formatDateTime(
                    createdAt,
                  ),
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall,
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            userName,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
          ),

          if (description
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              description,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall,
            ),
          ],

          if ((entityType != null &&
                  entityType.isNotEmpty) ||
              (entityId != null &&
                  entityId.isNotEmpty)) ...[
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (entityType != null &&
                    entityType.isNotEmpty)
                  _buildAuditTag(
                    context,
                    'Entity: $entityType',
                  ),
                if (entityId != null &&
                    entityId.isNotEmpty)
                  _buildAuditTag(
                    context,
                    'ID: $entityId',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // AUDIT TAG
  // ============================================================

  Widget _buildAuditTag(
    BuildContext context,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(8),
        color:
            Theme.of(context)
                .colorScheme
                .secondaryContainer,
      ),
      child: Text(
        text,
        style:
            Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.w600,
                ),
      ),
    );
  }

  // ============================================================
  // EMPTY AUDIT LOGS
  // ============================================================

  Widget _buildEmptyAuditLogs(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 25,
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .admin_panel_settings_outlined,
            size: 52,
            color:
                Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
          ),

          const SizedBox(height: 12),

          Text(
            'No audit records yet.',
            style:
                Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
          ),

          const SizedBox(height: 6),

          Text(
            'Important changes will appear here automatically.',
            textAlign:
                TextAlign.center,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY ICON
  // ============================================================

  IconData _activityIcon(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'authentication':
        return Icons.login_outlined;

      case 'admin':
        return Icons
            .admin_panel_settings_outlined;

      case 'user':
        return Icons.person_outline;

      case 'product':
        return Icons.inventory_2_outlined;

      case 'cart':
        return Icons.shopping_cart_outlined;

      case 'order':
        return Icons.receipt_long_outlined;

      case 'payment':
        return Icons.payments_outlined;

      case 'notification':
        return Icons.notifications_outlined;

      default:
        return Icons.history;
    }
  }

  // ============================================================
  // DISPLAY ACTION
  // ============================================================

  String _displayAction(
    String action,
  ) {
    if (action.trim().isEmpty) {
      return 'Unknown action';
    }

    final normalized =
        action.trim().replaceAll(
              '_',
              ' ',
            );

    return normalized
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) {
              return word;
            }

            return word[0].toUpperCase() +
                word.substring(1).toLowerCase();
          },
        )
        .join(' ');
  }

  // ============================================================
  // QUICK OVERVIEW
  // ============================================================

  Widget _buildQuickOverview(
    BuildContext context,
    AdminDashboardStats stats,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Overview',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
            ),

            const SizedBox(height: 16),

            _buildOverviewRow(
              context,
              icon:
                  Icons.inventory_2_outlined,
              title: 'Inventory',
              value:
                  '${stats.products} products',
            ),

            const Divider(height: 24),

            _buildOverviewRow(
              context,
              icon:
                  Icons.warning_amber_outlined,
              title: 'Stock Alerts',
              value:
                  '${stats.lowStockProducts} low-stock products',
            ),

            const Divider(height: 24),

            _buildOverviewRow(
              context,
              icon:
                  Icons.shopping_cart_outlined,
              title: 'Orders',
              value:
                  '${stats.pendingOrders} pending',
            ),

            const Divider(height: 24),

            _buildOverviewRow(
              context,
              icon:
                  Icons.people_outline,
              title: 'Users',
              value:
                  '${stats.totalUsers} registered users',
            ),

            const Divider(height: 24),

            _buildOverviewRow(
              context,
              icon:
                  Icons.payments_outlined,
              title: 'Sales',
              value:
                  _formatMoney(
                stats.totalSales,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW ROW
  // ============================================================

  Widget _buildOverviewRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color:
              Theme.of(context)
                  .colorScheme
                  .primary,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.end,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState({
    String? message,
  }) {
    final error =
        message ??
        _errorMessage ??
        'Something went wrong.';

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color:
                  Colors.grey.shade500,
            ),

            const SizedBox(height: 16),

            Text(
              error,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed:
                  _loadDashboard,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT STATUS COLOR
  // ============================================================

  Color _paymentStatusColor(
    BuildContext context,
    String status,
  ) {
    switch (status.toLowerCase()) {
      case PaymentService.completed:
        return Colors.green;

      case PaymentService.failed:
        return Colors.red;

      case PaymentService.cancelled:
        return Colors.orange;

      case PaymentService.pending:
      default:
        return Theme.of(context)
            .colorScheme
            .primary;
    }
  }

  // ============================================================
  // PAYMENT METHOD ICON
  // ============================================================

  IconData _paymentMethodIcon(
    String method,
  ) {
    switch (method.toLowerCase()) {
      case PaymentService.mpesa:
      case PaymentService.tigopesa:
      case PaymentService.airtelmoney:
        return Icons.phone_android_outlined;

      case PaymentService.bank:
        return Icons.account_balance_outlined;

      case PaymentService.cash:
        return Icons.payments_outlined;

      default:
        return Icons
            .account_balance_wallet_outlined;
    }
  }

  // ============================================================
  // PAYMENT METHOD DISPLAY
  // ============================================================

  String _paymentMethodDisplayName(
    String method,
  ) {
    switch (method.toLowerCase()) {
      case PaymentService.mpesa:
        return 'M-Pesa';

      case PaymentService.tigopesa:
        return 'Tigo Pesa';

      case PaymentService.airtelmoney:
        return 'Airtel Money';

      case PaymentService.bank:
        return 'Bank Transfer';

      case PaymentService.cash:
        return 'Cash';

      default:
        return method;
    }
  }

  // ============================================================
  // STATUS DISPLAY
  // ============================================================

  String _statusDisplayName(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case PaymentService.pending:
        return 'Pending';

      case PaymentService.completed:
        return 'Completed';

      case PaymentService.failed:
        return 'Failed';

      case PaymentService.cancelled:
        return 'Cancelled';

      default:
        return status;
    }
  }

  // ============================================================
  // MONEY FORMAT
  // ============================================================

  String _formatMoney(
    double amount,
  ) {
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
    String value,
  ) {
    final date =
        DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final local =
        date.toLocal();

    final day =
        local.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        local.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        local.year.toString();

    final hour =
        local.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        local.minute.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/$year $hour:$minute';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }
}

// ============================================================
// DASHBOARD CARD DATA
// ============================================================

class _DashboardCardData {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}