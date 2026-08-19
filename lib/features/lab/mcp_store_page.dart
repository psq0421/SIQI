import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/mcp_service.dart';
import '../../l10n/l10n.dart';

class McpStorePage extends ConsumerStatefulWidget {
  const McpStorePage({super.key});

  @override
  ConsumerState<McpStorePage> createState() => _McpStorePageState();
}

class _McpStorePageState extends ConsumerState<McpStorePage> {
  String _query = '';
  bool _syncing = false;
  String? _error;

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      final count = await ref.read(mcpServiceProvider).syncCatalog();
      ref.invalidate(mcpCatalogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mcpStoreSynced(count))),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().contains('protected')
              ? context.l10n.mcpStoreProtected
              : context.l10n.downloadFailedReason(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _import(Map<String, Object?> item) async {
    final imported = await ref
        .read(mcpServiceProvider)
        .importCatalogEntry(item);
    if (!mounted) return;
    if (imported) ref.invalidate(mcpServersProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          imported
              ? context.l10n.mcpImported
              : context.l10n.mcpImportManualRequired,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mcpCatalogProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mcpStore),
        actions: [
          IconButton(
            tooltip: context.l10n.openOfficialCatalog,
            onPressed: () => launchUrl(
              Uri.parse(McpService.catalogUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const SiqiIcon(SiqiGlyph.link),
          ),
          IconButton(
            tooltip: context.l10n.syncCatalog,
            onPressed: _syncing ? null : _sync,
            icon: _syncing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const SiqiIcon(SiqiGlyph.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              hintText: context.l10n.searchMcpStore,
              leading: const SiqiIcon(SiqiGlyph.search),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          if (_error != null)
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const SiqiIcon(SiqiGlyph.warning),
                title: Text(_error!),
                subtitle: Text(context.l10n.mcpStoreCacheNotice),
                trailing: TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(McpService.catalogUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(context.l10n.openOfficialCatalog),
                ),
              ),
            ),
          Expanded(
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(error.toString())),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SiqiIcon(SiqiGlyph.market, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              context.l10n.mcpStoreEmpty,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _syncing ? null : _sync,
                              icon: const SiqiIcon(SiqiGlyph.refresh),
                              label: Text(context.l10n.syncCatalog),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final tags =
                            (jsonDecode(item['tags_json']! as String) as List)
                                .map((tag) => tag.toString())
                                .take(4)
                                .toList();
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name']! as String,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(item['author']! as String),
                                if ((item['description']! as String)
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item['description']! as String,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: tags
                                        .map(
                                          (tag) => Chip(
                                            label: Text(tag),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => launchUrl(
                                        Uri.parse(item['homepage']! as String),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      icon: const SiqiIcon(
                                        SiqiGlyph.link,
                                        size: 18,
                                      ),
                                      label: Text(context.l10n.details),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _import(item),
                                      icon: const SiqiIcon(
                                        SiqiGlyph.add,
                                        size: 18,
                                      ),
                                      label: Text(context.l10n.importToMcp),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
