
import '../database/database_helper.dart';

class PaymentService {
  // ============================================================
  // SINGLETON
  // ============================================================

  static final PaymentService instance =
      PaymentService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  PaymentService._init();

  // ============================================================
  // PAYMENT METHODS
  // ============================================================

  static const String mpesa = 'mpesa';
  static const String tigopesa = 'tigopesa';
  static const String airtelmoney = 'airtelmoney';
  static const String bank = 'bank';
  static const String cash = 'cash';

  static const List<String> paymentMethods = [
    mpesa,
    tigopesa,
    airtelmoney,
    bank,
    cash,
  ];

  // ============================================================
  // PAYMENT STATUSES
  // ============================================================

  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';

  static const List<String> paymentStatuses = [
    pending,
    completed,
    failed,
    cancelled,
  ];

  // ============================================================
  // CREATE PAYMENT
  // ============================================================

  Future<String> createPayment({
    required String orderId,
    required String buyerId,
    required double amount,
    required String method,
    String? transactionReference,
  }) async {
    if (orderId.trim().isEmpty) {
      throw Exception('Order ID is required.');
    }

    if (buyerId.trim().isEmpty) {
      throw Exception('Buyer ID is required.');
    }

    if (amount <= 0) {
      throw Exception(
        'Payment amount must be greater than zero.',
      );
    }

    if (!paymentMethods.contains(method)) {
      throw Exception('Invalid payment method.');
    }

    final paymentId =
        'PAY-${DateTime.now().microsecondsSinceEpoch}';

    final now = DateTime.now().toIso8601String();

    final payment = {
      'id': paymentId,
      'order_id': orderId,
      'buyer_id': buyerId,
      'amount': amount,
      'payment_method': method,
      'status': pending,
      'transaction_reference':
          transactionReference?.trim(),
      'created_at': now,
      'updated_at': now,
      'paid_at': null,
    };

    await _databaseHelper.insert(
      'payments',
      payment,
    );

    // Keep the order payment information synchronized.
    await _databaseHelper.update(
      'orders',
      {
        'payment_status': pending,
        'payment_id': paymentId,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );

    return paymentId;
  }

  // ============================================================
  // GET PAYMENT BY ID
  // ============================================================

  Future<Map<String, dynamic>?> getPaymentById(
    String paymentId,
  ) async {
    if (paymentId.trim().isEmpty) {
      return null;
    }

    final result =
        await _databaseHelper.query(
      'payments',
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ============================================================
  // GET PAYMENT DETAILS
  //
  // Includes:
  // - Payment
  // - Order
  // - Buyer
  // - Seller
  // ============================================================

  Future<Map<String, dynamic>?> getPaymentDetails(
    String paymentId,
  ) async {
    if (paymentId.trim().isEmpty) {
      return null;
    }

    final result = await _databaseHelper.rawQuery(
      '''
      SELECT
        p.id AS payment_id,
        p.order_id,
        p.buyer_id,
        p.amount,
        p.payment_method,
        p.status AS payment_status,
        p.transaction_reference,
        p.created_at AS payment_created_at,
        p.updated_at AS payment_updated_at,
        p.paid_at,

        o.product_id,
        o.quantity,
        o.unit_price,
        o.total_amount,
        o.status AS order_status,
        o.created_at AS order_created_at,
        o.seller_id,

        buyer.name AS buyer_name,
        buyer.email AS buyer_email,
        buyer.phone AS buyer_phone,

        seller.name AS seller_name,
        seller.email AS seller_email,
        seller.phone AS seller_phone

      FROM payments p

      LEFT JOIN orders o
        ON o.id = p.order_id

      LEFT JOIN users buyer
        ON buyer.id = p.buyer_id

      LEFT JOIN users seller
        ON seller.id = o.seller_id

      WHERE p.id = ?

      LIMIT 1
      ''',
      [paymentId],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ============================================================
  // GET ALL PAYMENTS FOR ADMIN
  //
  // Includes buyer and seller information.
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getAllPaymentsWithPeople() async {
    return _databaseHelper.rawQuery(
      '''
      SELECT
        p.id AS payment_id,
        p.order_id,
        p.buyer_id,
        p.amount,
        p.payment_method,
        p.status AS payment_status,
        p.transaction_reference,
        p.created_at AS payment_created_at,
        p.updated_at AS payment_updated_at,
        p.paid_at,

        o.product_id,
        o.quantity,
        o.unit_price,
        o.total_amount,
        o.status AS order_status,
        o.created_at AS order_created_at,
        o.seller_id,

        buyer.name AS buyer_name,
        buyer.email AS buyer_email,
        buyer.phone AS buyer_phone,

        seller.name AS seller_name,
        seller.email AS seller_email,
        seller.phone AS seller_phone,

        pr.name AS product_name

      FROM payments p

      LEFT JOIN orders o
        ON o.id = p.order_id

      LEFT JOIN users buyer
        ON buyer.id = p.buyer_id

      LEFT JOIN users seller
        ON seller.id = o.seller_id

      LEFT JOIN products pr
        ON pr.id = o.product_id

      ORDER BY p.created_at DESC
      ''',
    );
  }

  // ============================================================
  // GET PAYMENT BY ORDER
  // ============================================================

  Future<Map<String, dynamic>?> getPaymentByOrderId(
    String orderId,
  ) async {
    if (orderId.trim().isEmpty) {
      return null;
    }

    final result =
        await _databaseHelper.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ============================================================
  // GET BUYER PAYMENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getBuyerPayments(
    String buyerId,
  ) async {
    if (buyerId.trim().isEmpty) {
      return [];
    }

    return _databaseHelper.query(
      'payments',
      where: 'buyer_id = ?',
      whereArgs: [buyerId],
      orderBy: 'created_at DESC',
    );
  }

  // ============================================================
  // GET ALL PAYMENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    return _databaseHelper.query(
      'payments',
      orderBy: 'created_at DESC',
    );
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================

  Future<int> updatePaymentStatus({
    required String paymentId,
    required String status,
  }) async {
    if (paymentId.trim().isEmpty) {
      throw Exception('Payment ID is required.');
    }

    if (!paymentStatuses.contains(status)) {
      throw Exception('Invalid payment status.');
    }

    final now = DateTime.now().toIso8601String();

    final Map<String, dynamic> values = {
  'status': status,
  'updated_at': now,
};

    if (status == completed) {
      values['paid_at'] = now;
    } else {
      values['paid_at'] = null;
    }

    final updated = await _databaseHelper.update(
      'payments',
      values,
      where: 'id = ?',
      whereArgs: [paymentId],
    );

    // Synchronize the order payment status.
    final payment = await getPaymentById(paymentId);

    if (payment != null) {
      await _databaseHelper.update(
        'orders',
        {
          'payment_status': status,
          'payment_id': paymentId,
        },
        where: 'id = ?',
        whereArgs: [payment['order_id']],
      );
    }

    return updated;
  }

  // ============================================================
  // MARK PAYMENT COMPLETED
  // ============================================================

  Future<int> markPaymentCompleted(
    String paymentId,
  ) async {
    return updatePaymentStatus(
      paymentId: paymentId,
      status: completed,
    );
  }

  // ============================================================
  // MARK PAYMENT FAILED
  // ============================================================

  Future<int> markPaymentFailed(
    String paymentId,
  ) async {
    return updatePaymentStatus(
      paymentId: paymentId,
      status: failed,
    );
  }

  // ============================================================
  // CANCEL PAYMENT
  // ============================================================

  Future<int> cancelPayment(
    String paymentId,
  ) async {
    return updatePaymentStatus(
      paymentId: paymentId,
      status: cancelled,
    );
  }

  // ============================================================
  // DELETE PAYMENT
  // ============================================================

  Future<int> deletePayment(
    String paymentId,
  ) async {
    if (paymentId.trim().isEmpty) {
      throw Exception('Payment ID is required.');
    }

    return _databaseHelper.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  // ============================================================
  // PAYMENT COUNT
  // ============================================================

  Future<int> getPaymentCount() async {
    final result =
        await _databaseHelper.rawQuery(
      'SELECT COUNT(*) AS count FROM payments',
    );

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  // ============================================================
  // BUYER PAYMENT COUNT
  // ============================================================

  Future<int> getBuyerPaymentCount(
    String buyerId,
  ) async {
    if (buyerId.trim().isEmpty) {
      return 0;
    }

    final result =
        await _databaseHelper.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM payments
      WHERE buyer_id = ?
      ''',
      [buyerId],
    );

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  // ============================================================
  // TOTAL PAYMENT AMOUNT
  // ============================================================

  Future<double> getTotalPaymentAmount() async {
    final result =
        await _databaseHelper.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM payments
      ''',
    );

    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ============================================================
  // BUYER TOTAL PAYMENT AMOUNT
  // ============================================================

  Future<double> getBuyerTotalPaymentAmount(
    String buyerId,
  ) async {
    if (buyerId.trim().isEmpty) {
      return 0.0;
    }

    final result =
        await _databaseHelper.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM payments
      WHERE buyer_id = ?
      ''',
      [buyerId],
    );

    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ============================================================
  // GET PAYMENTS BY STATUS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPaymentsByStatus(
    String status,
  ) async {
    if (!paymentStatuses.contains(status)) {
      throw Exception('Invalid payment status.');
    }

    return _databaseHelper.query(
      'payments',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
  }

  // ============================================================
  // GET BUYER PAYMENTS BY STATUS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getBuyerPaymentsByStatus({
    required String buyerId,
    required String status,
  }) async {
    if (buyerId.trim().isEmpty) {
      return [];
    }

    if (!paymentStatuses.contains(status)) {
      throw Exception('Invalid payment status.');
    }

    return _databaseHelper.query(
      'payments',
      where: 'buyer_id = ? AND status = ?',
      whereArgs: [
        buyerId,
        status,
      ],
      orderBy: 'created_at DESC',
    );
  }
}

