
import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final Order order;

  const PaymentScreen({
    super.key,
    required this.order,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final AuthService _authService = AuthService.instance;

  final PaymentService _paymentService = PaymentService.instance;

  final TextEditingController _accountController =
      TextEditingController();

  String? _selectedMethod;

  bool _isProcessing = false;

  // ============================================================
  // BUYER ID
  // ============================================================

  String? get _buyerId {
    return _authService.currentUser?.id;
  }

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice(double amount) {
    final amountString = amount.toStringAsFixed(0);

    final reversed = amountString.split('').reversed.toList();

    final buffer = StringBuffer();

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(reversed[i]);
    }

    return 'TZS ${buffer.toString().split('').reversed.join()}';
  }

  // ============================================================
  // PAYMENT METHOD LABEL
  // ============================================================

  String _methodLabel(String method) {
    switch (method) {
      case PaymentService.mpesa:
        return 'M-Pesa';

      case PaymentService.tigopesa:
        return 'Tigo Pesa';

      case PaymentService.airtelmoney:
        return 'Airtel Money';

      case PaymentService.bank:
        return 'Bank Transfer';

      case PaymentService.cash:
        return 'Cash';

      default:
        return method;
    }
  }

  // ============================================================
  // PAYMENT METHOD ICON
  // ============================================================

  IconData _methodIcon(String method) {
    switch (method) {
      case PaymentService.mpesa:
      case PaymentService.tigopesa:
      case PaymentService.airtelmoney:
        return Icons.phone_android;

      case PaymentService.bank:
        return Icons.account_balance;

      case PaymentService.cash:
        return Icons.payments_outlined;

      default:
        return Icons.payment;
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // REQUIRES ACCOUNT / PHONE
  // ============================================================

  bool get _requiresAccount {
    return _selectedMethod == PaymentService.mpesa ||
        _selectedMethod == PaymentService.tigopesa ||
        _selectedMethod == PaymentService.airtelmoney ||
        _selectedMethod == PaymentService.bank;
  }

  // ============================================================
  // ACCOUNT LABEL
  // ============================================================

  String get _accountLabel {
    switch (_selectedMethod) {
      case PaymentService.mpesa:
      case PaymentService.tigopesa:
      case PaymentService.airtelmoney:
        return 'Phone Number';

      case PaymentService.bank:
        return 'Bank Account / Reference';

      default:
        return 'Payment Reference';
    }
  }

  // ============================================================
  // ACCOUNT HINT
  // ============================================================

  String get _accountHint {
    switch (_selectedMethod) {
      case PaymentService.mpesa:
        return 'Enter M-Pesa phone number';

      case PaymentService.tigopesa:
        return 'Enter Tigo Pesa phone number';

      case PaymentService.airtelmoney:
        return 'Enter Airtel Money phone number';

      case PaymentService.bank:
        return 'Enter bank account or transfer reference';

      default:
        return 'Enter payment reference';
    }
  }

  // ============================================================
  // SELECT PAYMENT METHOD
  // ============================================================

  void _selectPaymentMethod(String method) {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _selectedMethod = method;
      _accountController.clear();
    });
  }

  // ============================================================
  // VALIDATE ACCOUNT
  // ============================================================

  bool _validateAccount() {
    if (!_requiresAccount) {
      return true;
    }

    final value = _accountController.text.trim();

    if (value.isEmpty) {
      _showMessage(
        'Please enter your $_accountLabel.',
      );
      return false;
    }

    final isMobileMoney =
        _selectedMethod == PaymentService.mpesa ||
        _selectedMethod == PaymentService.tigopesa ||
        _selectedMethod == PaymentService.airtelmoney;

    if (isMobileMoney && value.length < 9) {
      _showMessage(
        'Please enter a valid phone number.',
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // PAY NOW
  // ============================================================

  Future<void> _processPayment() async {
    if (_isProcessing) {
      return;
    }

    final buyerId = _buyerId;

    if (buyerId == null || buyerId.trim().isEmpty) {
      _showMessage(
        'Please login as a buyer before making payment.',
      );
      return;
    }

    final method = _selectedMethod;

    if (method == null || method.trim().isEmpty) {
      _showMessage(
        'Please select a payment method.',
      );
      return;
    }

    if (!_validateAccount()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      String? transactionReference;

      final accountValue = _accountController.text.trim();

      if (accountValue.isNotEmpty) {
        transactionReference = accountValue;
      }

      final paymentId = await _paymentService.createPayment(
        orderId: widget.order.id,
        buyerId: buyerId,
        amount: widget.order.totalAmount,
        method: method,
        transactionReference: transactionReference,
      );

      if (!mounted) {
        return;
      }

      await _showPaymentCreatedDialog(
        paymentId: paymentId,
        method: method,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ============================================================
  // PAYMENT CREATED DIALOG
  // ============================================================

  Future<void> _showPaymentCreatedDialog({
    required String paymentId,
    required String method,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment Recorded',
                ),
              ),
            ],
          ),
          content: Text(
            'Your payment has been recorded successfully.\n\n'
            'Method: ${_methodLabel(method)}\n'
            'Amount: ${_formatPrice(widget.order.totalAmount)}\n'
            'Payment ID: $paymentId\n\n'
            'Payment status: Pending',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Continue',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CLEAN ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString().trim();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message.isEmpty
        ? 'Unable to process payment.'
        : message;
  }

  // ============================================================
  // PAYMENT METHOD CARD
  // ============================================================

  Widget _buildPaymentMethod(String method) {
    final selected = _selectedMethod == method;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isProcessing
            ? null
            : () {
                _selectPaymentMethod(method);
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _methodIcon(method),
                  color: selected
                      ? Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                ),
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
                      _methodLabel(method),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      _paymentMethodDescription(method),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Radio<String>(
                value: method,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT METHOD DESCRIPTION
  // ============================================================

  String _paymentMethodDescription(String method) {
    switch (method) {
      case PaymentService.mpesa:
        return 'Pay using M-Pesa';

      case PaymentService.tigopesa:
        return 'Pay using Tigo Pesa';

      case PaymentService.airtelmoney:
        return 'Pay using Airtel Money';

      case PaymentService.bank:
        return 'Pay through bank transfer';

      case PaymentService.cash:
        return 'Pay with cash';

      default:
        return 'Payment method';
    }
  }

  // ============================================================
  // ORDER INFORMATION
  // ============================================================

  Widget _buildOrderInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            _buildInformationRow(
              'Order ID',
              widget.order.id,
            ),

            const SizedBox(
              height: 10,
            ),

            _buildInformationRow(
              'Quantity',
              widget.order.quantity.toString(),
            ),

            const SizedBox(
              height: 10,
            ),

            _buildInformationRow(
              'Unit Price',
              _formatPrice(
                widget.order.unitPrice,
              ),
            ),

            const Divider(
              height: 28,
            ),

            _buildInformationRow(
              'Total',
              _formatPrice(
                widget.order.totalAmount,
              ),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInformationRow(
    String title,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isTotal
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),

        const SizedBox(
          width: 20,
        ),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
              color: isTotal
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACCOUNT INPUT
  // ============================================================

  Widget _buildAccountInput() {
    if (!_requiresAccount) {
      return const SizedBox.shrink();
    }

    final isPhone =
        _selectedMethod == PaymentService.mpesa ||
        _selectedMethod == PaymentService.tigopesa ||
        _selectedMethod == PaymentService.airtelmoney;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              _accountLabel,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              isPhone
                  ? 'Enter the mobile-money number you will use for this payment.'
                  : 'Enter your bank account or transfer reference.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            TextField(
              controller: _accountController,
              enabled: !_isProcessing,
              keyboardType: isPhone
                  ? TextInputType.phone
                  : TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: _accountLabel,
                hintText: _accountHint,
                prefixIcon: Icon(
                  isPhone
                      ? Icons.phone
                      : Icons.account_balance,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT INFORMATION
  // ============================================================

  Widget _buildPaymentInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                'Your payment will initially be recorded as pending. '
                'A successful mobile-money or bank transaction can later '
                'be confirmed by the payment system.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authService.isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
        ),
        body: _buildLoginRequired(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ------------------------------------------------
                  // PAYMENT HEADER
                  // ------------------------------------------------

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            child: Icon(
                              Icons.payment,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Complete Payment',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  'Order ${widget.order.id}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ------------------------------------------------
                  // TOTAL
                  // ------------------------------------------------

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Amount to Pay',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            _formatPrice(
                              widget.order.totalAmount,
                            ),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight:
                                  FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ------------------------------------------------
                  // ORDER INFORMATION
                  // ------------------------------------------------

                  _buildOrderInformation(),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ------------------------------------------------
                  // PAYMENT METHODS
                  // ------------------------------------------------

                  RadioGroup<String>(
  groupValue: _selectedMethod,
  onChanged: (String? value) {
    if (_isProcessing) {
      return;
    }

    if (value == null) {
      return;
    }

    _selectPaymentMethod(value);
  },
  child: Column(
    children: PaymentService.paymentMethods
        .map(_buildPaymentMethod)
        .toList(),
  ),
),

                  const SizedBox(
                    height: 8,
                  ),

                  // ------------------------------------------------
                  // ACCOUNT / PHONE
                  // ------------------------------------------------

                  _buildAccountInput(),

                  const SizedBox(
                    height: 12,
                  ),

                  // ------------------------------------------------
                  // INFORMATION
                  // ------------------------------------------------

                  _buildPaymentInformation(),

                  const SizedBox(
                    height: 24,
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------
            // PAY BUTTON
            // ------------------------------------------------------

            Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                    color: Colors.black.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : _processPayment,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.lock_outline,
                        ),
                  label: Text(
                    _isProcessing
                        ? 'Processing Payment...'
                        : 'Pay ${_formatPrice(widget.order.totalAmount)}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN REQUIRED
  // ============================================================

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Please login as a buyer before making payment.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 24,
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
              ),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }
}

