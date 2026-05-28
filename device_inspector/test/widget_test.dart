import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_inspector/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DeviceInspectorApp()));
    await tester.pumpAndSettle();

    // Verify app title appears
    expect(find.text('DeviceInspector'), findsOneWidget);
  });
}