import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NewsNotificationService {
  NewsNotificationService._();

  static const String _oneSignalAppId = 'aea333e8-455f-4526-9bc2-bab597c328c4';
  static final NewsNotificationService instance = NewsNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_oneSignalAppId);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    await OneSignal.Notifications.requestPermission(true);

    _initialized = true;
  }

  Future<void> showNewNewsNotification({
    required int unreadCount,
    required String newsTitle,
    String? newsDescription,
  }) async {
    if (unreadCount <= 0) return;

    await initialize();

    final title = unreadCount == 1 ? newsTitle : '$newsTitle (+${unreadCount - 1} more)';
    final body = (newsDescription != null && newsDescription.trim().isNotEmpty)
        ? newsDescription.trim()
        : unreadCount == 1
        ? 'Tap to view the latest news.'
        : 'There are $unreadCount new news items to view.';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'local_news_updates',
        'Local News Updates',
        channelDescription: 'Local in-app fallback notifications for news updates.',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'news_update',
        number: unreadCount,
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    await _plugin.show(
      1001,
      title,
      body,
      details,
    );
  }

  Future<void> cancelNewsNotification() async {
    await _plugin.cancel(1001);
  }
}
