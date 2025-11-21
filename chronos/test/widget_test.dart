// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:chronos/src/app/chronos_app.dart';

void main() {
  testWidgets('Chronos app renders dashboard shell', (tester) async {
    // Give the test a large enough viewport to avoid layout overflows when
    // the dashboard has many side-by-side sections.
    tester.view.physicalSize = const Size(3200, 2200);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const ProviderScope(child: ChronosApp()));
    await tester.pumpAndSettle();

    // Expand the sidebar
    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chronos'), findsWidgets);
    expect(find.textContaining('Timeline'), findsWidgets);
  });
}
