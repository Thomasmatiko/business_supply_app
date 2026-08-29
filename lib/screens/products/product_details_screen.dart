import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../buyer/cart_screen.dart';
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

  final CartService _cartService =
      CartService.instance;

  late Product _currentProduct;

  bool _isDeleting = false;
  bool _isAddingToCart = false;

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
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart() async {
    if (_isAddingToCart || _isDeleting) {
      return;
    }

    final user = _authService.currentUser;

    // ----------------------------------------------------------
    // CHECK LOGIN
    // ----------------------------------------------------------

    if (user == null) {
      _showMessage(
        'Please login as a buyer to add products to cart.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK BUYER
    // ----------------------------------------------------------

    if (!user.isBuyer) {
      _showMessage(
        'Only buyers can add products to cart.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK STOCK
    // ----------------------------------------------------------

    if (_currentProduct.stock <= 0) {
      _showMessage(
        'This product is out of stock.',
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final success =
          await _cartService.addToCart(
        buyerId: user.id,
        productId: _currentProduct.id,
        quantity: 1,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        _showMessage(
          '${_currentProduct.name} added to cart.',
        );
      } else {
        _showMessage(
          'Unable to add product to cart. '
          'The requested quantity may exceed available stock.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Error adding product to cart: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN CART
  // ============================================================

  Future<void> _openCart() async {
    if (_isDeleting) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
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

    _showMessage(
      'Product updated successfully.',
    );
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

    _showMessage(
      'Stock updated successfully.',
    );
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  Future<void> _confirmDeleteProduct() async {
    if (!_canDeleteProduct || _isDeleting) {
      return;
    }

    try {
      // --------------------------------------------------------
      // CHECK ORDER HISTORY
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // CONFIRMATION DIALOG
      // --------------------------------------------------------

      final shouldDelete =
          await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Delete Product',
            ),
            content: Text(
              'Are you sure you want to delete '
              '"${_currentProduct.name}"?\n\n'
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(false);
                },
                child: const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(true);
                },
                child: const Text(
                  'Delete',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted || shouldDelete != true) {
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

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

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

      // --------------------------------------------------------
      // DELETE SUCCESS
      // --------------------------------------------------------

      if (result > 0) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Product deleted successfully.',
              ),
            ),
          );

        // IMPORTANT:
        // ProductsScreen does NOT expect Product here.
        // We return bool true to tell ProductsScreen
        // that the product was deleted.
        Navigator.of(context).pop(true);

        return;
      }

      // --------------------------------------------------------
      // DELETE FAILED
      // --------------------------------------------------------

      setState(() {
        _isDeleting = false;
      });

      _showMessage(
        'Product could not be deleted.',
      );
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
  // PRODUCT IMAGE PLACEHOLDER
  // ============================================================

  Widget _buildProductImagePlaceholder() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2,
              size: 70,
              color:
                  colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              _currentProduct.name.isNotEmpty
                  ? _currentProduct.name[0]
                      .toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color:
                    colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage() {
    final imagePath =
        _currentProduct.imagePath?.trim();

    if (imagePath != null &&
        imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(20),
        child: SizedBox(
          width: double.infinity,
          height: 260,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return _buildProductImagePlaceholder();
            },
          ),
        ),
      );
    }

    return _buildProductImagePlaceholder();
  }

  // ============================================================
  // BUYER CART ACTIONS
  // ============================================================

  Widget _buildBuyerCartActions() {
    if (!_isBuyer) {
      return const SizedBox.shrink();
    }

    final outOfStock =
        _currentProduct.stock <= 0;

    return Column(
      children: [
        const SizedBox(height: 20),

        // ------------------------------------------------------
        // ADD TO CART
        // ------------------------------------------------------

        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed:
                outOfStock ||
                        _isAddingToCart ||
                        _isDeleting
                    ? null
                    : _addToCart,
            icon: _isAddingToCart
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.add_shopping_cart,
                  ),
            label: Text(
              _isAddingToCart
                  ? 'Adding...'
                  : outOfStock
                      ? 'Out of Stock'
                      : 'Add to Cart',
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // VIEW CART
        // ------------------------------------------------------

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed:
                _isDeleting
                    ? null
                    : _openCart,
            icon: const Icon(
              Icons.shopping_cart,
            ),
            label: const Text(
              'View Cart',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
        ),
        actions: [
          if (_isBuyer)
            IconButton(
              onPressed:
                  _isDeleting
                      ? null
                      : _openCart,
              tooltip: 'My Cart',
              icon: const Icon(
                Icons.shopping_cart_outlined,
              ),
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT IMAGE
            // ==================================================

            Center(
              child: _buildProductImage(),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // PRODUCT NAME
            // ==================================================

            Center(
              child: Text(
                _currentProduct.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            // ==================================================
            // BUYER CART ACTIONS
            // ==================================================

            _buildBuyerCartActions(),

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
            // EDIT PRODUCT
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
                  icon: const Icon(
                    Icons.edit,
                  ),
                  label: const Text(
                    'Edit Product',
                  ),
                ),
              ),

            if (_canEditProduct)
              const SizedBox(height: 12),

            // ==================================================
            // ADJUST STOCK
            // ==================================================

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
                  label: const Text(
                    'Adjust Stock',
                  ),
                ),
              ),

            if (_canAdjustStock)
              const SizedBox(height: 12),

            // ==================================================
            // DELETE PRODUCT
            // ==================================================

            if (_canDeleteProduct)
              SizedBox(
                width: double.infinity,
                height: 52,
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
            // PRODUCT ID
            // ==================================================

            _buildInfoCard(
              icon: Icons.qr_code,
              title: 'Product ID',
              value:
                  _currentProduct.id,
            ),

            // ==================================================
            // CATEGORY
            // ==================================================

            _buildInfoCard(
              icon: Icons.category,
              title: 'Category',
              value:
                  _currentProduct.category,
            ),

            // ==================================================
            // SELLING PRICE
            // ==================================================

            _buildInfoCard(
              icon: Icons.sell,
              title: 'Selling Price',
              value: _formatPrice(
                _currentProduct
                    .sellingPrice,
              ),
            ),

            // ==================================================
            // COST PRICE
            // ==================================================

            if (!_isBuyer)
              _buildInfoCard(
                icon:
                    Icons.shopping_cart,
                title: 'Cost Price',
                value: _formatPrice(
                  _currentProduct
                      .costPrice,
                ),
              ),

            // ==================================================
            // STOCK
            // ==================================================

            _buildInfoCard(
              icon: Icons.inventory,
              title: 'Stock',
              value:
                  _currentProduct.stock
                      .toString(),
            ),

            // ==================================================
            // PROFIT
            // ==================================================

            if (!_isBuyer)
              _buildInfoCard(
                icon:
                    Icons.trending_up,
                title:
                    'Profit Per Unit',
                value: _formatPrice(
                  _currentProduct
                      .profit,
                ),
              ),

            // ==================================================
            // STOCK STATUS
            // ==================================================

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
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 8),

              const Text(
                'Description',
                style: TextStyle(
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
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
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
        trailing: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 220,
          ),
          child: Text(
            value,
            textAlign:
                TextAlign.end,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}