import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

class AdjustStockScreen extends StatefulWidget {
  final Product product;

  const AdjustStockScreen({
    super.key,
    required this.product,
  });

  @override
  State<AdjustStockScreen> createState() =>
      _AdjustStockScreenState();
}

class _AdjustStockScreenState extends State<AdjustStockScreen> {
  final ProductService _productService =
      ProductService.instance;

  final TextEditingController _quantityController =
      TextEditingController();

  final TextEditingController _reasonController =
      TextEditingController();

  String _adjustmentType = 'Stock In';

  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _quantity {
    return int.tryParse(
          _quantityController.text.trim(),
        ) ??
        0;
  }

  int get _newStock {
    if (_adjustmentType == 'Stock In') {
      return widget.product.stock + _quantity;
    }

    if (_adjustmentType == 'Stock Out') {
      return widget.product.stock - _quantity;
    }

    return _quantity;
  }

  Future<void> _saveAdjustment() async {
    if (_isSaving) {
      return;
    }

    if (_quantity <= 0) {
      _showMessage('Enter a valid quantity.');
      return;
    }

    if (_adjustmentType == 'Stock Out' &&
        _quantity > widget.product.stock) {
      _showMessage(
        'Stock Out quantity cannot be greater than '
        'the current stock.',
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showMessage('Please enter a reason.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProduct = widget.product.copyWith(
        stock: _newStock,
      );

      final result =
          await _productService.updateProduct(
        updatedProduct,
      );

      if (!mounted) {
        return;
      }

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Stock adjusted successfully.',
            ),
          ),
        );

        Navigator.pop(
          context,
          updatedProduct,
        );
      } else {
        _showMessage(
          'Failed to adjust stock.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Error adjusting stock: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatStock(int stock) {
    return stock.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Stock'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 55,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Stock: '
                      '${_formatStock(widget.product.stock)}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _adjustmentType,
              decoration: const InputDecoration(
                labelText: 'Adjustment Type',
                prefixIcon: Icon(
                  Icons.swap_vert,
                ),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Stock In',
                  child: Text('Stock In'),
                ),
                DropdownMenuItem(
                  value: 'Stock Out',
                  child: Text('Stock Out'),
                ),
                DropdownMenuItem(
                  value: 'Correction',
                  child: Text('Correction'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _adjustmentType = value;
                      });
                    },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: false,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Quantity',
                prefixIcon: Icon(
                  Icons.format_list_numbered,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText:
                    'Example: New supplier delivery',
                prefixIcon: Icon(
                  Icons.description,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.inventory,
                ),
                title: const Text(
                  'New Stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  _newStock.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _isSaving ? null : _saveAdjustment,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save Adjustment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}