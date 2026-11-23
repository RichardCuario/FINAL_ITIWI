import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/account_form_page.dart';

void main() {
  testWidgets('modal stays above profile and blocks dismissal while saving', (
    tester,
  ) async {
    final save = Completer<String>();
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AccountFormPage(
                    isPassword: true,
                    onSave: (_) => save.future,
                  ),
                );
              },
              child: const Text('Profile settings'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Profile settings'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Profile settings'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'secret123');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.close_rounded),
          )
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(Dialog), findsOneWidget);
    save.complete('Password updated');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(result, 'Password updated');
    expect(find.text('Profile settings'), findsOneWidget);
  });

  testWidgets('edit profile excludes email and validates username', (
    tester,
  ) async {
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountFormPage(
          username: 'Chad',
          onSave: (_) async {
            saves++;
            return 'Saved';
          },
        ),
      ),
    );
    expect(find.text('Email address'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.text('Enter your username.'), findsOneWidget);
  });

  testWidgets('password mismatch, visibility and retry preserve exact input', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountFormPage(
          isPassword: true,
          onSave: (values) async {
            submitted = values.password;
            throw 'Connection failed. Try again.';
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), ' secret123 ');
    await tester.enterText(find.byType(TextFormField).at(1), 'different');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords don’t match.'), findsOneWidget);
    expect(submitted, isNull);
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).obscureText,
      isFalse,
    );
    await tester.enterText(find.byType(TextFormField).at(1), ' secret123 ');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(submitted, ' secret123 ');
    expect(find.text('Connection failed. Try again.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('small dark screen supports large text and keyboard inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
            viewInsets: const EdgeInsets.only(bottom: 260),
          ),
          child: child!,
        ),
        home: AccountFormPage(onSave: (_) async => 'Saved'),
      ),
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Save changes'), findsOneWidget);
  });
}
