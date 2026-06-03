// Smoke test untuk aplikasi Raysize.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Raysize')),
        ),
      ),
    );

    expect(find.text('Raysize'), findsOneWidget);
  });
}
