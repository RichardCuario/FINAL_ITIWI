import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/data_compliance_page.dart';
import 'package:hotline_app/terms_of_use_page.dart';

void main() {
  for (final dark in [false, true]) {
    for (final terms in [false, true]) {
      testWidgets('${terms ? 'Terms' : 'Compliance'} navigation, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: terms ? const TermsOfUsePage() : const DataCompliancePage(),
          ),
        );
        final section = terms
            ? 'Reports are not emergency calls'
            : 'Relevant and accurate records';
        await tester.enterText(
          find.byType(TextField),
          terms ? 'emergency' : 'accurate records',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(section));
        await tester.pumpAndSettle();
        expect(find.text(section).hitTestable(), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Read the Privacy Policy'),
          250,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text('Read the Privacy Policy'));
        await tester.pumpAndSettle();
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
