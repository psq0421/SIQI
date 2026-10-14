import 'package:flutter/material.dart';

import '../../shared/page_top_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class ModelMarketPage extends ConsumerStatefulWidget {
  const ModelMarketPage({super.key});

  @override
  ConsumerState<ModelMarketPage> createState() => _ModelMarketPageState();
}

class _ModelMarketPageState extends ConsumerState<ModelMarketPage> {
  ModelTask _task = ModelTask.chat;

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadProvider);
    final settings = ref.watch(settingsProvider);
    final models = ModelCatalog.models
        .where(
          (model) =>
              model.family == ModelFamily.local &&
              model.sourceUrl != null &&
              _taskGroup(model.task) == _task,
        )
        .toList();
    int rank(ModelDefinition model) => switch (model.id) {
      'local-minicpmv47-35b-mixq3' => 0,
      'local-minicpmv47-35b-q4km' => 1,
      _ => model.provider == 'OpenBMB' ? 2 : 3,
    };
    models.sort((a, b) {
      final comparison = rank(a).compareTo(rank(b));
      return comparison != 0
          ? comparison
          : ModelCatalog.models
                .indexOf(a)
                .compareTo(ModelCatalog.models.indexOf(b));
    });
    return Scaffold(
      appBar: SiqiPageBar(title: Text(context.l10n.modelMarket)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SiqiIcon(SiqiGlyph.shield),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.l10n.modelLicenseNotice)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ModelTask>(
              segments: [
                ButtonSegment(
                  value: ModelTask.chat,
                  icon: const SiqiIcon(SiqiGlyph.chat, size: 18),
                  label: Text(context.l10n.conversationModels),
                ),
                ButtonSegment(
                  value: ModelTask.speechSynthesis,
                  icon: const SiqiIcon(SiqiGlyph.play, size: 18),
                  label: Text(context.l10n.textToSpeech),
                ),
                ButtonSegment(
                  value: ModelTask.speechRecognition,
                  icon: const SiqiIcon(SiqiGlyph.audio, size: 18),
                  label: Text(context.l10n.speechToText),
                ),
                ButtonSegment(
                  value: ModelTask.opticalCharacterRecognition,
                  icon: const SiqiIcon(SiqiGlyph.image, size: 18),
                  label: Text(context.l10n.ocrModels),
                ),
              ],
              selected: {_task},
              onSelectionChanged: (value) =>
                  setState(() => _task = value.first),
            ),
          ),
          const SizedBox(height: 8),
          for (final model in models)
            _ModelDownloadCard(
              model: model,
              download: downloads[model.id],
              onDownload: model.downloadable
                  ? () {
                      ref
                          .read(downloadProvider.notifier)
                          .start(
                            model: model,
                            storagePath: settings.modelStoragePath,
                            title: context.l10n.notificationDownloadTitle(
                              model.displayName,
                            ),
                            body: context.l10n.notificationDownloadBody,
                            channel: context.l10n.notificationChannelDownloads,
                            channelDescription: context
                                .l10n
                                .notificationChannelDownloadsDescription,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.downloadStarted)),
                      );
                    }
                  : null,
              onPause: () =>
                  ref.read(downloadProvider.notifier).pause(model.id),
              onRemove: () => _removeModel(context, ref, model),
              onSource: model.sourceUrl == null
                  ? null
                  : () => launchUrl(
                      Uri.parse(model.sourceUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
            ),
        ],
      ),
    );
  }

  ModelTask _taskGroup(ModelTask task) => switch (task) {
    ModelTask.chat || ModelTask.visionLanguage => ModelTask.chat,
    ModelTask.speechSynthesis => ModelTask.speechSynthesis,
    ModelTask.speechRecognition => ModelTask.speechRecognition,
    ModelTask.opticalCharacterRecognition ||
    ModelTask.vision => ModelTask.opticalCharacterRecognition,
  };

  Future<void> _removeModel(
    BuildContext context,
    WidgetRef ref,
    ModelDefinition model,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.removeModel),
        content: Text(context.l10n.removeModelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(localInferenceServiceProvider).unloadModel();
    final removed = await ref.read(downloadProvider.notifier).remove(model.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.modelRemoved(_formatBytes(removed))),
        ),
      );
    }
  }
}

