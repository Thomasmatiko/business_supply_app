import 'package:flutter_test/flutter_test.dart';

import 'package:business_supply_app/app/app.dart';

void main() {
  testWidgets(
    'Business Supply app starts',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const BusinessSupplyApp(),
      );

      expect(
        find.text('Business Supply'),
        findsOneWidget,
      );
    },
  );
}