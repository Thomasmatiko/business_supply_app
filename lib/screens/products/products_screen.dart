import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService =
      ProductService.instance;

  final AuthService _authService =
      AuthService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  List<Product> _products = [];

  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // CURRENT USER / PERMISSIONS
  // ============================================================

  bool get _isBuyer {
    return _authService.isBuyer;
  }

  bool get _canManageProducts {
    return _authService.canManageProducts;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRODUCTS
  // ============================================================

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        throw Exception('No logged-in user.');
      }

      List<Product> products;

      // ========================================================
      // BUYER
      //
      // Buyers can see ALL products from ALL sellers.
      // ========================================================

      if (currentUser.isBuyer) {
        products = await _productService.getProducts();
      }

      // ========================================================
      // SELLER
      //
      // Sellers can see ONLY their own products.
      // ========================================================

      else if (currentUser.isSeller) {
        products =
            await _productService.getProductsBySeller(
          currentUser.id,
        );
      }

      // ========================================================
      // ADMIN
      //
      // Normal Admin and Leader Admin see ALL products.
      // ========================================================

      else if (currentUser.isAnyAdmin) {
        products = await _productService.getProducts();
      }

      // ========================================================
      // UNKNOWN ROLE
      // ========================================================

      else {
        products = [];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load products.';
      });

      debugPrint(
        'Products loading error: $e',
      );
    }
  }

  // ============================================================
  // SEARCH PRODUCTS
  // ============================================================

  Future<void> _searchProducts(
    String query,
  ) async {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return;
    }

    final searchQuery = query.trim();

    // ==========================================================
    // EMPTY SEARCH
    // ==========================================================

    if (searchQuery.isEmpty) {
      await _loadProducts();
      return;
    }

    try {
      List<Product> products;

      // ========================================================
      // BUYER
      //
      // Search ALL marketplace products.
      // ========================================================

      if (currentUser.isBuyer) {
        products =
            await _productService.searchProducts(
          searchQuery,
        );
      }

      // ========================================================
      // SELLER
      //
      // Search ONLY seller's products.
      // ========================================================

      else if (currentUser.isSeller) {
        products =
            await _productService.searchProductsBySeller(
          currentUser.id,
          searchQuery,
        );
      }

      // ========================================================
      // ADMIN
      //
      // Search ALL products.
      // ========================================================

      else if (currentUser.isAnyAdmin) {
        products =
            await _productService.searchProducts(
          searchQuery,
        );
      }

      // ========================================================
      // UNKNOWN ROLE
      // ========================================================

      else {
        products = [];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
      });
    } catch (e) {
      debugPrint(
        'Product search error: $e',
      );
    }
  }

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  Future<void> _openAddProductScreen() async {
    if (!_canManageProducts) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddProductScreen(),
      ),
    );

    if (result == true) {
      await _loadProducts();
    }
  }

  // ============================================================
  // OPEN PRODUCT DETAILS
  // ============================================================

  Future<void> _openProductDetails(
    Product product,
  ) async {
    final updatedProduct =
        await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailsScreen(
          product: product,
        ),
      ),
    );

    if (!mounted || updatedProduct == null) {
      return;
    }

    setState(() {
      final index = _products.indexWhere(
        (item) => item.id == updatedProduct.id,
      );

      if (index != -1) {
        _products[index] = updatedProduct;
      }
    });
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshProducts() async {
    _searchController.clear();
    await _loadProducts();
  }

  // ============================================================
  // PRICE FORMAT
  // ============================================================

  String _formatPrice(
    double price,
  ) {
    final formatted =
        price.toStringAsFixed(0);

    final reversed =
        formatted.split('').reversed.toList();

    final buffer = StringBuffer();

    for (int i = 0;
        i < reversed.length;
        i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(reversed[i]);
    }

    return 'TZS ${buffer.toString().split('').reversed.join()}';
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
        title: Text(
          _isBuyer
              ? 'Marketplace'
              : 'Products',
        ),
        actions: [
          IconButton(
            onPressed: _refreshProducts,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),

      // ========================================================
      // ADD PRODUCT BUTTON
      //
      // Buyer does NOT see this.
      //
      // Seller and Admin can see this.
      // ========================================================

      floatingActionButton:
          _canManageProducts
              ? FloatingActionButton(
                  onPressed:
                      _openAddProductScreen,
                  tooltip: 'Add Product',
                  child: const Icon(
                    Icons.add,
                  ),
                )
              : null,

      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        8,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchProducts,
        decoration: InputDecoration(
          hintText: _isBuyer
              ? 'Search marketplace...'
              : 'Search products...',
          prefixIcon: const Icon(
            Icons.search,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadProducts();
                      },
                      icon: const Icon(
                        Icons.clear,
                      ),
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
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
                height: 16,
              ),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshProducts,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(
              height: 120,
            ),
            const Center(
              child: Icon(
                Icons.search_off,
                size: 60,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No products found'
                    : 'No matching products',
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Center(
              child: Text(
                _searchController.text.isEmpty
                    ? _isBuyer
                        ? 'No products are currently available.'
                        : 'Add your first product.'
                    : 'Try a different search.',
                textAlign:
                    TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // PRODUCT LIST
    // ==========================================================

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: ListView.builder(
        padding:
            const EdgeInsets.all(12),
        itemCount: _products.length,
        itemBuilder:
            (context, index) {
          final product =
              _products[index];

          return _buildProductCard(
            product,
          );
        },
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
    Product product,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        onTap: () {
          _openProductDetails(
            product,
          );
        },
        contentPadding:
            const EdgeInsets.all(12),

        // ======================================================
        // PRODUCT ICON
        // ======================================================

        leading: CircleAvatar(
          child: Text(
            product.name.isNotEmpty
                ? product.name[0]
                    .toUpperCase()
                : '?',
          ),
        ),

        // ======================================================
        // PRODUCT NAME
        // ======================================================

        title: Text(
          product.name,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        // ======================================================
        // PRODUCT INFORMATION
        // ======================================================

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 6,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${product.id}',
              ),

              Text(
                'Category: ${product.category}',
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'Selling Price: ${_formatPrice(product.sellingPrice)}',
              ),

              Text(
                'Stock: ${product.stock}',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      product.isLowStock
                          ? Colors.red
                          : Colors.green,
                ),
              ),

              // ==================================================
              // BUYER
              //
              // Buyers can see which seller owns the product.
              // ==================================================

              if (_isBuyer &&
                  product.sellerId != null)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 4,
                  ),
                  child: Text(
                    'Seller ID: ${product.sellerId}',
                    style:
                        const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        isThreeLine: true,

        trailing:
            const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}