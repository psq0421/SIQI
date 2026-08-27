import 'dart:io';
import 'dart:isolate';

import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../models/app_models.dart';
import 'local_task_service.dart';
import 'model_download_service.dart';
import 'platform_service.dart';

class TtsSynthesisResult {
  const TtsSynthesisResult({
    required this.path,
    required this.sampleRate,
    required this.sampleCount,
  });

  final String path;
  final int sampleRate;
  final int sampleCount;

  Duration get duration => sampleRate <= 0
      ? Duration.zero
      : Duration(milliseconds: sampleCount * 1000 ~/ sampleRate);
}

/// Local speech synthesis. The bundled sherpa-onnx C API is invoked from a
/// worker isolate; the UI isolate only receives the resulting WAV path.
class TtsService {
  TtsService(this._downloads, this._platform);

  static const maximumCharacters = 12000;
  final ModelDownloadService _downloads;
  final PlatformService _platform;
  final AudioPlayer _player = AudioPlayer();

  Future<LocalTaskStatus> status(ModelDefinition model) async {
    if (model.task != ModelTask.speechSynthesis) {
      return const LocalTaskStatus(
        available: false,
        runtime: 'sherpa-onnx',
        detail: 'wrong-model-task',
      );
    }
    if (!model.runnable || model.runtime != ModelRuntime.sherpaOnnx) {
      return const LocalTaskStatus(
        available: false,
        runtime: 'sherpa-onnx',
        detail: 'runtime-not-bundled-for-model',
      );
    }
    final installed = await _downloads.isFullyInstalled(model);
    return LocalTaskStatus(
      available: installed,
      runtime: 'sherpa-onnx FFI',
      detail: installed ? null : 'model-not-installed',
    );
  }

  Future<TtsSynthesisResult> synthesize({
    required ModelDefinition model,
    required String text,
    double speed = 1,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) throw const LocalTaskException('empty-text');
    if (normalized.length > maximumCharacters) {
      throw const LocalTaskException('text-too-long');
    }
    if (model.task != ModelTask.speechSynthesis ||
        model.runtime != ModelRuntime.sherpaOnnx ||
        !model.runnable) {
      throw const LocalTaskException('runtime-not-bundled-for-model');
    }
    final paths = await _downloads.installedArtifactPaths(model);
    if (paths.length <
        model.installArtifacts.where((e) => !e.optional).length) {
      throw const LocalTaskException('model-not-installed');
    }
    await _guardMemory(model.totalDownloadBytes);
    final cache = Directory(
      p.join((await getTemporaryDirectory()).path, 'tts'),
    );
    await cache.create(recursive: true);
    final output = p.join(
      cache.path,
      'siqi_tts_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    try {
      final result = await Isolate.run(
        () => _synthesizeSupertonic(paths, normalized, speed, output),
      );
      if (!await File(result.path).exists() || result.sampleCount == 0) {
        throw const LocalTaskException('empty-audio');
      }
      return result;
    } on LocalTaskException {
      rethrow;
    } on Object catch (error) {
      throw LocalTaskException('tts-inference-failed', error);
    }
  }

  Future<void> speak({
    required ModelDefinition model,
    required String text,
    double speed = 1,
  }) async {
    final result = await synthesize(model: model, text: text, speed: speed);
    await _player.stop();
    await _player.play(DeviceFileSource(result.path));
  }

  Future<void> stop() => _player.stop();

  Future<void> _guardMemory(int modelBytes) async {
    final memory = await _platform.deviceMemory();
    final totalBudget = (memory.totalBytes * .85).floor();
    final availableBudget =
        memory.availableBytes - memory.lowMemoryThresholdBytes;
    const workingReserve = 256 * 1024 * 1024;
    if (modelBytes + workingReserve > totalBudget ||
        workingReserve > availableBudget) {
      throw const LocalTaskException('insufficient-memory');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

TtsSynthesisResult _synthesizeSupertonic(
  Map<String, String> paths,
  String text,
  double speed,
  String output,
) {
  sherpa.initBindings();
  final model = sherpa.OfflineTtsModelConfig(
    supertonic: sherpa.OfflineTtsSupertonicModelConfig(
      durationPredictor: paths['durationPredictor'] ?? '',
      textEncoder: paths['textEncoder'] ?? '',
      vectorEstimator: paths['vectorEstimator'] ?? '',
      vocoder: paths['vocoder'] ?? '',
      ttsJson: paths['ttsJson'] ?? '',
      unicodeIndexer: paths['unicodeIndexer'] ?? '',
      voiceStyle: paths['voiceStyle'] ?? '',
    ),
    numThreads: Platform.numberOfProcessors.clamp(1, 4),
    debug: false,
    provider: 'cpu',
  );
  final tts = sherpa.OfflineTts(
    sherpa.OfflineTtsConfig(model: model, maxNumSenetences: 2),
  );
  try {
    final audio = tts.generate(text: text, speed: speed.clamp(.5, 2));
    if (audio.samples.isEmpty || audio.sampleRate <= 0) {
      throw const LocalTaskException('empty-audio');
    }
    final written = sherpa.writeWave(
      filename: output,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );
    if (!written) throw const LocalTaskException('audio-write-failed');
    return TtsSynthesisResult(
      path: output,
      sampleRate: audio.sampleRate,
      sampleCount: audio.samples.length,
    );
  } finally {
    tts.free();
  }
}
