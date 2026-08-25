import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final Product? product;

  const CreateOrderScreen({
    super.key,
    this.product,
  });

  @override
  State<CreateOrderScreen> createState() =>
      _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final TextEditingController _quantityController =
      TextEditingController();

  String? _selectedProduct;

  double _selectedUnitPrice = 0.0;
  int _quantity = 0;
  double _totalAmount = 0.0;

  List<Product> _products = [];

  bool _isLoadingProducts = true;
  bool _isLoadingSeller = false;
  bool _isCreatingOrder = false;

  String? _productError;
  String? _sellerError;

  AppUser? _selectedSeller;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // SECURITY CHECK
    // ==========================================================

    if (!AuthService.instance.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.login,
        );
      });

      return;
    }

    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================

  Future<void> _loadProducts() async {
    try {
      final products =
          await ProductService.instance.getProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });

      // ----------------------------------------------------------
      // Automatically select product when opened from
      // Public Product Details.
      // ----------------------------------------------------------

      if (widget.product != null) {
        final publicProduct = widget.product!;

        final matchingProducts = products.where(
          (product) => product.id == publicProduct.id,
        );

        if (matchingProducts.isNotEmpty) {
          final selected = matchingProducts.first;

          setState(() {
            _selectedProduct = selected.id;
            _selectedUnitPrice = selected.sellingPrice;
            _totalAmount =
                selected.sellingPrice * _quantity;
          });

          await _loadSellerForProduct(selected);
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProducts = false;
        _productError =
            'Failed to load products.';
      });
    }
  }

  // ============================================================
  // LOAD SELLER FOR PRODUCT
  //
  // Seller is determined by the product.sellerId.
  //
  // The buyer does NOT choose the seller manually.
  // ============================================================

  Future<void> _loadSellerForProduct(
    Product product,
  ) async {
    final sellerId = product.sellerId;

    if (sellerId == null || sellerId.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedSeller = null;
        _isLoadingSeller = false;
        _sellerError =
            'This product has no seller assigned.';
      });

      return;
    }

    setState(() {
      _isLoadingSeller = true;
      _sellerError = null;
      _selectedSeller = null;
    });

    try {
      final seller =
          await UserService.instance.getUserById(
        sellerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedSeller = seller;
        _isLoadingSeller = false;

        if (seller == null) {
          _sellerError =
              'Seller information not available.';
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSeller = false;
        _selectedSeller = null;
        _sellerError =
            'Failed to load seller information.';
      });
    }
  }

  // ============================================================
  // CALCULATE TOTAL
  // ============================================================

  void _calculateTotal() {
    final quantity =
        int.tryParse(
              _quantityController.text.trim(),
            ) ??
            0;

    setState(() {
      _quantity = quantity;
      _totalAmount =
          _selectedUnitPrice * quantity;
    });
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String _formatCurrency(double amount) {
    final amountString =
        amount.toStringAsFixed(0);

    final reversed =
        amountString.split('').reversed.toList();

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
  // CREATE ORDER
  // ============================================================

  Future<void> _createOrder() async {
    final currentUser =
        AuthService.instance.currentUser;

    // ----------------------------------------------------------
    // SECURITY
    // ----------------------------------------------------------

    if (currentUser == null ||
        !AuthService.instance.isLoggedIn) {
      _showMessage(
        'You must login before placing an order.',
      );

      return;
    }

    // ----------------------------------------------------------
    // PRODUCT
    // ----------------------------------------------------------

    if (_selectedProduct == null) {
      _showMessage(
        'Please select a product.',
      );

      return;
    }

    // ----------------------------------------------------------
    // QUANTITY
    // ----------------------------------------------------------

    final quantity =
        int.tryParse(
              _quantityController.text.trim(),
            ) ??
            0;

    if (quantity <= 0) {
      _showMessage(
        'Please enter a valid quantity.',
      );

      return;
    }

    // ----------------------------------------------------------
    // FIND PRODUCT
    // ----------------------------------------------------------

    final selectedProduct =
        _products.firstWhere(
      (product) =>
          product.id == _selectedProduct,
    );

    // ----------------------------------------------------------
    // SELLER
    //
    // Seller comes from the product.
    // The buyer cannot choose or change it.
    // ----------------------------------------------------------

    final sellerId =
        selectedProduct.sellerId;

    if (sellerId == null ||
        sellerId.isEmpty) {
      _showMessage(
        'This product has no seller assigned.',
      );

      return;
    }

    // ----------------------------------------------------------
    // STOCK
    // ----------------------------------------------------------

    if (selectedProduct.stock <= 0) {
      _showMessage(
        'This product is currently out of stock.',
      );

      return;
    }

    if (quantity > selectedProduct.stock) {
      _showMessage(
        'Not enough stock. Available stock: '
        '${selectedProduct.stock}.',
      );

      return;
    }

    // ----------------------------------------------------------
    // CREATE ORDER ID
    // ----------------------------------------------------------

    final orderId =
        'ORD${DateTime.now().millisecondsSinceEpoch}';

    // ----------------------------------------------------------
    // CREATE ORDER
    //
    // Relationship:
    //
    // buyerId  = logged-in user
    // sellerId = product owner
    //
    // There is NO customerId.
    // ----------------------------------------------------------

    final order = Order(
      id: orderId,

      buyerId: currentUser.id,

      sellerId: sellerId,

      productId: selectedProduct.id,

      quantity: quantity,

      unitPrice:
          selectedProduct.sellingPrice,

      totalAmount:
          selectedProduct.sellingPrice *
              quantity,

      status: 'pending',

      createdBy: currentUser.id,

      createdAt: DateTime.now(),
    );

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      final result =
          await OrderService.instance.addOrder(
        order,
      );

      if (!mounted) {
        return;
      }

      if (result <= 0) {
        setState(() {
          _isCreatingOrder = false;
        });

        _showMessage(
          'Order could not be created. '
          'The product may no longer have enough stock.',
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order created successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingOrder = false;
      });

      _showMessage(
        'Failed to create order. Please try again.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Order',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT
            // ==================================================

            const Text(
              'Product',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            _buildProductDropdown(),

            const SizedBox(height: 20),

            // ==================================================
            // SELLER
            // ==================================================

            const Text(
              'Seller',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            _buildSellerDisplay(),

            const SizedBox(height: 20),

            // ==================================================
            // QUANTITY
            // ==================================================

            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  _quantityController,
              keyboardType:
                  TextInputType.number,
              onChanged: (_) {
                _calculateTotal();
              },
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
                hintText:
                    'Enter quantity',
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PRICE
            // ==================================================

            Text(
              'Unit Price: TZS '
              '${_formatCurrency(_selectedUnitPrice)}',
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // TOTAL
            // ==================================================

            Text(
              'Total Amount: TZS '
              '${_formatCurrency(_totalAmount)}',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // CREATE ORDER BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              child:
                  FilledButton.icon(
                onPressed:
                    _isCreatingOrder
                        ? null
                        : _createOrder,
                icon:
                    _isCreatingOrder
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                          ),
                label: Text(
                  _isCreatingOrder
                      ? 'Creating Order...'
                      : 'Create Order',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT DROPDOWN
  // ============================================================

  Widget _buildProductDropdown() {
    if (_isLoadingProducts) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_productError != null) {
      return Text(
        _productError!,
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .error,
        ),
      );
    }

    if (_products.isEmpty) {
      return const Text(
        'No products available.',
      );
    }

    return DropdownButtonFormField<String>(
      initialValue:
          _selectedProduct,
      decoration:
          const InputDecoration(
        border:
            OutlineInputBorder(),
        hintText:
            'Select product',
      ),
      items: _products.map(
        (product) {
          return DropdownMenuItem<String>(
            value: product.id,
            child: Text(
              '${product.name} - '
              'TZS ${_formatCurrency(product.sellingPrice)}',
            ),
          );
        },
      ).toList(),
      onChanged: (value) async {
        if (value == null) {
          return;
        }

        final selectedProduct =
            _products.firstWhere(
          (product) =>
              product.id == value,
        );

        setState(() {
          _selectedProduct = value;

          _selectedUnitPrice =
              selectedProduct.sellingPrice;

          _totalAmount =
              _selectedUnitPrice *
                  _quantity;

          _selectedSeller = null;
          _sellerError = null;
        });

        await _loadSellerForProduct(
          selectedProduct,
        );
      },
    );
  }

  // ============================================================
  // SELLER DISPLAY
  // ============================================================

  Widget _buildSellerDisplay() {
    if (_selectedProduct == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400,
          ),
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: const Text(
          'Select a product to see the seller.',
        ),
      );
    }

    if (_isLoadingSeller) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_sellerError != null) {
      return Text(
        _sellerError!,
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .error,
        ),
      );
    }

    if (_selectedSeller == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .error,
          ),
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: Text(
          'Seller information not available.',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .error,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              _selectedSeller!.name.isNotEmpty
                  ? _selectedSeller!.name[0]
                      .toUpperCase()
                  : '?',
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seller',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _selectedSeller!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _selectedSeller!.phone,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}