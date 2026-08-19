import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

import '../models/app_models.dart';

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

class _LoadAttempt {
  const _LoadAttempt({
    required this.contextSize,
    required this.backend,
    required this.gpuLayers,
  });

  final int contextSize;
  final GpuBackend backend;
  final int gpuLayers;
}

/// Owns one current llama.cpp engine. The native runtime contains explicit
/// Qwen3.5, Gemma 4, and Hunyuan support and performs generation off the UI
/// isolate.
class LocalInferenceService {
  static const _platformChannel = MethodChannel('com.psq.siqi/platform');
  static const _gib = 1024 * 1024 * 1024;

  LlamaEngine? _engine;
  String? _loadedModelPath;
  int? _loadedContextSize;
  Future<void>? _loading;
  bool _disposed = false;

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
    required String modelPath,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required int contextWindow,
    required double temperature,
    required double topP,
    required int maxTokens,
    void Function(String text)? onText,
  }) async {
    if (_disposed) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'inference service disposed',
      );
    }
    final file = File(modelPath);
    if (!await file.exists()) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'model file missing',
      );
    }

    final resolvedContext = await _resolveContextSize(file, contextWindow);
    await _ensureModel(modelPath, resolvedContext);
    final engine = _engine;
    if (engine == null || !engine.isReady) {
      throw const LocalInferenceException(
        LocalInferenceStage.modelLoad,
        'engine not ready after model load',
      );
    }

    final llamaMessages = <LlamaChatMessage>[
      if (systemPrompt.trim().isNotEmpty)
        LlamaChatMessage.fromText(
          role: LlamaChatRole.system,
          text: systemPrompt.trim(),
        ),
      ...messages.map(
        (message) => LlamaChatMessage.fromText(
          role: switch (message.role) {
            MessageRole.user => LlamaChatRole.user,
            MessageRole.assistant => LlamaChatRole.assistant,
            MessageRole.system => LlamaChatRole.system,
            MessageRole.tool => LlamaChatRole.tool,
          },
          text: message.content,
        ),
      ),
    ];

    late final ({List<LlamaChatMessage> messages, int inputTokens}) fitted;
    try {
      fitted = await _fitMessages(
        engine,
        llamaMessages,
        contextSize: await engine.getContextSize(),
        requestedOutput: maxTokens,
      );
    } on Object catch (error) {
      throw LocalInferenceException(LocalInferenceStage.prompt, error);
    }

    final actualContext = await engine.getContextSize();
    final availableOutput = (actualContext - fitted.inputTokens - 32).clamp(
      1,
      maxTokens,
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
      throw LocalInferenceException(LocalInferenceStage.generation, error);
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

  Future<void> _ensureModel(String modelPath, int contextSize) async {
    while (_loading != null) {
      await _loading;
    }
    if (_loadedModelPath == modelPath &&
        _loadedContextSize == contextSize &&
        _engine?.isReady == true) {
      return;
    }
    final loading = _loadModel(modelPath, contextSize);
    _loading = loading;
    try {
      await loading;
    } finally {
      if (identical(_loading, loading)) _loading = null;
    }
  }

  Future<void> _loadModel(String modelPath, int contextSize) async {
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
      ),
      for (final size in contexts)
        _LoadAttempt(contextSize: size, backend: GpuBackend.cpu, gpuLayers: 0),
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
            useMmap: true,
          ),
        );
        if (_disposed) {
          await engine.dispose();
          throw StateError('inference service disposed during model load');
        }
        _engine = engine;
        _loadedModelPath = modelPath;
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

  Future<int> _resolveContextSize(File model, int requested) async {
    final modelBytes = await model.length();
    final memory = await _memoryStatus();
    final available = memory['availableBytes'] as int? ?? 0;
    final modelCap = switch (modelBytes) {
      < _gib => 32768,
      < 2 * _gib => 16384,
      < 4 * _gib => 8192,
      _ => 4096,
    };
    final memoryAfterWeights = available <= 0
        ? 4 * _gib
        : available - modelBytes;
    final memoryCap = switch (memoryAfterWeights) {
      >= 6 * _gib => 32768,
      >= 3 * _gib => 16384,
      >= 1536 * 1024 * 1024 => 8192,
      _ => 4096,
    };
    return requested.clamp(2048, modelCap < memoryCap ? modelCap : memoryCap);
  }

  Future<Map<String, dynamic>> _memoryStatus() async =>
      await _platformChannel.invokeMapMethod<String, dynamic>('memoryStatus') ??
      const <String, dynamic>{};

  Future<void> cancel() async => _engine?.cancelGeneration();

  Future<void> _releaseEngine() async {
    final engine = _engine;
    _engine = null;
    _loadedModelPath = null;
    _loadedContextSize = null;
    if (engine != null) await engine.dispose();
  }

  void dispose() {
    _disposed = true;
    _engine?.cancelGeneration();
    unawaited(_releaseEngine());
  }
}
