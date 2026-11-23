import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/privacy_policy_page.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Privacy search and expansion work in ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const PrivacyPolicyPage(),
        ),
      );
      expect(find.text('Your Privacy\nMatters'), findsOneWidget);
      expect(find.text('11 sections'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'PUBLIC FILE LINKS');
      await tester.pumpAndSettle();
      expect(find.text('1 result'), findsOneWidget);
      await tester.tap(find.text('Photos and shared links'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText &&
              widget.data!.contains(
                'Report photos currently use public file links.',
              ),
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching sections'), findsOneWidget);
      await tester.tap(find.text('Show all sections'));
      await tester.pumpAndSettle();
      expect(find.text('11 sections'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'retention');
      await tester.pumpAndSettle();
      expect(find.text('1 result'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('11 sections'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Privacy layout fits a narrow screen with large text', (
    tester,
  ) async {
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
        home: const PrivacyPolicyPage(),
      ),
    );
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Contact Us'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Contact Us').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
