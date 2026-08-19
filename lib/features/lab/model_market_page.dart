import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class ModelMarketPage extends ConsumerWidget {
  const ModelMarketPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadProvider);
    final settings = ref.watch(settingsProvider);
    final models = ModelCatalog.models
        .where(
          (model) =>
              model.family == ModelFamily.local &&
              model.downloadUrl != null &&
              model.sourceUrl != null &&
              model.sizeBytes != null &&
              model.expectedSha256 != null,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.modelMarket)),
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
          for (final model in models)
            _ModelDownloadCard(
              model: model,
              download: downloads[model.id],
              onDownload: () {
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
                      channelDescription:
                          context.l10n.notificationChannelDownloadsDescription,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.downloadStarted)),
                );
              },
              onPause: () =>
                  ref.read(downloadProvider.notifier).pause(model.id),
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
}

class _ModelDownloadCard extends ConsumerWidget {
  const _ModelDownloadCard({
    required this.model,
    required this.download,
    required this.onDownload,
    required this.onPause,
    required this.onSource,
  });
  final ModelDefinition model;
  final ModelDownloadState? download;
  final VoidCallback onDownload;
  final VoidCallback onPause;
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
                Chip(
                  label: Text(model.license),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
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
                if (model.sizeBytes != null)
                  Chip(
                    avatar: const SiqiIcon(SiqiGlyph.storage, size: 16),
                    label: Text(
                      context.l10n.modelSize(_formatBytes(model.sizeBytes!)),
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
                    avatar: const SiqiIcon(SiqiGlyph.warning, size: 16),
                    label: Text(context.l10n.serverOnlyModel),
                  ),
              ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onSource != null)
                  OutlinedButton.icon(
                    onPressed: onSource,
                    icon: const SiqiIcon(SiqiGlyph.link),
                    label: Text(context.l10n.officialSource),
                  ),
                if (onSource != null) const SizedBox(width: 8),
                active
                    ? OutlinedButton.icon(
                        onPressed: onPause,
                        icon: const SiqiIcon(SiqiGlyph.pause),
                        label: Text(context.l10n.pause),
                      )
                    : FutureBuilder<String?>(
                        future: ref
                            .read(modelDownloadServiceProvider)
                            .installedPath(model.id),
                        builder: (context, snapshot) {
                          if (snapshot.data != null) {
                            return Chip(
                              avatar: const SiqiIcon(SiqiGlyph.check, size: 18),
                              label: Text(context.l10n.installed),
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
