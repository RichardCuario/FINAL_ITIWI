import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/premium_bottom_navigation.dart';

void main() {
  testWidgets('rapid taps navigate immediately without waiting for animation', (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PremiumBottomNavigation(
            currentIndex: 0,
            onTap: taps.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text('News'));
    expect(taps, [1]);
    await tester.tap(find.text('Profile'));
    expect(taps, [1, 2]);
    await tester.pumpAndSettle();
    expect(taps, [1, 2]);
  });

  testWidgets('tapping the selected tab does not navigate again', (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PremiumBottomNavigation(
            currentIndex: 0,
            onTap: taps.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(taps, isEmpty);
  });

  testWidgets('reduced motion navigates immediately', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            bottomNavigationBar: PremiumBottomNavigation(
              currentIndex: 0,
              onTap: taps.add,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('News'));
    expect(taps, [1]);
    await tester.pumpAndSettle();
  });
}
