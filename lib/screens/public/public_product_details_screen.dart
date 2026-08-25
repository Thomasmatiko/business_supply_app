import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';

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

    final formatted = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add(',');
      }

      formatted.add(reversed[i]);
    }

    return formatted.reversed.join();
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  void _placeOrder(BuildContext context) {
    // ----------------------------------------------------------
    // PRODUCT OUT OF STOCK
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

    if (!AuthService.instance.isLoggedIn) {
      _showLoginRequired(context);
      return;
    }

    // ----------------------------------------------------------
    // USER IS LOGGED IN
    // ----------------------------------------------------------

    Navigator.pushNamed(
      context,
      AppRoutes.createOrder,
      arguments: product,
    );
  }

  // ============================================================
  // LOGIN REQUIRED
  // ============================================================

  void _showLoginRequired(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Login Required',
          ),
          content: const Text(
            'You can browse products without an account. '
            'Please login or create an account before placing an order.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final available = product.stock > 0;
    final isLoggedIn = AuthService.instance.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // PRODUCT IMAGE / ICON
            // ====================================================

            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 100,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // PRODUCT NAME
            // ====================================================

            Text(
              product.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // CATEGORY
            // ====================================================

            if (product.category.isNotEmpty)
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

            // ====================================================
            // SELLING PRICE
            // ====================================================

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

            const SizedBox(height: 16),

            // ====================================================
            // AVAILABILITY
            // ====================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: available
                    ? Colors.green.withValues(alpha: 0.10)
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

            // ====================================================
            // DESCRIPTION
            // ====================================================

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              product.description.isNotEmpty
                  ? product.description
                  : 'No description available.',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // ====================================================
            // PLACE ORDER BUTTON
            // ====================================================

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: available
                    ? () => _placeOrder(context)
                    : null,
                icon: const Icon(
                  Icons.shopping_cart,
                ),
                label: Text(
                  isLoggedIn
                      ? 'Place Order'
                      : 'Login to Place Order',
                ),
              ),
            ),

            // ====================================================
            // PUBLIC USER INFORMATION
            // ====================================================

            if (!isLoggedIn)
              const Padding(
                padding: EdgeInsets.only(
                  top: 12,
                ),
                child: Center(
                  child: Text(
                    'Browse freely without an account. '
                    'Login or register when you want to place an order.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ====================================================
            // SELL INFORMATION
            // ====================================================

            if (!isLoggedIn)
              _buildSellInformation(context),
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.storefront,
              size: 32,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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