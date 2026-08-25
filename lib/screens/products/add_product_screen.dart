import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ProductService _productService =
      ProductService.instance;

  final AuthService _authService =
      AuthService.instance;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE PRODUCT
  // ============================================================

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in to add a product.',
          ),
        ),
      );

      return;
    }

    // Only sellers and admins can create products.
    if (!_authService.canCreateProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You do not have permission to add products.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Generate product ID automatically.
      final productId =
          DateTime.now().millisecondsSinceEpoch.toString();

      // ========================================================
      // SELLER OWNERSHIP
      //
      // If the logged-in user is a seller, this product belongs
      // to that seller.
      //
      // If the logged-in user is an admin, sellerId remains null
      // for now. Later we can allow the admin to select a seller.
      // ========================================================

      String? sellerId;

      if (currentUser.isSeller) {
        sellerId = currentUser.id;
      }

      final product = Product(
        id: productId,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        sellingPrice: double.parse(
          _sellingPriceController.text.trim(),
        ),
        costPrice: double.parse(
          _costPriceController.text.trim(),
        ),
        stock: int.parse(
          _stockController.text.trim(),
        ),
        description: _descriptionController.text.trim(),
        sellerId: sellerId,
      );

      await _productService.addProduct(
        product,
        sellerId: sellerId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentUser.isSeller
                ? 'Product added successfully to your store.'
                : 'Product added successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add product: $e',
          ),
        ),
      );

      debugPrint(
        'Add product error: $e',
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    final isSeller =
        currentUser?.isSeller ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Product',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              if (isSeller)
                const Text(
                  'This product will automatically belong to your store.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                )
              else
                const Text(
                  'Create a new product.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

              const SizedBox(height: 20),

              // ==================================================
              // PRODUCT NAME
              // ==================================================

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  prefixIcon: Icon(
                    Icons.inventory_2,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter product name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // CATEGORY
              // ==================================================

              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Enter product category',
                  prefixIcon: Icon(
                    Icons.category,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter category';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // SELLING PRICE
              // ==================================================

              TextFormField(
                controller:
                    _sellingPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Selling Price (TZS)',
                  hintText:
                      'Enter selling price in TZS',
                  prefixIcon: Icon(
                    Icons.payments,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter selling price';
                  }

                  final price =
                      double.tryParse(
                    value.trim(),
                  );

                  if (price == null ||
                      price < 0) {
                    return 'Enter a valid selling price';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // COST PRICE
              // ==================================================

              TextFormField(
                controller:
                    _costPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Cost Price (TZS)',
                  hintText:
                      'Enter cost price in TZS',
                  prefixIcon: Icon(
                    Icons.price_check,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter cost price';
                  }

                  final price =
                      double.tryParse(
                    value.trim(),
                  );

                  if (price == null ||
                      price < 0) {
                    return 'Enter a valid cost price';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // STOCK
              // ==================================================

              TextFormField(
                controller: _stockController,
                keyboardType:
                    TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  hintText:
                      'Enter stock quantity',
                  prefixIcon: Icon(
                    Icons.warehouse,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter stock quantity';
                  }

                  final stock =
                      int.tryParse(
                    value.trim(),
                  );

                  if (stock == null ||
                      stock < 0) {
                    return 'Enter a valid stock quantity';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              TextFormField(
                controller:
                    _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'Enter product description',
                  prefixIcon: Icon(
                    Icons.description,
                  ),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isSaving
                          ? null
                          : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child:
                              CircularProgressIndicator(),
                        )
                      : const Text(
                          'Save Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}