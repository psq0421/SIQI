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
import 'core/services/preferences_service.dart';
import 'core/services/workspace_service.dart';
import 'features/startup/startup_failure_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logsFuture = AppLogService.open();
  final preferencesFuture = SharedPreferences.getInstance();
  final databaseFuture = LocalDatabase.open();
  final logs = await logsFuture;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(logs.error('flutter-error', details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(logs.error('platform-error', error, stackTrace));
    return true;
  };
  try {
    final preferences = await preferencesFuture;
    final database = await databaseFuture;
    final directories = await WorkspaceService.ensureAppDirectories();
    final preferencesService = PreferencesService(preferences);
    final currentSettings = preferencesService.load();
    if (currentSettings.activeWorkspacePath == null ||
        currentSettings.modelStoragePath == null) {
      await preferencesService.save(
        currentSettings.copyWith(
          activeWorkspacePath:
              currentSettings.activeWorkspacePath ?? directories.projects,
          modelStoragePath:
              currentSettings.modelStoragePath ?? directories.models,
        ),
      );
    }
    final notifications = NotificationService();

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
    unawaited(logs.info('application-start', 'database ready'));
    unawaited(
      notifications.initialize().catchError((Object error, StackTrace stack) {
        return logs.warning('notification-initialize', '$error\n$stack');
      }),
    );
  } on Object catch (error, stackTrace) {
    await logs.error('bootstrap-failed', error, stackTrace);
    runApp(StartupFailureApp(detail: error.toString()));
  }
}
