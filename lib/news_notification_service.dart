import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'content_cache_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NewsNotificationService {
  NewsNotificationService._();

  static const String _topicName = 'news_updates';
  static const String _androidChannelId = 'news_updates';
  static const String _androidChannelName = 'News Updates';
  static const String _androidChannelDescription =
      'Notifications for newly published news and announcements.';
  static final NewsNotificationService instance = NewsNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ContentCacheService _cacheService = const ContentCacheService();

  bool _initialized = false;
  bool _foregroundListenerAttached = false;
  String? _lastKnownToken;
  String? _lastSubscribedReportTopic;
  String? _lastSubscribedOnlineServiceTopic;

  Future<void> initialize({String? externalUserId}) async {
    if (_initialized) {
      await syncUser(externalUserId);
      return;
    }

    await _initializeLocalNotifications();
    await _requestPermissions();
    await _configureForegroundPresentation();
    await _subscribeToTopic();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (!_foregroundListenerAttached) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {});
      _foregroundListenerAttached = true;
    }

    _initialized = true;
    await syncUser(externalUserId);
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }

    if (Platform.isAndroid) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _configureForegroundPresentation() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _subscribeToTopic() async {
    await _messaging.subscribeToTopic(_topicName);
  }

  String _buildReportStatusTopic(String? userId) {
    final raw = userId?.trim() ?? '';
    final normalized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
    return 'report_user_${normalized.isEmpty ? 'anonymous' : normalized}';
  }

  String _buildOnlineServiceStatusTopic(String? userId) {
    final raw = userId?.trim() ?? '';
    final normalized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
    return 'online_service_user_${normalized.isEmpty ? 'anonymous' : normalized}';
  }

  Future<void> syncUser(String? externalUserId) async {
    if (!_initialized) {
      await initialize(externalUserId: externalUserId);
      return;
    }

    final normalizedUserId = externalUserId?.trim();
    final nextReportTopic = _buildReportStatusTopic(normalizedUserId);
    final nextOnlineServiceTopic = _buildOnlineServiceStatusTopic(
      normalizedUserId,
    );

    if (_lastSubscribedReportTopic != null &&
        _lastSubscribedReportTopic != nextReportTopic) {
      await _messaging.unsubscribeFromTopic(_lastSubscribedReportTopic!);
    }

    if (_lastSubscribedReportTopic != nextReportTopic) {
      await _messaging.subscribeToTopic(nextReportTopic);
      _lastSubscribedReportTopic = nextReportTopic;
    }

    if (_lastSubscribedOnlineServiceTopic != null &&
        _lastSubscribedOnlineServiceTopic != nextOnlineServiceTopic) {
      await _messaging.unsubscribeFromTopic(_lastSubscribedOnlineServiceTopic!);
    }

    if (_lastSubscribedOnlineServiceTopic != nextOnlineServiceTopic) {
      await _messaging.subscribeToTopic(nextOnlineServiceTopic);
      _lastSubscribedOnlineServiceTopic = nextOnlineServiceTopic;
    }

    final token = await _messaging.getToken();
    _lastKnownToken = token;
    debugPrint(
      'FCM initialized for user=${normalizedUserId ?? 'anonymous'} token=${token ?? 'unavailable'} reportTopic=$nextReportTopic onlineServiceTopic=$nextOnlineServiceTopic',
    );
  }

  Future<String?> getToken() async {
    if (!_initialized) {
      await initialize();
    }

    _lastKnownToken ??= await _messaging.getToken();
    return _lastKnownToken;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    await _persistIncomingNotification(data);

    final type = data['type']?.toString();
    final title = notification?.title?.trim().isNotEmpty == true
        ? notification!.title!.trim()
        : (data['title']?.toString().trim().isNotEmpty == true
              ? data['title'].toString().trim()
              : _buildFallbackTitle(type, data));

    final body = notification?.body?.trim().isNotEmpty == true
        ? notification!.body!.trim()
        : (data['description']?.toString().trim().isNotEmpty == true
              ? data['description'].toString().trim()
              : _buildFallbackBody(type, data));

    final notificationId = _buildNotificationId(type, data);

    await _plugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: _buildTicker(type),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _persistIncomingNotification(Map<String, dynamic> data) async {
    final type = data['type']?.toString();

    if (type == 'report_status') {
      await _persistReportStatusNotification(data);
      return;
    }

    if (type == 'online_service_status') {
      await _persistOnlineServiceStatusNotification(data);
    }
  }

  Future<void> _persistReportStatusNotification(
    Map<String, dynamic> data,
  ) async {
    if (data['type']?.toString() != 'report_status') {
      return;
    }

    final reportId = data['reportId']?.toString().trim() ?? '';
    if (reportId.isEmpty) {
      return;
    }

    final status = data['status']?.toString().trim() ?? 'under review';
    final normalizedStatus = _normalizeReportStatus(status);
    final rejectionReason = data['rejectionReason']?.toString().trim();
    final createdAt = DateTime.now().toIso8601String();

    final notifications = await _cacheService.getReportNotifications();
    notifications.removeWhere((item) => item['id']?.toString() == 'report_$reportId');
    notifications.insert(0, {
      'id': 'report_$reportId',
      'type': 'report_status',
      'title': _buildReportStatusTitle(status),
      'description': _buildReportStatusBody(data),
      'created_at': createdAt,
      'report_id': reportId,
      'report_status': normalizedStatus,
      'rejection_reason': rejectionReason,
    });

    await _cacheService.saveReportNotifications(notifications);

    final snapshot = await _cacheService.getReportStatusSnapshot();
    snapshot[reportId] = {
      'status': normalizedStatus,
      'updated_at': createdAt,
    };
    await _cacheService.saveReportStatusSnapshot(snapshot);
  }

  Future<void> _persistOnlineServiceStatusNotification(
    Map<String, dynamic> data,
  ) async {
    if (data['type']?.toString() != 'online_service_status') {
      return;
    }

    final requestId = data['requestId']?.toString().trim() ?? '';
    if (requestId.isEmpty) {
      return;
    }

    final createdAt = DateTime.now().toIso8601String();
    final status = _normalizeOnlineServiceStatus(
      data['status']?.toString() ?? 'pending',
    );
    final serviceLabel = data['serviceLabel']?.toString().trim().isNotEmpty == true
        ? data['serviceLabel'].toString().trim()
        : 'Online service';
    final applicantName = data['applicantName']?.toString().trim();
    final scheduleLabel = data['scheduleLabel']?.toString().trim();
    final notifications = await _cacheService.getReportNotifications();

    notifications.removeWhere(
      (item) => item['id']?.toString() == 'online_service_$requestId',
    );
    notifications.insert(0, {
      'id': 'online_service_$requestId',
      'type': 'online_service_status',
      'title': _buildOnlineServiceStatusTitle(serviceLabel, status),
      'description': _buildOnlineServiceStatusBody(data),
      'created_at': createdAt,
      'request_id': requestId,
      'service_label': serviceLabel,
      'service_status': status,
      'applicant_name': applicantName,
      'schedule_label': scheduleLabel,
      'table': data['table']?.toString(),
    });

    await _cacheService.saveReportNotifications(notifications);
  }

  int _buildNotificationId(String? type, Map<String, dynamic> data) {
    if (type == 'report_status') {
      return _buildStableNotificationId(data['reportId']?.toString(), 2000, 1002);
    }

    if (type == 'online_service_status') {
      return _buildStableNotificationId(
        data['requestId']?.toString(),
        3000,
        1003,
      );
    }

    return 1001;
  }

  int _buildStableNotificationId(String? value, int seed, int fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }

    return trimmed.codeUnits.fold<int>(
      seed,
      (hash, unit) => ((hash * 31) + unit) & 0x7fffffff,
    );
  }

  String _buildFallbackTitle(String? type, Map<String, dynamic> data) {
    if (type == 'report_status') {
      return 'Report status updated';
    }

    if (type == 'online_service_status') {
      final serviceLabel = data['serviceLabel']?.toString().trim();
      if (serviceLabel != null && serviceLabel.isNotEmpty) {
        return _buildOnlineServiceStatusTitle(
          serviceLabel,
          data['status']?.toString() ?? '',
        );
      }
      return 'Online service status updated';
    }

    return 'New Announcement';
  }

  String _buildFallbackBody(String? type, Map<String, dynamic> data) {
    if (type == 'report_status') {
      return _buildReportStatusBody(data);
    }

    if (type == 'online_service_status') {
      return _buildOnlineServiceStatusBody(data);
    }

    return 'Tap to view the latest news.';
  }

  String _buildTicker(String? type) {
    if (type == 'report_status') {
      return 'report_status_update';
    }

    if (type == 'online_service_status') {
      return 'online_service_status_update';
    }

    return 'news_update';
  }

  String _buildReportStatusTitle(String status) {
    switch (_normalizeReportStatus(status)) {
      case 'resolved':
        return 'Your report was resolved';
      case 'rejected':
        return 'Your report was rejected';
      case 'processing':
        return 'Your report is now processing';
      default:
        return 'Your report is under review';
    }
  }

  String _buildReportStatusBody(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? '';
    final normalizedStatus = _normalizeReportStatus(status);
    final rejectionReason = data['rejectionReason']?.toString().trim() ?? '';

    if (normalizedStatus == 'rejected' && rejectionReason.isNotEmpty) {
      return 'The admin rejected your report. Reason: $rejectionReason';
    }

    if (normalizedStatus == 'rejected') {
      return 'The admin rejected your report.';
    }

    if (normalizedStatus == 'resolved') {
      return 'The admin marked your report as resolved.';
    }

    if (normalizedStatus == 'processing') {
      return 'The admin started processing your report.';
    }

    return 'The admin updated your report status.';
  }

  String _normalizeReportStatus(String status) {
    final normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'reviewing':
      case 'processing':
      case 'in progress':
        return 'processing';
      case 'under review':
      case 'pending':
        return 'under review';
      case 'resolved':
        return 'resolved';
      case 'rejected':
        return 'rejected';
      default:
        return normalized.isEmpty ? 'under review' : normalized;
    }
  }

  String _normalizeOnlineServiceStatus(String status) {
    final normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'approved':
      case 'approve':
        return 'approved';
      case 'rejected':
      case 'reject':
        return 'rejected';
      case 'pending':
        return 'pending';
      default:
        return normalized.isEmpty ? 'pending' : normalized;
    }
  }

  String _buildOnlineServiceStatusTitle(String serviceLabel, String status) {
    switch (_normalizeOnlineServiceStatus(status)) {
      case 'approved':
        return '$serviceLabel request approved';
      case 'rejected':
        return '$serviceLabel request rejected';
      default:
        return '$serviceLabel request updated';
    }
  }

  String _buildOnlineServiceStatusBody(Map<String, dynamic> data) {
    final serviceLabel = data['serviceLabel']?.toString().trim().isNotEmpty == true
        ? data['serviceLabel'].toString().trim()
        : 'online service';
    final status = _normalizeOnlineServiceStatus(
      data['status']?.toString() ?? 'pending',
    );
    final scheduleLabel = data['scheduleLabel']?.toString().trim() ?? '';

    final suffix = scheduleLabel.isNotEmpty
        ? ' Schedule: $scheduleLabel.'
        : '';

    switch (status) {
      case 'approved':
        return 'The admin approved your $serviceLabel request.$suffix';
      case 'rejected':
        return 'The admin rejected your $serviceLabel request.$suffix';
      default:
        return 'The admin updated your $serviceLabel request status.$suffix';
    }
  }

  Future<void> showNewNewsNotification({
    required int unreadCount,
    required String newsTitle,
    String? newsDescription,
  }) async {
    if (unreadCount <= 0) return;

    await initialize();

    final title =
        unreadCount == 1 ? newsTitle : '$newsTitle (+${unreadCount - 1} more)';
    final body = (newsDescription != null && newsDescription.trim().isNotEmpty)
        ? newsDescription.trim()
        : unreadCount == 1
        ? 'Tap to view the latest news.'
        : 'There are $unreadCount new news items to view.';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'news_update',
        number: unreadCount,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(1001, title, body, details);
  }

  Future<void> cancelNewsNotification() async {
    await _plugin.cancel(1001);
  }
}
