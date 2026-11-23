import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/auto_image_carousel.dart';

void main() {
  testWidgets('opens the tapped gallery image full screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: AutoImageCarousel(
              urls: ['https://example.invalid/first.jpg'],
              placeholder: SizedBox(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AutoImageCarousel));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close image'), findsOneWidget);
    await tester.tap(find.byTooltip('Close image'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close image'), findsNothing);
  });

  testWidgets('opens the selected image in a multi-image gallery', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: AutoImageCarousel(
              urls: [
                'https://example.invalid/first.jpg',
                'https://example.invalid/second.jpg',
              ],
              placeholder: SizedBox(),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(PageView).first, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AutoImageCarousel));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
  });
}
