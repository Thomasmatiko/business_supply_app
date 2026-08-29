
import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class PublicProductsScreen extends StatefulWidget {
  const PublicProductsScreen({super.key});

  @override
  State<PublicProductsScreen> createState() =>
      _PublicProductsScreenState();
}

class _PublicProductsScreenState
    extends State<PublicProductsScreen> {
  final ProductService _productService =
      ProductService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  String _selectedCategory = 'All';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadProducts();

    _searchController.addListener(
      _filterProducts,
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filterProducts,
    );

    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products =
          await _productService.getProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });

      _filterProducts();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load products. Please try again.';
      });

      debugPrint(
        'Public products loading error: $e',
      );
    }
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  List<String> get _categories {
    final categories = _allProducts
        .map(
          (product) => product.category.trim(),
        )
        .where(
          (category) => category.isNotEmpty,
        )
        .toSet()
        .toList();

    categories.sort();

    return [
      'All',
      ...categories,
    ];
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _filterProducts() {
    final search =
        _searchController.text.trim().toLowerCase();

    final filtered =
        _allProducts.where((product) {
      final matchesSearch =
          product.name
                  .toLowerCase()
                  .contains(search) ||
              product.category
                  .toLowerCase()
                  .contains(search) ||
              product.description
                  .toLowerCase()
                  .contains(search);

      final matchesCategory =
          _selectedCategory == 'All' ||
              product.category ==
                  _selectedCategory;

      return matchesSearch &&
          matchesCategory;
    }).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredProducts = filtered;
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

    for (int i = 0;
        i < reversed.length;
        i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add(',');
      }

      formatted.add(
        reversed[i],
      );
    }

    return formatted.reversed.join();
  }

  // ============================================================
  // OPEN PRODUCT DETAILS
  // ============================================================

  void _openProductDetails(Product product) {
    Navigator.pushNamed(
      context,
      AppRoutes.publicProductDetails,
      arguments: product,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadProducts,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.35,
          ),
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    _errorMessage!,
                    textAlign:
                        TextAlign.center,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  FilledButton(
                    onPressed:
                        _loadProducts,
                    child:
                        const Text(
                      'Try Again',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildSearchField(),
        const SizedBox(height: 16),
        _buildCategoryFilter(),
        const SizedBox(height: 20),
        _buildProductCount(),
        const SizedBox(height: 12),
        _buildProducts(),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Find Products',
          style: TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Browse products available for your business.',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction:
          TextInputAction.search,
      decoration: InputDecoration(
        hintText:
            'Search products...',
        prefixIcon:
            const Icon(Icons.search),
        suffixIcon:
            _searchController.text
                    .isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController
                          .clear();
                    },
                    icon:
                        const Icon(
                      Icons.clear,
                    ),
                  )
                : null,
        border:
            const OutlineInputBorder(),
      ),
    );
  }

  // ============================================================
  // CATEGORY FILTER
  // ============================================================

  Widget _buildCategoryFilter() {
    final categories =
        _categories;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            categories.length,

        // FIXED:
        // The previous code used (_, _) which
        // declared the same parameter twice.
        separatorBuilder:
            (context, index) =>
                const SizedBox(
          width: 8,
        ),

        itemBuilder:
            (context, index) {
          final category =
              categories[index];

          final selected =
              category ==
                  _selectedCategory;

          return ChoiceChip(
            label:
                Text(category),
            selected:
                selected,
            onSelected: (selected) {
              if (!selected) {
                return;
              }

              setState(() {
                _selectedCategory =
                    category;
              });

              _filterProducts();
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // PRODUCT COUNT
  // ============================================================

  Widget _buildProductCount() {
    return Text(
      '${_filteredProducts.length} product${_filteredProducts.length == 1 ? '' : 's'} found',
      style:
          const TextStyle(
        fontWeight:
            FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Widget _buildProducts() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          _filteredProducts.map(
        (product) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child:
                _buildProductCard(
              product,
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
    Product product,
  ) {
    final available =
        product.stock > 0;

    return Card(
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _openProductDetails(
            product,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildProductIcon(
                product,
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      product.category,
                      style:
                          TextStyle(
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .primary,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'TZS ${_formatCurrency(product.sellingPrice)}',
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Row(
                      children: [
                        Icon(
                          available
                              ? Icons
                                  .check_circle
                              : Icons
                                  .cancel,
                          size: 17,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          available
                              ? 'Available'
                              : 'Out of stock',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductIcon(
    Product product,
  ) {
    final imagePath =
        product.imagePath?.trim();

    return Container(
      width: 72,
      height: 72,
      clipBehavior:
          Clip.antiAlias,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      child: imagePath != null &&
              imagePath.isNotEmpty
          ? Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return _buildProductPlaceholder();
              },
            )
          : _buildProductPlaceholder(),
    );
  }

  // ============================================================
  // PRODUCT IMAGE PLACEHOLDER
  // ============================================================

  Widget _buildProductPlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 34,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text
                        .trim()
                        .isNotEmpty ||
                    _selectedCategory !=
                        'All'
                ? 'Try another search or category.'
                : 'There are currently no products available.',
            textAlign:
                TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_searchController.text
                  .trim()
                  .isNotEmpty ||
              _selectedCategory !=
                  'All')
            OutlinedButton(
              onPressed: () {
                _searchController
                    .clear();

                setState(() {
                  _selectedCategory =
                      'All';
                });

                _filterProducts();
              },
              child:
                  const Text(
                'Clear Filters',
              ),
            ),
        ],
      ),
    );
  }
}

