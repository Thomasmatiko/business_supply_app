import 'order.dart';

enum OrderDetailsAction {
  updated,
  deleted,
}

class OrderDetailsResult {
  final Order order;
  final OrderDetailsAction action;

  const OrderDetailsResult({
    required this.order,
    required this.action,
  });
}