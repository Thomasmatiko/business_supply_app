
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService.instance;
  final AuthService _authService = AuthService.instance;

  List<CartItem> _items = [];

  bool _isLoading = true;
  bool _isUpdating = false;

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
    _loadCart();
  }

  // ============================================================
  // LOAD CART
  // ============================================================

  Future<void> _loadCart() async {
    final buyerId = _buyerId;

    if (buyerId == null || buyerId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items = [];
        _isLoading = false;
      });

      return;
    }

    try {
      final items = await _cartService.getCartItems(
        buyerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load cart: $e',
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshCart() async {
    await _loadCart();
  }

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice(double amount) {
    final amountString = amount.toStringAsFixed(0);

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
  // CART TOTAL
  // ============================================================

  double get _cartTotal {
    return _items.fold(
      0.0,
      (total, item) => total + item.total,
    );
  }

  // ============================================================
  // TOTAL QUANTITY
  // ============================================================

  int get _totalQuantity {
    return _items.fold(
      0,
      (total, item) => total + item.quantity,
    );
  }

  // ============================================================
  // INCREASE QUANTITY
  // ============================================================

  Future<void> _increaseQuantity(
    CartItem item,
  ) async {
    final buyerId = _buyerId;

    if (buyerId == null || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final success =
          await _cartService.increaseQuantity(
        buyerId,
        item.id,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showMessage(
          'Cannot increase quantity. Check available stock.',
        );
      }

      await _loadCart();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to update quantity: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ============================================================
  // DECREASE QUANTITY
  // ============================================================

  Future<void> _decreaseQuantity(
    CartItem item,
  ) async {
    final buyerId = _buyerId;

    if (buyerId == null || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final success =
          await _cartService.decreaseQuantity(
        buyerId,
        item.id,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showMessage(
          'Unable to decrease quantity.',
        );
      }

      await _loadCart();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to update quantity: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  Future<void> _removeItem(
    CartItem item,
  ) async {
    final buyerId = _buyerId;

    if (buyerId == null || _isUpdating) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Item',
          ),
          content: Text(
            'Remove "${item.productName}" from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Remove',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final success =
          await _cartService.removeFromCart(
        buyerId,
        item.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        success
            ? 'Item removed from cart.'
            : 'Item could not be removed.',
      );

      await _loadCart();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to remove item: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAR CART
  // ============================================================

  Future<void> _clearCart() async {
    final buyerId = _buyerId;

    if (buyerId == null ||
        _items.isEmpty ||
        _isUpdating) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear Cart',
          ),
          content: const Text(
            'Are you sure you want to remove all items from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Clear Cart',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _cartService.clearCart(
        buyerId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Cart cleared.',
      );

      await _loadCart();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to clear cart: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ============================================================
  // PROCEED TO CHECKOUT
  // ============================================================

  Future<void> _proceedToCheckout() async {
    if (_items.isEmpty || _isUpdating) {
      return;
    }

    final buyerId = _buyerId;

    if (buyerId == null || buyerId.trim().isEmpty) {
      _showMessage(
        'Please login as a buyer before checkout.',
      );
      return;
    }

    final checkoutItems =
        List<CartItem>.from(_items);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: checkoutItems,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _loadCart();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Order placed successfully.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
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
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath),
          width: 80,
          height: 80,
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 36,
        color: Theme.of(context)
            .colorScheme
            .onPrimaryContainer,
      ),
    );
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget _buildCartItem(
    CartItem item,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _formatPrice(
                      item.unitPrice,
                    ),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Subtotal: ${_formatPrice(item.total)}',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      IconButton(
                        tooltip:
                            'Decrease quantity',
                        onPressed:
                            _isUpdating
                                ? null
                                : () =>
                                    _decreaseQuantity(
                                      item,
                                    ),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                        ),
                      ),

                      Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 35,
                        ),
                        alignment:
                            Alignment.center,
                        child: Text(
                          item.quantity
                              .toString(),
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip:
                            'Increase quantity',
                        onPressed:
                            _isUpdating
                                ? null
                                : () =>
                                    _increaseQuantity(
                                      item,
                                    ),
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        tooltip:
                            'Remove item',
                        onPressed:
                            _isUpdating
                                ? null
                                : () =>
                                    _removeItem(
                                      item,
                                    ),
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                      ),
                    ],
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
  // EMPTY CART
  // ============================================================

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 90,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(height: 20),

            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add products to your cart and they will appear here.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.shopping_bag_outlined,
              ),
              label: const Text(
                'Continue Shopping',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CART SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Card(
      margin: const EdgeInsets.only(
        top: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
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
                  _formatPrice(_cartTotal),
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
                  _formatPrice(_cartTotal),
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

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _isUpdating
                        ? null
                        : _proceedToCheckout,
                icon: const Icon(
                  Icons.shopping_cart_checkout,
                ),
                label: const Text(
                  'Proceed to Checkout',
                ),
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              onPressed:
                  _isUpdating
                      ? null
                      : _clearCart,
              icon: const Icon(
                Icons.delete_sweep_outlined,
              ),
            ),
        ],
      ),
      body: !isLoggedIn
          ? _buildNotLoggedIn()
          : _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : _items.isEmpty
                  ? _buildEmptyCart()
                  : RefreshIndicator(
                      onRefresh:
                          _refreshCart,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Expanded(
                                child: Text(
                                  '$_totalQuantity item${_totalQuantity == 1 ? '' : 's'} in your cart',
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          ..._items.map(
                            _buildCartItem,
                          ),

                          _buildSummary(),

                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
    );
  }

  // ============================================================
  // NOT LOGGED IN
  // ============================================================

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please login as a buyer to access your cart.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
