import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_demo/main.dart';

void main() {
  testWidgets('shows a status line while the native checks run', (tester) async {
    await tester.pumpWidget(const SensorsDemo());
    // A plain widget test has no native side: the demo only has to build and show its first status.
    expect(find.text('starting'), findsOneWidget);
  });
}
