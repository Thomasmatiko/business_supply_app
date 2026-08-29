class Product {
  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final double costPrice;
  final int stock;
  final String description;

  // Seller who owns this product.
  // Nullable so existing products continue working.
  final String? sellerId;

  // Product image path.
  // Nullable so existing products without images continue working.
  final String? imagePath;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.costPrice,
    required this.stock,
    this.description = '',
    this.sellerId,
    this.imagePath,
  });

  // ============================================================
  // PROFIT
  // ============================================================

  double get profit {
    return sellingPrice - costPrice;
  }

  // ============================================================
  // LOW STOCK
  // ============================================================

  bool get isLowStock {
    return stock <= 10;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? sellingPrice,
    double? costPrice,
    int? stock,
    String? description,
    String? sellerId,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      sellerId: sellerId ?? this.sellerId,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  // ============================================================
  // TO MAP
  //
  // Convert Product to SQLite database format.
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'stock': stock,
      'description': description,
      'seller_id': sellerId,
      'image_path': imagePath,
    };
  }

  // ============================================================
  // FROM MAP
  //
  // Convert SQLite database data to Product.
  // ============================================================

  factory Product.fromMap(
    Map<String, dynamic> map,
  ) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      sellingPrice:
          (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      costPrice:
          (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      stock:
          (map['stock'] as num?)?.toInt() ?? 0,
      description:
          map['description']?.toString() ?? '',
      sellerId:
          map['seller_id']?.toString(),
      imagePath:
          map['image_path']?.toString(),
    );
  }
}