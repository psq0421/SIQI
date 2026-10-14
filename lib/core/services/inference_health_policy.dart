/// Pure, testable watchdog policy. Android SEVERE (3) denotes throttling;
/// it is not a cancellation request. Sampling is a guard, not an allocator.
class InferenceHealthPolicy {
  int _lowMemorySamples = 0;

  String? observe({
    required int availableBytes,
    required int lowMemoryThresholdBytes,
    required int thermalStatus,
    required int rssBytes,
    int? memoryBudgetBytes,
  }) {
    _lowMemorySamples =
        lowMemoryThresholdBytes > 0 && availableBytes < lowMemoryThresholdBytes
        ? _lowMemorySamples + 1
        : 0;
    if (memoryBudgetBytes != null && rssBytes > memoryBudgetBytes) {
      return 'model-memory-budget-exceeded';
    }
    if (thermalStatus >= 4) return 'critical-thermal-pressure';
    if (_lowMemorySamples >= 3) return 'sustained-critical-memory-pressure';
    return null;
  }
}
