import 'package:flutter_test/flutter_test.dart';

import 'package:diagnoz_app/app.dart';

void main() {
  testWidgets('App smoke test - renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DiagnozApp());
    await tester.pump();

    // Verify app renders
    expect(find.byType(DiagnozApp), findsOneWidget);
  });
}
