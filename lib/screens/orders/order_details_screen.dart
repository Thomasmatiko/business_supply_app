import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/order_details_result.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';
import 'edit_order_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;
  final Product? product;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.product,
  });

  @override
  State<OrderDetailsScreen> createState() =>
      _OrderDetailsScreenState();
}

class _OrderDetailsScreenState
    extends State<OrderDetailsScreen> {
  late Order _currentOrder;

  AppUser? _createdByUser;

  bool _isLoadingUser = true;
  bool _isUpdatingStatus = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _currentOrder = widget.order;

    _loadCreatedByUser();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadCreatedByUser() async {
    try {
      final user =
          await UserService.instance.getUserById(
        _currentOrder.createdBy,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _createdByUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to load order creator: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  // ============================================================
  // BACK
  // ============================================================

  void _goBack() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      OrderDetailsResult(
        order: _currentOrder,
        action: OrderDetailsAction.updated,
      ),
    );
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editOrder() async {
    if (_isDeleting) {
      return;
    }

    final result =
        await Navigator.of(context).push<Order>(
      MaterialPageRoute(
        builder: (context) {
          return EditOrderScreen(
            order: _currentOrder,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null) {
      setState(() {
        _currentOrder = result;
      });

      await _loadCreatedByUser();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order updated successfully.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteOrder() async {
    if (_isDeleting) {
      return;
    }

    if (_currentOrder.status.toLowerCase() !=
        'pending') {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Cannot Delete Order',
            ),
            content: Text(
              'Only pending orders can be deleted.\n\n'
              'This order is currently '
              '${_currentOrder.status.toUpperCase()}.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );

      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Order',
          ),
          content: const Text(
            'Are you sure you want to delete this order?\n\n'
            'The ordered quantity will be returned to product stock.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final deleted =
          await OrderService.instance.deleteOrderWithStock(
        _currentOrder.id,
      );

      if (!mounted) {
        return;
      }

      if (deleted) {
        Navigator.of(context).pop(
          OrderDetailsResult(
            order: _currentOrder,
            action: OrderDetailsAction.deleted,
          ),
        );
      } else {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The order could not be deleted.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting order: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  List<String> _allowedNextStatuses() {
    switch (_currentOrder.status.toLowerCase()) {
      case 'pending':
        return [
          'confirmed',
          'cancelled',
        ];

      case 'confirmed':
        return [
          'processing',
        ];

      case 'processing':
        return [
          'shipped',
        ];

      case 'shipped':
        return [
          'delivered',
        ];

      case 'delivered':
      case 'cancelled':
      default:
        return [];
    }
  }

  Future<void> _showStatusDialog() async {
    if (_isUpdatingStatus || _isDeleting) {
      return;
    }

    final allowedStatuses =
        _allowedNextStatuses();

    if (allowedStatuses.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          final status =
              _currentOrder.status.toLowerCase();

          String message;

          if (status == 'delivered') {
            message =
                'This order has already been delivered and cannot be changed.';
          } else if (status == 'cancelled') {
            message =
                'This order has been cancelled and cannot be changed.';
          } else {
            message =
                'There are no available status changes.';
          }

          return AlertDialog(
            title: const Text(
              'Order Status',
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Close',
                ),
              ),
            ],
          );
        },
      );

      return;
    }

    final selectedStatus =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Update Order Status',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                allowedStatuses.map((status) {
              return ListTile(
                leading: Icon(
                  Icons.arrow_forward,
                  color: _statusColor(status),
                ),
                title: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        _statusColor(status),
                  ),
                ),
                onTap: () {
                  Navigator.of(context)
                      .pop(status);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
              ),
            ),
          ],
        );
      },
    );

    if (selectedStatus == null) {
      return;
    }

    await _updateOrderStatus(
      selectedStatus,
    );
  }

  Future<void> _updateOrderStatus(
    String newStatus,
  ) async {
    if (_isUpdatingStatus) {
      return;
    }

    final currentUser =
        AuthService.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No logged-in user.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final result =
          await OrderService.instance.updateOrderStatus(
        _currentOrder.id,
        newStatus,
        currentUser.id,
      );

      if (!mounted) {
        return;
      }

      if (result > 0) {
        setState(() {
          _currentOrder =
              _currentOrder.copyWith(
            status: newStatus,
          );
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to '
              '${newStatus.toUpperCase()}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update order status.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error updating order status: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _formatCurrency(
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

      formatted.add(reversed[i]);
    }

    return 'TZS ${formatted.reversed.join()}';
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  String _formatDateTime(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/$year '
        '$hour:$minute';
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
  // PRODUCT
  // ============================================================

  String _productName() {
    return widget.product?.name ??
        _currentOrder.productId;
  }

  // ============================================================
  // CREATED BY
  // ============================================================

  String _createdByName() {
    if (_isLoadingUser) {
      return 'Loading...';
    }

    return _createdByUser?.name ??
        _currentOrder.createdBy;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final statusColor =
        _statusColor(
      _currentOrder.status,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          tooltip: 'Back',
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            onPressed:
                _isDeleting
                    ? null
                    : _editOrder,
            icon: const Icon(
              Icons.edit,
            ),
            tooltip: 'Edit Order',
          ),
          IconButton(
            onPressed:
                _isDeleting
                    ? null
                    : _deleteOrder,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.delete,
                  ),
            tooltip: 'Delete Order',
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ORDER ICON
            // ==================================================

            Center(
              child: Icon(
                Icons.receipt_long,
                size: 70,
                color:
                    Theme.of(context)
                        .colorScheme
                        .primary,
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // ORDER ID
            // ==================================================

            Center(
              child: Text(
                'Order ${_currentOrder.id}',
                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // STATUS
            // ==================================================

            Center(
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      statusColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  _currentOrder.status
                      .toUpperCase(),
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // UPDATE STATUS
            // ==================================================

            Center(
              child:
                  OutlinedButton.icon(
                onPressed:
                    _isUpdatingStatus ||
                            _isDeleting
                        ? null
                        : _showStatusDialog,
                icon:
                    _isUpdatingStatus
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.sync,
                          ),
                label: Text(
                  _isUpdatingStatus
                      ? 'Updating...'
                      : 'Update Status',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // BUYER
            // ==================================================

            _buildSectionTitle(
              'Buyer',
            ),

            _buildInfoCard(
              children: [
                _buildInfoRow(
                  'Buyer ID',
                  _currentOrder.buyerId,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SELLER
            // ==================================================

            _buildSectionTitle(
              'Seller',
            ),

            _buildInfoCard(
              children: [
                _buildInfoRow(
                  'Seller ID',
                  _currentOrder.sellerId,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PRODUCT
            // ==================================================

            _buildSectionTitle(
              'Product',
            ),

            _buildInfoCard(
              children: [
                _buildInfoRow(
                  'Product',
                  _productName(),
                ),
                _buildInfoRow(
                  'Quantity',
                  '${_currentOrder.quantity}',
                ),
                _buildInfoRow(
                  'Unit Price',
                  _formatCurrency(
                    _currentOrder.unitPrice,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ORDER SUMMARY
            // ==================================================

            _buildSectionTitle(
              'Order Summary',
            ),

            _buildInfoCard(
              children: [
                _buildInfoRow(
                  'Total Amount',
                  _formatCurrency(
                    _currentOrder.totalAmount,
                  ),
                  valueBold: true,
                ),
                _buildInfoRow(
                  'Order Date',
                  _formatDate(
                    _currentOrder.createdAt,
                  ),
                ),
                _buildInfoRow(
                  'Created At',
                  _formatDateTime(
                    _currentOrder.createdAt,
                  ),
                ),
                _buildInfoRow(
                  'Created By',
                  _createdByName(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==================================================
            // IDS
            // ==================================================

            _buildInfoCard(
              children: [
                if (widget.product != null)
                  _buildInfoRow(
                    'Product ID',
                    widget.product!.id,
                  ),

                _buildInfoRow(
                  'Buyer ID',
                  _currentOrder.buyerId,
                ),

                _buildInfoRow(
                  'Seller ID',
                  _currentOrder.sellerId,
                ),

                _buildInfoRow(
                  'Order ID',
                  _currentOrder.id,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _isDeleting
                            ? null
                            : _editOrder,
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'Edit Order',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      FilledButton.icon(
                    onPressed:
                        _isDeleting
                            ? null
                            : _deleteOrder,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.delete,
                          ),
                    label: Text(
                      _isDeleting
                          ? 'Deleting...'
                          : 'Delete Order',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // BACK BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: _goBack,
                icon: const Icon(
                  Icons.arrow_back,
                ),
                label: const Text(
                  'Back to Orders',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    String label,
    String value, {
    bool valueBold = false,
  }) {
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
            width: 110,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: valueBold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}