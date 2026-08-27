import 'dart:math' as math;

import '../models/app_models.dart';
import 'platform_service.dart';

class DownloadResourcePlan {
  const DownloadResourcePlan({
    required this.allowed,
    required this.requiredBytes,
    required this.availableBytes,
    this.reasonCode,
  });

  final bool allowed;
  final int requiredBytes;
  final int availableBytes;
  final String? reasonCode;
}

class InferenceResourcePlan {
  const InferenceResourcePlan({
    required this.allowed,
    required this.contextWindow,
    required this.maxOutputTokens,
    required this.threadCount,
    required this.estimatedPeakBytes,
    required this.audioDurationSeconds,
    this.reasonCode,
  });

  final bool allowed;
  final int contextWindow;
  final int maxOutputTokens;
  final int threadCount;
  final int estimatedPeakBytes;
  final int audioDurationSeconds;
  final String? reasonCode;
}

/// Separates storage admission from inference admission. Downloading a model
/// never implies that the current device can safely load it.
abstract final class ResourcePlanner {
  static const _mib = 1024 * 1024;
  static const _gib = 1024 * _mib;

  static DownloadResourcePlan planDownload({
    required int remainingBytes,
    required StorageInfo storage,
  }) {
    // Keep enough room for SQLite journals, a partial rename, and Android's
    // package/cache maintenance. The reserve scales on larger volumes.
    final reserve = math.max(512 * _mib, (storage.totalBytes * .03).round());
    final required = math.max(0, remainingBytes) + reserve;
    return DownloadResourcePlan(
      allowed: storage.availableBytes >= required,
      requiredBytes: required,
      availableBytes: storage.availableBytes,
      reasonCode: storage.availableBytes >= required
          ? null
          : 'insufficient-storage',
    );
  }

  static InferenceResourcePlan planInference({
    required ModelDefinition model,
    required int modelBytes,
    required DeviceMemoryInfo memory,
    required DeviceRuntimeInfo runtime,
    required int requestedContext,
    required int requestedOutput,
    bool withMultimodalProjector = false,
  }) {
    // ActivityManager.availMem already includes reclaimable cache; its
    // `threshold` is a low-memory signal, not memory that every app must
    // reserve again. Keep an explicit process-safety reserve and independently
    // cap the inference working set to 85% of physical RAM.
    final systemReserve = runtime.isLowRamDevice ? 1024 * _mib : 512 * _mib;
    final availableBudget = math.max(0, memory.availableBytes - systemReserve);
    final totalBudget = memory.totalBytes > 0
        ? (memory.totalBytes * .85).round()
        : availableBudget;
    final usable = math.min(availableBudget, totalBudget);
    final projectorWorkingSet = withMultimodalProjector
        ? (model.projectorArtifact?.sizeBytes ?? 384 * _mib) + 256 * _mib
        : 0;
    final baseWorkingSet = modelBytes + projectorWorkingSet + 512 * _mib;
    final headroom = usable - baseWorkingSet;
    final kvBytesPerToken = switch (modelBytes) {
      >= 4 * _gib => 96 * 1024,
      >= 2 * _gib => 72 * 1024,
      >= 1 * _gib => 48 * 1024,
      _ => 32 * 1024,
    };
    final contextByMemory = math.max(0, headroom ~/ kvBytesPerToken);
    const contextOptions = <int>[
      2048,
      4096,
      8192,
      16384,
      32768,
      65536,
      131072,
      262144,
    ];
    final contextCap = contextOptions.lastWhere(
      (value) => value <= contextByMemory,
      orElse: () => 2048,
    );
    final context = requestedContext.clamp(2048, contextCap).toInt();
    final output = requestedOutput
        .clamp(64, math.max(64, context ~/ 2))
        .toInt();
    final kvEstimate = context * kvBytesPerToken;
    final peak = baseWorkingSet + kvEstimate;
    final allowed =
        usable > 0 && contextByMemory >= contextOptions.first && peak <= usable;
    final audioBytesPerSecond = 16000 * 2 * 10;
    final audioSeconds = math
        .max(0, headroom ~/ audioBytesPerSecond)
        .clamp(0, 4 * 60 * 60)
        .toInt();
    return InferenceResourcePlan(
      allowed: allowed,
      contextWindow: context,
      maxOutputTokens: output,
      threadCount: runtime.processorCount
          .clamp(1, runtime.isLowRamDevice ? 4 : 6)
          .toInt(),
      estimatedPeakBytes: peak,
      audioDurationSeconds: audioSeconds,
      reasonCode: allowed ? null : 'insufficient-memory',
    );
  }
}
