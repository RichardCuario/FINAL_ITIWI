import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/charter_preview_page.dart';

void main() {
  testWidgets('previews a Charter image in the app and keeps Download available', (
    tester,
  ) async {
    var downloaded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CharterPreviewPage(
          name: 'charter.png',
          url: 'https://example.invalid/charter.png',
          onDownload: () => downloaded = true,
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Download file'));
    expect(downloaded, isTrue);
  });
}
