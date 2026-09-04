
import '../database/database_helper.dart';
import 'activity_log_service.dart';

class PaymentService {
  // ============================================================
  // SINGLETON
  // ============================================================

  static final PaymentService instance =
      PaymentService._init();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  final ActivityLogService _activityLogService =
      ActivityLogService.instance;

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
    final cleanOrderId = orderId.trim();
    final cleanBuyerId = buyerId.trim();
    final cleanMethod = method.trim().toLowerCase();
    final cleanReference =
        transactionReference?.trim();

    if (cleanOrderId.isEmpty) {
      throw Exception('Order ID is required.');
    }

    if (cleanBuyerId.isEmpty) {
      throw Exception('Buyer ID is required.');
    }

    if (amount <= 0) {
      throw Exception(
        'Payment amount must be greater than zero.',
      );
    }

    if (!paymentMethods.contains(cleanMethod)) {
      throw Exception('Invalid payment method.');
    }

    // ----------------------------------------------------------
    // Verify order
    // ----------------------------------------------------------

    final orderResult = await _databaseHelper.query(
      'orders',
      where: 'id = ?',
      whereArgs: [cleanOrderId],
      limit: 1,
    );

    if (orderResult.isEmpty) {
      throw Exception('Order not found.');
    }

    final order = orderResult.first;

    final orderBuyerId =
        order['buyer_id']?.toString().trim() ?? '';

    if (orderBuyerId.isEmpty ||
        orderBuyerId != cleanBuyerId) {
      throw Exception(
        'Buyer does not match the order.',
      );
    }

    // ----------------------------------------------------------
    // Verify buyer exists
    // ----------------------------------------------------------

    final buyerResult = await _databaseHelper.query(
      'users',
      columns: [
        'id',
        'name',
      ],
      where: 'id = ?',
      whereArgs: [cleanBuyerId],
      limit: 1,
    );

    if (buyerResult.isEmpty) {
      throw Exception('Buyer not found.');
    }

    final buyerName =
        buyerResult.first['name']?.toString();

    // ----------------------------------------------------------
    // Prevent duplicate active payment
    //
    // A failed/cancelled payment can be replaced.
    // Pending/completed payments cannot be duplicated.
    // ----------------------------------------------------------

    final existingPayments =
        await _databaseHelper.query(
      'payments',
      where:
          'order_id = ? AND status IN (?, ?)',
      whereArgs: [
        cleanOrderId,
        pending,
        completed,
      ],
      limit: 1,
    );

    if (existingPayments.isNotEmpty) {
      final existingStatus =
          existingPayments.first['status']
              ?.toString();

      if (existingStatus == completed) {
        throw Exception(
          'This order has already been paid.',
        );
      }

      throw Exception(
        'This order already has a pending payment.',
      );
    }

    // ----------------------------------------------------------
    // Generate payment
    // ----------------------------------------------------------

    final paymentId =
        'PAY-${DateTime.now().microsecondsSinceEpoch}';

    final now =
        DateTime.now().toIso8601String();

    final payment = {
      'id': paymentId,
      'order_id': cleanOrderId,
      'buyer_id': cleanBuyerId,
      'amount': amount,
      'payment_method': cleanMethod,
      'status': pending,
      'transaction_reference':
          cleanReference?.isEmpty == true
              ? null
              : cleanReference,
      'created_at': now,
      'updated_at': now,
      'paid_at': null,
    };

    // ----------------------------------------------------------
    // Payment + order synchronization
    // ----------------------------------------------------------

    final db =
        await _databaseHelper.database;

    await db.transaction(
      (txn) async {
        await txn.insert(
          'payments',
          payment,
        );

        await txn.update(
          'orders',
          {
            'payment_status': pending,
            'payment_id': paymentId,
          },
          where: 'id = ?',
          whereArgs: [cleanOrderId],
        );
      },
    );

    // ----------------------------------------------------------
    // Activity + Audit
    // ----------------------------------------------------------

