import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/onboarding_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('completed onboarding remains completed on the next read', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await OnboardingProgress.hasSeenOnboarding(), isFalse);
    await OnboardingProgress.markSeen();
    expect(await OnboardingProgress.hasSeenOnboarding(), isTrue);
  });
}
