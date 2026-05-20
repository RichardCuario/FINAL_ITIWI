import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedContentResult {
  final List<Map<String, dynamic>> items;
  final DateTime? updatedAt;

  const CachedContentResult({
    required this.items,
    required this.updatedAt,
  });

  bool get hasData => items.isNotEmpty;
}

class ContentCacheService {
  static const String _newsKey = 'cached_news';
  static const String _newsUpdatedAtKey = 'cached_news_updated_at';
  static const String _barangaysKey = 'cached_barangays';
  static const String _barangaysUpdatedAtKey = 'cached_barangays_updated_at';
  static const String _hotlinesKey = 'cached_hotlines';
  static const String _hotlinesUpdatedAtKey = 'cached_hotlines_updated_at';
  static const String _latestNewsMarkerKey = 'latest_news_marker';
  static const String _seenNewsMarkerKey = 'seen_news_marker';
  static const String _dismissedNewsMarkerKey = 'dismissed_news_marker';
  static const String _reportStatusSnapshotKey = 'report_status_snapshot';
  static const String _reportNotificationsKey = 'report_notifications';

  const ContentCacheService();

  Future<void> saveNews(List<Map<String, dynamic>> items) {
    return _saveItems(
      dataKey: _newsKey,
      updatedAtKey: _newsUpdatedAtKey,
      items: items,
    );
  }

  Future<CachedContentResult> getNews() {
    return _readItems(
      dataKey: _newsKey,
      updatedAtKey: _newsUpdatedAtKey,
    );
  }

  Future<void> saveBarangays(List<Map<String, dynamic>> items) {
    return _saveItems(
      dataKey: _barangaysKey,
      updatedAtKey: _barangaysUpdatedAtKey,
      items: items,
    );
  }

  Future<CachedContentResult> getBarangays() {
    return _readItems(
      dataKey: _barangaysKey,
      updatedAtKey: _barangaysUpdatedAtKey,
    );
  }

  Future<void> saveHotlines(List<Map<String, dynamic>> items) {
    return _saveItems(
      dataKey: _hotlinesKey,
      updatedAtKey: _hotlinesUpdatedAtKey,
      items: items,
    );
  }

  Future<CachedContentResult> getHotlines() {
    return _readItems(
      dataKey: _hotlinesKey,
      updatedAtKey: _hotlinesUpdatedAtKey,
    );
  }

  Future<void> saveLatestNewsMarker(String marker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_latestNewsMarkerKey, marker);
  }

  Future<String?> getLatestNewsMarker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_latestNewsMarkerKey);
  }

  Future<void> markNewsAsSeen(String marker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenNewsMarkerKey, marker);
  }

  Future<String?> getSeenNewsMarker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seenNewsMarkerKey);
  }

  Future<void> saveDismissedNewsMarker(String marker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedNewsMarkerKey, marker);
  }

  Future<String?> getDismissedNewsMarker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedNewsMarkerKey);
  }

  Future<void> saveReportStatusSnapshot(Map<String, dynamic> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reportStatusSnapshotKey, jsonEncode(snapshot));
  }

  Future<Map<String, dynamic>> getReportStatusSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportStatusSnapshotKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveReportNotifications(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reportNotificationsKey, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> getReportNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportNotificationsKey);

    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearNewsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_newsKey);
    await prefs.remove(_newsUpdatedAtKey);
    await prefs.remove(_latestNewsMarkerKey);
    await prefs.remove(_seenNewsMarkerKey);
  }

  Future<void> _saveItems({
    required String dataKey,
    required String updatedAtKey,
    required List<Map<String, dynamic>> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(items);
    await prefs.setString(dataKey, payload);
    await prefs.setString(updatedAtKey, DateTime.now().toIso8601String());
  }

  Future<CachedContentResult> _readItems({
    required String dataKey,
    required String updatedAtKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dataKey);
    final rawUpdatedAt = prefs.getString(updatedAtKey);

    if (raw == null || raw.isEmpty) {
      return CachedContentResult(
        items: const [],
        updatedAt: DateTime.tryParse(rawUpdatedAt ?? ''),
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return CachedContentResult(
          items: const [],
          updatedAt: DateTime.tryParse(rawUpdatedAt ?? ''),
        );
      }

      final items = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      return CachedContentResult(
        items: items,
        updatedAt: DateTime.tryParse(rawUpdatedAt ?? ''),
      );
    } catch (_) {
      return CachedContentResult(
        items: const [],
        updatedAt: DateTime.tryParse(rawUpdatedAt ?? ''),
      );
    }
  }
}
