class Order {
  /// Unique order ID.
  final String id;

  /// User who bought the product.
  final String buyerId;

  /// Seller who owns the product.
  final String sellerId;

  /// Product being ordered.
  final String productId;

  /// Number of units ordered.
  final int quantity;

  /// Product selling price at the time of order.
  final double unitPrice;

  /// quantity × unitPrice.
  final double totalAmount;

  /// Order status.
  ///
  /// Possible values:
  /// pending
  /// confirmed
  /// processing
  /// shipped
  /// delivered
  /// cancelled
  final String status;

  /// User who originally created the order.
  ///
  /// Normally this will be the buyer.
  final String createdBy;

  /// Date and time the order was created.
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  // ============================================================
  // COPY WITH
  // ============================================================

  Order copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    String? status,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory Order.fromMap(
    Map<String, dynamic> map,
  ) {
    return Order(
      id: map['id']?.toString() ?? '',

      buyerId:
          map['buyer_id']?.toString() ??
          map['created_by']?.toString() ??
          '',

      sellerId:
          map['seller_id']?.toString() ?? '',

      productId:
          map['product_id']?.toString() ?? '',

      quantity:
          (map['quantity'] as num?)?.toInt() ?? 0,

      unitPrice:
          (map['unit_price'] as num?)?.toDouble() ?? 0.0,

      totalAmount:
          (map['total_amount'] as num?)?.toDouble() ?? 0.0,

      status:
          map['status']?.toString() ?? 'pending',

      createdBy:
          map['created_by']?.toString() ?? '',

      createdAt:
          DateTime.tryParse(
                map['created_at']?.toString() ?? '',
              ) ??
              DateTime.now(),
    );
  }
}