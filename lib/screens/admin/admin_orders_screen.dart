import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState
    extends State<AdminOrdersScreen> {
  final OrderService _orderService =
      OrderService.instance;

  final AuthService _authService =
      AuthService.instance;

  List<Order> _orders = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // ============================================================
  // LOAD ALL ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _authService.refreshCurrentUser();

      final currentUser =
          _authService.currentUser;

      if (currentUser == null ||
          !currentUser.isAnyAdmin) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage =
              'You do not have permission to view orders.';
        });

        return;
      }

      final orders =
          await _orderService.getOrders();

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load orders: $e';
      });
    }
  }

  // ============================================================
  // FILTER ORDERS
  // ============================================================

  List<Order> get _filteredOrders {
    if (_selectedStatus == 'all') {
      return _orders;
    }

    return _orders.where((order) {
      return order.status
              .trim()
              .toLowerCase() ==
          _selectedStatus;
    }).toList();
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
          title: const Text('Admin Orders'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to view orders.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
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
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildStatusFilter(),
          const SizedBox(height: 16),
          _buildOrdersList(),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    final pending = _countStatus('pending');
    final confirmed = _countStatus('confirmed');
    final processing = _countStatus('processing');
    final shipped = _countStatus('shipped');
    final delivered = _countStatus('delivered');
    final cancelled = _countStatus('cancelled');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildSummaryItem(
                  'Total',
                  _orders.length,
                  Icons.shopping_cart_outlined,
                ),
                _buildSummaryItem(
                  'Pending',
                  pending,
                  Icons.pending_actions_outlined,
                ),
                _buildSummaryItem(
                  'Confirmed',
                  confirmed,
                  Icons.check_circle_outline,
                ),
                _buildSummaryItem(
                  'Processing',
                  processing,
                  Icons.sync_outlined,
                ),
                _buildSummaryItem(
                  'Shipped',
                  shipped,
                  Icons.local_shipping_outlined,
                ),
                _buildSummaryItem(
                  'Delivered',
                  delivered,
                  Icons.done_all_outlined,
                ),
                _buildSummaryItem(
                  'Cancelled',
                  cancelled,
                  Icons.cancel_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY ITEM
  // ============================================================

  Widget _buildSummaryItem(
    String title,
    int value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            '$title: $value',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Widget _buildStatusFilter() {
    const statuses = [
      'all',
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Filter by status',
            border: OutlineInputBorder(),
            prefixIcon:
                Icon(Icons.filter_list),
          ),
          items: statuses.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                _formatStatus(status),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedStatus = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // ORDERS LIST
  // ============================================================

  Widget _buildOrdersList() {
    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 60,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 16),
              Text(
                _selectedStatus == 'all'
                    ? 'No orders found.'
                    : 'No ${_formatStatus(_selectedStatus).toLowerCase()} orders found.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        return Padding(
          padding:
              const EdgeInsets.only(bottom: 12),
          child: _buildOrderCard(order),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(Order order) {
    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          _showOrderDetails(order);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusChip(
                    order.status,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _buildInfoRow(
                Icons.person_outline,
                'Buyer',
                order.buyerId,
              ),

              const SizedBox(height: 8),

              _buildInfoRow(
                Icons.storefront_outlined,
                'Seller',
                order.sellerId,
              ),

              const SizedBox(height: 8),

              _buildInfoRow(
                Icons.inventory_2_outlined,
                'Product',
                order.productId,
              ),

              const SizedBox(height: 8),

              _buildInfoRow(
                Icons.shopping_basket_outlined,
                'Quantity',
                order.quantity.toString(),
              ),

              const Divider(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  ),
                  Text(
                    _formatMoney(
                      order.totalAmount,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                _formatDate(order.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(String status) {
    final normalized =
        status.trim().toLowerCase();

    IconData icon;

    switch (normalized) {
      case 'pending':
        icon = Icons.pending_actions_outlined;
        break;

      case 'confirmed':
        icon = Icons.check_circle_outline;
        break;

      case 'processing':
        icon = Icons.sync_outlined;
        break;

      case 'shipped':
        icon = Icons.local_shipping_outlined;
        break;

      case 'delivered':
        icon = Icons.done_all_outlined;
        break;

      case 'cancelled':
        icon = Icons.cancel_outlined;
        break;

      default:
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(
        icon,
        size: 17,
      ),
      label: Text(
        _formatStatus(normalized),
      ),
    );
  }

  // ============================================================
  // ORDER DETAILS
  // ============================================================

  void _showOrderDetails(Order order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              32,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 20),

                _buildDetailRow(
                  'Order ID',
                  order.id,
                ),

                _buildDetailRow(
                  'Status',
                  _formatStatus(
                    order.status,
                  ),
                ),

                _buildDetailRow(
                  'Buyer ID',
                  order.buyerId,
                ),

                _buildDetailRow(
                  'Seller ID',
                  order.sellerId,
                ),

                _buildDetailRow(
                  'Product ID',
                  order.productId,
                ),

                _buildDetailRow(
                  'Quantity',
                  order.quantity.toString(),
                ),

                _buildDetailRow(
                  'Unit Price',
                  _formatMoney(
                    order.unitPrice,
                  ),
                ),

                _buildDetailRow(
                  'Total Amount',
                  _formatMoney(
                    order.totalAmount,
                  ),
                ),

                _buildDetailRow(
                  'Created By',
                  order.createdBy,
                ),

                _buildDetailRow(
                  'Created At',
                  _formatDate(
                    order.createdAt,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child:
                        const Text('Close'),
                  ),
                ),
              ],
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
          const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
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
          mainAxisAlignment:
              MainAxisAlignment.center,
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
              onPressed: _loadOrders,
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COUNT STATUS
  // ============================================================

  int _countStatus(String status) {
    return _orders.where((order) {
      return order.status
              .trim()
              .toLowerCase() ==
          status;
    }).length;
  }

  // ============================================================
  // FORMAT STATUS
  // ============================================================

  String _formatStatus(String status) {
    if (status.isEmpty) {
      return 'Unknown';
    }

    if (status == 'all') {
      return 'All Orders';
    }

    return status[0].toUpperCase() +
        status.substring(1).toLowerCase();
  }

  // ============================================================
  // FORMAT MONEY
  // ============================================================

  String _formatMoney(double amount) {
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day =
        localDate.day.toString().padLeft(2, '0');

    final month =
        localDate.month.toString().padLeft(2, '0');

    final year =
        localDate.year.toString();

    final hour =
        localDate.hour.toString().padLeft(2, '0');

    final minute =
        localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}