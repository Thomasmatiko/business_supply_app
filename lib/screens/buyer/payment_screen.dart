
import 'package:flutter/material.dart';

import '../../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final String buyerId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.buyerId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService.instance;

  String? _selectedMethod;

  bool _isProcessing = false;

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
  // PAYMENT METHOD NAME
  // ============================================================

  String _methodName(String method) {
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
  // PAYMENT ICON
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
  // CREATE PAYMENT
  // ============================================================

  Future<void> _continuePayment() async {
    if (_isProcessing) {
      return;
    }

    if (_selectedMethod == null) {
      _showMessage(
        'Please select a payment method.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentId = await _paymentService.createPayment(
        orderId: widget.orderId,
        buyerId: widget.buyerId,
        amount: widget.amount,
        method: _selectedMethod!,
      );

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // PAYMENT CREATED
      // ----------------------------------------------------------

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.payment_outlined,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payment Created',
                  ),
                ),
              ],
            ),
            content: Text(
              'Payment request created successfully.\n\n'
              'Payment ID: $paymentId\n'
              'Method: ${_methodName(_selectedMethod!)}\n'
              'Amount: ${_formatPrice(widget.amount)}\n\n'
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

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        paymentId,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      _showMessage(
        message.isEmpty
            ? 'Unable to create payment.'
            : message,
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
  // PAYMENT METHOD CARD
  // ============================================================

  Widget _buildPaymentMethod(
    String method,
  ) {
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
                setState(() {
                  _selectedMethod = method;
                });
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: selected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                child: Icon(
                  _methodIcon(method),
                  color: selected
                      ? Theme.of(context)
                          .colorScheme
                          .onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  _methodName(method),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ------------------------------------------------
                  // PAYMENT SUMMARY
                  // ------------------------------------------------

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          const Text(
                            'Amount to Pay',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            _formatPrice(widget.amount),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ------------------------------------------------
                  // PAYMENT METHODS
                  // ------------------------------------------------

                  RadioGroup<String>(
  groupValue: _selectedMethod,
  onChanged: (value) {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _selectedMethod = value;
    });
  },
  child: Column(
    children: PaymentService.paymentMethods
        .map(_buildPaymentMethod)
        .toList(),
  ),
),

                  const SizedBox(
                    height: 12,
                  ),

                  // ------------------------------------------------
                  // INFORMATION
                  // ------------------------------------------------

                  Card(
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
                              'Select your preferred payment method. '
                              'Your payment will initially be recorded as pending.',
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
                  ),

                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------
            // CONTINUE BUTTON
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
                      : _continuePayment,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward,
                        ),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Continue • ${_formatPrice(widget.amount)}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

