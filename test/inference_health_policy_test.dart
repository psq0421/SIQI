import 'package:flutter_test/flutter_test.dart';
import 'package:siqi/core/services/inference_health_policy.dart';
import 'package:siqi/core/services/memory_acceptance_report.dart';

void main() {
  String? sample(
    InferenceHealthPolicy policy, {
    int available = 2048,
    int thermal = 3,
    int rss = 4000,
  }) => policy.observe(
    availableBytes: available,
    lowMemoryThresholdBytes: 512,
    thermalStatus: thermal,
    rssBytes: rss,
    memoryBudgetBytes: 5000,
  );

  test(
    'Beta3 regression: SEVERE throttling never silently stops generation',
    () {
      final policy = InferenceHealthPolicy();
      for (var i = 0; i < 50; i++) {
        expect(sample(policy), isNull);
      }
    },
  );
  test('CRITICAL temperature stops safely', () {
    expect(
      sample(InferenceHealthPolicy(), thermal: 4),
      'critical-thermal-pressure',
    );
  });
  test('pressure requires three consecutive samples', () {
    final policy = InferenceHealthPolicy();
    expect(sample(policy, available: 100), isNull);
    expect(sample(policy, available: 100), isNull);
    expect(
      sample(policy, available: 100),
      'sustained-critical-memory-pressure',
    );
  });
  test('recovered headroom resets pressure streak', () {
    final policy = InferenceHealthPolicy();
    sample(policy, available: 100);
    sample(policy, available: 100);
    sample(policy);
    expect(sample(policy, available: 100), isNull);
  });
  test('RSS overshoot has an explicit reason', () {
    expect(
      sample(InferenceHealthPolicy(), rss: 5001),
      'model-memory-budget-exceeded',
    );
    expect(sample(InferenceHealthPolicy(), rss: 5000), isNull);
  });
  test('missing platform threshold is not fabricated pressure', () {
    expect(
      InferenceHealthPolicy().observe(
        availableBytes: 0,
        lowMemoryThresholdBytes: 0,
        thermalStatus: -1,
        rssBytes: 0,
      ),
      isNull,
    );
  });

  final samples = [
    <String, Object?>{'rssBytes': 4800000000, 'pssBytes': 4500000000},
    <String, Object?>{'rssBytes': 4900000000, 'pssBytes': 4600000000},
  ];
  Map<String, Object?> report({
    bool completed = true,
    int? context = 2048,
    int requested = 2048,
    List<Map<String, Object?>>? observations,
  }) => MemoryAcceptanceReport.evaluate(
    samples: observations ?? samples,
    completed: completed,
    requestedContext: requested,
    effectiveContext: context,
  );
  test('sampled 5 GB run passes only with measured RSS and PSS', () {
    expect(report()['verdict'], 'passed');
    expect(report()['peakRssBytes'], 4900000000);
  });
  test('reduced context is not credited as the requested context', () {
    expect(report(requested: 131072)['verdict'], 'failed');
  });
  test('incomplete inference is inconclusive', () {
    expect(report(completed: false)['verdict'], 'inconclusive');
    expect(report(context: null)['verdict'], 'inconclusive');
  });
  test('missing PSS cannot produce a passing report', () {
    expect(
      report(
        observations: [
          {'rssBytes': 100},
          {'rssBytes': 200},
        ],
      )['verdict'],
      'inconclusive',
    );
  });
  test('an observed peak over budget fails', () {
    expect(
      report(
        observations: [
          ...samples,
          {'rssBytes': 5000000001, 'pssBytes': 100},
        ],
      )['verdict'],
      'failed',
    );
  });
  test('one overshoot fails even if the run never completed', () {
    expect(
      report(
        completed: false,
        observations: [
          {'rssBytes': 5000000001, 'pssBytes': 100},
        ],
      )['verdict'],
      'failed',
    );
  });
}
