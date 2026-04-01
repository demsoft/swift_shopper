import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swift_shopper/main.dart';

void main() {
  testWidgets('app renders onboarding entry actions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SwiftShopperApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome to SwiftShopper'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
