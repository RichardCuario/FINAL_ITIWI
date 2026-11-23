import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/onboarding_page.dart';

void main() {
  testWidgets('keeps the primary action near the bottom on tall screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          isDarkMode: false,
          onToggleDarkMode: (_) {},
        ),
      ),
    );
    await tester.pump();

    final button = find.widgetWithText(ElevatedButton, 'Get started');
    expect(button, findsOneWidget);
    expect(tester.getBottomLeft(button).dy, greaterThan(770));
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
