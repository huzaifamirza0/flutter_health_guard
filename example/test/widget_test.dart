import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_example/main.dart';

void main() {
  testWidgets('Guardian example loads', (tester) async {
    await tester.pumpWidget(const GuardianExampleApp());
    expect(find.text('Flutter Guardian'), findsWidgets);
    expect(find.text('Generate Guardian report'), findsOneWidget);
  });
}