    await _activityLogService.logAction(
      userId: cleanBuyerId,
      userName: buyerName,
      action: 'CREATE_PAYMENT',
      type: 'payment',
      entityType: 'payment',
      entityId: paymentId,
      description:
          'Payment $paymentId was created for order '
          '$cleanOrderId. Amount: $amount. '
          'Method: $cleanMethod. Status: $pending.',
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
      whereArgs: [paymentId.trim()],
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

    final result =
        await _databaseHelper.rawQuery(
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
      [paymentId.trim()],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ============================================================
  // GET ALL PAYMENTS FOR ADMIN
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
      whereArgs: [orderId.trim()],
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
      whereArgs: [buyerId.trim()],
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
  // VALIDATE STATUS TRANSITION
  // ============================================================

  bool _isValidStatusTransition(
    String currentStatus,
    String newStatus,
  ) {
    if (currentStatus == newStatus) {
      return false;
    }

    switch (currentStatus) {
      case pending:
        return newStatus == completed ||
            newStatus == failed ||
            newStatus == cancelled;

      case completed:
        return false;

      case failed:
        return newStatus == pending ||
            newStatus == cancelled;

      case cancelled:
        return false;

      default:
        return false;
    }
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================

  Future<int> updatePaymentStatus({
    required String paymentId,
    required String status,
  }) async {
    final cleanPaymentId =
        paymentId.trim();

    final cleanStatus =
        status.trim().toLowerCase();

    if (cleanPaymentId.isEmpty) {
      throw Exception('Payment ID is required.');
    }

    if (!paymentStatuses.contains(cleanStatus)) {
      throw Exception('Invalid payment status.');
    }

    // ----------------------------------------------------------
    // Get current payment
    // ----------------------------------------------------------

    final payment =
        await getPaymentById(cleanPaymentId);

    if (payment == null) {
      throw Exception('Payment not found.');
    }

    final currentStatus =
        payment['status']?.toString() ?? pending;

    if (currentStatus == cleanStatus) {
      return 0;
    }

    if (!_isValidStatusTransition(
      currentStatus,
      cleanStatus,
    )) {
      throw Exception(
        'Invalid payment status transition: '
        '$currentStatus → $cleanStatus.',
      );
    }

    final orderId =
        payment['order_id']?.toString();

    final buyerId =
        payment['buyer_id']?.toString();

    if (orderId == null ||
        orderId.trim().isEmpty) {
      throw Exception(
        'Payment has no valid order.',
      );
    }

    // ----------------------------------------------------------
    // Get buyer
    // ----------------------------------------------------------

    String? buyerName;

    if (buyerId != null &&
        buyerId.trim().isNotEmpty) {
      final buyer =
          await _databaseHelper.query(
        'users',
        columns: [
          'name',
        ],
        where: 'id = ?',
        whereArgs: [buyerId.trim()],
        limit: 1,
      );

      if (buyer.isNotEmpty) {
        buyerName =
            buyer.first['name']?.toString();
      }
    }

    // ----------------------------------------------------------
    // Prepare values
    // ----------------------------------------------------------

    final now =
        DateTime.now().toIso8601String();

    final Map<String, dynamic> values = {
      'status': cleanStatus,
      'updated_at': now,
    };

    if (cleanStatus == completed) {
      values['paid_at'] = now;
    } else {
      values['paid_at'] = null;
    }

    // ----------------------------------------------------------
    // Update payment + order atomically
    // ----------------------------------------------------------

    final db =
        await _databaseHelper.database;

    int updated = 0;

    await db.transaction(
      (txn) async {
        updated = await txn.update(
          'payments',
          values,
          where: 'id = ?',
          whereArgs: [cleanPaymentId],
        );

        if (updated == 0) {
          throw Exception(
            'Payment could not be updated.',
          );
        }

        await txn.update(
          'orders',
          {
            'payment_status': cleanStatus,
            'payment_id': cleanPaymentId,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );
      },
    );

    // ----------------------------------------------------------
    // Activity + Audit
    // ----------------------------------------------------------

    String action;

    switch (cleanStatus) {
      case completed:
        action = 'COMPLETE_PAYMENT';
        break;

      case failed:
        action = 'FAIL_PAYMENT';
        break;

      case cancelled:
        action = 'CANCEL_PAYMENT';
        break;

      default:
        action = 'UPDATE_PAYMENT_STATUS';
    }

    await _activityLogService.logAction(
      userId: buyerId,
      userName: buyerName,
      action: action,
      type: 'payment',
      entityType: 'payment',
      entityId: cleanPaymentId,
      description:
          'Payment $cleanPaymentId for order '
          '$orderId changed from $currentStatus '
          'to $cleanStatus.',
    );

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
    final cleanPaymentId =
        paymentId.trim();

    if (cleanPaymentId.isEmpty) {
      throw Exception('Payment ID is required.');
    }

    // ----------------------------------------------------------
    // Get payment before deletion so we know what to audit.
    // ----------------------------------------------------------

    final payment =
        await getPaymentById(cleanPaymentId);

    if (payment == null) {
      return 0;
    }

    final orderId =
        payment['order_id']?.toString();

    final buyerId =
        payment['buyer_id']?.toString();

    final status =
        payment['status']?.toString() ?? '';

    // ----------------------------------------------------------
    // Get buyer name
    // ----------------------------------------------------------

    String? buyerName;

    if (buyerId != null &&
        buyerId.trim().isNotEmpty) {
      final buyer =
          await _databaseHelper.query(
        'users',
        columns: [
          'name',
        ],
        where: 'id = ?',
        whereArgs: [buyerId.trim()],
        limit: 1,
      );

      if (buyer.isNotEmpty) {
        buyerName =
            buyer.first['name']?.toString();
      }
    }

    // ----------------------------------------------------------
    // Delete payment and clean order reference.
    // ----------------------------------------------------------

    final db =
        await _databaseHelper.database;

    int deleted = 0;

    await db.transaction(
      (txn) async {
        deleted = await txn.delete(
          'payments',
          where: 'id = ?',
          whereArgs: [cleanPaymentId],
        );

        if (deleted > 0 &&
            orderId != null &&
            orderId.trim().isNotEmpty) {
          await txn.update(
            'orders',
            {
              'payment_id': null,
              'payment_status': pending,
            },
            where: 'id = ?',
            whereArgs: [orderId],
          );
        }
      },
    );

    // ----------------------------------------------------------
    // Activity + Audit
    // ----------------------------------------------------------

    if (deleted > 0) {
      await _activityLogService.logAction(
        userId: buyerId,
        userName: buyerName,
        action: 'DELETE_PAYMENT',
        type: 'payment',
        entityType: 'payment',
        entityId: cleanPaymentId,
        description:
            'Payment $cleanPaymentId was deleted.'
            ' Order: ${orderId ?? 'unknown'}.'
            ' Previous status: $status.',
      );
    }

    return deleted;
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

    return (result.first['count'] as num?)
            ?.toInt() ??
        0;
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
      [buyerId.trim()],
    );

    if (result.isEmpty) {
      return 0;
    }

    return (result.first['count'] as num?)
            ?.toInt() ??
        0;
  }

  // ============================================================
  // TOTAL COMPLETED PAYMENT AMOUNT
  // ============================================================

  Future<double> getTotalPaymentAmount() async {
    final result =
        await _databaseHelper.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM payments
      WHERE status = ?
      ''',
      [completed],
    );

    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0.0;
  }

  // ============================================================
  // BUYER TOTAL COMPLETED PAYMENT AMOUNT
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
      AND status = ?
      ''',
      [
        buyerId.trim(),
        completed,
      ],
    );

    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0.0;
  }

  // ============================================================
  // GET PAYMENTS BY STATUS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPaymentsByStatus(
    String status,
  ) async {
    final cleanStatus =
        status.trim().toLowerCase();

    if (!paymentStatuses.contains(cleanStatus)) {
      throw Exception('Invalid payment status.');
    }

    return _databaseHelper.query(
      'payments',
      where: 'status = ?',
      whereArgs: [cleanStatus],
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

    final cleanStatus =
        status.trim().toLowerCase();

    if (!paymentStatuses.contains(cleanStatus)) {
      throw Exception('Invalid payment status.');
    }

    return _databaseHelper.query(
      'payments',
      where:
          'buyer_id = ? AND status = ?',
      whereArgs: [
        buyerId.trim(),
        cleanStatus,
      ],
      orderBy: 'created_at DESC',
    );
  }
}

