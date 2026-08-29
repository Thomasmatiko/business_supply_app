class Payment {
  final String id;
  final String orderId;
  final String buyerId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? transactionReference;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionReference,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
  });

  // ============================================================
  // COPY WITH
  // ============================================================

  Payment copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    double? amount,
    String? paymentMethod,
    String? status,
    String? transactionReference,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      amount: amount ?? this.amount,
      paymentMethod:
          paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionReference:
          transactionReference ??
              this.transactionReference,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
      paidAt:
          paidAt ?? this.paidAt,
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory Payment.fromMap(
    Map<String, dynamic> map,
  ) {
    return Payment(
      id: map['id'].toString(),
      orderId: map['order_id'].toString(),
      buyerId: map['buyer_id'].toString(),
      amount:
          (map['amount'] as num).toDouble(),
      paymentMethod:
          map['payment_method']?.toString() ??
              map['method']?.toString() ??
              'cash',
      status:
          map['status']?.toString() ??
              'pending',
      transactionReference:
          map['transaction_reference']
              ?.toString(),
      createdAt:
          DateTime.parse(
        map['created_at'].toString(),
      ),
      updatedAt:
          map['updated_at'] != null
              ? DateTime.tryParse(
                  map['updated_at'].toString(),
                )
              : null,
      paidAt:
          map['paid_at'] != null
              ? DateTime.tryParse(
                  map['paid_at'].toString(),
                )
              : null,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'buyer_id': buyerId,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'transaction_reference':
          transactionReference,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String(),
      'paid_at':
          paidAt?.toIso8601String(),
    };
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool get isPending {
    return status.toLowerCase() == 'pending';
  }

  bool get isCompleted {
    return status.toLowerCase() == 'completed';
  }

  bool get isSuccessful {
    return isCompleted;
  }

  bool get isFailed {
    return status.toLowerCase() == 'failed';
  }

  bool get isCancelled {
    return status.toLowerCase() == 'cancelled';
  }

  bool get isRefunded {
    return status.toLowerCase() == 'refunded';
  }

  // ============================================================
  // DISPLAY STATUS
  // ============================================================

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';

      case 'completed':
        return 'Completed';

      case 'failed':
        return 'Failed';

      case 'cancelled':
        return 'Cancelled';

      case 'refunded':
        return 'Refunded';

      default:
        return status;
    }
  }

  // ============================================================
  // PAYMENT METHOD DISPLAY
  // ============================================================

  String get paymentMethodDisplayName {
    switch (paymentMethod.toLowerCase()) {
      case 'mpesa':
        return 'M-Pesa';

      case 'tigopesa':
        return 'Tigo Pesa';

      case 'airtelmoney':
        return 'Airtel Money';

      case 'bank':
        return 'Bank Transfer';

      case 'cash':
        return 'Cash';

      default:
        return paymentMethod;
    }
  }

  // ============================================================
  // DISPLAY TRANSACTION REFERENCE
  // ============================================================

  String get transactionReferenceDisplay {
    if (transactionReference == null ||
        transactionReference!.trim().isEmpty) {
      return 'Not provided';
    }

    return transactionReference!;
  }

  // ============================================================
  // DISPLAY
  // ============================================================

  @override
  String toString() {
    return 'Payment('
        'id: $id, '
        'orderId: $orderId, '
        'buyerId: $buyerId, '
        'amount: $amount, '
        'paymentMethod: $paymentMethod, '
        'status: $status, '
        'transactionReference: '
        '$transactionReference, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'paidAt: $paidAt'
        ')';
  }
}