import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  Future<void> _shareWorkLogs(BuildContext context, WidgetRef ref) async {
    final entries = await ref.read(localDatabaseProvider).listWorkLogs();
    final cache = await getTemporaryDirectory();
    final file = File(p.join(cache.path, 'siqi-work-log.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final entry in entries)
          {
            'category': entry.category,
            'title': entry.title,
            'detail': entry.detail,
            'status': entry.status,
            'createdAt': entry.createdAt.toIso8601String(),
          },
      ]),
      flush: true,
    );
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: context.l10n.workLogs),
    );
  }

  Future<void> _shareRuntimeLogs(BuildContext context, WidgetRef ref) async {
    final files = await ref.read(appLogServiceProvider).files();
    if (files.isEmpty || !context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final file in files) XFile(file.path)],
        text: context.l10n.runtimeLogs,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(cacheSizeProvider);
    final workLogs = ref.watch(workLogsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.logsAndCache)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const SiqiIcon(SiqiGlyph.storage),
                  title: Text(context.l10n.cache),
                  subtitle: Text(
                    cache.when(
                      data: _formatBytes,
                      loading: () => context.l10n.calculating,
                      error: (_, __) => context.l10n.unavailable,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(cacheServiceProvider).clear();
                      ref.invalidate(cacheSizeProvider);
                    },
                    child: Text(context.l10n.clearCache),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const SiqiIcon(SiqiGlyph.export),
                  title: Text(context.l10n.runtimeLogs),
                  subtitle: Text(context.l10n.runtimeLogsDescription),
                  onTap: () => _shareRuntimeLogs(context, ref),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'share') {
                        await _shareRuntimeLogs(context, ref);
                      } else {
                        await ref.read(appLogServiceProvider).clear();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'share',
                        child: Text(context.l10n.shareLogs),
                      ),
                      PopupMenuItem(
                        value: 'clear',
                        child: Text(context.l10n.clearLogs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.workLogs,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: context.l10n.shareLogs,
                onPressed: () => _shareWorkLogs(context, ref),
                icon: const SiqiIcon(SiqiGlyph.export),
              ),
              IconButton(
                tooltip: context.l10n.clearLogs,
                onPressed: () async {
                  await ref.read(localDatabaseProvider).clearWorkLogs();
                  ref.invalidate(workLogsProvider);
                },
                icon: const SiqiIcon(SiqiGlyph.close),
              ),
            ],
          ),
          workLogs.when(
            data: (entries) => entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      context.l10n.noWorkLogs,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in entries)
                        Card(
                          child: ListTile(
                            leading: const SiqiIcon(SiqiGlyph.history),
                            title: Text(entry.title),
                            subtitle: Text(
                              '${entry.detail}\n${DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).add_Hms().format(entry.createdAt)}',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(entry.status),
                          ),
                        ),
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(error.toString()),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
