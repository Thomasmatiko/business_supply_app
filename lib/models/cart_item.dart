class CartItem {
  final String id;
  final String buyerId;
  final String productId;
  final String sellerId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imagePath;

  const CartItem({
    required this.id,
    required this.buyerId,
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imagePath,
  });

  // ============================================================
  // TOTAL
  // ============================================================

  double get total {
    return unitPrice * quantity;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  CartItem copyWith({
    String? id,
    String? buyerId,
    String? productId,
    String? sellerId,
    String? productName,
    double? unitPrice,
    int? quantity,
    String? imagePath,
  }) {
    return CartItem(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'product_id': productId,
      'seller_id': sellerId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'image_path': imagePath,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory CartItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return CartItem(
      id: map['id']?.toString() ?? '',
      buyerId: map['buyer_id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      productName:
          map['product_name']?.toString() ?? '',
      unitPrice:
          (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity:
          (map['quantity'] as num?)?.toInt() ?? 0,
      imagePath:
          map['image_path']?.toString(),
    );
  }
}