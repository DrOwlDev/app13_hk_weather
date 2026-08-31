import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app13_hk_weather/main.dart';

void main() {
  testWidgets('Forecast screen renders HKO-only controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('HKO OCF Temperature'), findsOneWidget);
    expect(find.text('Hong Kong Observatory (HKO)'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
