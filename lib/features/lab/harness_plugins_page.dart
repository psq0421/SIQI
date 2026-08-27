import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/models/workbench_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';

class HarnessPluginsPage extends ConsumerStatefulWidget {
  const HarnessPluginsPage({super.key});

  @override
  ConsumerState<HarnessPluginsPage> createState() => _HarnessPluginsPageState();
}

class _HarnessPluginsPageState extends ConsumerState<HarnessPluginsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  PluginSyncState _sync = const PluginSyncState();
  final Map<String, double?> _downloads = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshProviders() {
    ref.invalidate(harnessPluginsProvider);
    ref.invalidate(harnessPluginCountProvider);
  }

  Future<void> _syncAll() async {
    setState(() => _sync = const PluginSyncState(running: true));
    try {
      await ref.read(deepSeekHarnessServiceProvider).syncPluginCatalog((
        completed,
        total,
        count,
      ) {
        if (!mounted) return;
        setState(
          () => _sync = PluginSyncState(
            running: true,
            completedPages: completed,
            totalPages: total,
            totalPlugins: count,
          ),
        );
      });
      if (mounted) {
        setState(
          () => _sync = PluginSyncState(
            completedPages: _sync.totalPages,
            totalPages: _sync.totalPages,
            totalPlugins: _sync.totalPlugins,
          ),
        );
        _refreshProviders();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _sync = PluginSyncState(
            completedPages: _sync.completedPages,
            totalPages: _sync.totalPages,
            totalPlugins: _sync.totalPlugins,
            error: error.toString(),
          ),
        );
      }
    }
  }

  Future<void> _download(HarnessPlugin plugin) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.pluginSecurityTitle),
        content: Text(context.l10n.pluginSecurityBody(plugin.repositoryId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.downloadSourceArchive),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    setState(() => _downloads[plugin.repositoryId] = null);
    try {
      await ref
          .read(deepSeekHarnessServiceProvider)
          .downloadPlugin(
            plugin,
            onProgress: (received, total) {
              if (!mounted) return;
              setState(
                () => _downloads[plugin.repositoryId] = total <= 0
                    ? null
                    : received / total,
              );
            },
          );
      if (mounted) {
        setState(() => _downloads.remove(plugin.repositoryId));
        _refreshProviders();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _downloads.remove(plugin.repositoryId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.downloadFailedReason(error.toString())),
          ),
        );
      }
    }
  }

  Future<void> _uninstall(HarnessPlugin plugin) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removePluginArchive),
        content: Text(context.l10n.removePluginArchiveBody(plugin.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await ref.read(deepSeekHarnessServiceProvider).uninstallPlugin(plugin);
    _refreshProviders();
  }

  Future<void> _copyInstallCommand(HarnessPlugin plugin) async {
    final command = ref
        .read(deepSeekHarnessServiceProvider)
        .installCommand(plugin);
    if (command.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: command));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plugins = ref.watch(harnessPluginsProvider(_query));
    final count = ref.watch(harnessPluginCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.harnessPluginCatalog),
        actions: [
          IconButton(
            tooltip: context.l10n.syncAllPlugins,
            onPressed: _sync.running ? null : _syncAll,
            icon: const SiqiIcon(SiqiGlyph.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SiqiIcon(SiqiGlyph.shield),
                        const SizedBox(width: 10),
                        Expanded(child: Text(context.l10n.pluginCatalogNotice)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchPlugins,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: SiqiIcon(SiqiGlyph.search),
                    ),
                    suffixText: count.when(
                      data: (value) => '$value',
                      loading: () => '',
                      error: (_, __) => '',
                    ),
                  ),
                ),
                if (_sync.running || _sync.error != null) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _sync.totalPages == 0 ? null : _sync.progress,
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _sync.error ??
                          context.l10n.pluginSyncProgress(
                            _sync.completedPages,
                            _sync.totalPages,
                            _sync.totalPlugins,
                          ),
                      style: TextStyle(
                        color: _sync.error == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: plugins.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SiqiIcon(SiqiGlyph.market, size: 52),
                            const SizedBox(height: 12),
                            Text(context.l10n.noPluginsSynced),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _sync.running ? null : _syncAll,
                              icon: const SiqiIcon(SiqiGlyph.refresh),
                              label: Text(context.l10n.syncAllPlugins),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _PluginCard(
                        plugin: items[index],
                        progress: _downloads[items[index].repositoryId],
                        downloading: _downloads.containsKey(
                          items[index].repositoryId,
                        ),
                        showInstallCommand: ref
                            .watch(settingsProvider)
                            .developerMode,
                        onOpen: () => launchUrl(
                          Uri.parse(items[index].repositoryUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        onDownload: () => _download(items[index]),
                        onUninstall: () => _uninstall(items[index]),
                        onCopyCommand: () => _copyInstallCommand(items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PluginCard extends StatelessWidget {
  const _PluginCard({
    required this.plugin,
    required this.progress,
    required this.downloading,
    required this.showInstallCommand,
    required this.onOpen,
    required this.onDownload,
    required this.onUninstall,
    required this.onCopyCommand,
  });
  final HarnessPlugin plugin;
  final double? progress;
  final bool downloading;
  final bool showInstallCommand;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onUninstall;
  final VoidCallback onCopyCommand;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SiqiIconBadge(glyph: SiqiGlyph.tools),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${plugin.owner} · ${plugin.category} · ${plugin.kind}',
                    ),
                  ],
                ),
              ),
              if (plugin.downloaded)
                SiqiStatusPill(
                  label: context.l10n.downloaded,
                  glyph: SiqiGlyph.check,
                  compact: true,
                ),
            ],
          ),
          if (plugin.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plugin.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (plugin.stars.isNotEmpty)
                Chip(
                  label: Text(plugin.stars),
                  visualDensity: VisualDensity.compact,
                ),
              if (plugin.license != null)
                Chip(
                  label: Text(plugin.license!),
                  visualDensity: VisualDensity.compact,
                ),
              if (plugin.commitSha != null)
                Chip(
                  label: Text(plugin.commitSha!.substring(0, 12)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onOpen,
                icon: const SiqiIcon(SiqiGlyph.link, size: 18),
                label: Text(context.l10n.repository),
              ),
              if (!plugin.downloaded)
                FilledButton.tonalIcon(
                  onPressed: downloading ? null : onDownload,
                  icon: const SiqiIcon(SiqiGlyph.download, size: 18),
                  label: Text(context.l10n.downloadSourceArchive),
                )
              else ...[
                if (showInstallCommand)
                  OutlinedButton.icon(
                    onPressed: onCopyCommand,
                    icon: const SiqiIcon(SiqiGlyph.copy, size: 18),
                    label: Text(context.l10n.copyInstallCommand),
                  ),
                TextButton.icon(
                  onPressed: onUninstall,
                  icon: const SiqiIcon(SiqiGlyph.close, size: 18),
                  label: Text(context.l10n.removePluginArchive),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
