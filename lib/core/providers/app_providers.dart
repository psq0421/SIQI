import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/chat_controller.dart';
import '../controllers/download_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/shell_queue_controller.dart';
import '../database/local_database.dart';
import '../models/app_models.dart';
import '../models/workbench_models.dart';
import '../services/agent_service.dart';
import '../services/ai_team_service.dart';
import '../services/api_service.dart';
import '../services/app_log_service.dart';
import '../services/archive_service.dart';
import '../services/cache_service.dart';
import '../services/file_content_service.dart';
import '../services/deepseek_harness_service.dart';
import '../services/github_service.dart';
import '../services/harness_service.dart';
import '../services/local_inference_service.dart';
import '../services/model_download_service.dart';
import '../services/mcp_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/preferences_service.dart';
import '../services/platform_service.dart';
import '../services/secure_key_service.dart';
import '../services/shell_service.dart';
import '../services/workspace_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final localDatabaseProvider = Provider<LocalDatabase>(
  (ref) => throw UnimplementedError(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
);
final appLogServiceProvider = Provider<AppLogService>(
  (ref) => throw UnimplementedError(),
);

@Riverpod(keepAlive: true)
Dio createDio(Ref ref) => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(minutes: 2),
  ),
);

final dioProvider = Provider<Dio>(createDio);
final preferencesServiceProvider = Provider(
  (ref) => PreferencesService(ref.watch(sharedPreferencesProvider)),
);
final secureKeyServiceProvider = Provider(
  (ref) => const SecureKeyService(
    FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ),
);
final apiServiceProvider = Provider(
  (ref) => ApiService(ref.watch(dioProvider)),
);
final localInferenceServiceProvider = Provider((ref) {
  final service = LocalInferenceService();
  ref.onDispose(service.dispose);
  return service;
});
final platformServiceProvider = Provider((ref) => const PlatformService());
final permissionServiceProvider = Provider(
  (ref) => PermissionService(ref.watch(localDatabaseProvider)),
);
final cacheServiceProvider = Provider((ref) => const CacheService());
final fileContentServiceProvider = Provider((ref) => FileContentService());
final archiveServiceProvider = Provider(
  (ref) => ArchiveService(ref.watch(localDatabaseProvider)),
);
final shellServiceProvider = Provider(
  (ref) => ShellService(ref.watch(localDatabaseProvider)),
);
final workspaceServiceProvider = Provider((ref) => WorkspaceService());
final harnessServiceProvider = Provider(
  (ref) => HarnessService(ref.watch(workspaceServiceProvider)),
);
final deepSeekHarnessServiceProvider = Provider(
  (ref) => DeepSeekHarnessService(
    ref.watch(dioProvider),
    ref.watch(localDatabaseProvider),
  ),
);
final mcpServiceProvider = Provider(
  (ref) => McpService(ref.watch(dioProvider), ref.watch(localDatabaseProvider)),
);
final agentServiceProvider = Provider(
  (ref) => AgentService(
    ref.watch(workspaceServiceProvider),
    ref.watch(shellServiceProvider),
  ),
);
final aiTeamServiceProvider = Provider(
  (ref) => AiTeamService(
    ref.watch(apiServiceProvider),
    ref.watch(secureKeyServiceProvider),
    ref.watch(localDatabaseProvider),
  ),
);
final githubServiceProvider = Provider(
  (ref) => GithubService(ref.watch(dioProvider)),
);
final modelDownloadServiceProvider = Provider(
  (ref) => ModelDownloadService(
    ref.watch(dioProvider),
    ref.watch(localDatabaseProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(platformServiceProvider),
    ref.watch(permissionServiceProvider),
  ),
);

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(ref.watch(preferencesServiceProvider)),
);
final chatProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) => ChatController(
    database: ref.watch(localDatabaseProvider),
    api: ref.watch(apiServiceProvider),
    keys: ref.watch(secureKeyServiceProvider),
    localInference: ref.watch(localInferenceServiceProvider),
    downloads: ref.watch(modelDownloadServiceProvider),
    agent: ref.watch(agentServiceProvider),
    settings: () => ref.read(settingsProvider),
  ),
);
final downloadProvider =
    StateNotifierProvider<DownloadController, Map<String, ModelDownloadState>>(
      (ref) => DownloadController(
        ref.watch(modelDownloadServiceProvider),
        () => ref.read(settingsProvider),
      ),
    );
final shellQueueProvider =
    StateNotifierProvider<ShellQueueController, List<ShellQueueItem>>(
      (ref) => ShellQueueController(
        ref.watch(shellServiceProvider),
        () => ref.read(settingsProvider),
      ),
    );
final apiProfilesProvider = FutureProvider<List<ApiProfile>>(
  (ref) => ref.watch(localDatabaseProvider).listApiProfiles(),
);
final mcpServersProvider = FutureProvider<List<Map<String, Object?>>>(
  (ref) => ref.watch(localDatabaseProvider).listMcpServers(),
);
final mcpCatalogProvider =
    FutureProvider.family<List<Map<String, Object?>>, String>(
      (ref, query) =>
          ref.watch(localDatabaseProvider).listMcpCatalog(query: query),
    );
final harnessPluginsProvider =
    FutureProvider.family<List<HarnessPlugin>, String>(
      (ref, query) =>
          ref.watch(localDatabaseProvider).listHarnessPlugins(query: query),
    );
final harnessPluginCountProvider = FutureProvider<int>(
  (ref) => ref.watch(localDatabaseProvider).harnessPluginCount(),
);
final permissionAuditProvider = FutureProvider(
  (ref) => ref.watch(localDatabaseProvider).listPermissionAudit(),
);
final workLogsProvider = FutureProvider(
  (ref) => ref.watch(localDatabaseProvider).listWorkLogs(),
);
final cacheSizeProvider = FutureProvider<int>(
  (ref) => ref.watch(cacheServiceProvider).size(),
);
