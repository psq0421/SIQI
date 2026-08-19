import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _activeForegroundNotifications = <int>{};
  static const _downloadChannel = 'model_downloads';

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    );
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> showDownloadProgress({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    required int progress,
    required int max,
  }) async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return;
      _activeForegroundNotifications.add(id);
      await android.startForegroundService(
        id == 0 ? 1 : id,
        title,
        body,
        notificationDetails: AndroidNotificationDetails(
          _downloadChannel,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: progress < max,
          onlyAlertOnce: true,
          showProgress: true,
          progress: progress,
          maxProgress: max,
          category: AndroidNotificationCategory.progress,
        ),
        foregroundServiceTypes: const {
          AndroidServiceForegroundType.foregroundServiceTypeDataSync,
        },
      );
    } on Object {
      _activeForegroundNotifications.remove(id);
    }
  }

  Future<void> cancel(int id) async {
    _activeForegroundNotifications.remove(id);
    await _plugin.cancel(id);
    if (_activeForegroundNotifications.isEmpty) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.stopForegroundService();
    }
  }
}
