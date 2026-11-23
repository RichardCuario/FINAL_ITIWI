import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/terms_of_use_page.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Terms search, filters and expansion in ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const TermsOfUsePage(),
        ),
      );
      expect(find.text('10 sections'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  PUBLIC FILE LINKS  ');
      await tester.pumpAndSettle();
      expect(find.text('1 result'), findsOneWidget);
      await tester.tap(find.text('Photos and submitted information'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Report photos may be resized'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('2 sections'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching terms'), findsOneWidget);
      await tester.tap(find.text('Show all terms'));
      await tester.pumpAndSettle();
      expect(find.text('10 sections'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Terms fits narrow screens with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const TermsOfUsePage(),
      ),
    );
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No matching terms'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('No matching terms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
