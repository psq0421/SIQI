import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tools/research/summarize_runs.dart';

void main() {
  Map<String, dynamic> record({
    int input = 51,
    int context = 2048,
    bool? cold = true,
  }) => {
    'modelId': 'synthetic-model',
    'profile': 'same-profile',
    'promptId': 'same-prompt-id',
    'promptSha256': 'synthetic-hash',
    'requestedContext': context,
    'performance': {
      'effectiveContext': context,
      'inputTokensAfterFitting': input,
      'evalTokens': 128,
      'coldLoad': cold,
    },
  };
  String key(Map<String, dynamic> item) =>
      jsonEncode(benchmarkGroupDimensions(item));

  test('short and real long inputs cannot share a summary group', () {
    expect(key(record()), isNot(key(record(input: 4785, context: 8192))));
    expect(key(record(input: 4785)), isNot(key(record())));
  });
  test('model-cold, reused and unknown states remain separate', () {
    expect(key(record(cold: true)), isNot(key(record(cold: false))));
    expect(key(record(cold: true)), isNot(key(record(cold: null))));
  });
  test('state replay is not an independent ordinary-generation repetition', () {
    final sweep = record();
    (sweep['performance'] as Map)['decodeThreadSweep'] = {'variants': []};
    expect(key(sweep), isNot(key(record())));
  });
}
