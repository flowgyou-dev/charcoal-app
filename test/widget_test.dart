import 'package:flutter_test/flutter_test.dart';
import 'package:charcoal_app/main.dart';

void main() {
  testWidgets('CharCoalApp renders RoleSelectScreen with Customer Portal', (WidgetTester tester) async {
    await tester.pumpWidget(const CharCoalApp());

    expect(find.text('Customer Portal'), findsOneWidget);
  });
}
