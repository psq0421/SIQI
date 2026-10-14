import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';

import '../../shared/page_top_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/local_inference_service.dart';
import '../../core/services/file_content_service.dart';
import '../../core/services/memory_acceptance_report.dart';
import '../../core/services/benchmark_journal.dart';
import '../../core/services/model_download_service.dart';
import '../../core/services/performance_benchmark_service.dart';
import '../../core/services/platform_service.dart';
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
  int _context = 2048;
  bool _reuseModel = false;
  String? _document;

  List<(String, LocalInferenceTuning)> get _availableProfiles =>
      _models.where((m) => m.id == _modelId).firstOrNull?.runtimeProfile ==
          'minicpm-v47-35b-les'
      ? const [
          (
            'LES / CPU 4 / Q4 KV / experts64 / micro8',
            LocalInferenceTuning(
              threads: 4,
              batchSize: 64,
              microBatchSize: 8,
              cacheType: 'q4_0',
              expertWindow: 64,
            ),
          ),
          (
            'LES / CPU 4 / Q4 KV / experts56 / micro8',
            LocalInferenceTuning(
              threads: 4,
              batchSize: 64,
              microBatchSize: 8,
              cacheType: 'q4_0',
              expertWindow: 56,
            ),
          ),
          (
            'LES CPU4 / KV4 / E96 / P4 / micro16',
            LocalInferenceTuning(
              threads: 4,
              batchSize: 64,
              microBatchSize: 16,
              cacheType: 'q4_0',
              expertWindow: 96,
            ),
          ),
          (
            'LES CPU4 / KV4 / E96 / P1 / micro16',
            LocalInferenceTuning(
              threads: 4,
              batchSize: 64,
              microBatchSize: 16,
              cacheType: 'q4_0',
              expertWindow: 96,
              prefetchDepth: 1,
            ),
          ),
          (
            'LES CPU4/2/6/8 / KV4 / E56 / state replay',
            LocalInferenceTuning(
              threads: 4,
              batchSize: 64,
              microBatchSize: 16,
              cacheType: 'q4_0',
              expertWindow: 56,
              decodeThreadSweep: true,
            ),
          ),
        ]
      : _profiles;

  Future<void> _pickDocument() async {
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...AppConstants.supportedTextExtensions,
          ...AppConstants.richDocumentExtensions,
        ],
        withData: false,
      );
      final path = files?.files.firstOrNull?.path;
      if (path == null) return;
      final attachment = await FileContentService().read(
        path,
        multimodal: false,
      );
      if (mounted) setState(() => _document = attachment.extractedText);
    } on Object catch (error) {
      if (mounted) setState(() => _result = error.toString());
    }
  }

  final _profiles = const [
    (
      'MiniCPM / CPU / Q4 KV / batch64',
      LocalInferenceTuning(
        threads: 4,
        batchSize: 64,
        microBatchSize: 32,
        cacheType: 'q4_0',
      ),
    ),
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
          (m.task == ModelTask.chat || m.task == ModelTask.visionLanguage) &&
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
            installed.where((m) => m.provider == 'OpenBMB').firstOrNull?.id ??
            installed.firstOrNull?.id;
      });
    }
  }

  Future<File> _records() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/benchmarks');
    await directory.create(recursive: true);
    return File('${directory.path}/beta4.jsonl');
  }

  Future<void> _run() async {
    final model = _models.where((m) => m.id == _modelId).firstOrNull;
    if (model == null) return;
    final profile = _availableProfiles[_profile];
    final inference = ref.read(localInferenceServiceProvider);
    final platform = ref.read(platformServiceProvider);
    final downloads = ref.read(modelDownloadServiceProvider);
    // Capture providers before awaiting. The benchmark can finish after this
    // page is popped; a disposed widget's ref must never be consulted then.
    final benchmark = ref.read(performanceBenchmarkServiceProvider);
    final owner = Object();
    if (!benchmark.tryBeginRun(owner)) {
      setState(() => _result = context.l10n.benchmarkBusy);
      return;
    }
    try {
      await _runReserved(
        model,
        profile,
        inference,
        platform,
        downloads,
        benchmark,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _result = error.toString());
    } finally {
      benchmark.endRun(owner);
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _runReserved(
    ModelDefinition model,
    (String, LocalInferenceTuning) profile,
    LocalInferenceService inference,
    PlatformService platform,
    ModelDownloadService downloads,
    PerformanceBenchmarkService benchmark,
  ) async {
    if (mounted) {
      setState(() {
        _running = true;
        _result = context.l10n.benchmarkRunning;
      });
    }
    final observations = <Map<String, Object?>>[];
    final started = DateTime.now();
    final runId = started.microsecondsSinceEpoch.toString();
    final file = await _records();
    final journal = BenchmarkJournal(file);
    final contextWindow = _context;
    final reuseModel = _reuseModel;
    final document = _document;
    final deadline = Duration(minutes: document == null ? 10 : 60);
    final promptId = document == null
        ? 'robot-tree-en-v1'
        : 'selected-document-v1';
    final prompt = document == null
        ? 'Write a short story of about 100 words about a robot planting a tree. Respond in English.'
        : 'Summarize the following document.\n\n$document';
    await journal.append({
      'schema': 2,
      'event': 'started',
      'runId': runId,
      'at': started.toIso8601String(),
      'modelId': model.id,
      'profile': profile.$1,
      'promptId': promptId,
      'promptSha256': sha256.convert(utf8.encode(prompt)).toString(),
      'requestedContext': contextWindow,
      'reuseModelRequested': reuseModel,
      'deadlineMinutes': deadline.inMinutes,
    });
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
        await journal.append({
          'schema': 2,
          'event': 'sample',
          'runId': runId,
          ...observation,
        });
        if (process.thermalStatus >= 4) await inference.cancel();
      } on Object {
        // Counter failures do not invalidate generation. A missing completed
        // event after restart makes an LMK/interruption visible in the journal.
      } finally {
        sampling = false;
      }
    }

    String? error;
    Map<String, Object?>? performance;
    try {
      if (!reuseModel) await inference.unloadModel();
      await sample();
      sampler = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(sample()),
      );
      final pending = benchmark.runDecode(
        model: model,
        artifactPaths: await downloads.installedArtifactPaths(model),
        prompt: prompt,
        contextWindow: contextWindow,
        maxTokens: profile.$2.decodeThreadSweep ? 64 : 256,
        tuning: profile.$2,
        onProgress: (event) {
          // Native stage events contain counts, not prompt text or paths.
          if (event['event'] == 'decode-sweep-progress') {
            // Preserve completed variants even if a later candidate is
            // cancelled or stalls. Never include prompt/generated text.
            unawaited(
              journal
                  .append({
                    'schema': 2,
                    'event': 'decode-sweep-variant',
                    'runId': runId,
                    'at': DateTime.now().toIso8601String(),
                    'variant': event['variant'],
                  })
                  .catchError((Object _) {}),
            );
            if (mounted) {
              setState(
                () => _result = context.l10n.benchmarkThreadSweepProgress(
                  event['completedVariants'] as int,
                  event['totalVariants'] as int,
                ),
              );
            }
            return;
          }
          if (event['event'] != 'prefill-progress') return;
          unawaited(
            journal
                .append({
                  'schema': 2,
                  'event': 'prefill-progress',
                  'runId': runId,
                  'at': DateTime.now().toIso8601String(),
                  'evaluatedTokens': event['evaluatedTokens'],
                  'totalTokens': event['totalTokens'],
                })
                .catchError((Object _) {}),
          );
          if (mounted) {
            setState(
              () => _result = context.l10n.benchmarkPrefillProgress(
                event['evaluatedTokens'] as int,
                event['totalTokens'] as int,
              ),
            );
          }
        },
      );
      await pending.timeout(
        deadline,
        onTimeout: () async {
          await inference.cancel();
          await inference.unloadModel();
          throw TimeoutException('benchmark-timeout');
        },
      );
    } on Object catch (e) {
      error = e.toString();
    } finally {
      // Capture before awaiting counters; a subsequent chat request must not
      // overwrite this run's metrics. Rejected requests have no fresh metrics.
      final latest = inference.lastPerformance;
      final requestAt = DateTime.tryParse(
        latest?['requestStartedAt']?.toString() ?? '',
      );
      if (latest?['modelId'] == model.id &&
          requestAt != null &&
          !requestAt.isBefore(started)) {
        performance = Map<String, Object?>.from(latest!);
      }
      sampler?.cancel();
      while (sampling) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await sample();
    }
    final runtime = await platform.runtimeInfo();
    final deviceMemory = await platform.deviceMemory();
    final record = <String, Object?>{
      'schema': 2,
      'event': 'completed',
      'runId': runId,
      'at': started.toIso8601String(),
      'modelId': model.id,
      'promptId': promptId,
      'promptSha256': sha256.convert(utf8.encode(prompt)).toString(),
      'reuseModelRequested': reuseModel,
      'profile': profile.$1,
      'runtimeProfile': model.runtimeProfile,
      'quantization': model.quantization,
      'modelSha256': model.primaryArtifact?.expectedSha256,
      'device': {
        'socModel': runtime.socModel,
        'androidSdk': runtime.sdkInt,
        'processorCount': runtime.processorCount,
        'ramBytes': deviceMemory.totalBytes,
        'swapTotalBytes': runtime.swapTotalBytes,
        'swapFreeBytes': runtime.swapFreeBytes,
      },
      'requestedContext': contextWindow,
      'requestedOutput': profile.$2.decodeThreadSweep ? 64 : 256,
      'deadlineMinutes': deadline.inMinutes,
      'performance': performance,
      'error': error,
      'samples': observations,
      'memoryAcceptance': MemoryAcceptanceReport.evaluate(
        samples: observations,
        completed: error == null && performance != null,
        requestedContext: contextWindow,
        effectiveContext: performance?['effectiveContext'] as int?,
        targetBytes:
            model.memoryBudgetBytes ??
            MemoryAcceptanceReport.miniCpmTargetBytes,
      ),
    };
    final encoded = jsonEncode(record);
    // Timer callbacks already in flight must finish before closing the sink.
    while (sampling) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await journal.append(record);
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
      appBar: SiqiPageBar(title: Text(l.benchmarkTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.benchmarkWarning),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _modelId,
            items: [
              for (final m in _models)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(m.displayName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _running
                ? null
                : (v) => setState(() {
                    _modelId = v;
                    _profile = 0;
                  }),
            isExpanded: true,
            decoration: InputDecoration(labelText: l.benchmarkModel),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: _profile,
            isExpanded: true,
            items: [
              for (var i = 0; i < _availableProfiles.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    _availableProfiles[i].$1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _running
                ? null
                : (v) => setState(() => _profile = v ?? 0),
            decoration: InputDecoration(labelText: l.benchmarkProfile),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: _context,
            items: [
              for (final window in [2048, 8192, 32768, 131072])
                DropdownMenuItem(
                  value: window,
                  child: Text('${window ~/ 1024}K'),
                ),
            ],
            onChanged: _running
                ? null
                : (value) => setState(() => _context = value ?? 2048),
            decoration: InputDecoration(labelText: l.contextWindow),
          ),
          const SizedBox(height: 12),
          Text(l.benchmarkContextNote),
          SwitchListTile(
            value: _reuseModel,
            onChanged: _running
                ? null
                : (value) => setState(() => _reuseModel = value),
            title: Text(l.benchmarkReuseModel),
            subtitle: Text(l.benchmarkReuseModelNote),
          ),
          OutlinedButton(
            onPressed: _running ? null : _pickDocument,
            child: Text(l.benchmarkPickDocument),
          ),
          if (_document != null)
            TextButton(
              onPressed: _running
                  ? null
                  : () => setState(() => _document = null),
              child: Text(l.benchmarkResetDocument),
            ),
          const SizedBox(height: 20),
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
