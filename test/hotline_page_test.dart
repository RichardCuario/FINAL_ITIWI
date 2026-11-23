import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/hotline.dart';
import 'package:shared_preferences/shared_preferences.dart';

const contacts = <Map<String, dynamic>>[
  {
    'id': 'fire',
    'name': 'Tiwi Fire Station',
    'category': 'Fire and Rescue',
    'description': 'Fire response and rescue assistance.',
    'phone_numbers': ['(052) 555-0100', '0917 555 0101'],
  },
  {
    'id': 'police',
    'name': 'Tiwi Municipal Police Station',
    'category': 'Law Enforcement',
    'description': 'Police assistance and public safety concerns.',
    'phone_number': '0917 555 0102',
  },
  {
    'id': 'health',
    'name': 'Municipal Health Office',
    'category': 'Health',
    'phone_numbers': [],
  },
];

Future<void> mountPage(
  WidgetTester tester, {
  Future<List<Map<String, dynamic>>> Function()? loader,
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: HotlinePage(loadHotlines: loader ?? () async => contacts),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('911 opens the dialer before contacts finish loading', (
    tester,
  ) async {
    final pending = Completer<List<Map<String, dynamic>>>();
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        calls.add(call);
        return true;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      ),
    );
    await mountPage(tester, loader: () => pending.future);
    await tester.pump();
    await tester.tap(find.text('Call 911'));
    await tester.pump();
    expect(calls.single.arguments['url'], 'tel:911');
    expect(find.text('Call 911'), findsOneWidget);
    expect(find.text('Send SMS'), findsNothing);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No local contacts yet'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('search, filters and reset work in ${brightness.name}', (
      tester,
    ) async {
      await mountPage(tester, brightness: brightness);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0525550100');
      await tester.pumpAndSettle();
      expect(find.text('1 contact'), findsOneWidget);
      expect(find.text('Tiwi Fire Station'), findsOneWidget);
      expect(find.text('Tiwi Municipal Police Station'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      final fireFilter = find.widgetWithText(ChoiceChip, 'Fire & Rescue');
      await tester.ensureVisible(fireFilter);
      await tester.tap(fireFilter);
      await tester.pumpAndSettle();
      expect(find.text('1 contact in Fire & Rescue'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'unmatched');
      await tester.pumpAndSettle();
      expect(find.text('No matching contacts'), findsOneWidget);
      await tester.ensureVisible(find.text('Show all contacts'));
      await tester.tap(find.text('Show all contacts'));
      await tester.pumpAndSettle();
      expect(find.text('3 contacts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed refresh preserves cached contacts and retry recovers', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'cached_hotlines': jsonEncode([
        ...contacts,
        {
          'id': 'hardcoded_911',
          'name': '911',
          'phone_numbers': ['911'],
        },
      ]),
      'cached_hotlines_updated_at': '2026-09-30T12:00:00',
    });
    var attempts = 0;
    await mountPage(
      tester,
      loader: () async {
        if (attempts++ == 0) throw Exception('offline');
        return [contacts.first];
      },
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Showing the last loaded directory'),
      findsOneWidget,
    );
    expect(find.text('3 contacts'), findsOneWidget);
    expect(find.text('Call 911'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('1 contact'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(attempts, 2);
  });

  testWidgets('dialer failure offers a working copy action', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (_) async => false,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = call.arguments['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await mountPage(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Call 911'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not open the dialer'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, '911');
    expect(find.text('Copied 911'), findsOneWidget);
  });

  testWidgets(
    'contact calls use the selected number and copy preserves formatting',
    (tester) async {
      String? dialed;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          dialed = call.arguments['url'] as String;
          return true;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = call.arguments['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await mountPage(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Copy (052) 555-0100'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Copy (052) 555-0100'));
      await tester.pumpAndSettle();
      expect(copied, '(052) 555-0100');
      final callButton = find.byTooltip(
        'Call Tiwi Fire Station at (052) 555-0100',
      );
      await tester.ensureVisible(callButton);
      await tester.pumpAndSettle();
      await tester.tap(callButton);
      await tester.pumpAndSettle();
      expect(dialed, 'tel:0525550100');
    },
  );

  testWidgets(
    'narrow layout supports large text and contacts without numbers',
    (tester) async {
      await mountPage(
        tester,
        size: const Size(320, 700),
        textScale: 2,
        brightness: Brightness.dark,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('No phone number listed'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 25,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No phone number listed'), findsOneWidget);
    },
  );
}
