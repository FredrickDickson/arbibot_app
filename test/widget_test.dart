import 'package:flutter_test/flutter_test.dart';

import 'package:arbibot/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(apiBaseUrl: 'http://localhost:8000'));
    await tester.pump();
    // App should build without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
