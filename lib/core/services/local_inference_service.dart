import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

import '../models/app_models.dart';
import 'file_content_service.dart';
import 'generation_delta_timings.dart';
import 'inference_health_policy.dart';
import 'platform_service.dart';
import 'resource_planner.dart';
import 'minicpm_les_backend.dart';

class LocalEngineStatus {
  const LocalEngineStatus({
    required this.available,
    required this.engine,
    required this.memoryBytes,
    this.detail,
  });

  final bool available;
  final String engine;
  final int memoryBytes;
  final String? detail;
}

enum LocalInferenceStage { modelLoad, prompt, generation, emptyOutput }

class LocalInferenceException implements Exception {
  const LocalInferenceException(this.stage, this.cause);

  final LocalInferenceStage stage;
  final Object cause;

  @override
  String toString() => 'local-${stage.name}: $cause';
}

class LocalInferenceCancelledException implements Exception {
  const LocalInferenceCancelledException();
}

/// Explicit, reproducible benchmark settings; never exposed to LAN callers.
class LocalInferenceTuning {
  const LocalInferenceTuning({
    this.backend = GpuBackend.cpu,
    this.gpuLayers = 0,
    this.threads = 4,
    this.batchSize = 128,
    this.microBatchSize = 64,
    this.cacheType = 'q8_0',
    this.flashAttention = true,
    this.expertWindow = 56,
    this.prefetchDepth = 4,
    this.decodeThreadSweep = false,
  });
  final GpuBackend backend;
  final int gpuLayers;
  final int threads;
  final int batchSize;
  final int microBatchSize;
  final String cacheType;
  final bool flashAttention;
  final int expertWindow;
  final int prefetchDepth;

  /// Lab-only comparison from an identical prefilled native state.
  final bool decodeThreadSweep;
}

class _LoadAttempt {
  const _LoadAttempt({
    required this.contextSize,
    required this.backend,
    required this.gpuLayers,
    required this.threadCount,
    required this.batchSize,
    required this.microBatchSize,
    required this.cacheType,
    required this.flashAttention,
    required this.liteRtLmBackend,
  });

  final int contextSize;
  final GpuBackend backend;
  final int gpuLayers;
  final int threadCount;
  final int batchSize;
  final int microBatchSize;
  final String cacheType;
  final bool flashAttention;
  final LiteRtLmBackendPreference liteRtLmBackend;
}

/// Owns one current llama.cpp engine. The native runtime contains explicit
/// Qwen3.5, Gemma 4, and Hunyuan support and performs generation off the UI
/// isolate.
class LocalInferenceService {
  static const _platformChannel = MethodChannel('com.psq.siqi/platform');

  /// Applies the persisted process mask before loading the native engine. The
  /// native worker inherits this mask when it is spawned, so selected cores
  /// also govern llama.cpp threads instead of only the UI isolate.
  Future<void> configureCpuAffinity(List<int> cores) async {
    if (cores.isEmpty) return;
    await _platformChannel.invokeMethod<bool>('setCpuAffinity', {
      'cores': cores,
    });
  }

  LlamaEngine? _engine;
  String? _loadedModelPath;
  String? _loadedProjectorPath;
  int? _loadedContextSize;
  Future<void>? _loading;
  bool _disposed = false;
  bool _cancellationRequested = false;
  String? _interruptionReason;
  Completer<void>? _requestDone;
  Future<void>? _unloading;
  bool get busy => _requestDone != null || _unloading != null;
  Map<String, Object?>? lastPerformance;
  bool _fileBackedRepack = false;
  _LoadAttempt? _effectiveAttempt;
  MiniCpmLesBackend? _les;

  Future<LocalEngineStatus> status() async {
    if (!Platform.isAndroid) {
      return const LocalEngineStatus(
        available: false,
        engine: 'llama.cpp',
        memoryBytes: 0,
        detail: 'Local inference is currently packaged for Android.',
      );
    }
    try {
      final result = await _memoryStatus();
      return LocalEngineStatus(
        available: true,
        engine: 'llama.cpp',
        memoryBytes: result['availableBytes'] as int? ?? 0,
        detail: 'llama.cpp b10333 native worker',
      );
    } on PlatformException catch (error) {
      return LocalEngineStatus(
        available: true,
        engine: 'llama.cpp',
        memoryBytes: 0,
        detail: error.message,
      );
    }
  }

