import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  bool _importing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(harnessPluginsProvider);
    ref.invalidate(harnessPluginCountProvider);
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip', 'tgz', 'gz', 'dsh', 'json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _importing = true);
    try {
      await ref.read(deepSeekHarnessServiceProvider).importLocalPlugin(path);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.harnessPluginImported)),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.harnessPluginImportFailed(error.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _delete(HarnessPlugin plugin) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.harnessDeleteLocalPlugin),
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
    await ref.read(deepSeekHarnessServiceProvider).deleteLocalPlugin(plugin);
    _refresh();
  }

  Future<void> _openExternal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final plugins = ref.watch(harnessPluginsProvider(_query));
    final count = ref.watch(harnessPluginCountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.harnessPluginManagement)),
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
                        Expanded(
                          child: Text(
                            context.l10n.harnessExternalPluginWarning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SiqiIcon(SiqiGlyph.import),
                      label: Text(context.l10n.harnessImportLocalPlugin),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openExternal('https://github.com/topics/dsh-plugin'),
                      icon: const SiqiIcon(SiqiGlyph.github),
                      label: Text(context.l10n.harnessBrowseGithubPlugins),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openExternal(
                        'https://dsh.deepseek404.com/index.php',
                      ),
                      icon: const SiqiIcon(SiqiGlyph.link),
                      label: Text(context.l10n.harnessBrowseChinesePlugins),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchLocalPlugins,
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
              ],
            ),
          ),
          Expanded(
            child: plugins.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (items) => items.isEmpty
                  ? SiqiEmptyState(
                      title: context.l10n.harnessNoLocalPlugins,
                      body: context.l10n.harnessImportHint,
                      glyph: SiqiGlyph.tools,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _LocalPluginCard(
                        plugin: items[index],
                        onDelete: () => _delete(items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalPluginCard extends StatelessWidget {
  const _LocalPluginCard({required this.plugin, required this.onDelete});

  final HarnessPlugin plugin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final path = plugin.archivePath;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SiqiIconBadge(glyph: SiqiGlyph.tools),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plugin.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SiqiStatusPill(
                  label: plugin.kind,
                  glyph: SiqiGlyph.storage,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(plugin.description),
            if (path != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                path,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const SiqiIcon(SiqiGlyph.close, size: 18),
                label: Text(context.l10n.harnessDeleteLocalPlugin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
