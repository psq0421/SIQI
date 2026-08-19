import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/local_database.dart';
import '../models/app_models.dart';
import '../models/privacy_models.dart';
import 'notification_service.dart';
import 'permission_service.dart';
import 'platform_service.dart';

class ModelDownloadService {
  ModelDownloadService(
    this._dio,
    this._database,
    this._notifications,
    this._platform,
    this._permissions,
  );
  final Dio _dio;
  final LocalDatabase _database;
  final NotificationService _notifications;
  final PlatformService _platform;
  final PermissionService _permissions;
  final Map<String, CancelToken> _tokens = {};
  final Map<String, Future<bool>> _verificationCache = {};

  Future<String> defaultStoragePath() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'models');
  }

  Future<String?> installedPath(String modelId) async {
    final record = await _database.downloadedModel(modelId);
    if (record == null) return null;
    final path = record['file_path']! as String;
    final file = File(path);
    if (!await file.exists()) return null;
    final expectedSize = record['file_size']! as int;
    final stat = await file.stat();
    if (stat.size != expectedSize) return null;
    final expectedChecksum = record['checksum'] as String?;
    if (expectedChecksum != null && expectedChecksum.isNotEmpty) {
      final fingerprint =
          '$path|${stat.size}|${stat.modified.microsecondsSinceEpoch}|$expectedChecksum';
      final verified = await (_verificationCache[fingerprint] ??=
          _verifyChecksum(file, expectedChecksum));
      if (!verified) return null;
    }
    return path;
  }

  Future<bool> _verifyChecksum(File file, String expectedChecksum) async {
    final actualChecksum = (await sha256.bind(file.openRead()).first)
        .toString();
    return actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
  }

  Future<void> download({
    required ModelDefinition model,
    required String? customStoragePath,
    required void Function(ModelDownloadState state) onProgress,
    required String notificationTitle,
    required String notificationBody,
    required String notificationChannel,
    required String notificationChannelDescription,
    required bool wifiOnly,
  }) async {
    if (wifiOnly) {
      final network = await _platform.networkStatus();
      if (!network.connected || !network.onWifi) {
        onProgress(
          const ModelDownloadState(
            status: DownloadStatus.failed,
            error: 'wifi-required',
          ),
        );
        return;
      }
    }
    final url = model.downloadUrl;
    if (url == null) {
      throw StateError('No verified download URL is available for this model.');
    }
    final notificationDecision = await _permissions.request(
      AppPermissionKind.notifications,
      PermissionPurpose.modelDownloadProgress,
      detail: model.id,
    );
    final notificationsAllowed =
        notificationDecision == PermissionDecision.granted;
    await _database.addWorkLog(
      category: 'model',
      title: 'download:${model.id}',
      detail: url,
      status: 'started',
    );
    final root = customStoragePath?.trim().isNotEmpty == true
        ? customStoragePath!.trim()
        : await defaultStoragePath();
    final directory = Directory(root);
    await directory.create(recursive: true);
    final target = File(p.join(root, '${model.id}.gguf'));
    final partial = File('${target.path}.part');
    final existing = await partial.exists() ? await partial.length() : 0;
    final token = CancelToken();
    _tokens[model.id] = token;
    onProgress(
      ModelDownloadState(
        status: DownloadStatus.downloading,
        received: existing,
        total: model.sizeBytes ?? 0,
        path: partial.path,
      ),
    );

    try {
      await _dio.download(
        url,
        partial.path,
        cancelToken: token,
        deleteOnError: false,
        fileAccessMode: existing > 0
            ? FileAccessMode.append
            : FileAccessMode.write,
        options: Options(
          headers: {
            if (existing > 0) HttpHeaders.rangeHeader: 'bytes=$existing-',
          },
        ),
        onReceiveProgress: (received, total) {
          final current = existing + received;
          final full = total <= 0 ? (model.sizeBytes ?? 0) : existing + total;
          onProgress(
            ModelDownloadState(
              status: DownloadStatus.downloading,
              received: current,
              total: full,
              path: partial.path,
            ),
          );
          if (notificationsAllowed &&
              full > 0 &&
              (current == full || current % (8 * 1024 * 1024) < 65536)) {
            _notifications.showDownloadProgress(
              id: model.id.hashCode & 0x7fffffff,
              title: notificationTitle,
              body: notificationBody,
              channelName: notificationChannel,
              channelDescription: notificationChannelDescription,
              progress: current.clamp(0, full).toInt(),
              max: full,
            );
          }
        },
      );
      final checksum = (await sha256.bind(partial.openRead()).first).toString();
      final expected = model.expectedSha256?.toLowerCase();
      if (expected != null && checksum.toLowerCase() != expected) {
        await partial.delete();
        await _database.addWorkLog(
          category: 'model',
          title: 'download:${model.id}',
          detail: 'checksum mismatch · expected=$expected · actual=$checksum',
          status: 'failed',
        );
        onProgress(
          const ModelDownloadState(
            status: DownloadStatus.failed,
            error: 'checksum-mismatch',
          ),
        );
        return;
      }
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
      final size = await target.length();
      await _database.saveDownloadedModel(
        model.id,
        target.path,
        size,
        checksum: checksum,
      );
      await _database.addWorkLog(
        category: 'model',
        title: 'download:${model.id}',
        detail: '$size bytes · sha256:$checksum',
        status: 'completed',
      );
      onProgress(
        ModelDownloadState(
          status: DownloadStatus.completed,
          received: size,
          total: size,
          path: target.path,
        ),
      );
      await _notifications.cancel(model.id.hashCode & 0x7fffffff);
    } on DioException catch (error) {
      final cancelled = CancelToken.isCancel(error);
      onProgress(
        ModelDownloadState(
          status: cancelled ? DownloadStatus.paused : DownloadStatus.failed,
          received: await partial.exists() ? await partial.length() : 0,
          total: model.sizeBytes ?? 0,
          path: partial.path,
          error: error.message,
        ),
      );
      await _database.addWorkLog(
        category: 'model',
        title: 'download:${model.id}',
        detail: error.message ?? error.type.name,
        status: cancelled ? 'paused' : 'failed',
      );
    } finally {
      _tokens.remove(model.id);
    }
  }

  void pause(String modelId) => _tokens[modelId]?.cancel('paused');
}
