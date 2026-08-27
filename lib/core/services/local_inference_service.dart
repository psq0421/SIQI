import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

import '../models/app_models.dart';
import 'file_content_service.dart';
import 'platform_service.dart';
import 'resource_planner.dart';

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

class _LoadAttempt {
  const _LoadAttempt({
    required this.contextSize,
    required this.backend,
    required this.gpuLayers,
    required this.threadCount,
  });

  final int contextSize;
  final GpuBackend backend;
  final int gpuLayers;
  final int threadCount;
}

/// Owns one current llama.cpp engine. The native runtime contains explicit
/// Qwen3.5, Gemma 4, and Hunyuan support and performs generation off the UI
/// isolate.
class LocalInferenceService {
  static const _platformChannel = MethodChannel('com.psq.siqi/platform');
  LlamaEngine? _engine;
  String? _loadedModelPath;
  String? _loadedProjectorPath;
  int? _loadedContextSize;
  Future<void>? _loading;
  bool _disposed = false;
  bool _cancellationRequested = false;

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
    void Function(String text)? onText,
  }) async {
    _cancellationRequested = false;
    if (_disposed) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'inference service disposed',
      );
    }
    final primaryId = model.primaryArtifact?.id ?? 'model';
    final modelPath = artifactPaths[primaryId];
    if (modelPath == null) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'primary model artifact missing',
      );
    }
    final projectorPath = model.projectorArtifact == null
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
    final requestedOutput = maxTokens.clamp(64, mobileOutputLimit).toInt();
    final requestedContext = projectorPath == null
        ? contextWindow
        : contextWindow.clamp(2048, 4096).toInt();
    final plan = canReuseLoadedAllocation
        ? InferenceResourcePlan(
            allowed: true,
            contextWindow: loadedContext,
            maxOutputTokens: requestedOutput
                .clamp(64, loadedContext ~/ 2)
                .toInt(),
            threadCount: 1,
            estimatedPeakBytes: modelBytes,
            audioDurationSeconds: 0,
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
    await _ensureModel(
      modelPath,
      projectorPath,
      plan.contextWindow,
      plan.threadCount,
    );
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
    try {
      await for (final chunk in engine.create(
        fitted.messages,
        enableThinking: false,
        params: GenerationParams(
          maxTokens: availableOutput,
          temp: temperature,
          topP: topP,
          topK: 40,
          penalty: 1.1,
        ),
      )) {
        final delta = chunk.choices.firstOrNull?.delta.content;
        if (delta == null || delta.isEmpty) continue;
        buffer.write(delta);
        onText?.call(buffer.toString());
      }
    } on Object catch (error) {
      if (_cancellationRequested) {
        throw const LocalInferenceCancelledException();
      }
      throw LocalInferenceException(LocalInferenceStage.generation, error);
    }

    if (_cancellationRequested) {
      throw const LocalInferenceCancelledException();
    }

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
    int threadCount,
  ) async {
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
    int threadCount,
  ) async {
    await _releaseEngine();
    final contexts = <int>{
      contextSize,
      4096,
      2048,
    }.where((value) => value <= contextSize).toList();
    final attempts = <_LoadAttempt>[
      _LoadAttempt(
        contextSize: contexts.first,
        backend: GpuBackend.auto,
        gpuLayers: ModelParams.maxGpuLayers,
        threadCount: threadCount,
      ),
      for (final size in contexts)
        _LoadAttempt(
          contextSize: size,
          backend: GpuBackend.cpu,
          gpuLayers: 0,
          threadCount: threadCount,
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
            batchSize: 512,
            microBatchSize: 256,
            useMmap: true,
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
    final withinTotalCap = total <= 0 || estimatedPeak <= (total * .85).round();
    final allowed = withinIncrementalHeadroom && withinTotalCap;
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
  }

  Future<void> _releaseEngine() async {
    final engine = _engine;
    _engine = null;
    _loadedModelPath = null;
    _loadedProjectorPath = null;
    _loadedContextSize = null;
    if (engine != null) await engine.dispose();
  }

  void dispose() {
    _disposed = true;
    _engine?.cancelGeneration();
    unawaited(_releaseEngine());
  }
}