  Future<CompletionResult> complete({
    required ModelDefinition model,
    required Map<String, String> artifactPaths,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required int contextWindow,
    required double temperature,
    required double topP,
    required int maxTokens,
    LocalInferenceTuning? tuning,
    void Function(String text)? onText,
    void Function(Map<String, dynamic> event)? onProgress,
  }) async {
    // A model can finish generating while its file mappings are still being
    // released off the UI. Wait before creating the next native owner.
    final unloading = _unloading;
    if (unloading != null) await unloading;
    if (busy) throw StateError('local-inference-busy');
    final done = Completer<void>();
    _requestDone = done;
    lastPerformance = null;
    _cancellationRequested = false;
    _interruptionReason = null;
    var checkingPressure = false;
    var criticalPressure = false;
    final health = InferenceHealthPolicy();
    var peakRssBytes = 0;
    var rssSamples = 0;
    final requestStarted = DateTime.now();
    final memoryBudgetBytes = model.memoryBudgetBytes;
    final watchdog = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (checkingPressure) return;
      checkingPressure = true;
      try {
        final memory = await _memoryStatus();
        final available = memory['availableBytes'] as int? ?? 0;
        final threshold = memory['lowMemoryThresholdBytes'] as int? ?? 0;
        final stats = await _platformChannel.invokeMapMethod<String, dynamic>(
          'processStats',
        );
        final rssBytes = stats?['rssBytes'] as int? ?? 0;
        if (rssBytes > 0) rssSamples++;
        if (rssBytes > peakRssBytes) peakRssBytes = rssBytes;
        final thermal = stats?['thermalStatus'] as int? ?? 0;
        // SEVERE (3) means throttling, not shutdown. Cancelling on it made
        // long conversations silently disappear as if the user pressed Stop.
        final reason = health.observe(
          availableBytes: available,
          lowMemoryThresholdBytes: threshold,
          thermalStatus: thermal,
          rssBytes: rssBytes,
          // File-backed LES has no fixed resident quota. Retain the measured
          // 5GB research target in metadata, but use actual Android pressure
          // and critical thermal state for cancellation, not an arbitrary cap.
          memoryBudgetBytes:
              MiniCpmLesBackend.bundled &&
                  model.runtimeProfile == 'minicpm-v47-35b-les'
              ? null
              : memoryBudgetBytes,
        );
        if (identical(_requestDone, done) && reason != null) {
          criticalPressure = true;
          _interruptionReason = reason;
          await cancel();
        }
      } on Object {
        /* best-effort counters must not break inference */
      } finally {
        checkingPressure = false;
      }
    });
    try {
      return await _completeInternal(
        model: model,
        artifactPaths: artifactPaths,
        messages: messages,
        systemPrompt: systemPrompt,
        contextWindow: contextWindow,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
        onText: onText,
        tuning: tuning,
        onProgress: onProgress,
      );
    } on Object catch (error) {
      lastPerformance = {
        ...?lastPerformance,
        'modelId': model.id,
        'requestedContext': contextWindow,
        'effectiveContext': _loadedContextSize,
        'runtimeProfile': model.runtimeProfile,
        'memoryBudgetBytes': memoryBudgetBytes,
        'status': error is LocalInferenceCancelledException
            ? 'cancelled'
            : 'failed',
        'failureStage': error is LocalInferenceException
            ? error.stage.name
            : 'request',
        'terminationReason':
            _interruptionReason ??
            (error is LocalInferenceException
                ? error.cause.toString()
                : error.runtimeType.toString()),
      };
      rethrow;
    } finally {
      watchdog.cancel();
      lastPerformance = {
        ...?lastPerformance,
        'requestStartedAt': requestStarted.toUtc().toIso8601String(),
        'sampledPeakRssBytes': peakRssBytes,
        'rssSamples': rssSamples,
      };
      try {
        if (criticalPressure || _interruptionReason != null) {
          await _releaseEngine();
        }
      } finally {
        _requestDone = null;
        done.complete();
      }
    }
  }

  Future<CompletionResult> _completeInternal({
    required ModelDefinition model,
    required Map<String, String> artifactPaths,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required int contextWindow,
    required double temperature,
    required double topP,
    required int maxTokens,
    LocalInferenceTuning? tuning,
    void Function(String text)? onText,
    void Function(Map<String, dynamic> event)? onProgress,
  }) async {
    if (!model.runnable) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'model-runtime-not-bundled',
      );
    }
    if (_disposed) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'inference service disposed',
      );
    }
    if (model.runtimeProfile == 'minicpm-v47-35b-les' &&
        MiniCpmLesBackend.bundled) {
      return _completeLes(
        model: model,
        artifactPaths: artifactPaths,
        messages: messages,
        systemPrompt: systemPrompt,
        contextWindow: contextWindow,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
        onText: onText,
        tuning: tuning,
        onProgress: onProgress,
      );
    }
    // Only one backend can own the phone's model working set at a time.
    if (_les != null) {
      await _les!.close();
      _les = null;
    }
    final primaryId = model.primaryArtifact?.id ?? 'model';
    final modelPath = artifactPaths[primaryId];
    if (modelPath == null) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'primary model artifact missing',
      );
    }
    final hasImageInput = messages.any(
      (message) => message.attachments.any(
        (attachment) => attachment.mimeType.startsWith('image/'),
      ),
    );
    // A visual encoder consumes hundreds of MB even for a text-only turn.
    // Load it only when an image is present; the next text turn unloads it.
    final projectorPath = model.projectorArtifact == null || !hasImageInput
        ? null
        : artifactPaths[model.projectorArtifact!.id];
    final file = File(modelPath);
    if (!await file.exists()) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'model file missing',
      );
    }

    final loadedContext = _loadedContextSize;
    final modelAlreadyLoaded =
        _loadedModelPath == modelPath &&
        loadedContext != null &&
        _engine?.isReady == true;
    final canReuseLoadedAllocation =
        modelAlreadyLoaded &&
        (projectorPath == null || _loadedProjectorPath == projectorPath);
    final isProjectorUpgrade =
        modelAlreadyLoaded &&
        projectorPath != null &&
        _loadedProjectorPath != projectorPath;
    // ActivityManager reports the model's current resident pages as used
    // memory. Re-running admission unchanged would therefore count the same
    // model twice and reject every warm request. Exact reuse needs no new
    // model allocation; adding a projector restores the resident model bytes
    // to the planner before estimating the incremental working set.
    final modelBytes = await file.length();
    final mobileOutputLimit = projectorPath != null
        ? 256
        : modelBytes >= 2 * 1024 * 1024 * 1024
        ? 512
        : 1024;
    final requestedOutput = maxTokens.clamp(1, mobileOutputLimit).toInt();
    final requestedContext = projectorPath == null
        ? contextWindow
        : contextWindow.clamp(2048, 4096).toInt();
    final plan = canReuseLoadedAllocation
        ? InferenceResourcePlan(
            allowed: true,
            contextWindow: loadedContext,
            maxOutputTokens: requestedOutput
                .clamp(1, loadedContext ~/ 2)
                .toInt(),
            threadCount: 1,
            estimatedPeakBytes: modelBytes,
            audioDurationSeconds: 0,
            backendHint: 'auto',
            cacheType: 'q8_0',
            flashAttention: true,
            memoryBudgetBytes: model.memoryBudgetBytes,
            runtimeProfile: model.runtimeProfile,
          )
        : isProjectorUpgrade
        ? await _projectorUpgradePlan(
            model: model,
            modelFile: file,
            projectorPath: projectorPath,
            loadedContext: loadedContext,
            requestedOutput: requestedOutput,
          )
        : await _resourcePlan(
            model: model,
            modelFile: file,
            requestedContext: requestedContext,
            requestedOutput: requestedOutput,
            withProjector: projectorPath != null,
          );
    if (!plan.allowed) {
      throw LocalInferenceException(
        LocalInferenceStage.modelLoad,
        plan.reasonCode ?? 'insufficient-memory',
      );
    }
    final requestClock = Stopwatch()..start();
    await _ensureModel(
      modelPath,
      projectorPath,
      plan.contextWindow,
      tuning?.threads ?? plan.threadCount,
      batchSize: tuning?.batchSize ?? plan.batchSize,
      microBatchSize: tuning?.microBatchSize ?? plan.microBatchSize,
      cacheType: tuning?.cacheType ?? plan.cacheType,
      flashAttention: tuning?.flashAttention ?? plan.flashAttention,
      gpuLayers: tuning?.gpuLayers ?? plan.gpuLayers,
      backend:
          tuning?.backend ??
          (plan.backendHint == 'cpu' ? GpuBackend.cpu : GpuBackend.auto),
    );
    final loadWallMs = requestClock.elapsedMilliseconds;
    if (_cancellationRequested) {
      throw const LocalInferenceCancelledException();
    }
    final engine = _engine;
    if (engine == null || !engine.isReady) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'engine not ready after model load',
      );
    }

    final conversationMessages = await Future.wait([
      for (var index = 0; index < messages.length; index++)
        _toLlamaMessage(
          messages[index],
          model,
          allowImageInput:
              projectorPath != null && index == messages.length - 1,
        ),
    ]);
    final llamaMessages = <LlamaChatMessage>[
      if (systemPrompt.trim().isNotEmpty)
        LlamaChatMessage.fromText(
          role: LlamaChatRole.system,
          text: systemPrompt.trim(),
        ),
      ...conversationMessages,
    ];

    late final ({List<LlamaChatMessage> messages, int inputTokens}) fitted;
    try {
      fitted = await _fitMessages(
        engine,
        llamaMessages,
        contextSize: await engine.getContextSize(),
        requestedOutput: plan.maxOutputTokens,
      );
    } on Object catch (error) {
      if (_cancellationRequested) {
        throw const LocalInferenceCancelledException();
      }
      throw LocalInferenceException(LocalInferenceStage.prompt, error);
    }

    if (_cancellationRequested) {
      throw const LocalInferenceCancelledException();
    }

    final actualContext = await engine.getContextSize();
    final availableOutput = (actualContext - fitted.inputTokens - 32).clamp(
      1,
      plan.maxOutputTokens,
    );
    final buffer = StringBuffer();
    final generationClock = Stopwatch()..start();
    final deltaTimings = GenerationDeltaTimings();
    try {
      await for (final chunk
          in engine
              .create(
                fitted.messages,
                enableThinking: false,
                params: GenerationParams(
                  maxTokens: availableOutput,
                  temp: temperature,
                  topP: topP,
                  topK: 40,
                  penalty: 1.1,
                  // MiniCPM5 explicitly recommends min_p=0 to avoid repetition loops.
                  minP: 0,
                ),
              )
              .timeout(
                const Duration(minutes: 5),
                onTimeout: (sink) {
                  // Native cancellation is cooperative. Never dispose live tensors
                  // while a native decode call may still be using them.
                  _interruptionReason = 'generation-idle-timeout';
                  engine.cancelGeneration();
                  sink.addError(
                    const LocalInferenceException(
                      LocalInferenceStage.generation,
                      'generation-idle-timeout',
                    ),
                  );
                  sink.close();
                },
              )) {
        final first = chunk.choices.firstOrNull?.delta;
        deltaTimings.observe(
          elapsedMs: generationClock.elapsedMilliseconds,
          content: first?.content,
          reasoning: first?.thinking,
        );
        final delta = first?.content;
        if (delta == null || delta.isEmpty) continue;
        buffer.write(delta);
        onText?.call(buffer.toString());
      }
    } on Object catch (error) {
      if (_cancellationRequested) {
        if (_interruptionReason != null) {
          throw LocalInferenceException(
            LocalInferenceStage.generation,
            _interruptionReason!,
          );
        }
        throw const LocalInferenceCancelledException();
      }
      throw LocalInferenceException(LocalInferenceStage.generation, error);
    }

    if (_cancellationRequested) {
      if (_interruptionReason != null) {
        throw LocalInferenceException(
          LocalInferenceStage.generation,
          _interruptionReason!,
        );
      }
      throw const LocalInferenceCancelledException();
    }

    final perf = await engine.getPerformanceContext();
    lastPerformance = {
      'runtime': 'llama.cpp-b10333/llamadart-0.8.19',
      'status': 'completed',
      'modelId': model.id,
      'requestedContext': contextWindow,
      'effectiveContext': actualContext,
      'contextWasReduced': actualContext < contextWindow,
      'effectiveBackend': await engine.getBackendName(),
      'effectiveGpuLayers': await engine.getResolvedGpuLayers(),
      // A multimodal catalog entry is not proof of a loaded visual encoder.
      // Keep text decode and image/projector measurements distinguishable.
      'requestedMode': hasImageInput ? 'vision' : 'text_only',
      'visionProjectorLoaded': _loadedProjectorPath != null,
      'inputTokensAfterFitting': fitted.inputTokens,
      'historyMessagesBeforeFitting': llamaMessages.length,
      'historyMessagesAfterFitting': fitted.messages.length,
      'threads': _effectiveAttempt?.threadCount,
      'batch': _effectiveAttempt?.batchSize,
      'microBatch': _effectiveAttempt?.microBatchSize,
      'cacheType': _effectiveAttempt?.cacheType,
      'flashAttention': _effectiveAttempt?.flashAttention,
      'coldLoad': !canReuseLoadedAllocation,
      'context': actualContext,
      'loadWallMs': loadWallMs,
      ...deltaTimings.toJson(),
      'generationWallMs': generationClock.elapsedMilliseconds,
      'promptEvalTokens': perf?.promptEvalTokens,
      'promptEvalMs': perf?.promptEvalMs,
      'evalTokens': perf?.evalTokens,
      'evalMs': perf?.evalMs,
      'decodeMs': perf?.decodeMs,
      'decodeTokensPerSecond': perf != null && perf.evalMs > 0
          ? perf.evalTokens * 1000 / perf.evalMs
          : null,
      'pressure': plan.pressureLevel,
      'swapAssisted': plan.swapAssisted,
      'fileBackedRepack': _fileBackedRepack,
      'memoryBudgetBytes': plan.memoryBudgetBytes,
      'runtimeProfile': plan.runtimeProfile,
    };

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw const LocalInferenceException(
        LocalInferenceStage.emptyOutput,
        'model returned no final content',
      );
    }
    final outputTokens = await engine.getTokenCount(text);
    return CompletionResult(
      text,
      TokenUsage(input: fitted.inputTokens, output: outputTokens),
    );
  }

  Future<CompletionResult> _completeLes({
    required ModelDefinition model,
    required Map<String, String> artifactPaths,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required int contextWindow,
    required double temperature,
    required double topP,
    required int maxTokens,
    LocalInferenceTuning? tuning,
    void Function(String text)? onText,
    void Function(Map<String, dynamic> event)? onProgress,
  }) async {
    // The text runtime deliberately does not load a visual encoder. Reject
    // image/audio inputs rather than quietly presenting text-only inference
    // as multimodal support; other model backends retain their vision path.
    if (messages.any(
      (message) => message.attachments.any(
        (attachment) =>
            attachment.mimeType.startsWith('image/') ||
            attachment.mimeType.startsWith('audio/'),
      ),
    )) {
      throw const LocalInferenceException(
        LocalInferenceStage.prompt,
        'les-vision-runtime-not-bundled',
      );
    }
    final path = artifactPaths[model.primaryArtifact?.id ?? 'model'];
    if (path == null || !await File(path).exists()) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'primary model artifact missing',
      );
    }
    if (_engine != null) await _releaseEngine();
    if (_cancellationRequested) throw const LocalInferenceCancelledException();
    final backend = _les ??= MiniCpmLesBackend();
    final cache = await MiniCpmLesBackend.cacheDirectory(model.id);
    final context = contextWindow.clamp(2048, 131072).toInt();
    final requestedOutput = maxTokens.clamp(1, context ~/ 2).toInt();
    final preparedMessages = <Map<String, String>>[
      if (systemPrompt.trim().isNotEmpty)
        {'role': 'system', 'content': systemPrompt.trim()},
      for (final message in messages)
        {
          'role': message.role.name,
          'content': [
            message.content,
            for (final attachment in message.attachments)
              if (attachment.extractedText?.isNotEmpty == true)
                '\n[${attachment.name}]\n${attachment.extractedText}',
          ].join('\n'),
        },
    ];
    final clock = Stopwatch()..start();
    final timings = GenerationDeltaTimings();
    try {
      final result = await backend.generate(
        onProgress: onProgress,
        request: {
          'modelPath': path,
          'cacheDirectory': cache.path,
          'context': context,
          'maxTokens': requestedOutput,
          'temperature': temperature,
          'topP': topP,
          'threads': (tuning?.threads ?? 4).clamp(1, 8),
          'expertWindow': (tuning?.expertWindow ?? 56).clamp(16, 128),
          'prefetchDepth': (tuning?.prefetchDepth ?? 4).clamp(0, 4),
          'microBatchSize': (tuning?.microBatchSize ?? 8).clamp(1, 16),
          'decodeThreadSweep': tuning?.decodeThreadSweep ?? false,
          'messages': preparedMessages,
        },
        onText: (text) {
          timings.observe(elapsedMs: clock.elapsedMilliseconds, content: text);
          onText?.call(text);
        },
      );
      if (_cancellationRequested) {
        throw const LocalInferenceCancelledException();
      }
      _loadedContextSize = context;
      lastPerformance = {
        ...Map<String, Object?>.from(result['performance'] as Map),
        'status': 'completed',
        'modelId': model.id,
        'requestedContext': contextWindow,
        'contextWasReduced': context != contextWindow,
        'requestedMaxOutput': maxTokens,
        'effectiveMaxOutput': requestedOutput,
        'maxOutputWasReduced': requestedOutput != maxTokens,
        'runtimeProfile': model.runtimeProfile,
        'memoryBudgetBytes': model.memoryBudgetBytes,
        'generationWallMs': clock.elapsedMilliseconds,
        ...timings.toJson(),
      };
      return CompletionResult(
        result['text'] as String,
        TokenUsage(
          input: result['inputTokens'] as int,
          output: result['outputTokens'] as int,
        ),
      );
    } on LesCancelledException {
      throw const LocalInferenceCancelledException();
    } on LocalInferenceCancelledException {
      rethrow;
    } on Object catch (error) {
      throw LocalInferenceException(LocalInferenceStage.generation, error);
    }
  }

  Future<LlamaChatMessage> _toLlamaMessage(
    ChatMessage message,
    ModelDefinition model, {
    required bool allowImageInput,
  }) async {
    final role = switch (message.role) {
      MessageRole.user => LlamaChatRole.user,
      MessageRole.assistant => LlamaChatRole.assistant,
      MessageRole.system => LlamaChatRole.system,
      MessageRole.tool => LlamaChatRole.tool,
    };
    if (message.attachments.isEmpty) {
      return LlamaChatMessage.fromText(role: role, text: message.content);
    }
    final text = StringBuffer(message.content);
    final parts = <LlamaContentPart>[];
    for (final attachment in message.attachments) {
      if (attachment.mimeType.startsWith('image/') &&
          model.capabilities.contains(ModelCapability.imageInput) &&
          allowImageInput) {
        final normalizedPath =
            await FileContentService.normalizeImageForInference(
              attachment.path,
            );
        parts.add(LlamaImageContent(path: normalizedPath));
      } else if (attachment.mimeType.startsWith('audio/') &&
          model.capabilities.contains(ModelCapability.audioInput)) {
        parts.add(LlamaAudioContent(path: attachment.path));
      } else {
        text
          ..writeln()
          ..writeln(attachment.name)
          ..write(attachment.extractedText ?? '');
      }
    }
    parts.insert(0, LlamaTextContent(text.toString()));
    return LlamaChatMessage.withContent(role: role, content: parts);
  }

  Future<({List<LlamaChatMessage> messages, int inputTokens})> _fitMessages(
    LlamaEngine engine,
    List<LlamaChatMessage> source, {
    required int contextSize,
    required int requestedOutput,
  }) async {
    final messages = [...source];
    final outputReserve = requestedOutput.clamp(128, 512);
    while (true) {
      final rendered = await engine.chatTemplate(
        messages,
        enableThinking: false,
        includeTokenCount: true,
      );
      final count =
          rendered.tokenCount ?? await engine.getTokenCount(rendered.prompt);
      if (count + outputReserve < contextSize || messages.length <= 2) {
        return (messages: messages, inputTokens: count);
      }
      final firstConversationIndex = messages.first.role == LlamaChatRole.system
          ? 1
          : 0;
      if (firstConversationIndex >= messages.length - 1) {
        return (messages: messages, inputTokens: count);
      }
      messages.removeAt(firstConversationIndex);
      if (firstConversationIndex < messages.length - 1 &&
          messages[firstConversationIndex].role == LlamaChatRole.assistant) {
        messages.removeAt(firstConversationIndex);
      }
    }
  }

  Future<void> _ensureModel(
    String modelPath,
    String? projectorPath,
    int contextSize,
    int threadCount, {
    required int batchSize,
    required int microBatchSize,
    required String cacheType,
    required bool flashAttention,
    required int gpuLayers,
    required GpuBackend backend,
  }) async {
    while (_loading != null) {
      await _loading;
    }
    if (_loadedModelPath == modelPath &&
        _loadedContextSize == contextSize &&
        _engine?.isReady == true) {
      if (_loadedProjectorPath != projectorPath) {
        if (projectorPath == null) {
          await _engine!.unloadMultimodalProjector();
        } else {
          await _engine!.loadMultimodalProjector(projectorPath);
        }
        _loadedProjectorPath = projectorPath;
      }
      return;
    }
    final loading = _loadModel(
      modelPath,
      projectorPath,
      contextSize,
      threadCount,
      batchSize: batchSize,
      microBatchSize: microBatchSize,
      cacheType: cacheType,
      flashAttention: flashAttention,
      gpuLayers: gpuLayers,
      backend: backend,
    );
    _loading = loading;
    try {
      await loading;
    } finally {
      if (identical(_loading, loading)) _loading = null;
    }
  }

  Future<void> _loadModel(
    String modelPath,
    String? projectorPath,
    int contextSize,
    int threadCount, {
    required int batchSize,
    required int microBatchSize,
    required String cacheType,
    required bool flashAttention,
    required int gpuLayers,
    required GpuBackend backend,
  }) async {
    await _releaseEngine();
    final bytes = await File(modelPath).length();
    _fileBackedRepack =
        await _platformChannel.invokeMethod<bool>('configureInferenceScratch', {
          'modelBytes': bytes,
          'enabled': modelPath.toLowerCase().contains('gpt-oss'),
        }) ??
        false;
    final contexts = <int>{
      contextSize,
      4096,
      2048,
    }.where((value) => value <= contextSize).toList();
    final attempts = <_LoadAttempt>[
      _LoadAttempt(
        contextSize: contexts.first,
        backend: backend,
        gpuLayers: gpuLayers,
        threadCount: threadCount,
        batchSize: batchSize,
        microBatchSize: microBatchSize,
        cacheType: cacheType,
        flashAttention: flashAttention,
        liteRtLmBackend: await _preferredLiteRtLmBackend(modelPath),
      ),
      for (final size in contexts)
        _LoadAttempt(
          contextSize: size,
          backend: GpuBackend.cpu,
          gpuLayers: 0,
          threadCount: threadCount,
          batchSize: batchSize.clamp(64, 256),
          microBatchSize: microBatchSize.clamp(32, 128),
          cacheType: cacheType,
          flashAttention: flashAttention,
          liteRtLmBackend: LiteRtLmBackendPreference.auto,
        ),
    ];
    final errors = <String>[];
    for (final attempt in attempts) {
      final engine = LlamaEngine(LlamaBackend());
      try {
        await engine.setLogLevel(LlamaLogLevel.error);
        await engine.loadModel(
          modelPath,
          modelParams: ModelParams(
            contextSize: attempt.contextSize,
            gpuLayers: attempt.gpuLayers,
            preferredBackend: attempt.backend,
            numberOfThreads: attempt.threadCount,
            numberOfThreadsBatch: attempt.threadCount,
            batchSize: attempt.batchSize,
            microBatchSize: attempt.microBatchSize,
            useMmap: true,
            useExtraBufferTypes:
                _fileBackedRepack || bytes < 2 * 1024 * 1024 * 1024,
            flashAttention: attempt.flashAttention
                ? FlashAttention.enabled
                : FlashAttention.disabled,
            cacheTypeK: switch (attempt.cacheType) {
              'q4_0' => KvCacheType.q4_0,
              'f16' => KvCacheType.f16,
              _ => KvCacheType.q8_0,
            },
            cacheTypeV: switch (attempt.cacheType) {
              'q4_0' => KvCacheType.q4_0,
              'f16' => KvCacheType.f16,
              _ => KvCacheType.q8_0,
            },
            liteRtLmBackend: attempt.liteRtLmBackend,
          ),
        );
        if (projectorPath != null) {
          await engine.loadMultimodalProjector(projectorPath);
        }
        if (_disposed) {
          await engine.dispose();
          throw StateError('inference service disposed during model load');
        }
        _engine = engine;
        _loadedModelPath = modelPath;
        _loadedProjectorPath = projectorPath;
        _loadedContextSize = attempt.contextSize;
        _effectiveAttempt = attempt;
        return;
      } on Object catch (error) {
        errors.add('${attempt.backend.name}/${attempt.contextSize}: $error');
        await engine.dispose();
      }
    }
    throw LocalInferenceException(
      LocalInferenceStage.modelLoad,
      errors.join(' | '),
    );
  }

  Future<LiteRtLmBackendPreference> _preferredLiteRtLmBackend(
    String modelPath,
  ) async {
    if (!modelPath.toLowerCase().endsWith('.litertlm')) {
      return LiteRtLmBackendPreference.auto;
    }
    final runtime = await _runtimeInfo();
    final eligible = runtime['npuOptimizationEligible'] as bool? ?? false;
    return eligible
        ? LiteRtLmBackendPreference.npu
        : LiteRtLmBackendPreference.auto;
  }

  Future<InferenceResourcePlan> _resourcePlan({
    required ModelDefinition model,
    required File modelFile,
    required int requestedContext,
    required int requestedOutput,
    required bool withProjector,
  }) async {
    final memoryMap = await _memoryStatus();
    final runtimeMap = await _runtimeInfo();
    final totalBytes = memoryMap['totalBytes'] as int? ?? 0;
    return ResourcePlanner.planInference(
      model: model,
      modelBytes: await modelFile.length(),
      memory: DeviceMemoryInfo(
        availableBytes: memoryMap['availableBytes'] as int? ?? 0,
        totalBytes: totalBytes,
        lowMemoryThresholdBytes:
            memoryMap['lowMemoryThresholdBytes'] as int? ?? 0,
      ),
      runtime: DeviceRuntimeInfo(
        sdkInt: runtimeMap['sdkInt'] as int? ?? 0,
        processorCount: runtimeMap['processorCount'] as int? ?? 1,
        isLowRamDevice: runtimeMap['isLowRamDevice'] as bool? ?? false,
        supportedAbis: (runtimeMap['supportedAbis'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
        zramTotalBytes: runtimeMap['zramTotalBytes'] as int? ?? 0,
        zramUsedBytes: runtimeMap['zramUsedBytes'] as int? ?? 0,
        swapTotalBytes: runtimeMap['swapTotalBytes'] as int? ?? 0,
        swapFreeBytes: runtimeMap['swapFreeBytes'] as int? ?? 0,
      ),
      requestedContext: requestedContext,
      requestedOutput: requestedOutput,
      withMultimodalProjector: withProjector,
    );
  }

  Future<InferenceResourcePlan> _projectorUpgradePlan({
    required ModelDefinition model,
    required File modelFile,
    required String projectorPath,
    required int loadedContext,
    required int requestedOutput,
  }) async {
    const mib = 1024 * 1024;
    const gib = 1024 * mib;
    final memoryMap = await _memoryStatus();
    final projectorBytes = await File(projectorPath).length();
    final modelBytes = await modelFile.length();
    final available = memoryMap['availableBytes'] as int? ?? 0;
    final total = memoryMap['totalBytes'] as int? ?? 0;
    final incrementalBytes = projectorBytes + 256 * mib;
    final kvBytesPerToken = switch (modelBytes) {
      >= 4 * gib => 96 * 1024,
      >= 2 * gib => 72 * 1024,
      >= 1 * gib => 48 * 1024,
      _ => 32 * 1024,
    };
    final estimatedPeak =
        modelBytes +
        projectorBytes +
        768 * mib +
        loadedContext * kvBytesPerToken;
    final withinIncrementalHeadroom = available >= incrementalBytes + 512 * mib;
    // No fixed physical-RAM percentage: the platform's available memory and
    // current swap headroom are the admission signals for an upgrade.
    final swap = (await _runtimeInfo())['swapFreeBytes'] as int? ?? 0;
    final dynamicBudget = available + (swap * .25).round();
    final allowed =
        withinIncrementalHeadroom &&
        (total <= 0 || estimatedPeak <= dynamicBudget + modelBytes);
    return InferenceResourcePlan(
      allowed: allowed,
      contextWindow: loadedContext.clamp(2048, 4096).toInt(),
      maxOutputTokens: requestedOutput.clamp(64, loadedContext ~/ 2).toInt(),
      threadCount: 1,
      estimatedPeakBytes: estimatedPeak,
      audioDurationSeconds: 0,
      reasonCode: allowed ? null : 'insufficient-memory',
    );
  }

  Future<Map<String, dynamic>> _memoryStatus() async =>
      await _platformChannel.invokeMapMethod<String, dynamic>('memoryStatus') ??
      const <String, dynamic>{};

  Future<Map<String, dynamic>> _runtimeInfo() async =>
      await _platformChannel.invokeMapMethod<String, dynamic>('runtimeInfo') ??
      const <String, dynamic>{};

  Future<void> cancel() async {
    _cancellationRequested = true;
    _engine?.cancelGeneration();
    _les?.cancel();
  }

  /// Stops generation and releases the native model allocation. This is
  /// intentionally explicit so users can reclaim memory after a long task.
  Future<void> unloadModel() {
    final current = _unloading;
    if (current != null) return current;
    late final Future<void> pending;
    pending = _unloadOnce().whenComplete(() {
      if (identical(_unloading, pending)) _unloading = null;
    });
    _unloading = pending;
    return pending;
  }

  Future<void> _unloadOnce() async {
    _cancellationRequested = true;
    _engine?.cancelGeneration();
    _les?.cancel();
    await _requestDone?.future;
    while (_loading != null) {
      await _loading;
    }
    await _releaseEngine();
  }

  Future<void> restart() async {
    await unloadModel();
    _cancellationRequested = false;
  }

  Future<void> _releaseEngine() async {
    final engine = _engine;
    _engine = null;
    _loadedModelPath = null;
    _loadedProjectorPath = null;
    _loadedContextSize = null;
    _effectiveAttempt = null;
    if (engine != null) await engine.dispose();
    final les = _les;
    _les = null;
    if (les != null) await les.close();
  }

  void dispose() {
    _disposed = true;
    _engine?.cancelGeneration();
    unawaited(unloadModel());
  }
}
