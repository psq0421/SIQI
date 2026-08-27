import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/models/privacy_models.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class PermissionPrivacyPage extends ConsumerWidget {
  const PermissionPrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = ref.watch(permissionAuditProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.permissionPrivacy),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(permissionServiceProvider).openSystemSettings(),
            child: Text(context.l10n.openSystemSettings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SiqiIcon(SiqiGlyph.shield),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.l10n.permissionPrivacyBody)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.currentPermissions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final kind in AppPermissionKind.values) ...[
                  _PermissionTile(kind: kind),
                  if (kind != AppPermissionKind.values.last)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.permissionHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: audit.valueOrNull?.isEmpty ?? true
                    ? null
                    : () async {
                        await ref
                            .read(localDatabaseProvider)
                            .clearPermissionAudit();
                        ref.invalidate(permissionAuditProvider);
                      },
                icon: const SiqiIcon(SiqiGlyph.close, size: 18),
                label: Text(context.l10n.clearHistory),
              ),
            ],
          ),
          audit.when(
            data: (entries) => entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      context.l10n.noPermissionHistory,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in entries)
                        Card(
                          child: ListTile(
                            leading: const SiqiIcon(SiqiGlyph.shield),
                            title: Text(
                              _permissionName(context, entry.permission),
                            ),
                            subtitle: Text(
                              '${_purposeName(context, entry.purpose)}\n'
                              '${DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).add_Hms().format(entry.requestedAt)}'
                              '${entry.detail?.isNotEmpty == true ? '\n${entry.detail}' : ''}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_decisionName(context, entry.decision)),
                                IconButton(
                                  tooltip: context.l10n.deleteRecord,
                                  onPressed: () async {
                                    await ref
                                        .read(localDatabaseProvider)
                                        .deletePermissionAudit(entry.id);
                                    ref.invalidate(permissionAuditProvider);
                                  },
                                  icon: const SiqiIcon(
                                    SiqiGlyph.close,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
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

class _PermissionTile extends ConsumerWidget {
  const _PermissionTile({required this.kind});

  final AppPermissionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
    future: ref.read(permissionServiceProvider).status(kind),
    builder: (context, snapshot) => ListTile(
      leading: SiqiIcon(_permissionGlyph(kind)),
      title: Text(_permissionName(context, kind)),
      subtitle: Text(_permissionDescription(context, kind)),
      trailing: kind == AppPermissionKind.workspaceFolder
          ? Text(context.l10n.systemPickerManaged)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_statusName(context, snapshot.data)),
                const SizedBox(width: 6),
                const SiqiIcon(SiqiGlyph.chevronRight, size: 16),
              ],
            ),
      onTap: kind == AppPermissionKind.workspaceFolder
          ? null
          : () async {
              await ref
                  .read(permissionServiceProvider)
                  .request(kind, _permissionPurpose(kind));
              ref.invalidate(permissionAuditProvider);
            },
    ),
  );
}

PermissionPurpose _permissionPurpose(AppPermissionKind kind) => switch (kind) {
  AppPermissionKind.notifications => PermissionPurpose.modelDownloadProgress,
  AppPermissionKind.microphone => PermissionPurpose.speechToText,
  AppPermissionKind.camera => PermissionPurpose.cameraAttachment,
  AppPermissionKind.photos => PermissionPurpose.imageAttachment,
  AppPermissionKind.fileReadWrite ||
  AppPermissionKind.allFilesAccess => PermissionPurpose.fileAccess,
  AppPermissionKind.workspaceFolder => PermissionPurpose.workspaceAccess,
};

SiqiGlyph _permissionGlyph(AppPermissionKind kind) => switch (kind) {
  AppPermissionKind.notifications => SiqiGlyph.warning,
  AppPermissionKind.microphone => SiqiGlyph.audio,
  AppPermissionKind.camera => SiqiGlyph.image,
  AppPermissionKind.photos => SiqiGlyph.image,
  AppPermissionKind.fileReadWrite => SiqiGlyph.folder,
  AppPermissionKind.allFilesAccess => SiqiGlyph.storage,
  AppPermissionKind.workspaceFolder => SiqiGlyph.folder,
};

String _permissionName(BuildContext context, AppPermissionKind kind) =>
    switch (kind) {
      AppPermissionKind.notifications => context.l10n.permissionNotifications,
      AppPermissionKind.microphone => context.l10n.permissionMicrophone,
      AppPermissionKind.camera => context.l10n.permissionCamera,
      AppPermissionKind.photos => context.l10n.permissionPhotos,
      AppPermissionKind.fileReadWrite => context.l10n.permissionFileReadWrite,
      AppPermissionKind.allFilesAccess => context.l10n.permissionAllFilesAccess,
      AppPermissionKind.workspaceFolder => context.l10n.permissionWorkspace,
    };

String _permissionDescription(BuildContext context, AppPermissionKind kind) =>
    switch (kind) {
      AppPermissionKind.notifications =>
        context.l10n.permissionNotificationsDescription,
      AppPermissionKind.microphone =>
        context.l10n.permissionMicrophoneDescription,
      AppPermissionKind.camera => context.l10n.permissionCameraDescription,
      AppPermissionKind.photos => context.l10n.permissionPhotosDescription,
      AppPermissionKind.fileReadWrite =>
        context.l10n.permissionFileReadWriteDescription,
      AppPermissionKind.allFilesAccess =>
        context.l10n.permissionAllFilesAccessDescription,
      AppPermissionKind.workspaceFolder =>
        context.l10n.permissionWorkspaceDescription,
    };

String _purposeName(
  BuildContext context,
  PermissionPurpose purpose,
) => switch (purpose) {
  PermissionPurpose.modelDownloadProgress => context.l10n.purposeModelDownload,
  PermissionPurpose.speechToText => context.l10n.purposeSpeechToText,
  PermissionPurpose.cameraAttachment => context.l10n.purposeCameraAttachment,
  PermissionPurpose.imageAttachment => context.l10n.purposeImageAttachment,
  PermissionPurpose.workspaceAccess => context.l10n.purposeWorkspace,
  PermissionPurpose.modelStorageAccess => context.l10n.purposeModelStorage,
  PermissionPurpose.fileAccess => context.l10n.purposeFileAccess,
};

String _decisionName(BuildContext context, PermissionDecision decision) =>
    switch (decision) {
      PermissionDecision.granted => context.l10n.permissionGranted,
      PermissionDecision.denied => context.l10n.permissionDenied,
      PermissionDecision.permanentlyDenied =>
        context.l10n.permissionPermanentlyDenied,
      PermissionDecision.restricted => context.l10n.permissionRestricted,
      PermissionDecision.limited => context.l10n.permissionLimited,
      PermissionDecision.systemPickerGranted => context.l10n.permissionGranted,
      PermissionDecision.systemPickerCancelled => context.l10n.permissionDenied,
    };

String _statusName(BuildContext context, PermissionStatus? status) {
  if (status == null) return context.l10n.permissionUnknown;
  if (status.isGranted) return context.l10n.permissionGranted;
  if (status.isPermanentlyDenied) {
    return context.l10n.permissionPermanentlyDenied;
  }
  if (status.isRestricted) return context.l10n.permissionRestricted;
  if (status.isLimited) return context.l10n.permissionLimited;
  return context.l10n.permissionDenied;
}