class _ModelDownloadCard extends ConsumerWidget {
  const _ModelDownloadCard({
    required this.model,
    required this.download,
    required this.onDownload,
    required this.onPause,
    required this.onRemove,
    required this.onSource,
  });
  final ModelDefinition model;
  final ModelDownloadState? download;
  final VoidCallback? onDownload;
  final VoidCallback onPause;
  final VoidCallback onRemove;
  final VoidCallback? onSource;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = download?.status == DownloadStatus.downloading;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(model.license, style: Theme.of(context).textTheme.labelMedium),
            Text(
              model.provider,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (model.totalDownloadBytes > 0)
                  Chip(
                    avatar: const SiqiIcon(SiqiGlyph.storage, size: 16),
                    label: Text(
                      context.l10n.modelSize(
                        _formatBytes(model.totalDownloadBytes),
                      ),
                    ),
                  ),
                if (model.minimumMemoryGb != null)
                  Chip(
                    avatar: const SiqiIcon(SiqiGlyph.memory, size: 16),
                    label: Text(
                      context.l10n.memoryRequirement(model.minimumMemoryGb!),
                    ),
                  ),
                if (!model.isDeviceCompatible)
                  Chip(
                    avatar: const SiqiIcon(SiqiGlyph.info, size: 16),
                    label: Text(
                      model.downloadable
                          ? context.l10n.modelFilesOnly
                          : context.l10n.compatibilityTarget,
                    ),
                  ),
                if (model.runtimeBundled)
                  Chip(
                    avatar: const SiqiIcon(SiqiGlyph.check, size: 16),
                    label: Text(context.l10n.runtimeBundled),
                  ),
                if (model.runtimeBundled &&
                    model.runtimeProfile == 'minicpm-v47-35b-les')
                  Chip(label: Text(context.l10n.lesTextOnly)),
                if (!model.runtimeBundled && model.downloadable)
                  Chip(
                    avatar: const SiqiIcon(SiqiGlyph.info, size: 16),
                    label: Text(context.l10n.modelRuntimePending),
                  ),
              ],
            ),
            if (model.runtimeBundled &&
                model.runtimeProfile == 'minicpm-v47-35b-les')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(context.l10n.lesPreparationNotice),
              ),
            if (download != null &&
                download!.status != DownloadStatus.idle) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: download!.total > 0
                    ? download!.progress.clamp(0, 1).toDouble()
                    : null,
              ),
              const SizedBox(height: 5),
              Text(
                context.l10n.downloadProgress(
                  (download!.progress * 100).clamp(0, 100).round(),
                ),
              ),
            ],
            if (download?.status == DownloadStatus.failed &&
                download?.error != null) ...[
              const SizedBox(height: 6),
              Text(
                download!.error == 'wifi-required'
                    ? context.l10n.downloadWifiRequired
                    : download!.error == 'checksum-mismatch'
                    ? context.l10n.downloadChecksumMismatch
                    : context.l10n.downloadFailedReason(download!.error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onSource != null)
                  OutlinedButton.icon(
                    onPressed: onSource,
                    icon: const SiqiIcon(SiqiGlyph.link),
                    label: Text(context.l10n.officialSource),
                  ),
                active
                    ? OutlinedButton.icon(
                        onPressed: onPause,
                        icon: const SiqiIcon(SiqiGlyph.pause),
                        label: Text(context.l10n.pause),
                      )
                    : !model.downloadable
                    ? FilledButton.tonalIcon(
                        onPressed: null,
                        icon: const SiqiIcon(SiqiGlyph.info),
                        label: Text(context.l10n.awaitingOfficialArtifacts),
                      )
                    : FutureBuilder<Map<String, String>>(
                        future: ref
                            .read(modelDownloadServiceProvider)
                            .installedArtifactPaths(model),
                        builder: (context, snapshot) {
                          final installed = snapshot.data ?? const {};
                          if (installed.isNotEmpty) {
                            final complete = model.installArtifacts
                                .where((artifact) => !artifact.optional)
                                .every(
                                  (artifact) =>
                                      installed.containsKey(artifact.id),
                                );
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  avatar: const SiqiIcon(
                                    SiqiGlyph.check,
                                    size: 18,
                                  ),
                                  label: Text(
                                    complete
                                        ? context.l10n.installed
                                        : context.l10n.modelFilesDetected,
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.l10n.removeModel,
                                  onPressed: onRemove,
                                  icon: const SiqiIcon(
                                    SiqiGlyph.close,
                                    size: 18,
                                  ),
                                ),
                              ],
                            );
                          }
                          return FilledButton.tonalIcon(
                            onPressed: onDownload,
                            icon: const SiqiIcon(SiqiGlyph.download),
                            label: Text(
                              download?.status == DownloadStatus.paused
                                  ? context.l10n.resume
                                  : context.l10n.download,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  final gib = bytes / (1024 * 1024 * 1024);
  return '${gib.toStringAsFixed(gib >= 10 ? 0 : 1)} GB';
}
