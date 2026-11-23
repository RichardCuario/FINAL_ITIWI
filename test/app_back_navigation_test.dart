import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/app_back_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android Back backgrounds the task', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    const channel = MethodChannel('com.ecoimpact.itiwi/navigation');
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'backgroundApp');
          calls++;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await AppBackNavigation.backgroundApp();
    expect(calls, 1);
  });
}
