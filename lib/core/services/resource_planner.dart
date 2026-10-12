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
    this.pressureLevel = 'normal',
    this.backendHint = 'auto',
    this.gpuLayers = 999,
    this.batchSize = 256,
    this.microBatchSize = 128,
    this.cacheType = 'q8_0',
    this.flashAttention = true,
    this.swapAssisted = false,
    this.reasonCode,
  });

  final bool allowed;
  final int contextWindow;
  final int maxOutputTokens;
  final int threadCount;
  final int estimatedPeakBytes;
  final int audioDurationSeconds;

  /// A diagnostic label, not a fixed memory quota. It is derived from the
  /// current kernel pressure and can change between requests.
  final String pressureLevel;
  final String backendHint;
  final int gpuLayers;
  final int batchSize;
  final int microBatchSize;
  final String cacheType;
  final bool flashAttention;
  final bool swapAssisted;
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
    // Do not impose a percentage of physical RAM. Android's availMem already
    // accounts for reclaimable pages and the kernel's low-memory threshold is
    // a pressure signal, not a user-facing quota. A mapped GGUF can be larger
    // than RAM, so admission is based on the estimated resident working set
    // plus currently free swap/ZRAM.
    final lowThreshold = memory.lowMemoryThresholdBytes > 0
        ? memory.lowMemoryThresholdBytes
        : (runtime.isLowRamDevice ? 768 : 512) * _mib;
    final pressure = memory.availableBytes <= lowThreshold
        ? 'critical'
        : memory.availableBytes <= lowThreshold * 2
        ? 'constrained'
        : runtime.swapFreeBytes > 512 * _mib && memory.availableBytes < 2 * _gib
        ? 'swap-assisted'
        : 'normal';
    final reserve = pressure == 'critical'
        ? 256 * _mib
        : pressure == 'constrained'
        ? 384 * _mib
        : 512 * _mib;
    final swapCredit = runtime.swapFreeBytes > 0
        ? (runtime.swapFreeBytes * (pressure == 'normal' ? .20 : .35)).round()
        : 0;
    final usable = math.max(0, memory.availableBytes - reserve) + swapCredit;
    final projectorWorkingSet = withMultimodalProjector
        ? (model.projectorArtifact?.sizeBytes ?? 384 * _mib) + 256 * _mib
        : 0;
    // mmap keeps cold model pages file-backed. Use a conservative resident
    // estimate rather than charging the complete GGUF size to RAM.
    final largeMapped = modelBytes > math.max(2 * _gib, memory.availableBytes);
    // This is a bootstrap estimate, NOT a predicted peak RSS. File-backed
    // pages can grow beyond it during generation; benchmark pressure is
    // recorded separately. Dense models must not be assumed to have a tiny
    // MoE active set.
    final mappedResident = largeMapped
        ? math.min(modelBytes, 1024 * _mib)
        : modelBytes;
    final baseWorkingSet = mappedResident + projectorWorkingSet + 256 * _mib;
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
    ];
    final contextCap = contextOptions.lastWhere(
      (value) => value <= contextByMemory,
      orElse: () => 2048,
    );
    final context = requestedContext
        .clamp(2048, largeMapped ? math.min(contextCap, 2048) : contextCap)
        .toInt();
    final output = requestedOutput
        .clamp(1, math.max(1, context ~/ 2))
        .toInt();
    final kvEstimate = context * kvBytesPerToken;
    final peak = baseWorkingSet + kvEstimate;
    final allowed =
        pressure != 'critical' &&
        usable > 0 &&
        contextByMemory >= contextOptions.first &&
        peak <= usable + (pressure == 'critical' ? 0 : 128 * _mib);
    final audioBytesPerSecond = 16000 * 2 * 10;
    final audioSeconds = math
        .max(0, headroom ~/ audioBytesPerSecond)
        .clamp(0, 4 * 60 * 60)
        .toInt();
    // Vulkan often duplicates/offloads weights rather than paging them.
    // Never try full GPU allocation for a GGUF larger than free physical RAM.
    final gpu = largeMapped || pressure == 'critical' ? 0 : 999;
    final batch = pressure == 'normal' ? 512 : 256;
    final microBatch = pressure == 'normal' ? 256 : 128;
    return InferenceResourcePlan(
      allowed: allowed,
      contextWindow: context,
      maxOutputTokens: output,
      threadCount: runtime.processorCount.clamp(1, 4).toInt(),
      estimatedPeakBytes: peak,
      audioDurationSeconds: audioSeconds,
      pressureLevel: pressure,
      backendHint: gpu == 0 ? 'cpu' : 'auto',
      gpuLayers: gpu,
      batchSize: batch,
      microBatchSize: microBatch,
      cacheType: pressure == 'critical' ? 'q4_0' : 'q8_0',
      flashAttention: true,
      swapAssisted: runtime.swapFreeBytes > 0 && mappedResident < modelBytes,
      reasonCode: allowed ? null : 'insufficient-memory',
    );
  }
}
