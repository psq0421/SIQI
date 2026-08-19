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
}
