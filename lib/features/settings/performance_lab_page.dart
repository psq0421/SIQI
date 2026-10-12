import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/local_inference_service.dart';
import '../../l10n/l10n.dart';

class PerformanceLabPage extends ConsumerStatefulWidget {
  const PerformanceLabPage({super.key});
  @override
  ConsumerState<PerformanceLabPage> createState() => _PerformanceLabPageState();
}

class _PerformanceLabPageState extends ConsumerState<PerformanceLabPage> {
  List<ModelDefinition> _models = [];
  String? _modelId;
  bool _running = false;
  String _result = '';
  int _profile = 0;
  final _profiles = const [
    (
      'CPU / 4 / Q8 KV · batch256',
      LocalInferenceTuning(batchSize: 256, microBatchSize: 128),
    ),
    ('CPU / 4 / Q8 KV · batch128', LocalInferenceTuning()),
    ('CPU / 8 / Q8 KV', LocalInferenceTuning(threads: 8)),
    (
      'CPU / 4 / F16 KV',
      LocalInferenceTuning(cacheType: 'f16', flashAttention: false),
    ),
    (
      'Vulkan / 2 layers / Q8 KV',
      LocalInferenceTuning(backend: GpuBackend.vulkan, gpuLayers: 2),
    ),
    (
      'Vulkan / 4 layers / Q8 KV',
      LocalInferenceTuning(backend: GpuBackend.vulkan, gpuLayers: 4),
    ),
  ];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final installed = <ModelDefinition>[];
    final downloads = ref.read(modelDownloadServiceProvider);
    for (final m in ModelCatalog.models.where(
      (m) =>
          m.family == ModelFamily.local &&
          m.task == ModelTask.chat &&
          m.runnable,
    )) {
      if (await downloads.isFullyInstalled(m)) {
        installed.add(m);
      }
    }
    if (mounted) {
      setState(() {
        _models = installed;
        _modelId =
            installed
                .where((m) => m.id == 'local-gpt-oss-20b-q4km')
                .firstOrNull
                ?.id ??
            installed.firstOrNull?.id;
      });
    }
  }

  Future<File> _records() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/benchmarks');
    await directory.create(recursive: true);
    return File('${directory.path}/beta3.jsonl');
  }

  Future<void> _run() async {
    final model = _models.where((m) => m.id == _modelId).firstOrNull;
    if (model == null) return;
    final profile = _profiles[_profile];
    final inference = ref.read(localInferenceServiceProvider);
    final platform = ref.read(platformServiceProvider);
    final downloads = ref.read(modelDownloadServiceProvider);
    setState(() {
      _running = true;
      _result = context.l10n.benchmarkRunning;
    });
    final observations = <Map<String, Object?>>[];
    final started = DateTime.now();
    final runId = started.microsecondsSinceEpoch.toString();
    final file = await _records();
    final journal = file.openWrite(mode: FileMode.append);
    journal.writeln(
      jsonEncode({
        'schema': 2,
        'event': 'started',
        'runId': runId,
        'at': started.toIso8601String(),
        'modelId': model.id,
        'profile': profile.$1,
        'promptId': 'robot-tree-en-v1',
      }),
    );
    await journal.flush();
    Timer? sampler;
    var sampling = false;
    Future<void> sample() async {
      if (sampling) return;
      sampling = true;
      try {
        final process = await platform.processStats();
        final memory = await platform.deviceMemory();
        final observation = <String, Object?>{
          'at': process.timestamp.toIso8601String(),
          'rssBytes': process.rssBytes,
          'pssBytes': process.pssBytes,
          'swapPssBytes': process.swapPssBytes,
          'minorFaults': process.minorFaults,
          'majorFaults': process.majorFaults,
          'batteryPercent': process.batteryPercent,
          'batteryTemperatureDeciC': process.batteryTemperatureDeciC,
          'thermalStatus': process.thermalStatus,
          'availableBytes': memory.availableBytes,
        };
        observations.add(observation);
        journal.writeln(
          jsonEncode({
            'schema': 2,
            'event': 'sample',
            'runId': runId,
            ...observation,
          }),
        );
        await journal.flush();
        if (process.thermalStatus >= 3) await inference.cancel();
      } on Object {
        // Counter failures do not invalidate generation. A missing completed
        // event after restart makes an LMK/interruption visible in the journal.
      } finally {
        sampling = false;
      }
    }

    String? error;
    try {
      await inference.unloadModel();
      await sample();
      sampler = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(sample()),
      );
      final pending = ref
          .read(performanceBenchmarkServiceProvider)
          .runDecode(
            model: model,
            artifactPaths: await downloads.installedArtifactPaths(model),
            prompt:
                'Write a short story of about 100 words about a robot planting a tree. Respond in English.',
            contextWindow: 2048,
            maxTokens: 256,
            tuning: profile.$2,
          );
      await pending.timeout(
        const Duration(minutes: 10),
        onTimeout: () async {
          await inference.cancel();
          await inference.unloadModel();
          throw TimeoutException('benchmark-timeout');
        },
      );
    } on Object catch (e) {
      error = e.toString();
    } finally {
      sampler?.cancel();
      await sample();
    }
    final record = <String, Object?>{
      'schema': 2,
      'event': 'completed',
      'runId': runId,
      'at': started.toIso8601String(),
      'modelId': model.id,
      'promptId': 'robot-tree-en-v1',
      'profile': profile.$1,
      'requestedContext': 2048,
      'requestedOutput': 256,
      'performance': inference.lastPerformance,
      'error': error,
      'samples': observations,
    };
    final encoded = jsonEncode(record);
    // Timer callbacks already in flight must finish before closing the sink.
    while (sampling) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    journal.writeln(encoded);
    await journal.flush();
    await journal.close();
    // Safe for ADB automated collection: records contain no user prompts,
    // credentials, paths, or generated content.
    debugPrint('SIQI_BENCH_RESULT $encoded');
    if (mounted) {
      setState(() {
        _running = false;
        _result = const JsonEncoder.withIndent(
          '  ',
        ).convert({...record}..remove('samples'));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.benchmarkTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.benchmarkWarning),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _modelId,
            items: [
              for (final m in _models)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(m.displayName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _running ? null : (v) => setState(() => _modelId = v),
            isExpanded: true,
            decoration: InputDecoration(labelText: l.benchmarkModel),
          ),
          DropdownButtonFormField<int>(
            initialValue: _profile,
            items: [
              for (var i = 0; i < _profiles.length; i++)
                DropdownMenuItem(value: i, child: Text(_profiles[i].$1)),
            ],
            onChanged: _running
                ? null
                : (v) => setState(() => _profile = v ?? 0),
            decoration: InputDecoration(labelText: l.benchmarkProfile),
          ),
          FilledButton(
            onPressed: _running || _models.isEmpty ? null : _run,
            child: Text(l.benchmarkStart),
          ),
          OutlinedButton(
            onPressed: () async {
              await ref.read(localInferenceServiceProvider).unloadModel();
            },
            child: Text(l.benchmarkStop),
          ),
          TextButton(
            onPressed: _running
                ? null
                : () async {
                    final file = await _records();
                    if (await file.exists()) {
                      await SharePlus.instance.share(
                        ShareParams(files: [XFile(file.path)]),
                      );
                    }
                  },
            child: Text(l.benchmarkExport),
          ),
          SelectableText(
            _result.isEmpty
                ? (_models.isEmpty ? l.benchmarkNoModel : l.benchmarkIdle)
                : _result,
          ),
        ],
      ),
    );
  }
}
