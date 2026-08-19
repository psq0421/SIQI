import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';

class ModelSheet extends ConsumerWidget {
  const ModelSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final selected = settings.selectedModelId;
    final profiles = ref.watch(chatProvider.select((value) => value.profiles));
    final harnessMode = settings.selectedChatMode == ChatMode.harness;
    final visibleProfiles = harnessMode
        ? profiles.where((profile) => profile.providerId == 'deepseek').toList()
        : profiles;
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.48,
        maxChildSize: 0.94,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(SiqiRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.chooseModel,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              icon: SiqiGlyph.key,
              title: harnessMode
                  ? context.l10n.harnessDeepSeekProfile
                  : context.l10n.customApi,
            ),
            if (visibleProfiles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.noProfiles,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...visibleProfiles.map(
                (profile) => _ProfileTile(
                  profile: profile,
                  selected: selected == 'custom:${profile.id}',
                  onTap: () => _selectProfile(context, ref, profile),
                ),
              ),
            if (!harnessMode) ...[
              const SizedBox(height: 18),
              _SectionTitle(
                icon: SiqiGlyph.memory,
                title: context.l10n.localOffline,
              ),
              if (!ModelCatalog.models.any(
                (model) =>
                    model.family == ModelFamily.local &&
                    model.isDeviceCompatible,
              ))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.l10n.noCompatibleLocalModels,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ...ModelCatalog.models
                  .where(
                    (model) =>
                        model.family == ModelFamily.local &&
                        model.isDeviceCompatible,
                  )
                  .map(
                    (model) => _ModelTile(
                      model: model,
                      selected: selected == model.id,
                      onTap: () => _selectModel(context, ref, model),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool isMultimodal,
  ) async {
    await ref
        .read(settingsProvider.notifier)
        .update((current) => current.copyWith(selectedModelId: id));
    if (!isMultimodal) ref.read(chatProvider.notifier).clearAttachments();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _selectModel(
    BuildContext context,
    WidgetRef ref,
    ModelDefinition model,
  ) async {
    if (context.mounted) {
      await _select(context, ref, model.id, model.isMultimodal);
    }
  }

  Future<void> _selectProfile(
    BuildContext context,
    WidgetRef ref,
    ApiProfile profile,
  ) async {
    final harnessMode =
        ref.read(settingsProvider).selectedChatMode == ChatMode.harness;
    await ref
        .read(settingsProvider.notifier)
        .update(
          (current) => current.copyWith(
            selectedModelId: 'custom:${profile.id}',
            harnessApiProfileId: harnessMode ? profile.id : null,
          ),
        );
    if (!profile.isMultimodal) {
      ref.read(chatProvider.notifier).clearAttachments();
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final SiqiGlyph icon;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
    child: Row(
      children: [
        SiqiIcon(icon, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ModelTile extends ConsumerWidget {
  const _ModelTile({
    required this.model,
    required this.selected,
    required this.onTap,
  });
  final ModelDefinition model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailing = model.family == ModelFamily.local
        ? FutureBuilder<String?>(
            future: ref
                .read(modelDownloadServiceProvider)
                .installedPath(model.id),
            builder: (context, snapshot) => Text(
              snapshot.data == null
                  ? context.l10n.notInstalled
                  : context.l10n.installed,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          )
        : null;
    return Card(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: SiqiIcon(
          model.isMultimodal ? SiqiGlyph.image : SiqiGlyph.chat,
        ),
        title: Text(model.displayName),
        subtitle: Text(
          '${model.provider} · ${context.l10n.license(model.license)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            trailing ?? (selected ? const SiqiIcon(SiqiGlyph.check) : null),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.onTap,
  });
  final ApiProfile profile;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
    child: ListTile(
      onTap: onTap,
      leading: SiqiIcon(profile.isMultimodal ? SiqiGlyph.image : SiqiGlyph.key),
      title: Text(profile.name),
      subtitle: Text(profile.modelId),
      trailing: selected ? const SiqiIcon(SiqiGlyph.check) : null,
    ),
  );
}
