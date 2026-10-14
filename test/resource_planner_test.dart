import 'package:flutter_test/flutter_test.dart';
import 'package:siqi/core/constants/minicpm_catalog.dart';
import 'package:siqi/core/services/local_inference_service.dart';
import 'package:siqi/core/services/platform_service.dart';
import 'package:siqi/core/services/resource_planner.dart';

void main() {
  test('production expert window retains the validated 56-slot default', () {
    expect(const LocalInferenceTuning().expertWindow, 56);
    expect(const LocalInferenceTuning().prefetchDepth, 4);
    expect(const LocalInferenceTuning(expertWindow: 64).expertWindow, 64);
    expect(
      const LocalInferenceTuning(
        expertWindow: 96,
        prefetchDepth: 1,
      ).prefetchDepth,
      1,
    );
  });
  final large = MiniCpmCatalog.models.firstWhere(
    (model) => model.runtimeProfile == 'minicpm-v47-35b-les',
  );
  InferenceResourcePlan plan({int available = 8000000000}) =>
      ResourcePlanner.planInference(
        model: large,
        modelBytes: large.sizeBytes!,
        memory: DeviceMemoryInfo(
          availableBytes: available,
          totalBytes: 12000000000,
          lowMemoryThresholdBytes: 512000000,
        ),
        runtime: const DeviceRuntimeInfo(
          sdkInt: 37,
          processorCount: 8,
          isLowRamDevice: false,
          supportedAbis: ['arm64-v8a'],
        ),
        requestedContext: 131072,
        requestedOutput: 8192,
      );

  test('35B planning exposes target without pretending it has LES support', () {
    final result = plan();
    expect(result.memoryBudgetBytes, 5000000000);
    expect(result.contextWindow, 2048);
    expect(result.cacheType, 'q4_0');
    expect(result.batchSize, 64);
    expect(result.gpuLayers, 0);
    expect(result.estimatedPeakBytes, lessThan(5000000000));
    expect(
      large.runtimeBundled,
      const bool.fromEnvironment('SIQI_LES_RUNTIME'),
    );
    expect(large.runnable, const bool.fromEnvironment('SIQI_LES_RUNTIME'));
  });
  test('kernel critical memory cannot be admitted by the 5GB profile', () {
    expect(plan(available: 400000000).allowed, isFalse);
  });
  test('LES capability never claims to load the visual projector', () {
    if (const bool.fromEnvironment('SIQI_LES_RUNTIME')) {
      expect(large.isMultimodal, isFalse);
      expect(large.capabilities.length, 1);
    }
    final unverifiedQ4 = MiniCpmCatalog.models.firstWhere(
      (model) => model.id == 'local-minicpmv47-35b-q4km',
    );
    expect(unverifiedQ4.runtimeBundled, isFalse);
  });
}
