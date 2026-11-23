import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/news_link_text.dart';

void main() {
  testWidgets('news links open in the browser without trailing punctuation', (
    tester,
  ) async {
    final launched = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        launched.add(call.arguments['url'] as String);
        return true;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NewsLinkText(
            'Read https://example.com/news, then www.example.org.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(NewsLinkText),
        matching: find.byType(RichText),
      ),
    );
    final links = <TextSpan>[];
    void collectLinks(InlineSpan span) {
      if (span is! TextSpan) return;
      if (span.recognizer is TapGestureRecognizer) links.add(span);
      for (final child in span.children ?? <InlineSpan>[]) {
        collectLinks(child);
      }
    }

    collectLinks(richText.text);
    expect(links.map((span) => span.text), [
      'https://example.com/news',
      'www.example.org',
    ]);

    for (final link in links) {
      (link.recognizer as TapGestureRecognizer).onTap!();
      await tester.pump();
    }
    expect(launched, ['https://example.com/news', 'https://www.example.org']);
  });
}
