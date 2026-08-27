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

class DeviceRuntimeInfo {
  const DeviceRuntimeInfo({
    required this.sdkInt,
    required this.processorCount,
    required this.isLowRamDevice,
    required this.supportedAbis,
  });

  final int sdkInt;
  final int processorCount;
  final bool isLowRamDevice;
  final List<String> supportedAbis;
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
    );
  }
}
