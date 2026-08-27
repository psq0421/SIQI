import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/models/privacy_models.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class DataStorageSettingsPage extends ConsumerStatefulWidget {
  const DataStorageSettingsPage({super.key});

  @override
  ConsumerState<DataStorageSettingsPage> createState() =>
      _DataStorageSettingsPageState();
}

class _DataStorageSettingsPageState
    extends ConsumerState<DataStorageSettingsPage> {
  Future<void> _chooseModelFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    final writable =
        path != null &&
        await ref.read(workspaceServiceProvider).verifyWritableDirectory(path);
    await ref
        .read(permissionServiceProvider)
        .recordSystemPicker(
          kind: AppPermissionKind.workspaceFolder,
          purpose: PermissionPurpose.modelStorageAccess,
          granted: writable,
          detail: path,
        );
    if (path != null && !writable && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.folderNotWritable)));
    }
    if (writable) {
      await ref
          .read(settingsProvider.notifier)
          .update((current) => current.copyWith(modelStoragePath: path));
    }
  }

  Future<void> _chooseWorkspaceFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      initialDirectory: AppConstants.preferredProjectsPath,
    );
    final writable =
        path != null &&
        await ref.read(workspaceServiceProvider).verifyWritableDirectory(path);
    await ref
        .read(permissionServiceProvider)
        .recordSystemPicker(
          kind: AppPermissionKind.workspaceFolder,
          purpose: PermissionPurpose.workspaceAccess,
          granted: writable,
          detail: path,
        );
    if (path != null && !writable && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.folderNotWritable)));
    }
    if (writable) {
      await ref
          .read(settingsProvider.notifier)
          .update((current) => current.copyWith(activeWorkspacePath: path));
    }
  }

  Future<void> _shareFile(File file) => SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: context.l10n.appName),
  );

  Future<void> _exportAll() async {
    final file = await ref
        .read(archiveServiceProvider)
        .exportAll(ref.read(settingsProvider));
    if (mounted) await _shareFile(file);
  }

  Future<void> _exportConfig() async {
    final profiles = await ref.read(localDatabaseProvider).listApiProfiles();
    final file = await ref
        .read(archiveServiceProvider)
        .exportConfiguration(ref.read(settingsProvider), profiles);
    if (mounted) await _shareFile(file);
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['siqi', 'siji_config'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      final settings = path.endsWith('.siji_config')
          ? (await ref.read(archiveServiceProvider).importConfiguration(path))
                .settings
          : await ref.read(archiveServiceProvider).importAll(path);
      await ref.read(settingsProvider.notifier).replace(settings);
      ref.invalidate(apiProfilesProvider);
      await ref.read(chatProvider.notifier).initialize();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.importSuccess)));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.importFailed(error.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dataStorage)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const SiqiIcon(SiqiGlyph.workspace),
                  title: Text(context.l10n.activeWorkspace),
                  subtitle: Text(
                    settings.activeWorkspacePath ??
                        context.l10n.noWorkspaceSelected,
                  ),
                  trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
                  onTap: _chooseWorkspaceFolder,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const SiqiIcon(SiqiGlyph.storage),
                  title: Text(context.l10n.modelStorage),
                  subtitle: Text(
                    settings.modelStoragePath ?? context.l10n.defaultPath,
                  ),
                  trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
                  onTap: _chooseModelFolder,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.l10n.preferredProjectsPath(
                AppConstants.preferredProjectsPath,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<SaveInterval>(
            initialValue: settings.saveInterval,
            decoration: InputDecoration(labelText: context.l10n.saveInterval),
            items: [
              DropdownMenuItem(
                value: SaveInterval.realtime,
                child: Text(context.l10n.saveRealtime),
              ),
              DropdownMenuItem(
                value: SaveInterval.fiveMinutes,
                child: Text(context.l10n.saveFiveMinutes),
              ),
              DropdownMenuItem(
                value: SaveInterval.manual,
                child: Text(context.l10n.saveManual),
              ),
            ],
            onChanged: (value) => value == null
                ? null
                : update((current) => current.copyWith(saveInterval: value)),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              value: settings.downloadOverWifiOnly,
              onChanged: (value) => update(
                (current) => current.copyWith(downloadOverWifiOnly: value),
              ),
              secondary: const SiqiIcon(SiqiGlyph.download),
              title: Text(context.l10n.downloadWifiOnly),
              subtitle: Text(context.l10n.downloadWifiOnlyDescription),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const SiqiIcon(SiqiGlyph.export),
                  title: Text(context.l10n.exportData),
                  trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
                  onTap: _exportAll,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const SiqiIcon(SiqiGlyph.export),
                  title: Text(context.l10n.exportConfig),
                  trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
                  onTap: _exportConfig,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const SiqiIcon(SiqiGlyph.import),
                  title: Text(context.l10n.importData),
                  trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
                  onTap: _import,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
