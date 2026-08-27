import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/platform_service.dart';
import '../../l10n/l10n.dart';

class MultimodalPage extends ConsumerWidget {
  const MultimodalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskModels = ModelCatalog.models
        .where(
          (model) =>
              model.task == ModelTask.speechSynthesis ||
              model.task == ModelTask.speechRecognition ||
              model.task == ModelTask.opticalCharacterRecognition,
        )
        .toList();
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
              for (final task in const [
                ModelTask.speechSynthesis,
                ModelTask.speechRecognition,
                ModelTask.opticalCharacterRecognition,
              ]) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text(
                    _taskName(context, task),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final model in taskModels.where(
                  (item) => item.task == task,
                ))
                  Card(
                    child: ListTile(
                      leading: SiqiIcon(_taskGlyph(task)),
                      title: Text(model.displayName),
                      subtitle: Text(
                        '${model.provider}\n${_modelStatus(context, model)}',
                      ),
                      isThreeLine: true,
                      trailing: model.sourceUrl == null
                          ? null
                          : IconButton(
                              tooltip: context.l10n.officialSource,
                              onPressed: () => launchUrl(
                                Uri.parse(model.sourceUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const SiqiIcon(SiqiGlyph.link),
                            ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _taskName(BuildContext context, ModelTask task) => switch (task) {
  ModelTask.speechSynthesis => context.l10n.textToSpeech,
  ModelTask.speechRecognition => context.l10n.speechToText,
  ModelTask.opticalCharacterRecognition => context.l10n.ocrModels,
  _ => context.l10n.conversationModels,
};

SiqiGlyph _taskGlyph(ModelTask task) => switch (task) {
  ModelTask.speechSynthesis => SiqiGlyph.play,
  ModelTask.speechRecognition => SiqiGlyph.audio,
  ModelTask.opticalCharacterRecognition => SiqiGlyph.image,
  _ => SiqiGlyph.chat,
};

String _modelStatus(BuildContext context, ModelDefinition model) {
  if (model.runtimeBundled) return context.l10n.runtimeBundled;
  if (model.downloadable) return context.l10n.modelFilesOnly;
  return context.l10n.awaitingOfficialArtifacts;
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 GB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
