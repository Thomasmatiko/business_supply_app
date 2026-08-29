
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({
    super.key,
  });

  @override
  State<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState
    extends State<PaymentHistoryScreen> {
  final AuthService _authService =
      AuthService.instance;

  final PaymentService _paymentService =
      PaymentService.instance;

  List<Map<String, dynamic>> _payments = [];

  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // BUYER ID
  // ============================================================

  String? get _buyerId {
    return _authService.currentUser?.id;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ============================================================
  // LOAD PAYMENTS
  // ============================================================

  Future<void> _loadPayments() async {
    final buyerId = _buyerId;

    if (buyerId == null ||
        buyerId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Please login as a buyer to view your payments.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final payments =
          await _paymentService.getBuyerPayments(
        buyerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            _cleanErrorMessage(e);
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshPayments() async {
    await _loadPayments();
  }

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice(double amount) {
    final amountString =
        amount.toStringAsFixed(0);

    final reversed =
        amountString.split('').reversed.toList();

    final buffer = StringBuffer();

    for (int i = 0;
        i < reversed.length;
        i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(reversed[i]);
    }

    return 'TZS ${buffer.toString().split('').reversed.join()}';
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Unknown date';
    }

    final date =
        DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final localDate =
        date.toLocal();

    final day =
        localDate.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        localDate.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        localDate.year.toString();

    final hour =
        localDate.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        localDate.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/$year $hour:$minute';
  }

  // ============================================================
  // PAYMENT METHOD LABEL
  // ============================================================

  String _methodLabel(
    String? method,
  ) {
    switch (method) {
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
        return method == null ||
                method.trim().isEmpty
            ? 'Unknown'
            : method;
    }
  }

  // ============================================================
  // PAYMENT ICON
  // ============================================================

  IconData _methodIcon(
    String? method,
  ) {
    switch (method) {
      case PaymentService.mpesa:
      case PaymentService.tigopesa:
      case PaymentService.airtelmoney:
        return Icons.phone_android;

      case PaymentService.bank:
        return Icons.account_balance;

      case PaymentService.cash:
        return Icons.payments_outlined;

      default:
        return Icons.payment;
    }
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(
    String status,
  ) {
    switch (status) {
      case PaymentService.completed:
        return Icons.check_circle;

      case PaymentService.pending:
        return Icons.pending;

      case PaymentService.failed:
        return Icons.error;

      case PaymentService.cancelled:
        return Icons.cancel;

      default:
        return Icons.help_outline;
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    BuildContext context,
    String status,
  ) {
    switch (status) {
      case PaymentService.completed:
        return Colors.green;

      case PaymentService.pending:
        return Colors.orange;

      case PaymentService.failed:
        return Colors.red;

      case PaymentService.cancelled:
        return Colors.grey;

      default:
        return Theme.of(context)
            .colorScheme
            .onSurfaceVariant;
    }
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case PaymentService.completed:
        return 'Successful';

      case PaymentService.pending:
        return 'Pending';

      case PaymentService.failed:
        return 'Failed';

      case PaymentService.cancelled:
        return 'Cancelled';

      default:
        return status.isEmpty
            ? 'Unknown'
            : status;
    }
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanErrorMessage(
    Object error,
  ) {
    final message =
        error.toString().trim();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message.isEmpty
        ? 'Unable to load payments.'
        : message;
  }

  // ============================================================
  // PAYMENT DETAILS
  // ============================================================

  Future<void> _showPaymentDetails(
    Map<String, dynamic> payment,
  ) async {
    if (!mounted) {
      return;
    }

    final paymentId =
        payment['id']?.toString() ??
            '';

    final orderId =
        payment['order_id']?.toString() ??
            '';

    final amount =
        (payment['amount'] as num?)
                ?.toDouble() ??
            0.0;

    final method =
        payment['method']?.toString();

    final status =
        payment['status']?.toString() ??
            PaymentService.pending;

    final reference =
        payment['transaction_reference']
            ?.toString();

    final createdAt =
        payment['created_at']?.toString();

    final statusColor =
        _statusColor(
      context,
      status,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Center(
                    child: Column(
                      children: [
                        Icon(
                          _statusIcon(
                            status,
                          ),
                          size: 58,
                          color:
                              statusColor,
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          _statusLabel(
                            status,
                          ),
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                statusColor,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          _formatPrice(
                            amount,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  _buildDetailRow(
                    'Payment ID',
                    paymentId,
                  ),

                  _buildDetailRow(
                    'Order ID',
                    orderId,
                  ),

                  _buildDetailRow(
                    'Method',
                    _methodLabel(method),
                  ),

                  _buildDetailRow(
                    'Amount',
                    _formatPrice(amount),
                  ),

                  _buildDetailRow(
                    'Reference',
                    reference == null ||
                            reference
                                .trim()
                                .isEmpty
                        ? 'Not provided'
                        : reference,
                  ),

                  _buildDetailRow(
                    'Status',
                    _statusLabel(status),
                  ),

                  _buildDetailRow(
                    'Created',
                    _formatDate(
                      createdAt,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      child:
                          const Text(
                        'Close',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.end,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard(
    Map<String, dynamic> payment,
  ) {
    final orderId =
        payment['order_id']?.toString() ??
            '';

    final amount =
        (payment['amount'] as num?)
                ?.toDouble() ??
            0.0;

    final method =
        payment['method']?.toString();

    final status =
        payment['status']?.toString() ??
            PaymentService.pending;

    final createdAt =
        payment['created_at']?.toString();

    final statusColor =
        _statusColor(
      context,
      status,
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          _showPaymentDetails(
            payment,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  _methodIcon(method),
                  color:
                      Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      _methodLabel(
                        method,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Order: $orderId',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: TextStyle(
                        color:
                            Theme.of(
                          context,
                        )
                                .colorScheme
                                .onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      _formatDate(
                        createdAt,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(
                          context,
                        )
                                .colorScheme
                                .onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
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
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(
                              status,
                            ),
                            size: 15,
                            color:
                                statusColor,
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Text(
                            _statusLabel(
                              status,
                            ),
                            style:
                                TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(
                      amount,
                    ),
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Theme.of(
                        context,
                      )
                              .colorScheme
                              .primary,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

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
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh:
          _refreshPayments,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                    .size
                    .height *
                0.25,
          ),

          Icon(
            Icons
                .account_balance_wallet_outlined,
            size: 80,
            color:
                Theme.of(context)
                    .colorScheme
                    .primary,
          ),

          const SizedBox(
            height: 20,
          ),

          const Center(
            child: Text(
              'No Payments Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Center(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Text(
                'Your payment history will appear here after you make a payment.',
                textAlign:
                    TextAlign.center,
              ),
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
    return RefreshIndicator(
      onRefresh:
          _refreshPayments,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                    .size
                    .height *
                0.25,
          ),

          const Icon(
            Icons.error_outline,
            size: 70,
          ),

          const SizedBox(
            height: 20,
          ),

          const Center(
            child: Text(
              'Unable to Load Payments',
              style: TextStyle(
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
                  const EdgeInsets
                      .symmetric(
                horizontal: 32,
              ),
              child: Text(
                _errorMessage ??
                    'Something went wrong.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Center(
            child:
                FilledButton.icon(
              onPressed:
                  _loadPayments,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child:
          CircularProgressIndicator(),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final isLoggedIn =
        _authService.isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Payment History',
          ),
        ),
        body:
            _buildLoginRequired(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment History',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadPayments,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _payments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh:
                          _refreshPayments,
                      child:
                          ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        itemCount:
                            _payments.length,
                        itemBuilder:
                            (context, index) {
                          return _buildPaymentCard(
                            _payments[
                                index],
                          );
                        },
                      ),
                    ),
    );
  }

  // ============================================================
  // LOGIN REQUIRED
  // ============================================================

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Please login as a buyer to view your payment history.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 24,
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              icon: const Icon(
                Icons.arrow_back,
              ),
              label:
                  const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

