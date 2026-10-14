import 'dart:convert';
import 'dart:io';

/// Keep materially different workloads apart, including old records whose
/// missing counters must never be inferred from a modern profile's labels.
Map<String, Object?> benchmarkGroupDimensions(Map<String, dynamic> record) {
  final device = record['device'] as Map?;
  final performance = record['performance'] as Map?;
  return {
    'modelId': record['modelId'],
    'modelSha256': record['modelSha256'],
    'quantization': record['quantization'],
    'profile': record['profile'],
    'socModel': device?['socModel'],
    'androidSdk': device?['androidSdk'],
    'promptId': record['promptId'],
    'promptSha256': record['promptSha256'],
    'requestedContext': record['requestedContext'],
    'effectiveContext': performance?['effectiveContext'],
    'actualInputTokens': performance?['inputTokensAfterFitting'],
    'actualOutputTokens': performance?['evalTokens'],
    'requestedOutput': record['requestedOutput'],
    'fullPromptEvaluated': performance?['fullPromptEvaluated'],
    'historyWasReduced': performance?['historyWasReduced'],
    'coldLoad': performance?['coldLoad'],
    'effectiveBackend': performance?['effectiveBackend'],
    'runtimeRevision': performance?['runtimeRevision'],
    'mode': performance?['requestedMode'],
    'threadSweep': performance?['decodeThreadSweep'] != null,
  };
}

/// Summarizes exported benchmark JSONL without interpreting sampled peaks as
/// allocator guarantees or treating requested context as resident KV context.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tools/research/summarize_runs.dart <beta4.jsonl>',
    );
    exitCode = 64;
    return;
  }
  final file = File(args.single);
  if (!await file.exists()) {
    stderr.writeln('Benchmark file does not exist.');
    exitCode = 66;
    return;
  }
  final started = <String>{};
  final completed = <String>{};
  final groups = <String, List<Map<String, dynamic>>>{};
  var malformed = 0;
  await for (final line
      in file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    try {
      final record = Map<String, dynamic>.from(jsonDecode(line) as Map);
      final id = record['runId']?.toString() ?? '';
      if (record['event'] == 'started') started.add(id);
      if (record['event'] != 'completed') continue;
      completed.add(id);
      final key = jsonEncode(benchmarkGroupDimensions(record));
      groups.putIfAbsent(key, () => []).add(record);
    } on Object {
      malformed++;
    }
  }
  double? median(List<double> values) {
    if (values.isEmpty) return null;
    values.sort();
    final middle = values.length ~/ 2;
    return values.length.isOdd
        ? values[middle]
        : (values[middle - 1] + values[middle]) / 2;
  }

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 2,
      'unfinishedRunCount': started.difference(completed).length,
      'malformedLines': malformed,
      'groups': [
        for (final entry in groups.entries)
          {
            'workload': jsonDecode(entry.key),
            'runs': entry.value.length,
            'failedRuns': entry.value.where((r) => r['error'] != null).length,
            'memoryVerdicts': {
              for (final verdict in ['passed', 'failed', 'inconclusive'])
                verdict: entry.value
                    .where(
                      (r) =>
                          (r['memoryAcceptance'] as Map?)?['verdict'] ==
                          verdict,
                    )
                    .length,
            },
            'medianSuccessfulDecodeTokensPerSecond': median([
              for (final record in entry.value.where((r) => r['error'] == null))
                if ((record['performance'] as Map?)?['decodeTokensPerSecond']
                    is num)
                  ((record['performance'] as Map)['decodeTokensPerSecond']
                          as num)
                      .toDouble(),
            ]),
          },
      ],
      'limitation':
          'Sampled process memory, not a hard allocator cap. '
          '2K runs do not prove 128K capacity; decode throughput excludes load and prefill. '
          'Unknown workload metadata forms a separate group. State-replay variants '
          'are diagnostic, not independent repetitions or cache-controlled comparisons.',
    }),
  );
}
