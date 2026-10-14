import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:siqi/core/services/benchmark_journal.dart';
import 'package:siqi/core/services/generation_delta_timings.dart';

void main() {
  test(
    'multiple journal instances never interleave large JSON lines',
    () async {
      final directory = await Directory.systemTemp.createTemp('siqi-journal-');
      try {
        final file = File('${directory.path}/nested/runs.jsonl');
        final journals = [BenchmarkJournal(file), BenchmarkJournal(file)];
        await Future.wait([
          for (var i = 0; i < 40; i++)
            journals[i % 2].append({
              'runId': '$i',
              'event': 'sample',
              'padding': List.filled(12000, '中文').join(),
            }),
        ]);
        final lines = await file.readAsLines();
        expect(lines, hasLength(40));
        final records = lines.map((line) => jsonDecode(line) as Map).toList();
        expect(records.map((r) => r['runId']), [
          for (var i = 0; i < 40; i++) '$i',
        ]);
        expect(records.every((r) => r['padding'].length == 24000), isTrue);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('queued records are encoded before callers can mutate them', () async {
    final directory = await Directory.systemTemp.createTemp('siqi-journal-');
    try {
      final file = File('${directory.path}/runs.jsonl');
      final journal = BenchmarkJournal(file);
      final record = <String, Object?>{'value': 'before'};
      final pending = journal.append(record);
      record['value'] = 'after';
      await pending;
      expect(jsonDecode(await file.readAsString())['value'], 'before');
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test(
    'journal failure is reported and does not poison later writes',
    () async {
      final directory = await Directory.systemTemp.createTemp('siqi-journal-');
      try {
        final blocker = File('${directory.path}/blocked');
        await blocker.writeAsString('fixture');
        final file = File('${blocker.path}/runs.jsonl');
        final journal = BenchmarkJournal(file);
        await expectLater(
          journal.append({'value': 1}),
          throwsA(isA<FileSystemException>()),
        );
        await blocker.delete();
        await journal.append({'value': 2});
        expect(jsonDecode(await file.readAsString())['value'], 2);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('page changes cannot acquire or release another run reservation', () {
    final gate = BenchmarkRunGate();
    final first = Object();
    final second = Object();
    expect(gate.acquire(first), isTrue);
    expect(gate.acquire(second), isFalse);
    gate.release(second);
    expect(gate.running, isTrue);
    gate.release(first);
    expect(gate.acquire(second), isTrue);
  });

  test('reasoning is not credited as the first visible answer', () {
    final timing = GenerationDeltaTimings();
    timing.observe(elapsedMs: 1, content: '', reasoning: '');
    expect(timing.firstDeltaMs, isNull);
    timing.observe(elapsedMs: 50, reasoning: 'thinking');
    timing.observe(elapsedMs: 150, content: 'answer');
    timing.observe(elapsedMs: 200, content: 'continuation');
    expect(timing.firstDeltaMs, 50);
    expect(timing.firstReasoningDeltaMs, 50);
    expect(timing.firstContentDeltaMs, 150);
    expect(timing.toJson()['timingSchema'], 2);
  });

  test('empty final answer retains a missing content timestamp', () {
    final timing = GenerationDeltaTimings();
    timing.observe(elapsedMs: 50, reasoning: 'thinking');
    expect(timing.firstContentDeltaMs, isNull);
  });
}
