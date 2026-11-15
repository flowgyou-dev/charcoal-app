import 'package:flutter_test/flutter_test.dart';
import 'package:charcoal_app/main.dart';

void main() {
  testWidgets('CharCoalApp renders CustomerLoginScreen directly with Remember Me', (WidgetTester tester) async {
    await tester.pumpWidget(const CharCoalApp());
    await tester.pumpAndSettle();

    expect(find.text('Remember Me'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('Delivery Driver Portal'), findsNothing);
  });
}
