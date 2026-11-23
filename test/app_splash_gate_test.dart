import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/app_splash_gate.dart';

void main() {
  testWidgets('shows the branded splash once before the app content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppSplashGate(child: Scaffold(body: Text('App content'))),
      ),
    );

    expect(find.text('iTIWI'), findsOneWidget);
    expect(find.text('App content'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();

    expect(find.text('App content'), findsOneWidget);
    expect(find.text('iTIWI'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
