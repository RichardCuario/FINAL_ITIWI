import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProgress {
  static const _key = 'has_seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
  }
}
