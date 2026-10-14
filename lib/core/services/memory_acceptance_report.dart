/// A measured acceptance result, not an allocator quota or an RSS prediction.
class MemoryAcceptanceReport {
  static const miniCpmTargetBytes = 5000000000;

  static Map<String, Object?> evaluate({
    required List<Map<String, Object?>> samples,
    required bool completed,
    required int requestedContext,
    required int? effectiveContext,
    int targetBytes = miniCpmTargetBytes,
  }) {
    var peakRss = 0;
    var peakPss = 0;
    var validRssSamples = 0;
    var validPssSamples = 0;
    for (final sample in samples) {
      final rss = (sample['rssBytes'] as num?)?.toInt() ?? 0;
      final pss = (sample['pssBytes'] as num?)?.toInt() ?? 0;
      if (rss > 0) {
        validRssSamples++;
        if (rss > peakRss) peakRss = rss;
      }
      if (pss > 0) {
        validPssSamples++;
        if (pss > peakPss) peakPss = pss;
      }
    }
    final measured = validRssSamples >= 2 && validPssSamples >= 2;
    final contextMet =
        effectiveContext != null && effectiveContext >= requestedContext;
    return {
      'schemaVersion': 1,
      'scope': 'sampled-whole-app-process-peak-for-this-run',
      'targetBytes': targetBytes,
      'peakRssBytes': peakRss,
      'peakPssBytes': peakPss,
      'rssSamples': validRssSamples,
      'pssSamples': validPssSamples,
      'completed': completed,
      'requestedContext': requestedContext,
      'effectiveContext': effectiveContext,
      'contextTargetMet': contextMet,
      'verdict': peakRss > targetBytes || peakPss > targetBytes
          ? 'failed'
          : !measured || !completed || effectiveContext == null
          ? 'inconclusive'
          : !contextMet
          ? 'failed'
          : 'passed',
      'limitation':
          'Sampling can miss transient peaks. A passing run does not '
          'validate other contexts, image inputs, or long conversations.',
    };
  }
}
