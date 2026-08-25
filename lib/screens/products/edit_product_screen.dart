import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService _productService = ProductService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.product.name,
    );

    _categoryController = TextEditingController(
      text: widget.product.category,
    );

    _sellingPriceController = TextEditingController(
      text: widget.product.sellingPrice.toStringAsFixed(0),
    );

    _costPriceController = TextEditingController(
      text: widget.product.costPrice.toStringAsFixed(0),
    );

    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_isSaving) {
      return;
    }

    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final sellingPriceText =
        _sellingPriceController.text.trim();
    final costPriceText =
        _costPriceController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage('Product name is required.');
      return;
    }

    if (category.isEmpty) {
      _showMessage('Product category is required.');
      return;
    }

    final sellingPrice = double.tryParse(
      sellingPriceText,
    );

    if (sellingPrice == null || sellingPrice < 0) {
      _showMessage('Enter a valid selling price.');
      return;
    }

    final costPrice = double.tryParse(
      costPriceText,
    );

    if (costPrice == null || costPrice < 0) {
      _showMessage('Enter a valid cost price.');
      return;
    }

    if (sellingPrice < costPrice) {
      _showMessage(
        'Selling price cannot be lower than cost price.',
      );
      return;
    }

    final updatedProduct = widget.product.copyWith(
      name: name,
      category: category,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      description: description,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await _productService.updateProduct(
        updatedProduct,
      );

      if (!mounted) {
        return;
      }

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Product updated successfully.',
            ),
          ),
        );

        Navigator.pop(
          context,
          updatedProduct,
        );
      } else {
        _showMessage(
          'Failed to update product.',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Error updating product: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'Enter product name',
                prefixIcon: Icon(Icons.inventory_2),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _categoryController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'Enter product category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _sellingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                hintText: 'Enter selling price',
                prefixIcon: Icon(Icons.sell),
                prefixText: 'TZS ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _costPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Cost Price',
                hintText: 'Enter cost price',
                prefixIcon: Icon(Icons.shopping_cart),
                prefixText: 'TZS ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter product description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text(
                  'Current Stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  '${widget.product.stock}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Stock cannot be changed from the product edit screen.',
              style: TextStyle(
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProduct,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}