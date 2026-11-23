import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/app_session_gate.dart';

Widget sessionApp(
  Stream<String?> stream, {
  String? initialUser,
  String? Function()? readCurrentUser,
  GlobalKey<NavigatorState>? navigatorKey,
}) => MaterialApp(
  navigatorKey: navigatorKey,
  home: AppSessionGate<String>(
    sessions: stream,
    initialUser: initialUser,
    readCurrentUser: readCurrentUser,
    signedInBuilder: (_, user) => Scaffold(body: Text('Home: $user')),
    signedOutBuilder: (_) => const Scaffold(body: Text('Onboarding')),
  ),
);

Future<void> finishSplash(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
}

void main() {
  testWidgets(
    'resume reconciles the SDK session without another stream event',
    (tester) async {
      final sessions = StreamController<String?>.broadcast();
      addTearDown(sessions.close);
      String? sdkUser;
      await tester.pumpWidget(
        sessionApp(sessions.stream, readCurrentUser: () => sdkUser),
      );
      sessions.add(null);
      await tester.pump();
      await finishSplash(tester);
      expect(find.text('Onboarding'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      sdkUser = 'resident';
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      expect(find.text('Home: resident'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      sdkUser = null;
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      expect(find.text('Home: resident'), findsOneWidget);

      // A real sign-out is authoritative even after a cache-only resume.
      sessions.add(null);
      await tester.pump();
      await tester.pump();
      expect(find.text('Onboarding'), findsOneWidget);
    },
  );

  testWidgets('empty resume cache and stream error retain confirmed session', (
    tester,
  ) async {
    final sessions = StreamController<String?>.broadcast();
    addTearDown(sessions.close);
    String? sdkUser = 'resident';
    await tester.pumpWidget(
      sessionApp(sessions.stream, readCurrentUser: () => sdkUser),
    );
    await finishSplash(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    sdkUser = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    sessions.addError(StateError('Temporary restore failure'));
    await tester.pump();
    expect(find.text('Home: resident'), findsOneWidget);
    expect(find.text('Onboarding'), findsNothing);

    sessions.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.text('Onboarding'), findsOneWidget);
  });

  testWidgets('recreated app waits for delayed persisted session', (
    tester,
  ) async {
    final original = StreamController<String?>.broadcast();
    final restored = StreamController<String?>.broadcast();
    addTearDown(original.close);
    addTearDown(restored.close);
    await tester.pumpWidget(sessionApp(original.stream, initialUser: 'resident'));
    await finishSplash(tester);
    expect(find.text('Home: resident'), findsOneWidget);

    // Simulate Android destroying the UI while the app is in the background.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(sessionApp(restored.stream));
    await finishSplash(tester);
    expect(find.text('Onboarding'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    restored.add('resident');
    await tester.pump();
    expect(find.text('Home: resident'), findsOneWidget);
  });

  testWidgets('startup error offers retry instead of assuming signed out', (
    tester,
  ) async {
    final sessions = StreamController<String?>.broadcast();
    addTearDown(sessions.close);
    await tester.pumpWidget(sessionApp(sessions.stream));
    sessions.addError(StateError('Session unavailable'));
    await tester.pump();
    await finishSplash(tester);
    expect(find.text('Onboarding'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(sessions.hasListener, isTrue);
    sessions.add('resident');
    await tester.pump();
    await tester.pump();
    expect(find.text('Home: resident'), findsOneWidget);
  });

  testWidgets('auth stream errors do not send a signed-in user to login', (
    tester,
  ) async {
    final sessions = StreamController<String?>.broadcast();
    addTearDown(sessions.close);
    await tester.pumpWidget(sessionApp(sessions.stream));
    sessions.add('resident');
    await tester.pump();
    await finishSplash(tester);
    sessions.addError(StateError('Temporary auth error'));
    await tester.pump();
    expect(find.text('Home: resident'), findsOneWidget);
    expect(find.text('Onboarding'), findsNothing);

    sessions.add(null);
    await tester.pump();
    expect(find.text('Onboarding'), findsOneWidget);
  });

  testWidgets('restored session emitted during splash opens Home', (
    tester,
  ) async {
    final sessions = StreamController<String?>.broadcast();
    addTearDown(sessions.close);
    await tester.pumpWidget(sessionApp(sessions.stream));
    sessions.add('resident');
    await tester.pump();
    await finishSplash(tester);
    expect(find.text('Home: resident'), findsOneWidget);
    expect(find.text('Onboarding'), findsNothing);
  });

  testWidgets('persisted user opens Home before another auth event', (
    tester,
  ) async {
    final sessions = StreamController<String?>.broadcast();
    addTearDown(sessions.close);
    await tester.pumpWidget(
      sessionApp(sessions.stream, initialUser: 'resident'),
    );
    await finishSplash(tester);
    expect(find.text('Home: resident'), findsOneWidget);
    expect(find.text('Onboarding'), findsNothing);
  });

  testWidgets('waits for session restoration instead of showing onboarding', (
    tester,
  ) async {
    final sessions = StreamController<String?>.broadcast();
    addTearDown(sessions.close);
    await tester.pumpWidget(sessionApp(sessions.stream));
    await finishSplash(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Onboarding'), findsNothing);
    sessions.add(null);
    await tester.pump();
    expect(find.text('Onboarding'), findsOneWidget);
  });

  testWidgets(
    'login returns to persistent root and Back cannot reveal onboarding',
    (tester) async {
      final sessions = StreamController<String?>.broadcast();
      addTearDown(sessions.close);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        sessionApp(sessions.stream, navigatorKey: navigator),
      );
      sessions.add(null);
      await tester.pump();
      await finishSplash(tester);
      unawaited(
        navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => returnToSessionRoot(context),
                child: const Text('Finish login'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      sessions.add('resident');
      await tester.pump();
      await tester.tap(find.text('Finish login'));
      await tester.pumpAndSettle();
      expect(find.text('Home: resident'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isFalse);
      await navigator.currentState!.maybePop();
      await tester.pump();
      expect(find.text('Home: resident'), findsOneWidget);
      expect(find.text('Onboarding'), findsNothing);

      // The root still listens after login and handles a real logout/re-login.
      sessions.add(null);
      await tester.pump();
      await tester.pump();
      expect(find.text('Onboarding'), findsOneWidget);
      sessions.add('resident');
      await tester.pump();
      await tester.pump();
      expect(find.text('Home: resident'), findsOneWidget);
    },
  );
}
