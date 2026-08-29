
import 'package:flutter/material.dart';

import '../../models/order.dart';

class PaymentMethodScreen extends StatefulWidget {
  final List<Order> orders;
  final double totalAmount;

  const PaymentMethodScreen({
    super.key,
    required this.orders,
    required this.totalAmount,
  });

  @override
  State<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState
    extends State<PaymentMethodScreen> {
  String? _selectedMethod;

  bool _isProcessing = false;

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice(double amount) {
    final amountString = amount.toStringAsFixed(0);

    final reversed =
        amountString.split('').reversed.toList();

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
  // PAYMENT METHODS
  // ============================================================

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'title': 'Cash on Delivery',
      'subtitle': 'Pay when your order is delivered',
      'icon': Icons.payments_outlined,
    },
    {
      'id': 'mpesa',
      'title': 'M-Pesa',
      'subtitle': 'Pay using Vodacom M-Pesa',
      'icon': Icons.phone_android,
    },
    {
      'id': 'airtel_money',
      'title': 'Airtel Money',
      'subtitle': 'Pay using Airtel Money',
      'icon': Icons.phone_android,
    },
    {
      'id': 'tigopesa',
      'title': 'Mixx by Yas',
      'subtitle': 'Pay using Mixx by Yas',
      'icon': Icons.phone_android,
    },
    {
      'id': 'halopesa',
      'title': 'HaloPesa',
      'subtitle': 'Pay using HaloPesa',
      'icon': Icons.phone_android,
    },
    {
      'id': 'bank_transfer',
      'title': 'Bank Transfer',
      'subtitle': 'Pay directly through your bank',
      'icon': Icons.account_balance_outlined,
    },
  ];

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
  // SELECT PAYMENT METHOD
  // ============================================================

  void _selectPaymentMethod(String method) {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _selectedMethod = method;
    });
  }

  // ============================================================
  // CONFIRM PAYMENT
  // ============================================================

  Future<void> _confirmPayment() async {
    if (_isProcessing) {
      return;
    }

    if (_selectedMethod == null) {
      _showMessage(
        'Please select a payment method.',
      );
      return;
    }

    if (widget.orders.isEmpty) {
      _showMessage(
        'No orders available for payment.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // --------------------------------------------------------
      // TEMPORARY PAYMENT FLOW
      //
      // This screen currently selects the payment method.
      //
      // The actual payment database operation can be connected
      // through PaymentService in the payment integration step.
      // --------------------------------------------------------

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        _selectedMethod,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to continue with payment: $e',
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

  Widget _buildPaymentMethodCard(
    Map<String, dynamic> method,
  ) {
    final id = method['id'] as String;
    final title = method['title'] as String;
    final subtitle = method['subtitle'] as String;
    final icon = method['icon'] as IconData;

    final isSelected =
        _selectedMethod == id;

    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isProcessing
            ? null
            : () => _selectPaymentMethod(id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // --------------------------------------------------
              // PAYMENT ICON
              // --------------------------------------------------

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // --------------------------------------------------
              // PAYMENT INFORMATION
              // --------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // --------------------------------------------------
              // RADIO
              //
              // groupValue and onChanged are now handled by the
              // RadioGroup in the build method.
              // --------------------------------------------------

              Radio<String>(
                value: id,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDER SUMMARY
  // ============================================================

  Widget _buildOrderSummary() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: colorScheme.primary,
                ),

                const SizedBox(
                  width: 10,
                ),

                const Expanded(
                  child: Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 28,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Orders',
                ),
                Text(
                  widget.orders.length.toString(),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount to pay',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  _formatPrice(
                    widget.totalAmount,
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        colorScheme.primary,
                  ),
                ),
              ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Method',
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            child: Icon(
                              Icons
                                  .account_balance_wallet_outlined,
                              color: Theme.of(
                                context,
                              )
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
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Choose Payment Method',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        19,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Select how you want to pay for your order.',
                                  style:
                                      TextStyle(
                                    color: Theme.of(
                                      context,
                                    )
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ------------------------------------------------
                  // SUMMARY
                  // ------------------------------------------------

                  _buildOrderSummary(),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Available Payment Methods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ------------------------------------------------
                  // PAYMENT METHODS
                  //
                  // RadioGroup replaces the deprecated
                  // groupValue/onChanged properties.
                  // ------------------------------------------------

                  RadioGroup<String>(
                    groupValue: _selectedMethod,
                    onChanged: (String? value) {
                      if (value != null &&
                          !_isProcessing) {
                        _selectPaymentMethod(
                          value,
                        );
                      }
                    },
                    child: Column(
                      children: [
                        ..._paymentMethods.map(
                          _buildPaymentMethodCard,
                        ),
                      ],
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
                      padding:
                          const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .primary,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Text(
                              'Your selected payment method will be attached to your order. '
                              'Online mobile-money and bank payments will be connected to '
                              'their respective payment services in the next payment integration step.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                )
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
            // CONFIRM BUTTON
            // ------------------------------------------------------

            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16,
              ),
              decoration:
                  BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset:
                        const Offset(0, -2),
                    color: Colors.black
                        .withValues(
                      alpha: 0.08,
                    ),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed:
                      _isProcessing
                          ? null
                          : _confirmPayment,
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
                          Icons.arrow_forward,
                        ),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Continue • ${_formatPrice(widget.totalAmount)}',
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

