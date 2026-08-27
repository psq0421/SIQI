import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/local_database.dart';
import '../models/app_models.dart';
import '../models/privacy_models.dart';
import 'notification_service.dart';
import 'permission_service.dart';
import 'platform_service.dart';
import 'resource_planner.dart';

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
  static const _verificationValidity = Duration(days: 30);
  static const _fileTimestampTolerance = Duration(seconds: 5);

  Future<String> defaultStoragePath() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'models');
  }

  Future<String?> installedPath(String modelId) async {
    final artifacts = await _database.listDownloadedModelArtifacts(modelId);
    for (final record in artifacts) {
      if (record['role'] != ModelArtifactRole.model.name) continue;
      if (await _verifiedRecordPath(record) case final path?) return path;
    }
    final legacy = await _database.downloadedModel(modelId);
    return legacy == null ? null : _verifiedRecordPath(legacy);
  }

  Future<Map<String, String>> installedArtifactPaths(
    ModelDefinition model,
  ) async {
    final result = <String, String>{};
    for (final artifact in model.installArtifacts) {
      final path = await _installedArtifactPath(model.id, artifact);
      if (path != null) result[artifact.id] = path;
    }
    return result;
  }

  Future<bool> isFullyInstalled(ModelDefinition model) async {
    final installed = await installedArtifactPaths(model);
    return model.installArtifacts
        .where((artifact) => !artifact.optional)
        .every((artifact) => installed.containsKey(artifact.id));
  }

  Future<int> removeInstalled(String modelId) async {
    if (_tokens.containsKey(modelId)) {
      throw StateError('download-active');
    }
    final records = await _database.listDownloadedModelArtifacts(modelId);
    final legacy = await _database.downloadedModel(modelId);
    final paths = <String>{
      for (final record in records)
        if (record['file_path'] case final String path) path,
      if (legacy?['file_path'] case final String path) path,
    };
    var removedBytes = 0;
    final parents = <String>{};
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) continue;
      removedBytes += await file.length();
      parents.add(file.parent.path);
      await file.delete();
    }
    for (final parent in parents) {
      final directory = Directory(parent);
      if (await directory.exists() &&
          await directory.list(followLinks: false).isEmpty) {
        await directory.delete();
      }
    }
    await _database.deleteDownloadedModelRecords(modelId);
    _verificationCache.clear();
    await _database.addWorkLog(
      category: 'model',
      title: 'remove:$modelId',
      detail: '$removedBytes bytes',
      status: 'completed',
    );
    return removedBytes;
  }

  Future<String?> _installedArtifactPath(
    String modelId,
    ModelArtifact artifact,
  ) async {
    final record = await _database.downloadedModelArtifact(
      modelId,
      artifact.id,
    );
    if (record != null) return _verifiedRecordPath(record);
    if (artifact.role == ModelArtifactRole.model) {
      final legacy = await _database.downloadedModel(modelId);
      if (legacy != null) return _verifiedRecordPath(legacy);
    }
    return null;
  }

  Future<String?> _verifiedRecordPath(Map<String, Object?> record) async {
    final path = record['file_path'] as String?;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final expectedSize = (record['file_size'] as num?)?.toInt();
    final stat = await file.stat();
    if (expectedSize != null && stat.size != expectedSize) return null;
    final expectedChecksum = record['checksum'] as String?;
    if (expectedChecksum != null && expectedChecksum.isNotEmpty) {
      final verifiedAt = (record['verified_at'] as num?)?.toInt();
      final fileUnchangedSinceVerification =
          verifiedAt != null &&
          stat.modified.millisecondsSinceEpoch <=
              verifiedAt + _fileTimestampTolerance.inMilliseconds;
      final verificationStillFresh =
          verifiedAt != null &&
          DateTime.now().millisecondsSinceEpoch - verifiedAt <=
              _verificationValidity.inMilliseconds;
      if (fileUnchangedSinceVerification && verificationStillFresh) {
        return path;
      }
      final fingerprint =
          '$path|${stat.size}|${stat.modified.microsecondsSinceEpoch}|$expectedChecksum';
      final verified = await (_verificationCache[fingerprint] ??=
          _verifyChecksum(file, expectedChecksum));
      if (!verified) return null;
      final modelId = record['model_id'] as String?;
      final artifactId = record['artifact_id'] as String?;
      if (modelId != null && artifactId != null) {
        await _database.markModelArtifactVerified(modelId, artifactId);
      }
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
    if (_tokens.containsKey(model.id)) {
      onProgress(
        const ModelDownloadState(
          status: DownloadStatus.failed,
          error: 'download-already-running',
        ),
      );
      return;
    }
    if (!model.downloadable) {
      onProgress(
        ModelDownloadState(
          status: DownloadStatus.failed,
          error: model.blockReason ?? 'source-unverified',
        ),
      );
      return;
    }
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

    final root = customStoragePath?.trim().isNotEmpty == true
        ? customStoragePath!.trim()
        : await defaultStoragePath();
    final modelDirectory = Directory(p.join(root, model.id));
    await modelDirectory.create(recursive: true);
    final artifacts = model.installArtifacts;
    final installed = await installedArtifactPaths(model);
    final completedBytes = artifacts
        .where((artifact) => installed.containsKey(artifact.id))
        .fold<int>(0, (total, artifact) => total + artifact.sizeBytes);
    final storage = await _platform.storageInfo(modelDirectory.path);
    final storagePlan = ResourcePlanner.planDownload(
      remainingBytes: model.totalDownloadBytes - completedBytes,
      storage: storage,
    );
    if (!storagePlan.allowed) {
      onProgress(
        ModelDownloadState(
          status: DownloadStatus.failed,
          received: completedBytes,
          total: model.totalDownloadBytes,
          error: storagePlan.reasonCode,
        ),
      );
      return;
    }

    final notificationDecision = await _permissions.request(
      AppPermissionKind.notifications,
      PermissionPurpose.modelDownloadProgress,
      detail: model.id,
    );
    final notificationsAllowed =
        notificationDecision == PermissionDecision.granted;
    final token = CancelToken();
    _tokens[model.id] = token;
    await _database.addWorkLog(
      category: 'model',
      title: 'download:${model.id}',
      detail:
          '${artifacts.length} artifacts | ${model.totalDownloadBytes} bytes | ModelScope',
      status: 'started',
    );

    var aggregateCompleted = completedBytes;
    try {
      for (final artifact in artifacts) {
        if (installed.containsKey(artifact.id)) continue;
        await _downloadArtifact(
          model: model,
          artifact: artifact,
          directory: modelDirectory,
          token: token,
          baseReceived: aggregateCompleted,
          totalBytes: model.totalDownloadBytes,
          notificationsAllowed: notificationsAllowed,
          notificationTitle: notificationTitle,
          notificationBody: notificationBody,
          notificationChannel: notificationChannel,
          notificationChannelDescription: notificationChannelDescription,
          onProgress: onProgress,
        );
        aggregateCompleted += artifact.sizeBytes;
      }
      final primary = await installedPath(model.id);
      if (primary == null) throw const FormatException('model-file-missing');
      await _database.addWorkLog(
        category: 'model',
        title: 'download:${model.id}',
        detail:
            '${artifacts.length} artifacts verified | ${model.totalDownloadBytes} bytes',
        status: 'completed',
      );
      onProgress(
        ModelDownloadState(
          status: DownloadStatus.completed,
          received: model.totalDownloadBytes,
          total: model.totalDownloadBytes,
          path: primary,
        ),
      );
    } on DioException catch (error) {
      final cancelled = CancelToken.isCancel(error);
      final code = cancelled ? 'paused' : _networkErrorCode(error);
      onProgress(
        ModelDownloadState(
          status: cancelled ? DownloadStatus.paused : DownloadStatus.failed,
          received: aggregateCompleted,
          total: model.totalDownloadBytes,
          error: code,
        ),
      );
      await _logFailure(model.id, code, cancelled ? 'paused' : 'failed');
    } on FileSystemException catch (error) {
      onProgress(
        ModelDownloadState(
          status: DownloadStatus.failed,
          received: aggregateCompleted,
          total: model.totalDownloadBytes,
          error: 'storage-error:${error.osError?.errorCode ?? 0}',
        ),
      );
      await _logFailure(model.id, error.toString(), 'failed');
    } on FormatException catch (error) {
      onProgress(
        ModelDownloadState(
          status: DownloadStatus.failed,
          received: aggregateCompleted,
          total: model.totalDownloadBytes,
          error: error.message,
        ),
      );
      await _logFailure(model.id, error.message, 'failed');
    } finally {
      _tokens.remove(model.id);
      await _notifications.cancel(model.id.hashCode & 0x7fffffff);
    }
  }

  Future<void> _downloadArtifact({
    required ModelDefinition model,
    required ModelArtifact artifact,
    required Directory directory,
    required CancelToken token,
    required int baseReceived,
    required int totalBytes,
    required bool notificationsAllowed,
    required String notificationTitle,
    required String notificationBody,
    required String notificationChannel,
    required String notificationChannelDescription,
    required void Function(ModelDownloadState state) onProgress,
  }) async {
    final safeName = p.basename(artifact.fileName);
    if (safeName != artifact.fileName || safeName.isEmpty) {
      throw const FormatException('invalid-artifact-name');
    }
    final target = File(p.join(directory.path, safeName));
    final partial = File('${target.path}.part');
    final resumeFile = File('${partial.path}.resume.json');
    var existing = await partial.exists() ? await partial.length() : 0;
    if (existing > artifact.sizeBytes) {
      await partial.delete();
      existing = 0;
    }
    var resumeMetadata = await _readResumeMetadata(resumeFile);
    final metadataMatches =
        resumeMetadata['source'] == artifact.downloadUrl &&
        resumeMetadata['expectedSize'] == artifact.sizeBytes &&
        resumeMetadata['expectedSha256'] == artifact.expectedSha256;
    if (existing > 0 && !metadataMatches) {
      await partial.delete();
      if (await resumeFile.exists()) await resumeFile.delete();
      existing = 0;
      resumeMetadata = const {};
    }
    final resumeEtag = resumeMetadata['etag'];
    final resumeLastModified = resumeMetadata['lastModified'];
    final headers = <String, Object>{
      HttpHeaders.acceptEncodingHeader: 'identity',
      if (existing > 0) HttpHeaders.rangeHeader: 'bytes=$existing-',
      if (existing > 0 && resumeEtag is String)
        HttpHeaders.ifRangeHeader: resumeEtag,
      if (existing > 0 && resumeEtag is! String && resumeLastModified is String)
        HttpHeaders.ifRangeHeader: resumeLastModified,
    };

    onProgress(
      ModelDownloadState(
        status: DownloadStatus.downloading,
        received: baseReceived + existing,
        total: totalBytes,
        path: partial.path,
      ),
    );
    final response = await _dio.get<ResponseBody>(
      artifact.downloadUrl,
      cancelToken: token,
      options: Options(
        responseType: ResponseType.stream,
        headers: headers,
        followRedirects: true,
        maxRedirects: 8,
        receiveTimeout: const Duration(minutes: 30),
        validateStatus: (status) =>
            status != null && (status == 200 || status == 206 || status == 416),
      ),
    );
    final status = response.statusCode ?? 0;
    final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
    final rangeStart = contentRange == null
        ? null
        : int.tryParse(
            RegExp(
                  r'^bytes\s+(\d+)-',
                  caseSensitive: false,
                ).firstMatch(contentRange)?.group(1) ??
                '',
          );
    if (status == 416 && existing == artifact.sizeBytes) {
      await _finalizeArtifact(
        model: model,
        artifact: artifact,
        partial: partial,
        target: target,
        resumeFile: resumeFile,
        etag: resumeMetadata['etag'] as String?,
        lastModified: resumeMetadata['lastModified'] as String?,
      );
      return;
    }
    if (status == 416) throw const FormatException('range-rejected');

    final append = existing > 0 && status == 206 && rangeStart == existing;
    if (!append) existing = 0;
    final etag = response.headers.value(HttpHeaders.etagHeader);
    final lastModified = response.headers.value(HttpHeaders.lastModifiedHeader);
    await resumeFile.writeAsString(
      jsonEncode({
        'source': artifact.downloadUrl,
        'etag': etag,
        'lastModified': lastModified,
        'expectedSize': artifact.sizeBytes,
        'expectedSha256': artifact.expectedSha256,
      }),
      flush: true,
    );

    final sink = partial.openWrite(
      mode: append ? FileMode.writeOnlyAppend : FileMode.writeOnly,
    );
    var received = existing;
    var lastNotification = -1;
    var lastReportedBytes = existing;
    var lastReportAt = DateTime.now();
    try {
      final body = response.data;
      if (body == null) throw const FormatException('empty-response');
      await for (final chunk in body.stream) {
        if (token.isCancelled) {
          throw DioException.requestCancelled(
            requestOptions: response.requestOptions,
            reason: token.cancelError,
          );
        }
        sink.add(chunk);
        received += chunk.length;
        final aggregate = baseReceived + received;
        final now = DateTime.now();
        if (received == artifact.sizeBytes ||
            (received - lastReportedBytes >= 1024 * 1024 &&
                now.difference(lastReportAt) >=
                    const Duration(milliseconds: 120))) {
          lastReportedBytes = received;
          lastReportAt = now;
          onProgress(
            ModelDownloadState(
              status: DownloadStatus.downloading,
              received: aggregate,
              total: totalBytes,
              path: partial.path,
            ),
          );
        }
        final notificationProgress = totalBytes <= 0
            ? 0
            : ((aggregate / totalBytes) * 1000).clamp(0, 1000).round();
        if (notificationsAllowed &&
            (notificationProgress == 1000 ||
                notificationProgress >= lastNotification + 5)) {
          lastNotification = notificationProgress;
          unawaited(
            _notifications.showDownloadProgress(
              id: model.id.hashCode & 0x7fffffff,
              title: notificationTitle,
              body: notificationBody,
              channelName: notificationChannel,
              channelDescription: notificationChannelDescription,
              progress: notificationProgress,
              max: 1000,
            ),
          );
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    final actualSize = await partial.length();
    if (actualSize != artifact.sizeBytes) {
      if (actualSize > artifact.sizeBytes) await partial.delete();
      throw FormatException(
        actualSize < artifact.sizeBytes
            ? 'incomplete-download'
            : 'size-mismatch',
      );
    }
    await _finalizeArtifact(
      model: model,
      artifact: artifact,
      partial: partial,
      target: target,
      resumeFile: resumeFile,
      etag: etag,
      lastModified: lastModified,
    );
  }

  Future<void> _finalizeArtifact({
    required ModelDefinition model,
    required ModelArtifact artifact,
    required File partial,
    required File target,
    required File resumeFile,
    required String? etag,
    required String? lastModified,
  }) async {
    final checksum = (await sha256.bind(partial.openRead()).first).toString();
    if (checksum.toLowerCase() != artifact.expectedSha256.toLowerCase()) {
      await partial.delete();
      if (await resumeFile.exists()) await resumeFile.delete();
      throw const FormatException('checksum-mismatch');
    }
    if (artifact.format == ModelFormat.gguf) {
      final handle = await partial.open();
      try {
        final magic = await handle.read(4);
        if (magic.length != 4 ||
            magic[0] != 0x47 ||
            magic[1] != 0x47 ||
            magic[2] != 0x55 ||
            magic[3] != 0x46) {
          throw const FormatException('format-mismatch');
        }
      } finally {
        await handle.close();
      }
    }
    if (await target.exists()) await target.delete();
    final installed = await partial.rename(target.path);
    if (await resumeFile.exists()) await resumeFile.delete();
    await _database.saveModelArtifact(
      modelId: model.id,
      artifact: artifact,
      path: installed.path,
      size: await installed.length(),
      checksum: checksum,
      etag: etag,
      lastModified: lastModified,
    );
    if (artifact.role == ModelArtifactRole.model) {
      await _database.saveDownloadedModel(
        model.id,
        installed.path,
        await installed.length(),
        checksum: checksum,
      );
    }
  }

  Future<Map<String, Object?>> _readResumeMetadata(File file) async {
    try {
      if (!await file.exists()) return const {};
      final value = jsonDecode(await file.readAsString());
      return value is Map ? Map<String, Object?>.from(value) : const {};
    } on Object {
      return const {};
    }
  }

  String _networkErrorCode(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout => 'connection-timeout',
    DioExceptionType.sendTimeout => 'send-timeout',
    DioExceptionType.receiveTimeout => 'receive-timeout',
    DioExceptionType.badCertificate => 'certificate-error',
    DioExceptionType.badResponse => 'http-${error.response?.statusCode ?? 0}',
    DioExceptionType.connectionError => 'network-unavailable',
    DioExceptionType.transformTimeout => 'response-timeout',
    DioExceptionType.cancel => 'paused',
    DioExceptionType.unknown => 'network-error',
  };

  Future<void> _logFailure(String modelId, String detail, String status) =>
      _database.addWorkLog(
        category: 'model',
        title: 'download:$modelId',
        detail: detail,
        status: status,
      );

  void pause(String modelId) => _tokens[modelId]?.cancel('paused');
}
