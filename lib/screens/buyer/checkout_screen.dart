
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../payment/payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;

  const CheckoutScreen({
    super.key,
    required this.items,
  });

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState
    extends State<CheckoutScreen> {
  final AuthService _authService =
      AuthService.instance;

  final OrderService _orderService =
      OrderService.instance;

  bool _isSubmitting = false;

  // ============================================================
  // BUYER ID
  // ============================================================

  String? get _buyerId {
    return _authService.currentUser?.id;
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get _total {
    return widget.items.fold(
      0.0,
      (total, item) => total + item.total,
    );
  }

  // ============================================================
  // TOTAL QUANTITY
  // ============================================================

  int get _totalQuantity {
    return widget.items.fold(
      0,
      (total, item) => total + item.quantity,
    );
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

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(reversed[i]);
    }

    return 'TZS ${buffer.toString().split('').reversed.join()}';
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    CartItem item,
  ) {
    final imagePath = item.imagePath;

    if (imagePath != null &&
        imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child: Image.file(
          File(imagePath),
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder:
              (
                context,
                error,
                stackTrace,
              ) {
            return _buildImagePlaceholder();
          },
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _buildImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: Theme.of(context)
            .colorScheme
            .onPrimaryContainer,
      ),
    );
  }

  // ============================================================
  // CHECKOUT ITEM
  // ============================================================

  Widget _buildCheckoutItem(
    CartItem item,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildProductImage(item),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${item.quantity} × ${_formatPrice(item.unitPrice)}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _formatPrice(item.total),
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLACE ORDER
  //
  // FLOW:
  //
  // CART
  //   ↓
  // CHECKOUT
  //   ↓
  // CREATE ORDER(S)
  //   ↓
  // PAYMENT SCREEN
  //   ↓
  // SELECT PAYMENT METHOD
  //   ↓
  // CREATE PAYMENT
  //   ↓
  // NEXT ORDER PAYMENT
  //   ↓
  // FINISH
  //
  // IMPORTANT:
  // Every cart item becomes an order according to the
  // OrderService implementation.
  //
  // If there are multiple orders, each order gets its
  // own payment record.
  // ============================================================

  Future<void> _placeOrder() async {
    if (_isSubmitting) {
      return;
    }

    // ----------------------------------------------------------
    // CHECK CART
    // ----------------------------------------------------------

    if (widget.items.isEmpty) {
      _showMessage(
        'Your cart is empty.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK BUYER LOGIN
    // ----------------------------------------------------------

    final buyerId = _buyerId;

    if (buyerId == null ||
        buyerId.trim().isEmpty) {
      _showMessage(
        'Please login as a buyer before placing an order.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // --------------------------------------------------------
      // CREATE ORDERS FROM CART
      //
      // OrderService handles:
      //
      // - stock validation
      // - seller lookup
      // - current product price
      // - order creation
      // - stock reduction
      // - cart clearing
      // - transaction rollback
      // --------------------------------------------------------

      final List<Order> createdOrders =
          await _orderService.createOrderFromCart(
        buyerId: buyerId,
        cartItems: widget.items,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // CHECK RESULT
      // --------------------------------------------------------

      if (createdOrders.isEmpty) {
        _showMessage(
          'Unable to place order.',
        );
        return;
      }

      // --------------------------------------------------------
      // PAYMENT PROCESS
      // --------------------------------------------------------

      int completedPayments = 0;

      for (
        int i = 0;
        i < createdOrders.length;
        i++
      ) {
        if (!mounted) {
          return;
        }

        final order =
            createdOrders[i];

        // ------------------------------------------------------
        // OPEN PAYMENT SCREEN
        // ------------------------------------------------------

        final paymentResult =
            await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PaymentScreen(
              order: order,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        // ------------------------------------------------------
        // PAYMENT COMPLETED
        // ------------------------------------------------------

        if (paymentResult == true) {
          completedPayments++;
          continue;
        }

        // ------------------------------------------------------
        // PAYMENT NOT COMPLETED
        // ------------------------------------------------------

        await _showPaymentIncompleteDialog(
          order: order,
          completedPayments:
              completedPayments,
          totalOrders:
              createdOrders.length,
        );

        return;
      }

      // --------------------------------------------------------
      // ALL PAYMENTS COMPLETED
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      await _showSuccessDialog(
        createdOrders.length,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // RETURN TO CART
      //
      // OrderService already cleared the cart.
      //
      // Returning true allows CartScreen to refresh.
      // --------------------------------------------------------

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // PAYMENT INCOMPLETE DIALOG
  // ============================================================

  Future<void> _showPaymentIncompleteDialog({
    required Order order,
    required int completedPayments,
    required int totalOrders,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment Incomplete',
                ),
              ),
            ],
          ),
          content: Text(
            completedPayments == 0
                ? 'Your order was created, but payment has not been completed.'
                : '$completedPayments of $totalOrders payments were completed.\n\n'
                  'Payment for order ${order.id} was not completed.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog(
    int orderCount,
  ) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Order Completed',
                ),
              ),
            ],
          ),
          content: Text(
            orderCount == 1
                ? 'Your order has been created and payment has been recorded successfully.'
                : '$orderCount orders have been created and their payments have been recorded successfully.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Done',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CLEAN ERROR MESSAGE
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
        ? 'Unable to place order.'
        : message;
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total items',
                ),
                Text(
                  _totalQuantity.toString(),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                ),
                Text(
                  _formatPrice(_total),
                ),
              ],
            ),

            const Divider(
              height: 28,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  _formatPrice(_total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isLoggedIn =
        _authService.isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('Checkout'),
        ),
        body:
            _buildLoginRequired(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Checkout'),
      ),

      body: widget.items.isEmpty
          ? _buildEmptyCheckout()
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      children: [
                        // --------------------------------------
                        // HEADER
                        // --------------------------------------

                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  child: Icon(
                                    Icons
                                        .shopping_cart_checkout,
                                    color: Theme.of(
                                      context,
                                    )
                                        .colorScheme
                                        .primary,
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
                                      const Text(
                                        'Review your order',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      Text(
                                        '$_totalQuantity item${_totalQuantity == 1 ? '' : 's'}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // --------------------------------------
                        // ORDER ITEMS
                        // --------------------------------------

                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        ...widget.items.map(
                          _buildCheckoutItem,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // --------------------------------------
                        // SUMMARY
                        // --------------------------------------

                        _buildSummary(),

                        const SizedBox(
                          height: 16,
                        ),

                        // --------------------------------------
                        // INFORMATION
                        // --------------------------------------

                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(
                                    context,
                                  )
                                      .colorScheme
                                      .primary,
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(
                                  child: Text(
                                    'Review your items carefully. '
                                    'When you continue, your order will be created and you will be taken to the payment screen.',
                                    style:
                                        TextStyle(
                                      color: Theme.of(
                                        context,
                                      )
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),

                  // --------------------------------------------
                  // CONTINUE TO PAYMENT BUTTON
                  // --------------------------------------------

                  Container(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      16,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          offset:
                              const Offset(
                            0,
                            -2,
                          ),
                          color: Colors.black
                              .withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child:
                          FilledButton.icon(
                        onPressed:
                            _isSubmitting
                                ? null
                                : _placeOrder,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.payment,
                              ),
                        label: Text(
                          _isSubmitting
                              ? 'Creating Order...'
                              : 'Continue to Payment • ${_formatPrice(_total)}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // EMPTY CHECKOUT
  // ============================================================

  Widget _buildEmptyCheckout() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .shopping_cart_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'No Items to Checkout',
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
              'Your cart does not contain any items.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 24,
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
              ),
              label:
                  const Text('Back to Cart'),
            ),
          ],
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
              'Please login as a buyer before checkout.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 24,
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
              ),
              label: const Text(
                'Back',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

