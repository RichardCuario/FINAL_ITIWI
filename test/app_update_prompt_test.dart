import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/app_update_prompt.dart';
import 'package:hotline_app/app_update_service.dart';

class FakeUpdates extends AppUpdateService {
  AppRelease? release = AppRelease(
    version: '1.0.4',
    buildNumber: 7,
    apkUrl: Uri.parse('https://www.itiwi.online/downloads/itiwi-7.apk'),
    sha256: 'a' * 64,
    notes: 'New features',
  );
  bool failCheck = false;
  bool failDownload = false;
  int checks = 0;
  int downloads = 0;
  int installs = 0;
  Completer<void>? pendingDownload;
  @override
  bool get supported => true;
  @override
  Future<AppRelease?> check() async {
    checks++;
    if (failCheck) throw StateError('Offline');
    return release;
  }

  @override
  Future<void> download(
    AppRelease release,
    ValueChanged<double?> progress,
  ) async {
    downloads++;
    progress(0.5);
    if (failDownload) throw StateError('Checksum mismatch');
    await pendingDownload?.future;
  }

  @override
  Future<String> install() async {
    installs++;
    return installs == 1 ? 'permission' : 'opened';
  }
}

Future<void> openApp(WidgetTester tester, FakeUpdates service) async {
  final key = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: key,
      builder: (_, child) =>
          AppUpdatePrompt(navigatorKey: key, service: service, child: child!),
      home: const Scaffold(body: Text('App content')),
    ),
  );
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('checks on launch and return to app, without a timer', (
    tester,
  ) async {
    final service = FakeUpdates()..release = null;
    await openApp(tester, service);
    expect(service.checks, 1);

    await tester.pump(const Duration(hours: 2));
    expect(service.checks, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(service.checks, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'small screens keep actions visible with large text and long notes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final service = FakeUpdates();
      service.release = AppRelease(
        version: '1.0.5',
        buildNumber: 8,
        apkUrl: Uri.parse('https://www.itiwi.online/downloads/itiwi-8.apk'),
        sha256: 'a' * 64,
        notes: 'Updated About Us and improved the municipal hall photo. ' * 12,
      );
      await openApp(tester, service);
      expect(tester.takeException(), isNull);
      expect(find.text('Update now').hitTestable(), findsOneWidget);
      expect(find.text('Download in browser').hitTestable(), findsOneWidget);
      expect(find.text('Later').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('new release offers update and Later leaves the app usable', (
    tester,
  ) async {
    await openApp(tester, FakeUpdates());
    expect(find.text('New update available'), findsOneWidget);
    expect(find.text('Download in browser'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('New update available'), findsNothing);
    expect(find.text('App content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'progress prevents duplicates and permission retry reuses download',
    (tester) async {
      final service = FakeUpdates()..pendingDownload = Completer<void>();
      await openApp(tester, service);
      await tester.tap(find.text('Update now'));
      await tester.pump();
      expect(find.text('Downloading update… 50%'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      service.pendingDownload!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Allow updates from iTIWI'), findsOneWidget);
      await tester.tap(find.text('Install update'));
      await tester.pumpAndSettle();
      expect(service.downloads, 1);
      expect(service.installs, 2);
      expect(
        find.textContaining('Complete the Android installation prompt'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('failed downloads can be retried', (tester) async {
    final service = FakeUpdates()..failDownload = true;
    await openApp(tester, service);
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be completed'), findsOneWidget);
    expect(service.installs, 0);
    service.failDownload = false;
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(service.downloads, 2);
    expect(service.installs, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('offline and current installations show no prompt', (
    tester,
  ) async {
    for (final service in [
      FakeUpdates()..failCheck = true,
      FakeUpdates()..release = null,
    ]) {
      await openApp(tester, service);
      expect(find.text('New update available'), findsNothing);
      expect(find.text('App content'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
