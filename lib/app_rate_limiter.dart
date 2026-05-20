import 'package:shared_preferences/shared_preferences.dart';

class RateLimitResult {
  final bool allowed;
  final Duration? retryAfter;
  final String? message;

  const RateLimitResult({
    required this.allowed,
    this.retryAfter,
    this.message,
  });
}

class AppRateLimiter {
  AppRateLimiter._();

  static final Map<String, DateTime> _inFlightActions = <String, DateTime>{};

  static Future<RateLimitResult> checkAndLock({
    required String actionKey,
    required Duration cooldown,
    String? message,
    bool persistAcrossRestarts = true,
  }) async {
    final now = DateTime.now();

    if (_inFlightActions.containsKey(actionKey)) {
      return RateLimitResult(
        allowed: false,
        retryAfter: const Duration(seconds: 1),
        message: message ?? 'Please wait for the current action to finish.',
      );
    }

    final blockedUntil = persistAcrossRestarts
        ? await _readBlockedUntil(actionKey)
        : null;

    if (blockedUntil != null && blockedUntil.isAfter(now)) {
      return RateLimitResult(
        allowed: false,
        retryAfter: blockedUntil.difference(now),
        message: message ?? _defaultCooldownMessage(blockedUntil.difference(now)),
      );
    }

    _inFlightActions[actionKey] = now;

    if (persistAcrossRestarts) {
      final nextBlockedUntil = now.add(cooldown);
      await _writeBlockedUntil(actionKey, nextBlockedUntil);
    }

    return const RateLimitResult(allowed: true);
  }

  static Future<void> release(String actionKey) async {
    _inFlightActions.remove(actionKey);
  }

  static Future<void> clear(String actionKey) async {
    _inFlightActions.remove(actionKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(actionKey));
  }

  static Future<DateTime?> _readBlockedUntil(String actionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getInt(_storageKey(actionKey));
    if (rawValue == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(rawValue);
  }

  static Future<void> _writeBlockedUntil(
    String actionKey,
    DateTime blockedUntil,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _storageKey(actionKey),
      blockedUntil.millisecondsSinceEpoch,
    );
  }

  static String _storageKey(String actionKey) => 'app_rate_limit:$actionKey';

  static String _defaultCooldownMessage(Duration retryAfter) {
    final seconds = retryAfter.inSeconds <= 0 ? 1 : retryAfter.inSeconds;
    return 'Please wait $seconds seconds before trying again.';
  }
}
