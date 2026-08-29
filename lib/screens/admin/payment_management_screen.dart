
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/payment_service.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState
    extends State<PaymentManagementScreen> {
  final PaymentService _paymentService =
      PaymentService.instance;

  final AuthService _authService =
      AuthService.instance;

  List<Map<String, dynamic>> _payments = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ============================================================
  // LOAD PAYMENTS
  // ============================================================

  Future<void> _loadPayments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.refreshCurrentUser();

      if (!mounted) return;

      if (!_authService.isAdmin) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'You do not have permission to manage payments.';
        });

        return;
      }

      final payments =
          await _paymentService.getAllPaymentsWithPeople();

      if (!mounted) return;

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load payments: $e';
      });
    }
  }

  // ============================================================
  // FILTERED PAYMENTS
  // ============================================================

  List<Map<String, dynamic>> get _filteredPayments {
    if (_selectedFilter == 'all') {
      return _payments;
    }

    return _payments.where((payment) {
      final status = payment['payment_status']
              ?.toString()
              .toLowerCase() ??
          '';

      return status == _selectedFilter;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null || !user.isAnyAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment Management'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to manage payments.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadPayments,
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

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          _buildSummary(context),

          const SizedBox(height: 24),

          _buildFilterSection(context),

          const SizedBox(height: 16),

          if (_filteredPayments.isEmpty)
            _buildEmptyState()
          else
            ..._filteredPayments.map(
              (payment) => _buildPaymentCard(
                context,
                payment,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(BuildContext context) {
    final total = _payments.length;

    final pending = _countByStatus(
      PaymentService.pending,
    );

    final completed = _countByStatus(
      PaymentService.completed,
    );

    final failed = _countByStatus(
      PaymentService.failed,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                'Total',
                total.toString(),
                Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                context,
                'Pending',
                pending.toString(),
                Icons.pending_actions_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                'Completed',
                completed.toString(),
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                context,
                'Failed',
                failed.toString(),
                Icons.error_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _countByStatus(String status) {
    return _payments.where((payment) {
      final paymentStatus =
          payment['payment_status']
                  ?.toString()
                  .toLowerCase() ??
              '';

      return paymentStatus == status;
    }).length;
  }

  Widget _summaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final color =
        Theme.of(context).colorScheme.primary;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 105,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 26,
          ),

          const SizedBox(height: 10),

          Text(
            value,
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
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _buildFilterSection(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Payments',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                'all',
                'All',
              ),
              _filterChip(
                PaymentService.pending,
                'Pending',
              ),
              _filterChip(
                PaymentService.completed,
                'Completed',
              ),
              _filterChip(
                PaymentService.failed,
                'Failed',
              ),
              _filterChip(
                PaymentService.cancelled,
                'Cancelled',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    String value,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: FilterChip(
        label: Text(label),
        selected:
            _selectedFilter == value,
        onSelected: (_) {
          setState(() {
            _selectedFilter = value;
          });
        },
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
        payment['payment_id']?.toString() ?? '';

    final orderId =
        payment['order_id']?.toString() ?? '-';

    final productName =
        payment['product_name']?.toString() ??
            'Unknown product';

    final buyerName =
        payment['buyer_name']?.toString() ??
            'Unknown buyer';

    final amount =
        _toDouble(payment['amount']);

    final method =
        payment['payment_method']?.toString() ??
            PaymentService.cash;

    final status =
        payment['payment_status']?.toString() ??
            PaymentService.pending;

    final date =
        payment['payment_created_at']?.toString();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: paymentId.isEmpty
            ? null
            : () {
                _showPaymentDetails(
                  context,
                  payment,
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _paymentIcon(
                context,
                status,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Buyer: $buyerName',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Order: $orderId',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Method: '
                      '${_paymentMethodName(method)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),

                    if (date != null &&
                        date.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(date),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMoney(amount),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 7),

                  _statusChip(
                    context,
                    status,
                  ),

                  const SizedBox(height: 6),

                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT ICON
  // ============================================================

  Widget _paymentIcon(
    BuildContext context,
    String status,
  ) {
    final color =
        _statusColor(context, status);

    IconData icon;

    switch (status.toLowerCase()) {
      case PaymentService.completed:
        icon = Icons.check_circle_outline;
        break;

      case PaymentService.failed:
        icon = Icons.error_outline;
        break;

      case PaymentService.cancelled:
        icon = Icons.cancel_outlined;
        break;

      case PaymentService.pending:
      default:
        icon = Icons.pending_actions_outlined;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
        size: 27,
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
    BuildContext context,
    String status,
  ) {
    final color =
        _statusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _statusName(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT DETAILS
  // ============================================================

  Future<void> _showPaymentDetails(
    BuildContext context,
    Map<String, dynamic> payment,
  ) async {
    final paymentId =
        payment['payment_id']?.toString() ?? '';

    if (paymentId.isEmpty) {
      return;
    }

    try {
      final details =
          await _paymentService.getPaymentDetails(
        paymentId,
      );

      if (!context.mounted) {
        return;
      }

      if (details == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Payment details could not be found.',
            ),
          ),
        );

        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) {
          return _PaymentDetailsSheet(
            payment: details,
            onStatusChanged: _loadPayments,
          );
        },
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load payment details: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_outlined,
            size: 64,
            color: Colors.grey.shade500,
          ),

          const SizedBox(height: 16),

          const Text(
            'No payments found.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _selectedFilter == 'all'
                ? 'There are no payments yet.'
                : 'There are no '
                    '$_selectedFilter payments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
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
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _loadPayments,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
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

  String _formatMoney(double amount) {
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  String _paymentMethodName(String method) {
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

  String _statusName(String status) {
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

  Color _statusColor(
    BuildContext context,
    String status,
  ) {
    switch (status.toLowerCase()) {
      case PaymentService.completed:
        return Colors.green;

      case PaymentService.failed:
        return Colors.red;

      case PaymentService.cancelled:
        return Colors.grey;

      case PaymentService.pending:
      default:
        return Theme.of(context)
            .colorScheme
            .primary;
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final local = date.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');

    final month =
        local.month.toString().padLeft(2, '0');

    final year =
        local.year.toString();

    final hour =
        local.hour.toString().padLeft(2, '0');

    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

// ============================================================
// PAYMENT DETAILS SHEET
// ============================================================

class _PaymentDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onStatusChanged;

  const _PaymentDetailsSheet({
    required this.payment,
    required this.onStatusChanged,
  });

  @override
  State<_PaymentDetailsSheet> createState() =>
      _PaymentDetailsSheetState();
}

class _PaymentDetailsSheetState
    extends State<_PaymentDetailsSheet> {
  final PaymentService _paymentService =
      PaymentService.instance;

  bool _isUpdating = false;

  String get _paymentId =>
      widget.payment['payment_id']
          ?.toString() ??
      '';

  String get _status =>
      widget.payment['payment_status']
          ?.toString() ??
      PaymentService.pending;

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(
    String newStatus,
  ) async {
    if (_paymentId.isEmpty) {
      return;
    }

    if (_status.toLowerCase() == newStatus) {
      return;
    }

    final confirmed =
        await _confirmStatusChange(
      newStatus,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _paymentService.updatePaymentStatus(
        paymentId: _paymentId,
        status: newStatus,
      );

      if (!mounted) {
        return;
      }

      widget.onStatusChanged();

      Navigator.of(context).pop();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Payment marked as '
            '${_statusName(newStatus)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update payment: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CONFIRM STATUS CHANGE
  // ============================================================

  Future<bool> _confirmStatusChange(
    String newStatus,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Change Payment Status',
          ),
          content: Text(
            'Are you sure you want to mark this '
            'payment as ${_statusName(newStatus)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text('Confirm'),
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
    final payment = widget.payment;

    final amount =
        _toDouble(payment['amount']);

    final method =
        payment['payment_method']
                ?.toString() ??
            PaymentService.cash;

    final transaction =
        payment['transaction_reference']
            ?.toString();

    final orderId =
        payment['order_id']?.toString() ??
            '-';

    final buyerName =
        payment['buyer_name']?.toString() ??
            'Unknown';

    final buyerEmail =
        payment['buyer_email']?.toString() ??
            '-';

    final buyerPhone =
        payment['buyer_phone']?.toString() ??
            '-';

    final sellerName =
        payment['seller_name']?.toString() ??
            'Unknown';

    final sellerEmail =
        payment['seller_email']?.toString() ??
            '-';

    final sellerPhone =
        payment['seller_phone']?.toString() ??
            '-';

    final productName =
        payment['product_name']?.toString() ??
            'Unknown product';

    final quantity =
        payment['quantity']?.toString() ??
            '-';

    final orderStatus =
        payment['order_status']?.toString() ??
            '-';

    final createdAt =
        payment['payment_created_at']
                ?.toString() ??
            '-';

    final paidAt =
        payment['paid_at']?.toString();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom:
              MediaQuery.of(context)
                      .viewInsets
                      .bottom +
                  20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Details',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 20),

              _detailRow(
                'Payment ID',
                _paymentId,
              ),

              _detailRow(
                'Order ID',
                orderId,
              ),

              _detailRow(
                'Product',
                productName,
              ),

              _detailRow(
                'Quantity',
                quantity,
              ),

              _detailRow(
                'Amount',
                _formatMoney(amount),
              ),

              _detailRow(
                'Payment Method',
                _paymentMethodName(method),
              ),

              _detailRow(
                'Transaction Reference',
                transaction == null ||
                        transaction.trim().isEmpty
                    ? 'Not provided'
                    : transaction,
              ),

              const Divider(height: 28),

              Text(
                'Buyer',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 10),

              _detailRow(
                'Name',
                buyerName,
              ),

              _detailRow(
                'Email',
                buyerEmail,
              ),

              _detailRow(
                'Phone',
                buyerPhone,
              ),

              const Divider(height: 28),

              Text(
                'Seller',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 10),

              _detailRow(
                'Name',
                sellerName,
              ),

              _detailRow(
                'Email',
                sellerEmail,
              ),

              _detailRow(
                'Phone',
                sellerPhone,
              ),

              const Divider(height: 28),

              _detailRow(
                'Order Status',
                orderStatus,
              ),

              _detailRow(
                'Created',
                _formatDate(createdAt),
              ),

              if (paidAt != null &&
                  paidAt.trim().isNotEmpty)
                _detailRow(
                  'Paid At',
                  _formatDate(paidAt),
                ),

              const SizedBox(height: 24),

              Text(
                'Payment Status',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              _buildStatusButtons(),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BUTTONS
  // ============================================================

  Widget _buildStatusButtons() {
    if (_isUpdating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentStatus =
        _status.toLowerCase();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                currentStatus ==
                        PaymentService.completed
                    ? null
                    : () {
                        _updateStatus(
                          PaymentService.completed,
                        );
                      },
            icon: const Icon(
              Icons.check_circle_outline,
            ),
            label: const Text(
              'Mark as Completed',
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                currentStatus ==
                        PaymentService.failed
                    ? null
                    : () {
                        _updateStatus(
                          PaymentService.failed,
                        );
                      },
            icon: const Icon(
              Icons.error_outline,
            ),
            label: const Text(
              'Mark as Failed',
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                currentStatus ==
                        PaymentService.cancelled
                    ? null
                    : () {
                        _updateStatus(
                          PaymentService.cancelled,
                        );
                      },
            icon: const Icon(
              Icons.cancel_outlined,
            ),
            label: const Text(
              'Cancel Payment',
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed:
                currentStatus ==
                        PaymentService.pending
                    ? null
                    : () {
                        _updateStatus(
                          PaymentService.pending,
                        );
                      },
            icon: const Icon(
              Icons.pending_actions_outlined,
            ),
            label: const Text(
              'Set as Pending',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
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

  String _formatMoney(double amount) {
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  String _paymentMethodName(String method) {
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

  String _statusName(String status) {
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

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final local = date.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');

    final month =
        local.month.toString().padLeft(2, '0');

    final year =
        local.year.toString();

    final hour =
        local.hour.toString().padLeft(2, '0');

    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

