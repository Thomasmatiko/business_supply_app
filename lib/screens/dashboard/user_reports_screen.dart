import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/report_service.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() =>
      _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  final AuthService _authService = AuthService.instance;
  final ReportService _reportService = ReportService.instance;

  Map<String, dynamic>? _report;

  bool _isLoading = true;

  String? _errorMessage;

  bool get _isSeller {
    return _authService.currentUser?.isSeller ?? false;
  }

  
  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _authService.refreshCurrentUser();

      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        throw Exception('You are not logged in.');
      }

      Map<String, dynamic> report;

      if (currentUser.isSeller) {
        report = await _reportService.getSellerReport(
          currentUser,
        );
      } else if (currentUser.isBuyer) {
        report = await _reportService.getBuyerReport(
          currentUser,
        );
      } else {
        throw Exception(
          'Reports are only available for sellers and buyers.',
        );
      }

      if (!mounted) return;

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('User report error: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSeller ? 'Seller Reports' : 'My Reports',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadReport,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
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
      return _buildErrorState(context);
    }

    if (_report == null) {
      return _buildErrorState(
        context,
        message: 'Report information is unavailable.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          40,
        ),
        children: [
          _buildHeader(context),

          const SizedBox(height: 24),

          _buildSectionTitle(
            context,
            _isSeller
                ? 'Business Summary'
                : 'Shopping Summary',
          ),

          const SizedBox(height: 12),

          _buildSummaryGrid(
            context,
            _report!,
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(
            context,
            'Order Analysis',
          ),

          const SizedBox(height: 12),

          _buildOrderAnalysis(
            context,
            _report!,
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(
            context,
            'Order Status Breakdown',
          ),

          const SizedBox(height: 12),

          _buildOrderStatusBreakdown(
            context,
            _report!,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final title = _isSeller
        ? 'Seller Reports'
        : 'My Shopping Reports';

    final description = _isSeller
        ? 'Track your products, orders, sales and business performance.'
        : 'Track your orders, spending and purchased items.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.primaryContainer,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.primary,
            ),
            child: Icon(
              _isSeller
                  ? Icons.analytics_outlined
                  : Icons.shopping_bag_outlined,
              color: colorScheme.onPrimary,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

                const SizedBox(height: 6),

                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
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
          .titleLarge
          ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ============================================================
  // SUMMARY GRID
  // ============================================================

  Widget _buildSummaryGrid(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    if (_isSeller) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.25,
        children: [
          _buildSummaryCard(
            context,
            title: 'My Products',
            value: _toInt(report['products']).toString(),
            icon: Icons.inventory_2_outlined,
          ),
          _buildSummaryCard(
            context,
            title: 'My Orders',
            value: _toInt(report['orders']).toString(),
            icon: Icons.shopping_cart_outlined,
          ),
          _buildSummaryCard(
            context,
            title: 'Total Sales',
            value: _formatMoney(
              _toDouble(report['totalSales']),
            ),
            icon: Icons.payments_outlined,
          ),
          _buildSummaryCard(
            context,
            title: 'Units Sold',
            value: _toInt(report['unitsSold']).toString(),
            icon: Icons.inventory_outlined,
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        _buildSummaryCard(
          context,
          title: 'My Orders',
          value: _toInt(report['orders']).toString(),
          icon: Icons.receipt_long_outlined,
        ),
        _buildSummaryCard(
          context,
          title: 'Total Spent',
          value: _formatMoney(
            _toDouble(report['totalSpent']),
          ),
          icon: Icons.payments_outlined,
        ),
        _buildSummaryCard(
          context,
          title: 'Items Purchased',
          value: _toInt(report['itemsPurchased']).toString(),
          icon: Icons.shopping_bag_outlined,
        ),
        _buildSummaryCard(
          context,
          title: 'Delivered',
          value: _toInt(report['delivered']).toString(),
          icon: Icons.done_all_outlined,
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: colorScheme.primary,
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

          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER ANALYSIS
  // ============================================================

  Widget _buildOrderAnalysis(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    final total = _toInt(report['orders']);
    final pending = _toInt(report['pending']);
    final confirmed = _toInt(report['confirmed']);
    final processing = _toInt(report['processing']);
    final shipped = _toInt(report['shipped']);
    final delivered = _toInt(report['delivered']);
    final cancelled = _toInt(report['cancelled']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildAnalysisRow(
              context,
              icon: Icons.shopping_cart_outlined,
              title: 'All Orders',
              value: total.toString(),
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon: Icons.pending_actions_outlined,
              title: 'Pending',
              value: pending.toString(),
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon: Icons.check_circle_outline,
              title: 'Confirmed',
              value: confirmed.toString(),
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon: Icons.sync_outlined,
              title: 'Processing',
              value: processing.toString(),
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Shipped',
              value: shipped.toString(),
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon: Icons.done_all_outlined,
              title: 'Delivered',
              value: delivered.toString(),
            ),

            const Divider(height: 24),

            _buildAnalysisRow(
              context,
              icon: Icons.cancel_outlined,
              title: 'Cancelled',
              value: cancelled.toString(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ORDER STATUS BREAKDOWN
  // ============================================================

  Widget _buildOrderStatusBreakdown(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    final total = _toInt(report['orders']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildStatusBar(
              context,
              title: 'Pending',
              count: _toInt(report['pending']),
              total: total,
            ),

            const SizedBox(height: 18),

            _buildStatusBar(
              context,
              title: 'Confirmed',
              count: _toInt(report['confirmed']),
              total: total,
            ),

            const SizedBox(height: 18),

            _buildStatusBar(
              context,
              title: 'Processing',
              count: _toInt(report['processing']),
              total: total,
            ),

            const SizedBox(height: 18),

            _buildStatusBar(
              context,
              title: 'Shipped',
              count: _toInt(report['shipped']),
              total: total,
            ),

            const SizedBox(height: 18),

            _buildStatusBar(
              context,
              title: 'Delivered',
              count: _toInt(report['delivered']),
              total: total,
            ),

            const SizedBox(height: 18),

            _buildStatusBar(
              context,
              title: 'Cancelled',
              count: _toInt(report['cancelled']),
              total: total,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BAR
  // ============================================================

  Widget _buildStatusBar(
    BuildContext context, {
    required String title,
    required int count,
    required int total,
  }) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 9,
          ),
        ),
      ],
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
        Theme.of(context).colorScheme.primary;

    return Row(
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(
    BuildContext context, {
    String? message,
  }) {
    final error =
        message ??
        _errorMessage ??
        'Something went wrong.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade500,
            ),

            const SizedBox(height: 16),

            Text(
              error,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTEGER
  // ============================================================

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _formatMoney(double amount) {
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
}