import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() =>
      _EditProductScreenState();
}

class _EditProductScreenState
    extends State<EditProductScreen> {
  final ProductService _productService =
      ProductService.instance;

  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _descriptionController;

  String? _imagePath;

  bool _isSaving = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.product.name,
    );

    _categoryController = TextEditingController(
      text: widget.product.category,
    );

    _sellingPriceController =
        TextEditingController(
      text: widget.product.sellingPrice
          .toStringAsFixed(0),
    );

    _costPriceController =
        TextEditingController(
      text: widget.product.costPrice
          .toStringAsFixed(0),
    );

    _descriptionController =
        TextEditingController(
      text: widget.product.description,
    );

    _imagePath = widget.product.imagePath;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(
    ImageSource source,
  ) async {
    try {
      final XFile? selectedImage =
          await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (selectedImage == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _imagePath = selectedImage.path;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to select image: $e',
      );

      debugPrint(
        'Edit product image error: $e',
      );
    }
  }

  // ============================================================
  // IMAGE OPTIONS
  // ============================================================

  Future<void> _showImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Product Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.photo_library,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                  ),
                  subtitle: const Text(
                    'Select a new product image',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    _pickImage(
                      ImageSource.gallery,
                    );
                  },
                ),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.camera_alt,
                    ),
                  ),
                  title: const Text(
                    'Take a Photo',
                  ),
                  subtitle: const Text(
                    'Use your device camera',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    _pickImage(
                      ImageSource.camera,
                    );
                  },
                ),

                if (_imagePath != null)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.red.shade50,
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Remove Image',
                    ),
                    subtitle: const Text(
                      'Remove the current image',
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      setState(() {
                        _imagePath = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildProductImage() {
    final hasImage =
        _imagePath != null &&
        _imagePath!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: _showImageOptions,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                context,
                                error,
                                stackTrace,
                              ) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons
                                        .broken_image_outlined,
                                    size: 50,
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Image unavailable',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            decoration:
                                const BoxDecoration(
                              color: Colors.white,
                              shape:
                                  BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed:
                                  _showImageOptions,
                              icon: const Icon(
                                Icons.edit,
                              ),
                              tooltip:
                                  'Change image',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .add_photo_alternate_outlined,
                        size: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Add Product Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Tap to choose from gallery or camera',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE PRODUCT
  // ============================================================

  Future<void> _saveProduct() async {
    if (_isSaving) {
      return;
    }

    final name =
        _nameController.text.trim();

    final category =
        _categoryController.text.trim();

    final sellingPriceText =
        _sellingPriceController.text.trim();

    final costPriceText =
        _costPriceController.text.trim();

    final description =
        _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Product name is required.',
      );
      return;
    }

    if (category.isEmpty) {
      _showMessage(
        'Product category is required.',
      );
      return;
    }

    final sellingPrice =
        double.tryParse(
      sellingPriceText,
    );

    if (sellingPrice == null ||
        sellingPrice < 0) {
      _showMessage(
        'Enter a valid selling price.',
      );
      return;
    }

    final costPrice =
        double.tryParse(
      costPriceText,
    );

    if (costPrice == null ||
        costPrice < 0) {
      _showMessage(
        'Enter a valid cost price.',
      );
      return;
    }

    if (sellingPrice < costPrice) {
      _showMessage(
        'Selling price cannot be lower than cost price.',
      );
      return;
    }

    // ==========================================================
    // CREATE UPDATED PRODUCT
    // ==========================================================

    final updatedProduct =
        widget.product.copyWith(
      name: name,
      category: category,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      description: description,
      imagePath:
          _imagePath ?? widget.product.imagePath,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final result =
          await _productService.updateProduct(
        updatedProduct,
      );

      if (!mounted) {
        return;
      }

      if (result > 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
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

      debugPrint(
        'Edit product error: $e',
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
        title: const Text(
          'Edit Product',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Product Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PRODUCT IMAGE
            // ==================================================

            _buildProductImage(),

            const SizedBox(height: 24),

            // ==================================================
            // PRODUCT NAME
            // ==================================================

            TextFormField(
              controller: _nameController,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  const InputDecoration(
                labelText: 'Product Name',
                hintText:
                    'Enter product name',
                prefixIcon: Icon(
                  Icons.inventory_2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // CATEGORY
            // ==================================================

            TextFormField(
              controller:
                  _categoryController,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  const InputDecoration(
                labelText: 'Category',
                hintText:
                    'Enter product category',
                prefixIcon: Icon(
                  Icons.category,
                ),
              ),
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
              textInputAction:
                  TextInputAction.next,
              decoration:
                  const InputDecoration(
                labelText: 'Selling Price',
                hintText:
                    'Enter selling price',
                prefixIcon: Icon(
                  Icons.sell,
                ),
                prefixText: 'TZS ',
              ),
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
              textInputAction:
                  TextInputAction.next,
              decoration:
                  const InputDecoration(
                labelText: 'Cost Price',
                hintText:
                    'Enter cost price',
                prefixIcon: Icon(
                  Icons.shopping_cart,
                ),
                prefixText: 'TZS ',
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            TextFormField(
              controller:
                  _descriptionController,
              maxLines: 4,
              textInputAction:
                  TextInputAction.newline,
              decoration:
                  const InputDecoration(
                labelText: 'Description',
                hintText:
                    'Enter product description',
                prefixIcon: Icon(
                  Icons.description,
                ),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CURRENT STOCK
            // ==================================================

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.inventory,
                ),
                title: const Text(
                  'Current Stock',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  '${widget.product.stock}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
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

            // ==================================================
            // SAVE BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _isSaving
                        ? null
                        : _saveProduct,
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
      ),
    );
  }
}