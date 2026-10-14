import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../shared/page_top_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/minicpm_les_backend.dart';
import '../../l10n/l10n.dart';

class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  Future<void> _guardExport(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      await ref
          .read(appLogServiceProvider)
          .warning('diagnostics-export', error.runtimeType.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.traceExportFailed)));
      }
    }
  }

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

  Future<void> _shareAgentTrace(
    BuildContext context,
    WidgetRef ref, {
    bool failedOnly = false,
  }) async {
    final traces = await ref
        .read(localDatabaseProvider)
        .exportAgentExecutions(failedOnly: failedOnly);
    if (!context.mounted) return;
    if (traces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.traceEmpty)));
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.exportAgentTrace),
        content: Text(context.l10n.tracePrivacyWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.exportAgentTrace),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final directory = await getTemporaryDirectory();
    final suffix = failedOnly ? 'failures' : 'traces';
    final file = File(p.join(directory.path, 'siqi-agent-$suffix.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(traces),
      flush: true,
    );
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: context.l10n.exportAgentTrace,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(cacheSizeProvider);
    final lesCache = ref.watch(lesCacheSizeProvider);
    final workLogs = ref.watch(workLogsProvider);
    final spill = ref.watch(runtimeSpillSizeProvider);
    return Scaffold(
      appBar: SiqiPageBar(title: Text(context.l10n.logsAndCache)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.agentTraces,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(context.l10n.agentTraceDescription),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _guardExport(
                          context,
                          ref,
                          () => _shareAgentTrace(context, ref),
                        ),
                        icon: const SiqiIcon(SiqiGlyph.export),
                        label: Text(context.l10n.exportAgentTrace),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _guardExport(
                          context,
                          ref,
                          () =>
                              _shareAgentTrace(context, ref, failedOnly: true),
                        ),
                        icon: const Icon(Icons.error_outline_rounded),
                        label: Text(context.l10n.exportFailedAgentTrace),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: Text(context.l10n.releaseActiveModel),
                  subtitle: Text(context.l10n.releaseActiveModelDescription),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref
                          .read(localInferenceServiceProvider)
                          .unloadModel();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.modelMemoryReleased),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.stop_rounded),
                  ),
                ),
                const Divider(height: 1),
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
                  leading: const Icon(Icons.memory_rounded),
                  title: Text(context.l10n.lesExpertCache),
                  subtitle: Text(
                    lesCache.when(
                      data: _formatBytes,
                      loading: () => context.l10n.calculating,
                      error: (_, __) => context.l10n.unavailable,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref
                          .read(localInferenceServiceProvider)
                          .unloadModel();
                      await MiniCpmLesBackend.clearCaches();
                      ref.invalidate(lesCacheSizeProvider);
                    },
                    child: Text(context.l10n.clearCache),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.memory_rounded),
                  title: Text(context.l10n.runtimeSpillCache),
                  subtitle: Text(
                    spill.when(
                      data: _formatBytes,
                      loading: () => context.l10n.calculating,
                      error: (_, __) => context.l10n.unavailable,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(runtimeSpillServiceProvider).clear();
                      ref.invalidate(runtimeSpillSizeProvider);
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
