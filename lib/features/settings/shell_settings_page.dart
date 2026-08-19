import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class ShellSettingsPage extends ConsumerWidget {
  const ShellSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.shellSettings)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: SwitchListTile(
              value: settings.developerMode,
              onChanged: (value) =>
                  update((current) => current.copyWith(developerMode: value)),
              title: Text(context.l10n.developerMode),
              subtitle: Text(context.l10n.developerModeDescription),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(context.l10n.historyLength)),
                      Text(
                        settings.shellHistoryLength.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.shellHistoryLength.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    onChanged: (value) => update(
                      (current) => current.copyWith(
                        shellHistoryLength: (value / 10).round() * 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ShellEnvironment>(
            initialValue: settings.shellEnvironment,
            decoration: InputDecoration(labelText: context.l10n.defaultShell),
            items: [
              DropdownMenuItem(
                value: ShellEnvironment.system,
                child: Text(context.l10n.shellSystemName),
              ),
              DropdownMenuItem(
                value: ShellEnvironment.termux,
                child: Text(context.l10n.shellTermuxName),
              ),
            ],
            onChanged: (value) => value == null
                ? null
                : update(
                    (current) => current.copyWith(shellEnvironment: value),
                  ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              value: settings.confirmDangerousCommands,
              onChanged: (value) => update(
                (current) => current.copyWith(confirmDangerousCommands: value),
              ),
              title: Text(context.l10n.dangerousConfirmation),
            ),
          ),
        ],
      ),
    );
  }
}
