import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aqari_app/views/payment_screen.dart';

void main() {
  testWidgets('a paid package is not activated from the app', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentScreen(propertyId: 'property-1')),
    );

    // Tap the paid "الباقة العامة" package and confirm the dialog.
    await tester.tap(find.text('الباقة العامة'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'تأكيد الاشتراك'));
    await tester.pumpAndSettle();

    // The app asks the user to complete the payment. It does not report a
    // completed subscription and writes no entitlement.
    expect(find.textContaining('تأكيدها من الإدارة'), findsOneWidget);
    expect(find.textContaining('بنجاح'), findsNothing);
  });
}
