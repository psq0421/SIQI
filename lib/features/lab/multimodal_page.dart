import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/platform_service.dart';
import '../../l10n/l10n.dart';

class MultimodalPage extends ConsumerWidget {
  const MultimodalPage({super.key});

  static const _models = <_AudioModel>[
    _AudioModel(
      name: 'MiMo-V2.5-ASR',
      task: _AudioTask.asr,
      weightBytes: 32074435744,
      source: 'https://modelscope.cn/models/XiaomiMiMo/MiMo-V2.5-ASR',
    ),
    _AudioModel(
      name: 'MiMo-Audio-7B-Instruct + Audio Tokenizer',
      task: _AudioTask.tts,
      weightBytes: 23850641200,
      source: 'https://modelscope.cn/models/XiaomiMiMo/MiMo-Audio-7B-Instruct',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.multimodalZone)),
      body: FutureBuilder<DeviceMemoryInfo>(
        future: ref.read(platformServiceProvider).deviceMemory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final memory = snapshot.data!;
          final budget = (memory.totalBytes * .6).floor();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SiqiIcon(SiqiGlyph.memory),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.audioMemoryGuard,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.audioMemorySummary(
                          _formatBytes(memory.totalBytes),
                          _formatBytes(budget),
                          _formatBytes(memory.availableBytes),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(context.l10n.audioMemoryPolicy),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final model in _models)
                _AudioModelCard(model: model, memoryBudget: budget),
            ],
          );
        },
      ),
    );
  }
}

class _AudioModelCard extends StatelessWidget {
  const _AudioModelCard({required this.model, required this.memoryBudget});

  final _AudioModel model;
  final int memoryBudget;

  @override
  Widget build(BuildContext context) {
    final fits = model.weightBytes <= memoryBudget;
    final suggestedSeconds = _suggestedSeconds(memoryBudget, model.weightBytes);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SiqiIcon(
                  model.task == _AudioTask.asr
                      ? SiqiGlyph.audio
                      : SiqiGlyph.play,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    model.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    model.task == _AudioTask.asr
                        ? context.l10n.speechToText
                        : context.l10n.textToSpeech,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.officialWeightSize(_formatBytes(model.weightBytes)),
            ),
            const SizedBox(height: 4),
            Text(
              fits
                  ? context.l10n.audioRuntimeUnavailable
                  : context.l10n.audioModelExceedsLimit,
            ),
            const SizedBox(height: 4),
            Text(
              suggestedSeconds <= 0
                  ? context.l10n.audioDurationUnavailable
                  : context.l10n.audioDurationSuggestion(
                      _formatDuration(suggestedSeconds),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(model.source),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const SiqiIcon(SiqiGlyph.link, size: 18),
                  label: Text(context.l10n.officialSource),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: null,
                  icon: const SiqiIcon(SiqiGlyph.download, size: 18),
                  label: Text(context.l10n.notCompatible),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

int _suggestedSeconds(int budget, int weights) {
  final remaining = budget - weights;
  if (remaining <= 0) return 0;
  // 16 kHz mono PCM plus conservative feature and decoder working buffers.
  return (remaining ~/ (16000 * 2 * 12)).clamp(1, 4 * 60 * 60);
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 GB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

enum _AudioTask { asr, tts }

class _AudioModel {
  const _AudioModel({
    required this.name,
    required this.task,
    required this.weightBytes,
    required this.source,
  });

  final String name;
  final _AudioTask task;
  final int weightBytes;
  final String source;
}
