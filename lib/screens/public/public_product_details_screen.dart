
import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../buyer/cart_screen.dart';

class PublicProductDetailsScreen extends StatelessWidget {
  final Product product;

  const PublicProductDetailsScreen({
    super.key,
    required this.product,
  });

  // ============================================================
  // CURRENCY
  // ============================================================

  String _formatCurrency(double amount) {
    final amountString = amount.toStringAsFixed(0);

    final reversed = amountString.split('').reversed.toList();

    final buffer = StringBuffer();

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(reversed[i]);
    }

    return buffer.toString().split('').reversed.join();
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart(
    BuildContext context,
  ) async {
    // ----------------------------------------------------------
    // CHECK STOCK
    // ----------------------------------------------------------

    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This product is currently out of stock.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CHECK LOGIN
    // ----------------------------------------------------------

    final authService = AuthService.instance;
    final user = authService.currentUser;

    if (user == null) {
      _showLoginRequired(context);
      return;
    }

    // ----------------------------------------------------------
    // CHECK BUYER ROLE
    // ----------------------------------------------------------

    if (!user.isBuyer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only buyers can add products to cart.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // ADD TO CART
    // ----------------------------------------------------------

    try {
      final success = await CartService.instance.addToCart(
        buyerId: user.id,
        productId: product.id,
        quantity: 1,
      );

      if (!context.mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${product.name} added to cart.',
              ),
              action: SnackBarAction(
                label: 'VIEW CART',
                onPressed: () {
                  _openCart(context);
                },
              ),
            ),
          );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to add product to cart. '
              'The requested quantity may exceed available stock.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error adding product to cart: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // OPEN CART
  // ============================================================

  void _openCart(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  // ============================================================
  // LOGIN REQUIRED
  // ============================================================

  void _showLoginRequired(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Login Required',
          ),
          content: const Text(
            'You can browse products without an account. '
            'Please login or create an account before adding products to your cart.',
          ),
          actions: [
            // --------------------------------------------------
            // CANCEL
            // --------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            // --------------------------------------------------
            // REGISTER
            // --------------------------------------------------

            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushNamed(
                  context,
                  AppRoutes.register,
                );
              },
              child: const Text(
                'Register',
              ),
            ),

            // --------------------------------------------------
            // LOGIN
            // --------------------------------------------------

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushNamed(
                  context,
                  AppRoutes.login,
                );
              },
              child: const Text(
                'Login',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    BuildContext context,
  ) {
    final imagePath = product.imagePath?.trim();

    // ----------------------------------------------------------
    // NO IMAGE
    // ----------------------------------------------------------

    if (imagePath == null || imagePath.isEmpty) {
      return _buildProductPlaceholder(context);
    }

    // ----------------------------------------------------------
    // IMAGE
    // ----------------------------------------------------------

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _buildProductPlaceholder(context);
      },
    );
  }

  // ============================================================
  // PRODUCT IMAGE PLACEHOLDER
  // ============================================================

  Widget _buildProductPlaceholder(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 100,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final available = product.stock > 0;

    final authService = AuthService.instance;

    final isLoggedIn = authService.isLoggedIn;

    final currentUser = authService.currentUser;

    final isBuyer = currentUser?.isBuyer ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
        ),

        // ------------------------------------------------------
        // CART BUTTON
        // ------------------------------------------------------

        actions: [
          if (isBuyer)
            IconButton(
              onPressed: () {
                _openCart(context);
              },
              tooltip: 'My Cart',
              icon: const Icon(
                Icons.shopping_cart_outlined,
              ),
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT IMAGE
            // ==================================================

            Container(
              width: double.infinity,
              height: 240,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: _buildProductImage(context),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // PRODUCT NAME
            // ==================================================

            Text(
              product.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // CATEGORY
            // ==================================================

            if (product.category.trim().isNotEmpty)
              Chip(
                avatar: const Icon(
                  Icons.category_outlined,
                  size: 18,
                ),
                label: Text(
                  product.category,
                ),
              ),

            const SizedBox(height: 20),

            // ==================================================
            // SELLING PRICE
            // ==================================================

            Text(
              'TZS ${_formatCurrency(product.sellingPrice)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // AVAILABILITY
            // ==================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: available
                    ? Colors.green.withValues(
                        alpha: 0.10,
                      )
                    : Theme.of(context)
                        .colorScheme
                        .errorContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    available
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: available
                        ? Colors.green
                        : Theme.of(context)
                            .colorScheme
                            .error,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    available
                        ? '${product.stock} available'
                        : 'Out of stock',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  product.description.trim().isNotEmpty
                      ? product.description
                      : 'No description available.',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ==================================================
            // ADD TO CART
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: available
                    ? () {
                        _addToCart(context);
                      }
                    : null,
                icon: const Icon(
                  Icons.add_shopping_cart,
                ),
                label: Text(
                  isLoggedIn
                      ? 'Add to Cart'
                      : 'Login to Add to Cart',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // VIEW CART
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isBuyer
                    ? () {
                        _openCart(context);
                      }
                    : null,
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                ),
                label: const Text(
                  'View Cart',
                ),
              ),
            ),

            // ==================================================
            // PUBLIC USER INFORMATION
            // ==================================================

            if (!isLoggedIn) ...[
              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'Browse freely without an account. '
                  'Login or register when you want to add products to your cart.',
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              _buildSellInformation(context),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELL INFORMATION
  // ============================================================

  Widget _buildSellInformation(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.storefront,
              size: 32,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Want to sell products?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Create an account to join the selling side of Business Supply.',
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.register,
                      );
                    },
                    child: const Text(
                      'Create Seller Account',
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
}

