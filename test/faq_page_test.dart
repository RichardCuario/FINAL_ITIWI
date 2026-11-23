import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/faq_page.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('FAQ search and expansion work in ${brightness.name} mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const FaqPage(),
        ),
      );
      await tester.enterText(find.byType(TextField), 'password');
      await tester.pumpAndSettle();
      expect(find.text('1 result'), findsOneWidget);
      await tester.tap(find.text('How do I reset my password?'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Check your inbox and spam folder'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching questions'), findsOneWidget);
      await tester.tap(find.text('Show all questions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('4 questions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
