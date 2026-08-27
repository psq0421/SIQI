import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/models/workbench_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';
import 'mcp_store_page.dart';

class McpPage extends ConsumerStatefulWidget {
  const McpPage({super.key});

  @override
  ConsumerState<McpPage> createState() => _McpPageState();
}

class _McpPageState extends ConsumerState<McpPage> {
  final Map<String, McpConnectionResult> _results = {};
  final Set<String> _testing = {};
  final Set<String> _invoking = {};

  Future<void> _test(Map<String, Object?> server) async {
    final id = server['id']! as String;
    setState(() => _testing.add(id));
    final result = await ref.read(mcpServiceProvider).test(server);
    if (mounted) {
      setState(() {
        _testing.remove(id);
        _results[id] = result;
      });
    }
  }

  Future<void> _delete(Map<String, Object?> server) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteServer),
        content: Text(context.l10n.deleteServerBody(server['name']! as String)),
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
    if (accepted != true) return;
    await ref
        .read(localDatabaseProvider)
        .deleteMcpServer(server['id']! as String);
    ref.invalidate(mcpServersProvider);
  }

  Future<void> _invoke(
    Map<String, Object?> server,
    McpToolDefinition tool,
  ) async {
    final controller = TextEditingController(text: '{}');
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.invokeTool),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: context.l10n.toolArgumentsJson,
              helperText: tool.name,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.continueLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || !mounted) return;
    late final Map<String, dynamic> arguments;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException();
      arguments = Map<String, dynamic>.from(decoded);
    } on Object {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.invalidJsonObject)));
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const SiqiIcon(SiqiGlyph.shield, size: 34),
        title: Text(context.l10n.approveToolCall),
        content: Text(context.l10n.approveToolCallBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.confirmExecute),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    final invocationId = '${server['id']}/${tool.name}';
    setState(() => _invoking.add(invocationId));
    try {
      final output = await ref
          .read(mcpServiceProvider)
          .invokeTool(server, toolName: tool.name, arguments: arguments);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.toolResult),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(child: SelectableText(output)),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.done),
            ),
          ],
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.toolCallFailed(error.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _invoking.remove(invocationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final servers = ref.watch(mcpServersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mcpTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.mcpStore,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const McpStorePage()),
            ),
            icon: const SiqiIcon(SiqiGlyph.market),
          ),
          IconButton(
            tooltip: context.l10n.addServer,
            onPressed: () => _edit(context),
            icon: const SiqiIcon(SiqiGlyph.add),
          ),
        ],
      ),
      body: servers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SiqiEmptyState(
          title: context.l10n.error,
          body: error.toString(),
          glyph: SiqiGlyph.warning,
        ),
        data: (items) {
          final developerMode = ref.read(settingsProvider).developerMode;
          final visibleItems = developerMode
              ? items
              : items.where((item) => item['transport'] != 'stdio').toList();
          return visibleItems.isEmpty
              ? SiqiEmptyState(
                  title: context.l10n.noServers,
                  body: context.l10n.noServersBody,
                  glyph: SiqiGlyph.mcp,
                  action: FilledButton.icon(
                    onPressed: () => _edit(context),
                    icon: const SiqiIcon(SiqiGlyph.add, size: 18),
                    label: Text(context.l10n.addServer),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) {
                    final server = visibleItems[index];
                    final id = server['id']! as String;
                    return _ServerCard(
                      server: server,
                      result: _results[id],
                      testing: _testing.contains(id),
                      invoking: _invoking,
                      onTest: () => _test(server),
                      onInvoke: (tool) => _invoke(server, tool),
                      onEdit: () => _edit(context, server),
                      onDelete: () => _delete(server),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const SiqiIcon(SiqiGlyph.add),
        label: Text(context.l10n.addServer),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context, [
    Map<String, Object?>? server,
  ]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _McpEditor(server: server),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.server,
    required this.result,
    required this.testing,
    required this.invoking,
    required this.onTest,
    required this.onInvoke,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, Object?> server;
  final McpConnectionResult? result;
  final bool testing;
  final Set<String> invoking;
  final VoidCallback onTest;
  final Future<void> Function(McpToolDefinition tool) onInvoke;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final enabled = server['enabled'] == 1;
    final transport = server['transport'] as String? ?? 'http';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SiqiIconBadge(
                  glyph: transport == 'stdio'
                      ? SiqiGlyph.terminal
                      : SiqiGlyph.webhook,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server['name']! as String,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        server['command_or_url']! as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SiqiStatusPill(
                  label: enabled
                      ? context.l10n.enabledStatus
                      : context.l10n.disabledStatus,
                  glyph: enabled ? SiqiGlyph.check : SiqiGlyph.close,
                  compact: true,
                  color: enabled ? null : Theme.of(context).disabledColor,
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (result!.success
                              ? Colors.green
                              : Theme.of(context).colorScheme.error)
                          .withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(SiqiRadius.surface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SiqiIcon(
                          result!.success ? SiqiGlyph.check : SiqiGlyph.warning,
                          size: 18,
                          color: result!.success
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result!.success
                                ? context.l10n.connectionSuccess
                                : context.l10n.connectionFailed,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          context.l10n.latencyMs(
                            result!.latency.inMilliseconds,
                          ),
                        ),
                      ],
                    ),
                    if (result!.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelectableText(
                          result!.error!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (result!.success) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.toolsDiscovered(result!.tools.length),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      if (result!.protocolVersion != null)
                        Text(
                          context.l10n.protocolVersion(
                            result!.protocolVersion!,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (result!.tools.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(context.l10n.noTools),
                        )
                      else
                        for (final tool in result!.tools)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const SiqiIcon(SiqiGlyph.tools, size: 19),
                            title: Text(tool.name),
                            subtitle: Text(
                              tool.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: transport == 'stdio'
                                ? null
                                : IconButton(
                                    tooltip: context.l10n.invokeTool,
                                    onPressed:
                                        invoking.contains(
                                          '${server['id']}/${tool.name}',
                                        )
                                        ? null
                                        : () => onInvoke(tool),
                                    icon:
                                        invoking.contains(
                                          '${server['id']}/${tool.name}',
                                        )
                                        ? const SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const SiqiIcon(
                                            SiqiGlyph.play,
                                            size: 18,
                                          ),
                                  ),
                          ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const SiqiIcon(SiqiGlyph.close, size: 17),
                  label: Text(context.l10n.delete),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const SiqiIcon(SiqiGlyph.settings, size: 17),
                  label: Text(context.l10n.edit),
                ),
                FilledButton.icon(
                  onPressed: !enabled || testing ? null : onTest,
                  icon: testing
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const SiqiIcon(SiqiGlyph.play, size: 17),
                  label: Text(
                    testing ? context.l10n.testing : context.l10n.testServer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _McpEditor extends ConsumerStatefulWidget {
  const _McpEditor({this.server});
  final Map<String, Object?>? server;
  @override
  ConsumerState<_McpEditor> createState() => _McpEditorState();
}

class _McpEditorState extends ConsumerState<_McpEditor> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _config;
  late String _transport;
  late bool _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    final server = widget.server;
    _name = TextEditingController(text: server?['name'] as String? ?? '');
    _target = TextEditingController(
      text: server?['command_or_url'] as String? ?? '',
    );
    _config = TextEditingController(
      text: server?['config_json'] as String? ?? '{}',
    );
    _transport = server?['transport'] as String? ?? 'http';
    _enabled = server?['enabled'] != 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _config.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _target.text.trim().isEmpty) {
      setState(() => _error = context.l10n.requiredField);
      return;
    }
    try {
      final json = jsonDecode(_config.text);
      if (json is! Map) throw const FormatException();
    } on Object {
      setState(() => _error = context.l10n.configurationJsonInvalid);
      return;
    }
    if (_transport == 'stdio' && !ref.read(settingsProvider).developerMode) {
      setState(() => _error = context.l10n.developerModeRequired);
      return;
    }
    await ref.read(localDatabaseProvider).saveMcpServer({
      'id': widget.server?['id'] as String? ?? const Uuid().v4(),
      'name': _name.text.trim(),
      'transport': _transport,
      'command_or_url': _target.text.trim(),
      'config_json': _config.text.trim(),
      'enabled': _enabled ? 1 : 0,
    });
    ref.invalidate(mcpServersProvider);
    if (mounted) Navigator.pop(context);
  }

  void _template(String type) {
    if (type == 'files') {
      _name.text = context.l10n.localFilesTemplate;
      _transport = 'stdio';
      _target.text = 'siqi-mcp-files';
      _config.text = '{"roots":[]}';
    } else if (type == 'database') {
      _name.text = context.l10n.databaseTemplate;
      _transport = 'stdio';
      _target.text = 'siqi-mcp-sqlite';
      _config.text = '{"databases":[]}';
    } else {
      _name.text = context.l10n.webhookTemplate;
      _transport = 'http';
      _target.text = 'https://';
      _config.text = '{"headers":{}}';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final developerMode = ref.watch(settingsProvider).developerMode;
    return AlertDialog(
      title: Text(
        widget.server == null
            ? context.l10n.addServer
            : context.l10n.editServer,
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (developerMode)
                    ActionChip(
                      avatar: const SiqiIcon(SiqiGlyph.folder, size: 16),
                      label: Text(context.l10n.localFilesTemplate),
                      onPressed: () => _template('files'),
                    ),
                  if (developerMode)
                    ActionChip(
                      avatar: const SiqiIcon(SiqiGlyph.database, size: 16),
                      label: Text(context.l10n.databaseTemplate),
                      onPressed: () => _template('database'),
                    ),
                  ActionChip(
                    avatar: const SiqiIcon(SiqiGlyph.webhook, size: 16),
                    label: Text(context.l10n.webhookTemplate),
                    onPressed: () => _template('webhook'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: context.l10n.serverName),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _transport,
                decoration: InputDecoration(labelText: context.l10n.transport),
                items: [
                  if (developerMode)
                    DropdownMenuItem(
                      value: 'stdio',
                      child: Text(context.l10n.transportStdio),
                    ),
                  DropdownMenuItem(
                    value: 'http',
                    child: Text(context.l10n.transportHttp),
                  ),
                  DropdownMenuItem(
                    value: 'sse',
                    child: Text(context.l10n.transportSse),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _transport = value ?? 'http'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _target,
                decoration: InputDecoration(
                  labelText: developerMode
                      ? context.l10n.commandOrUrl
                      : context.l10n.serverUrl,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _config,
                minLines: 3,
                maxLines: 7,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: context.l10n.configurationJson,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
                title: Text(context.l10n.enabledStatus),
              ),
              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }
}
