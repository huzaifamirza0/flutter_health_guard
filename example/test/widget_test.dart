import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_example/main.dart';

void main() {
  testWidgets('example loads', (tester) async {
    await tester.pumpWidget(const GuardianExampleApp());
    expect(find.text('Flutter Health Guard'), findsWidgets);
  });
}
