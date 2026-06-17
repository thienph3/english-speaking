import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Daily reminder notification service.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);
  }

  static Future<void> scheduleDailyReminder() async {
    const android = AndroidNotificationDetails(
      'daily_reminder',
      'Nhắc luyện tập',
      channelDescription: 'Nhắc nhở luyện nói hàng ngày',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.periodicallyShow(
      id: 0,
      title: 'SpeakEng',
      body: '5 phút luyện nói hôm nay! 🎤',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
