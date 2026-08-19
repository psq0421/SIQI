import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/local_database.dart';
import 'core/providers/app_providers.dart';
import 'core/services/app_log_service.dart';
import 'core/services/notification_service.dart';
import 'features/startup/startup_failure_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logs = await AppLogService.open();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(logs.error('flutter-error', details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(logs.error('platform-error', error, stackTrace));
    return true;
  };
  try {
    final preferences = await SharedPreferences.getInstance();
    final database = await LocalDatabase.open();
    final notifications = NotificationService();
    try {
      await notifications.initialize();
    } on Object catch (error, stackTrace) {
      await logs.warning('notification-initialize', '$error\n$stackTrace');
    }
    await logs.info('application-start', 'database ready');

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          localDatabaseProvider.overrideWithValue(database),
          notificationServiceProvider.overrideWithValue(notifications),
          appLogServiceProvider.overrideWithValue(logs),
        ],
        child: const SiqiApp(),
      ),
    );
  } on Object catch (error, stackTrace) {
    await logs.error('bootstrap-failed', error, stackTrace);
    runApp(StartupFailureApp(detail: error.toString()));
  }
}
