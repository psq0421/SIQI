import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../models/app_models.dart';
import 'local_task_service.dart';
import 'model_download_service.dart';
import 'platform_service.dart';

class AsrTranscriptionResult {
  const AsrTranscriptionResult({
    required this.text,
    required this.duration,
    required this.segmentCount,
  });

  final String text;
  final Duration duration;
  final int segmentCount;
}

/// Local ASR facade for sherpa-onnx. Long audio is converted to a path-backed
/// PCM WAV and decoded in 30-second chunks, so the 180-minute limit does not
/// imply loading an entire recording into Dart memory.
class AsrService {
  AsrService(this._downloads, this._platform);

  static const maximumDuration = Duration(minutes: 180);
  static const _platformChannel = MethodChannel('com.psq.siqi/platform');
  final ModelDownloadService _downloads;
  final PlatformService _platform;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  bool get isRecording => _recordingPath != null;

  Future<LocalTaskStatus> status(ModelDefinition model) async {
    if (model.task != ModelTask.speechRecognition) {
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

  Future<String> startRecording() async {
    if (_recordingPath != null) return _recordingPath!;
    if (!await _recorder.hasPermission()) {
      throw const LocalTaskException('microphone-denied');
    }
    final cache = Directory(
      p.join((await getTemporaryDirectory()).path, 'asr'),
    );
    await cache.create(recursive: true);
    final path = p.join(
      cache.path,
      'siqi_recording_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: path,
    );
    _recordingPath = path;
    return path;
  }

  Future<String?> stopRecording() async {
    if (_recordingPath == null) return null;
    final path = await _recorder.stop() ?? _recordingPath;
    _recordingPath = null;
    return path;
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    _recordingPath = null;
  }

  Future<AsrTranscriptionResult> transcribe({
    required ModelDefinition model,
    required String audioPath,
    void Function(double progress)? onProgress,
  }) async {
    if (model.task != ModelTask.speechRecognition ||
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
    final normalizedPath = await _ensurePcmWav(audioPath);
    final header = await _readWavHeader(File(normalizedPath));
    final duration = Duration(
      microseconds:
          header.frameCount *
          Duration.microsecondsPerSecond ~/
          header.sampleRate,
    );
    if (duration > maximumDuration) {
      throw const LocalTaskException('audio-too-long');
    }
    try {
      // Progress crosses isolate boundaries through a receive port to keep the
      // native decode off the UI thread without retaining the full waveform.
      final receive = ReceivePort();
      final subscription = receive.listen((value) {
        if (value is double) onProgress?.call(value);
      });
      try {
        final result = await Isolate.run(
          () =>
              _transcribeWav(model.id, paths, normalizedPath, receive.sendPort),
        );
        return AsrTranscriptionResult(
          text: result.text,
          duration: duration,
          segmentCount: result.segmentCount,
        );
      } finally {
        await subscription.cancel();
        receive.close();
      }
    } on LocalTaskException {
      rethrow;
    } on Object catch (error) {
      throw LocalTaskException('asr-inference-failed', error);
    }
  }

  Future<String> _ensurePcmWav(String sourcePath) async {
    final extension = p.extension(sourcePath).toLowerCase();
    if (extension == '.wav' || extension == '.wave') return sourcePath;
    final cache = Directory(
      p.join((await getTemporaryDirectory()).path, 'asr'),
    );
    await cache.create(recursive: true);
    final target = p.join(
      cache.path,
      'decoded_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    try {
      final result = await _platformChannel
          .invokeMethod<String>('decodeAudioToWav', {
            'source': sourcePath,
            'target': target,
            'maximumDurationMs': maximumDuration.inMilliseconds,
          });
      if (result == null || !await File(result).exists()) {
        throw const LocalTaskException('audio-decode-failed');
      }
      return result;
    } on PlatformException catch (error) {
      throw LocalTaskException('audio-decode-failed', error.code);
    }
  }

  Future<void> _guardMemory(int modelBytes) async {
    final memory = await _platform.deviceMemory();
    final totalBudget = (memory.totalBytes * .85).floor();
    const workingReserve = 384 * 1024 * 1024;
    if (modelBytes + workingReserve > totalBudget ||
        workingReserve >
            memory.availableBytes - memory.lowMemoryThresholdBytes) {
      throw const LocalTaskException('insufficient-memory');
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

class _AsrWorkerResult {
  const _AsrWorkerResult(this.text, this.segmentCount);
  final String text;
  final int segmentCount;
}

Future<_AsrWorkerResult> _transcribeWav(
  String modelId,
  Map<String, String> paths,
  String wavPath,
  SendPort progress,
) async {
  sherpa.initBindings();
  final model = _recognizerModel(modelId, paths);
  final recognizer = sherpa.OfflineRecognizer(
    sherpa.OfflineRecognizerConfig(model: model),
  );
  final header = await _readWavHeader(File(wavPath));
  final text = StringBuffer();
  var segments = 0;
  try {
    await for (final samples in _readWavChunks(File(wavPath), header)) {
      final stream = recognizer.createStream();
      try {
        stream.acceptWaveform(samples: samples, sampleRate: header.sampleRate);
        recognizer.decode(stream);
        final result = recognizer.getResult(stream).text.trim();
        if (result.isNotEmpty) {
          if (text.isNotEmpty) text.writeln();
          text.write(result);
        }
      } finally {
        stream.free();
      }
      segments++;
      final consumed = segments * header.sampleRate * 30;
      progress.send((consumed / header.frameCount).clamp(0, 1).toDouble());
    }
  } finally {
    recognizer.free();
  }
  return _AsrWorkerResult(text.toString(), segments);
}

sherpa.OfflineModelConfig _recognizerModel(
  String modelId,
  Map<String, String> paths,
) {
  if (modelId.contains('moonshine')) {
    return sherpa.OfflineModelConfig(
      moonshine: sherpa.OfflineMoonshineModelConfig(
        preprocessor: paths['preprocessor'] ?? '',
        encoder: paths['encoder'] ?? '',
        uncachedDecoder: paths['uncachedDecoder'] ?? '',
        cachedDecoder: paths['cachedDecoder'] ?? '',
        mergedDecoder: paths['mergedDecoder'] ?? '',
      ),
      tokens: paths['tokens'] ?? '',
      numThreads: Platform.numberOfProcessors.clamp(1, 4),
      debug: false,
      provider: 'cpu',
    );
  }
  if (modelId.contains('qwen3')) {
    return sherpa.OfflineModelConfig(
      qwen3Asr: sherpa.OfflineQwen3AsrModelConfig(
        convFrontend: paths['convFrontend'] ?? '',
        encoder: paths['encoder'] ?? '',
        decoder: paths['decoder'] ?? '',
        tokenizer: paths['tokenizer'] ?? '',
      ),
      tokens: paths['tokens'] ?? '',
      numThreads: Platform.numberOfProcessors.clamp(1, 4),
      debug: false,
      provider: 'cpu',
    );
  }
  throw const LocalTaskException('unsupported-asr-model-layout');
}

class _WavHeader {
  const _WavHeader({
    required this.dataOffset,
    required this.dataBytes,
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.audioFormat,
    required this.blockAlign,
  });

  final int dataOffset;
  final int dataBytes;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final int audioFormat;
  final int blockAlign;
  int get frameCount => dataBytes ~/ blockAlign;
}

Future<_WavHeader> _readWavHeader(File file) async {
  final handle = await file.open();
  try {
    final riff = await handle.read(12);
    if (riff.length != 12 ||
        String.fromCharCodes(riff.take(4)) != 'RIFF' ||
        String.fromCharCodes(riff.skip(8)) != 'WAVE') {
      throw const LocalTaskException('unsupported-wav');
    }
    int? sampleRate;
    int? channels;
    int? bits;
    int? format;
    int? blockAlign;
    while (await handle.position() + 8 <= await file.length()) {
      final chunkHeader = await handle.read(8);
      if (chunkHeader.length < 8) break;
      final name = String.fromCharCodes(chunkHeader.take(4));
      final size = ByteData.sublistView(
        Uint8List.fromList(chunkHeader),
        4,
        8,
      ).getUint32(0, Endian.little);
      final payloadOffset = await handle.position();
      if (name == 'fmt ') {
        final data = await handle.read(size);
        if (data.length < 16) throw const LocalTaskException('unsupported-wav');
        final view = ByteData.sublistView(Uint8List.fromList(data));
        format = view.getUint16(0, Endian.little);
        channels = view.getUint16(2, Endian.little);
        sampleRate = view.getUint32(4, Endian.little);
        blockAlign = view.getUint16(12, Endian.little);
        bits = view.getUint16(14, Endian.little);
      } else if (name == 'data') {
        if (sampleRate == null ||
            channels == null ||
            bits == null ||
            format == null ||
            blockAlign == null) {
          throw const LocalTaskException('invalid-wav-order');
        }
        return _WavHeader(
          dataOffset: payloadOffset,
          dataBytes: size,
          sampleRate: sampleRate,
          channels: channels,
          bitsPerSample: bits,
          audioFormat: format,
          blockAlign: blockAlign,
        );
      } else {
        await handle.setPosition(payloadOffset + size + (size.isOdd ? 1 : 0));
      }
    }
    throw const LocalTaskException('wav-data-missing');
  } finally {
    await handle.close();
  }
}

Stream<Float32List> _readWavChunks(File file, _WavHeader header) async* {
  if (!((header.audioFormat == 1 && header.bitsPerSample == 16) ||
      (header.audioFormat == 3 && header.bitsPerSample == 32))) {
    throw const LocalTaskException('unsupported-wav-encoding');
  }
  final handle = await file.open();
  try {
    await handle.setPosition(header.dataOffset);
    var remaining = header.dataBytes;
    final chunkBytes = header.sampleRate * 30 * header.blockAlign;
    while (remaining > 0) {
      final bytes = await handle.read(
        remaining < chunkBytes ? remaining : chunkBytes,
      );
      if (bytes.isEmpty) break;
      remaining -= bytes.length;
      final frames = bytes.length ~/ header.blockAlign;
      final samples = Float32List(frames);
      final view = ByteData.sublistView(Uint8List.fromList(bytes));
      for (var frame = 0; frame < frames; frame++) {
        var mixed = 0.0;
        for (var channel = 0; channel < header.channels; channel++) {
          final offset =
              frame * header.blockAlign + channel * (header.bitsPerSample ~/ 8);
          mixed += header.audioFormat == 1
              ? view.getInt16(offset, Endian.little) / 32768.0
              : view.getFloat32(offset, Endian.little);
        }
        samples[frame] = (mixed / header.channels).clamp(-1, 1).toDouble();
      }
      yield samples;
    }
  } finally {
    await handle.close();
  }
}
