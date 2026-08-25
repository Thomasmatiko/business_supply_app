import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

class EditOrderScreen extends StatefulWidget {
  final Order order;

  const EditOrderScreen({
    super.key,
    required this.order,
  });

  @override
  State<EditOrderScreen> createState() =>
      _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final ProductService _productService =
      ProductService.instance;

  final OrderService _orderService =
      OrderService.instance;

  final TextEditingController _quantityController =
      TextEditingController();

  List<Product> _products = [];

  Product? _selectedProduct;

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _quantityController.text =
        widget.order.quantity.toString();

    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================

  Future<void> _loadData() async {
    try {
      final products =
          await _productService.getProducts();

      if (!mounted) {
        return;
      }

      Product? selectedProduct;

      for (final product in products) {
        if (product.id == widget.order.productId) {
          selectedProduct = product;
          break;
        }
      }

      setState(() {
        _products = products;
        _selectedProduct = selectedProduct;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load order information.';
      });

      debugPrint(
        'Edit order loading error: $e',
      );
    }
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  int get _quantity {
    return int.tryParse(
          _quantityController.text.trim(),
        ) ??
        0;
  }

  // ============================================================
  // UNIT PRICE
  // ============================================================

  double get _unitPrice {
    return _selectedProduct?.sellingPrice ?? 0.0;
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get _totalAmount {
    return _unitPrice * _quantity;
  }

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice(double price) {
    final formatted =
        price.toStringAsFixed(0);

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
  // CAN EDIT
  // ============================================================

  bool get _canEdit {
    return widget.order.status == 'pending' ||
        widget.order.status == 'confirmed';
  }

  // ============================================================
  // SAVE ORDER
  // ============================================================

  Future<void> _saveOrder() async {
    if (_isSaving) {
      return;
    }

    if (!_canEdit) {
      _showMessage(
        'This order cannot be edited in its current status.',
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

    if (_quantity <= 0) {
      _showMessage(
        'Enter a valid quantity.',
      );

      return;
    }

    // ----------------------------------------------------------
    // CREATE UPDATED ORDER
    //
    // IMPORTANT:
    //
    // We deliberately do NOT change:
    //
    // buyerId
    // sellerId
    // createdBy
    // status
    //
    // OrderService.updateOrderWithStock()
    // protects those fields.
    // ----------------------------------------------------------

    final updatedOrder =
        widget.order.copyWith(
      productId:
          _selectedProduct!.id,
      quantity:
          _quantity,
      unitPrice:
          _unitPrice,
      totalAmount:
          _totalAmount,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final success =
          await _orderService.updateOrderWithStock(
        updatedOrder,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Order updated successfully.',
            ),
          ),
        );

        Navigator.pop(
          context,
          updatedOrder,
        );

        return;
      }

      _showMessage(
        'Order could not be updated. '
        'Please check the available stock.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint(
        'Order update error: $e',
      );

      _showMessage(
        'Error updating order. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Order',
        ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_canEdit) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'This order cannot be edited.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order status: '
                '${widget.order.status.toUpperCase()}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ======================================================
          // ORDER INFORMATION
          // ======================================================

          const Text(
            'Order Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // BUYER
          // ======================================================

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.person,
                ),
              ),
              title: const Text(
                'Buyer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                widget.order.buyerId,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // SELLER
          // ======================================================

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.store,
                ),
              ),
              title: const Text(
                'Seller',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
  _selectedProduct?.sellerId ??
      widget.order.sellerId,
),
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // PRODUCT
          // ======================================================

          DropdownButtonFormField<Product>(
            initialValue: _selectedProduct,
            decoration: const InputDecoration(
              labelText: 'Product',
              prefixIcon: Icon(
                Icons.inventory_2,
              ),
              border: OutlineInputBorder(),
            ),
            items: _products.map(
              (product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  child: Text(
                    '${product.name} '
                    '(Stock: ${product.stock})',
                  ),
                );
              },
            ).toList(),
            onChanged: _isSaving
                ? null
                : (product) {
                    setState(() {
                      _selectedProduct =
                          product;
                    });
                  },
          ),

          const SizedBox(height: 16),

          // ======================================================
          // QUANTITY
          // ======================================================

          TextFormField(
            controller:
                _quantityController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: false,
            ),
            onChanged: (_) {
              setState(() {});
            },
            decoration:
                const InputDecoration(
              labelText: 'Quantity',
              prefixIcon: Icon(
                Icons.format_list_numbered,
              ),
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // PRICE SUMMARY
          // ======================================================

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.sell,
                  ),
                  title: const Text(
                    'Unit Price',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    _formatPrice(
                      _unitPrice,
                    ),
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                ListTile(
                  leading: const Icon(
                    Icons.calculate,
                  ),
                  title: const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    _formatPrice(
                      _totalAmount,
                    ),
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
          ),

          const SizedBox(height: 28),

          // ======================================================
          // SAVE
          // ======================================================

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : _saveOrder,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Save Changes',
              ),
            ),
          ),
        ],
      ),
    );
  }
}