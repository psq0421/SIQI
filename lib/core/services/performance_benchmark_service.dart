import 'dart:async';

import '../models/app_models.dart';
import 'benchmark_journal.dart';
import 'local_inference_service.dart';
import 'platform_service.dart';

class PerformanceSample {
  const PerformanceSample({
    required this.at,
    required this.stage,
    required this.stats,
    this.tokens,
    this.elapsed,
  });

  final DateTime at;
  final String stage;
  final ProcessStats stats;
  final int? tokens;
  final Duration? elapsed;

  double? get endToEndTokensPerSecond =>
      tokens == null || elapsed == null || elapsed!.inMicroseconds == 0
      ? null
      : tokens! / (elapsed!.inMicroseconds / Duration.microsecondsPerSecond);

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'stage': stage,
    'rssBytes': stats.rssBytes,
    'pssBytes': stats.pssBytes,
    'swapPssBytes': stats.swapPssBytes,
    'minorFaults': stats.minorFaults,
    'majorFaults': stats.majorFaults,
    'batteryPercent': stats.batteryPercent,
    'tokens': tokens,
    'elapsedMs': elapsed?.inMilliseconds,
    'endToEndTokensPerSecond': endToEndTokensPerSecond,
  };
}

class PerformanceBenchmarkService {
  PerformanceBenchmarkService(this._platform, this._inference);

  final PlatformService _platform;
  final LocalInferenceService _inference;
  final _runGate = BenchmarkRunGate();

  bool tryBeginRun(Object owner) => !_inference.busy && _runGate.acquire(owner);

  void endRun(Object owner) => _runGate.release(owner);

  Future<PerformanceSample> sample(String stage) async => PerformanceSample(
    at: DateTime.now(),
    stage: stage,
    stats: await _platform.processStats(),
  );

  /// Runs one deterministic local request and returns privacy-safe metrics.
  /// The prompt is supplied by the caller so benchmark sets can be versioned
  /// and published without embedding user data in the app.
  Future<PerformanceSample> runDecode({
    required ModelDefinition model,
    required Map<String, String> artifactPaths,
    required String prompt,
    int contextWindow = 2048,
    int maxTokens = 128,
    LocalInferenceTuning? tuning,
    void Function(Map<String, dynamic> event)? onProgress,
  }) async {
    final started = DateTime.now();
    final clock = Stopwatch()..start();
    final before = await _platform.processStats();
    final result = await _inference.complete(
      model: model,
      artifactPaths: artifactPaths,
      messages: [
        ChatMessage(
          id: 'benchmark-user',
          sessionId: 'benchmark',
          role: MessageRole.user,
          content: prompt,
          createdAt: started,
        ),
      ],
      systemPrompt:
          'You are a benchmark worker. Answer briefly and deterministically.',
      contextWindow: contextWindow,
      temperature: 0,
      topP: 1,
      maxTokens: maxTokens,
      tuning: tuning,
      onProgress: onProgress,
    );
    final elapsed = clock.elapsed;
    final after = await _platform.processStats();
    return PerformanceSample(
      at: after.timestamp,
      stage: 'decode',
      stats: ProcessStats(
        rssBytes: after.rssBytes,
        pssBytes: after.pssBytes,
        swapPssBytes: after.swapPssBytes,
        minorFaults: after.minorFaults - before.minorFaults,
        majorFaults: after.majorFaults - before.majorFaults,
        batteryPercent: after.batteryPercent,
        timestamp: after.timestamp,
      ),
      tokens: result.usage.output,
      elapsed: elapsed,
    );
  }

  Future<void> stopModel() => _inference.unloadModel();
}
