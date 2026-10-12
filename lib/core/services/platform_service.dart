import 'package:flutter/services.dart';

class NetworkStatus {
  const NetworkStatus({required this.connected, required this.onWifi});

  final bool connected;
  final bool onWifi;
}

class DeviceMemoryInfo {
  const DeviceMemoryInfo({
    required this.availableBytes,
    required this.totalBytes,
    required this.lowMemoryThresholdBytes,
  });

  final int availableBytes;
  final int totalBytes;
  final int lowMemoryThresholdBytes;
}

class StorageInfo {
  const StorageInfo({required this.availableBytes, required this.totalBytes});

  final int availableBytes;
  final int totalBytes;
}

class ProcessStats {
  const ProcessStats({
    required this.rssBytes,
    required this.pssBytes,
    required this.swapPssBytes,
    required this.minorFaults,
    required this.majorFaults,
    required this.batteryPercent,
    required this.timestamp,
    this.batteryTemperatureDeciC = -1,
    this.thermalStatus = -1,
  });

  final int rssBytes;
  final int pssBytes;
  final int swapPssBytes;
  final int minorFaults;
  final int majorFaults;
  final int batteryPercent;
  final DateTime timestamp;
  final int batteryTemperatureDeciC;
  final int thermalStatus;
}

class DeviceRuntimeInfo {
  const DeviceRuntimeInfo({
    required this.sdkInt,
    required this.processorCount,
    required this.isLowRamDevice,
    required this.supportedAbis,
    this.zramTotalBytes = 0,
    this.zramUsedBytes = 0,
    this.swapTotalBytes = 0,
    this.swapFreeBytes = 0,
    this.socModel = '',
    this.armVersion = 0,
    this.armV9Candidate = false,
    this.hexagonDevice = false,
    this.hexagonNpuRuntime = false,
    this.npuOptimizationEligible = false,
    this.npuOptimizationProfile = 'unverified',
    this.cpuCores = const [],
  });

  final int sdkInt;
  final int processorCount;
  final bool isLowRamDevice;
  final List<String> supportedAbis;

  /// Read-only kernel swap metrics. Android apps cannot reconfigure ZRAM
  /// without privileged access, so SIQI only reports its current state.
  final int zramTotalBytes;
  final int zramUsedBytes;
  final int swapTotalBytes;
  final int swapFreeBytes;
  final String socModel;
  final int armVersion;
  final bool armV9Candidate;
  final bool hexagonDevice;
  /// True only when a readable Qualcomm/Hexagon runtime library was found.
  /// This still does not prove that the current model uses the NPU.
  final bool hexagonNpuRuntime;
  final bool npuOptimizationEligible;
  final String npuOptimizationProfile;
  final List<Map<String, Object?>> cpuCores;
}

class PlatformService {
  const PlatformService();

  static const _channel = MethodChannel('com.psq.siqi/platform');

  Future<NetworkStatus> networkStatus() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('networkStatus') ??
        const <String, dynamic>{};
    return NetworkStatus(
      connected: result['connected'] as bool? ?? false,
      onWifi: result['onWifi'] as bool? ?? false,
    );
  }

  Future<DeviceMemoryInfo> deviceMemory() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('memoryStatus') ??
        const <String, dynamic>{};
    return DeviceMemoryInfo(
      availableBytes: result['availableBytes'] as int? ?? 0,
      totalBytes: result['totalBytes'] as int? ?? 0,
      lowMemoryThresholdBytes: result['lowMemoryThresholdBytes'] as int? ?? 0,
    );
  }

  Future<StorageInfo> storageInfo(String path) async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('storageStatus', {
          'path': path,
        }) ??
        const <String, dynamic>{};
    return StorageInfo(
      availableBytes: result['availableBytes'] as int? ?? 0,
      totalBytes: result['totalBytes'] as int? ?? 0,
    );
  }

  Future<DeviceRuntimeInfo> runtimeInfo() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('runtimeInfo') ??
        const <String, dynamic>{};
    return DeviceRuntimeInfo(
      sdkInt: result['sdkInt'] as int? ?? 0,
      processorCount: result['processorCount'] as int? ?? 1,
      isLowRamDevice: result['isLowRamDevice'] as bool? ?? false,
      supportedAbis: (result['supportedAbis'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      zramTotalBytes: result['zramTotalBytes'] as int? ?? 0,
      zramUsedBytes: result['zramUsedBytes'] as int? ?? 0,
      swapTotalBytes: result['swapTotalBytes'] as int? ?? 0,
      swapFreeBytes: result['swapFreeBytes'] as int? ?? 0,
      socModel: result['socModel'] as String? ?? '',
      armVersion: result['armVersion'] as int? ?? 0,
      armV9Candidate: result['armV9Candidate'] as bool? ?? false,
      hexagonDevice: result['hexagonDevice'] as bool? ?? false,
      hexagonNpuRuntime: result['hexagonNpuRuntime'] as bool? ?? false,
      npuOptimizationEligible:
          result['npuOptimizationEligible'] as bool? ?? false,
      npuOptimizationProfile:
          result['npuOptimizationProfile'] as String? ?? 'unverified',
      cpuCores: (result['cpuCores'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (core) => core.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(),
    );
  }

  Future<bool> setCpuAffinity(List<int> cores) async =>
      await _channel.invokeMethod<bool>('setCpuAffinity', {'cores': cores}) ??
      false;

  Future<ProcessStats> processStats() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('processStats', {
          'includePss': true,
        }) ??
        const <String, dynamic>{};
    return ProcessStats(
      rssBytes: result['rssBytes'] as int? ?? 0,
      pssBytes: result['pssBytes'] as int? ?? 0,
      swapPssBytes: result['swapPssBytes'] as int? ?? 0,
      minorFaults: result['minorFaults'] as int? ?? 0,
      majorFaults: result['majorFaults'] as int? ?? 0,
      batteryPercent: result['batteryPercent'] as int? ?? -1,
      batteryTemperatureDeciC: result['batteryTemperatureDeciC'] as int? ?? -1,
      thermalStatus: result['thermalStatus'] as int? ?? -1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        result['timestampMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<String?> captureWithSystemCamera() async {
    final path = await _channel.invokeMethod<String>('captureWithSystemCamera');
    return path;
  }

  Future<bool> openFile(String path) async {
    return await _channel.invokeMethod<bool>('openFile', {'path': path}) ??
        false;
  }
}
