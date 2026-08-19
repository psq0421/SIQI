import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/models/workbench_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';

class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key});

  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  final _command = TextEditingController();
  late Future<List<Map<String, Object?>>> _history;

  @override
  void initState() {
    super.initState();
    _history = _loadHistory();
  }

  Future<List<Map<String, Object?>>> _loadHistory() => ref
      .read(localDatabaseProvider)
      .shellHistory(ref.read(settingsProvider).shellHistoryLength);

  void _refreshHistory() => setState(() => _history = _loadHistory());

  @override
  void dispose() {
    _command.dispose();
    super.dispose();
  }

  Future<void> _enqueue() async {
    final command = _command.text.trim();
    if (command.isEmpty) return;
    final service = ref.read(shellServiceProvider);
    final settings = ref.read(settingsProvider);
    if (settings.confirmDangerousCommands && service.isDangerous(command)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const SiqiIcon(SiqiGlyph.warning, size: 34),
          title: Text(context.l10n.dangerousTitle),
          content: Text(context.l10n.dangerousBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirmRun),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    ref.read(shellQueueProvider.notifier).enqueue(command);
    _command.clear();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(shellQueueProvider);
    final settings = ref.watch(settingsProvider);
    if (!settings.developerMode) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.shellTitle)),
        body: SiqiEmptyState(
          title: context.l10n.developerModeRequired,
          body: context.l10n.developerModeRequiredDescription,
          glyph: SiqiGlyph.shield,
        ),
      );
    }
    final active = queue
        .where(
          (item) =>
              item.status == ShellQueueStatus.queued ||
              item.status == ShellQueueStatus.running,
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.shellTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SiqiSectionHeader(
            title: context.l10n.commandQueue,
            subtitle:
                settings.activeWorkspacePath ?? context.l10n.shellAppDirectory,
            icon: SiqiGlyph.terminal,
            trailing: SiqiStatusPill(
              label: context.l10n.activeTasks(active),
              glyph: SiqiGlyph.queue,
              compact: true,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _command,
                    minLines: 2,
                    maxLines: 7,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: context.l10n.commandHint,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: SiqiIcon(SiqiGlyph.terminal),
                      ),
                    ),
                    onSubmitted: (_) => _enqueue(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _enqueue,
                      icon: const SiqiIcon(SiqiGlyph.queue, size: 18),
                      label: Text(context.l10n.addToQueue),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.taskQueue,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: queue.isEmpty
                    ? null
                    : ref.read(shellQueueProvider.notifier).clearCompleted,
                icon: const SiqiIcon(SiqiGlyph.close, size: 16),
                label: Text(context.l10n.clearCompleted),
              ),
            ],
          ),
          if (queue.isEmpty)
            SiqiEmptyState(
              title: context.l10n.queueEmpty,
              body: context.l10n.queueEmptyBody,
              glyph: SiqiGlyph.queue,
            )
          else
            for (final item in queue.reversed) _QueueCard(item: item),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.history,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: context.l10n.refresh,
                onPressed: _refreshHistory,
                icon: const SiqiIcon(SiqiGlyph.refresh),
              ),
            ],
          ),
          FutureBuilder<List<Map<String, Object?>>>(
            future: _history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    context.l10n.noCommandHistory,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final entry in items.take(30))
                      ListTile(
                        leading: SiqiIcon(
                          (entry['exit_code'] as int? ?? -1) == 0
                              ? SiqiGlyph.check
                              : SiqiGlyph.warning,
                          size: 19,
                        ),
                        title: Text(
                          entry['command']! as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: Text(
                          context.l10n.exitCode(
                            entry['exit_code'] as int? ?? -1,
                          ),
                        ),
                        onTap: () {
                          _command.text = entry['command']! as String;
                          _command.selection = TextSelection.collapsed(
                            offset: _command.text.length,
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.item});
  final ShellQueueItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (item.status) {
      ShellQueueStatus.queued => Theme.of(context).colorScheme.primary,
      ShellQueueStatus.running => Colors.orange,
      ShellQueueStatus.completed => Colors.green,
      ShellQueueStatus.failed => Theme.of(context).colorScheme.error,
      ShellQueueStatus.cancelled => Theme.of(context).disabledColor,
    };
    final output = '${item.stdout}${item.stderr}';
    return Card(
      child: ExpansionTile(
        leading: item.status == ShellQueueStatus.running
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : SiqiIcon(_statusGlyph(item.status), color: color),
        title: Text(
          item.command,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          _statusName(context, item.status),
          style: TextStyle(color: color),
        ),
        trailing: item.status == ShellQueueStatus.queued
            ? IconButton(
                tooltip: context.l10n.cancel,
                onPressed: () =>
                    ref.read(shellQueueProvider.notifier).cancelQueued(item.id),
                icon: const SiqiIcon(SiqiGlyph.close, size: 18),
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (item.exitCode != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.exitCode(item.exitCode!)),
            ),
          if (output.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(SiqiRadius.surface),
              ),
              child: SelectableText(
                output,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.l10n.noOutput),
            ),
        ],
      ),
    );
  }
}

SiqiGlyph _statusGlyph(ShellQueueStatus status) => switch (status) {
  ShellQueueStatus.queued => SiqiGlyph.queue,
  ShellQueueStatus.running => SiqiGlyph.play,
  ShellQueueStatus.completed => SiqiGlyph.check,
  ShellQueueStatus.failed => SiqiGlyph.warning,
  ShellQueueStatus.cancelled => SiqiGlyph.close,
};
String _statusName(BuildContext context, ShellQueueStatus status) =>
    switch (status) {
      ShellQueueStatus.queued => context.l10n.statusQueued,
      ShellQueueStatus.running => context.l10n.statusRunning,
      ShellQueueStatus.completed => context.l10n.statusCompleted,
      ShellQueueStatus.failed => context.l10n.statusFailed,
      ShellQueueStatus.cancelled => context.l10n.statusCancelled,
    };
