import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turf_showcase/main.dart';

void main() {
  testWidgets('app boots and renders the first demo as breadcrumb + table',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TurfShowcaseApp());
    await tester.pumpAndSettle();

    // App title is shown in the sidebar header.
    expect(find.text('turf_dart'), findsOneWidget);

    // First demo (`distance`) shows up at least in the sidebar tile + the
    // breadcrumb of the detail page.
    expect(find.text('distance'), findsWidgets);

    // Parameters table header is rendered.
    expect(find.text('PARAMETERS'), findsOneWidget);
    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
    expect(find.text('REQUIRED'), findsOneWidget);
    expect(find.text('DEFAULT'), findsOneWidget);
    expect(find.text('DESCRIPTION'), findsOneWidget);
  });
}
