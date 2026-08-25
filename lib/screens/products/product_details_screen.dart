import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import 'adjust_stock_screen.dart';
import 'edit_product_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  final ProductService _productService =
      ProductService.instance;

  final AuthService _authService =
      AuthService.instance;

  late Product _currentProduct;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  // ============================================================
  // ROLE / PERMISSION
  // ============================================================

  bool get _isBuyer {
    return _authService.currentUser?.isBuyer ?? false;
  }

  bool get _isSeller {
    return _authService.currentUser?.isSeller ?? false;
  }

  bool get _isAdmin {
    return _authService.currentUser?.isAnyAdmin ?? false;
  }

  bool get _isProductOwner {
    final user = _authService.currentUser;

    if (user == null) {
      return false;
    }

    if (_currentProduct.sellerId == null) {
      return false;
    }

    return _currentProduct.sellerId == user.id;
  }

  bool get _canEditProduct {
    if (_isAdmin) {
      return true;
    }

    if (_isSeller && _isProductOwner) {
      return true;
    }

    return false;
  }

  bool get _canAdjustStock {
    if (_isAdmin) {
      return true;
    }

    if (_isSeller && _isProductOwner) {
      return true;
    }

    return false;
  }

  bool get _canDeleteProduct {
    if (_isAdmin) {
      return true;
    }

    if (_isSeller && _isProductOwner) {
      return true;
    }

    return false;
  }

  // ============================================================
  // PRICE
  // ============================================================

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0);

    final reversed =
        formatted.split('').reversed.toList();

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
  // EDIT PRODUCT
  // ============================================================

  Future<void> _openEditProduct() async {
    if (!_canEditProduct || _isDeleting) {
      return;
    }

    final updatedProduct =
        await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProductScreen(
          product: _currentProduct,
        ),
      ),
    );

    if (!mounted || updatedProduct == null) {
      return;
    }

    setState(() {
      _currentProduct = updatedProduct;
    });
  }

  // ============================================================
  // ADJUST STOCK
  // ============================================================

  Future<void> _adjustStock() async {
    if (!_canAdjustStock || _isDeleting) {
      return;
    }

    final updatedProduct =
        await Navigator.of(context)
            .push<Product>(
      MaterialPageRoute(
        builder: (context) =>
            AdjustStockScreen(
          product: _currentProduct,
        ),
      ),
    );

    if (!mounted || updatedProduct == null) {
      return;
    }

    setState(() {
      _currentProduct = updatedProduct;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text('Stock updated successfully.'),
      ),
    );
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> _confirmDeleteProduct() async {
    if (!_canDeleteProduct || _isDeleting) {
      return;
    }

    try {
      final hasOrders =
          await OrderService.instance
              .hasOrdersForProduct(
        _currentProduct.id,
      );

      if (!mounted) {
        return;
      }

      if (hasOrders) {
        _showMessage(
          'This product cannot be deleted because it has order history.',
        );
        return;
      }

      final shouldDelete =
          await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title:
                const Text('Delete Product'),
            content: Text(
              'Are you sure you want to delete '
              '"${_currentProduct.name}"?\n\n'
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child:
                    const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child:
                    const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (shouldDelete != true ||
          !mounted) {
        return;
      }

      await _deleteProduct();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Error checking product order history: $e',
      );
    }
  }

  Future<void> _deleteProduct() async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final result =
          await _productService.deleteProduct(
        _currentProduct.id,
      );

      if (!mounted) {
        return;
      }

      if (result > 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Product deleted successfully.',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        setState(() {
          _isDeleting = false;
        });

        _showMessage(
          'Product could not be deleted.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      _showMessage(
        'Error deleting product: $e',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Product Details'),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 45,
                child: Text(
                  _currentProduct.name.isNotEmpty
                      ? _currentProduct.name[0]
                          .toUpperCase()
                      : '?',
                  style:
                      const TextStyle(
                    fontSize: 32,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                _currentProduct.name,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // SELLER INFORMATION
            // ==================================================

            if (_currentProduct.sellerId != null)
              _buildInfoCard(
                icon: Icons.store,
                title: 'Seller ID',
                value:
                    _currentProduct.sellerId!,
              ),

            // ==================================================
            // PRODUCT MANAGEMENT
            // ==================================================

            if (_canEditProduct)
              SizedBox(
                width: double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _isDeleting
                          ? null
                          : _openEditProduct,
                  icon:
                      const Icon(Icons.edit),
                  label:
                      const Text(
                    'Edit Product',
                  ),
                ),
              ),

            if (_canEditProduct)
              const SizedBox(height: 12),

            if (_canAdjustStock)
              SizedBox(
                width: double.infinity,
                height: 52,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _isDeleting
                          ? null
                          : _adjustStock,
                  icon: const Icon(
                    Icons.inventory_2,
                  ),
                  label:
                      const Text(
                    'Adjust Stock',
                  ),
                ),
              ),

            if (_canAdjustStock)
              const SizedBox(height: 12),

            if (_canDeleteProduct)
              SizedBox(
                width: double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _isDeleting
                          ? null
                          : _confirmDeleteProduct,
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
                  label: Text(
                    _isDeleting
                        ? 'Deleting...'
                        : 'Delete Product',
                  ),
                ),
              ),

            if (_canDeleteProduct)
              const SizedBox(height: 24),

            // ==================================================
            // PRODUCT INFORMATION
            // ==================================================

            _buildInfoCard(
              icon: Icons.qr_code,
              title: 'Product ID',
              value:
                  _currentProduct.id,
            ),

            _buildInfoCard(
              icon: Icons.category,
              title: 'Category',
              value:
                  _currentProduct.category,
            ),

            _buildInfoCard(
              icon: Icons.sell,
              title: 'Selling Price',
              value: _formatPrice(
                _currentProduct
                    .sellingPrice,
              ),
            ),

            // Cost price should not be shown
            // to buyers.

            if (!_isBuyer)
              _buildInfoCard(
                icon: Icons.shopping_cart,
                title: 'Cost Price',
                value: _formatPrice(
                  _currentProduct
                      .costPrice,
                ),
              ),

            _buildInfoCard(
              icon: Icons.inventory,
              title: 'Stock',
              value:
                  _currentProduct.stock
                      .toString(),
            ),

            if (!_isBuyer)
              _buildInfoCard(
                icon: Icons.trending_up,
                title: 'Profit Per Unit',
                value: _formatPrice(
                  _currentProduct
                      .profit,
                ),
              ),

            _buildInfoCard(
              icon: _currentProduct
                      .isLowStock
                  ? Icons.warning
                  : Icons.check_circle,
              title: 'Stock Status',
              value: _currentProduct
                      .isLowStock
                  ? 'Low Stock'
                  : 'Stock Available',
            ),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            if (_currentProduct
                .description
                .isNotEmpty) ...[
              const SizedBox(height: 8),

              const Text(
                'Description',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Text(
                    _currentProduct
                        .description,
                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        trailing: Text(
          value,
          style:
              const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}