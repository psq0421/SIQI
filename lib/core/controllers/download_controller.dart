import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../services/model_download_service.dart';

class DownloadController
    extends StateNotifier<Map<String, ModelDownloadState>> {
  DownloadController(this._service, this._settings) : super(const {});
  final ModelDownloadService _service;
  final AppSettings Function() _settings;

  Future<void> start({
    required ModelDefinition model,
    required String? storagePath,
    required String title,
    required String body,
    required String channel,
    required String channelDescription,
  }) async {
    await _service.download(
      model: model,
      customStoragePath: storagePath,
      notificationTitle: title,
      notificationBody: body,
      notificationChannel: channel,
      notificationChannelDescription: channelDescription,
      wifiOnly: _settings().downloadOverWifiOnly,
      onProgress: (download) => state = {...state, model.id: download},
    );
  }

  void pause(String modelId) => _service.pause(modelId);
}
