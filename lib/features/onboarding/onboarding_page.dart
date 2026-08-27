import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/models/privacy_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 3) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final localizations = context.l10n;
    await ref
        .read(settingsProvider.notifier)
        .update(
          (current) => current.copyWith(
            onboardingComplete: true,
            userName: _nameController.text.trim(),
            systemPrompt: localizations.defaultSystemPrompt,
          ),
        );
  }

  Future<void> _pickWorkspace() async {
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
    if (path == null) return;
    if (!writable) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.folderNotWritable)));
      }
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .update((current) => current.copyWith(activeWorkspacePath: path));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  const _WelcomeStep(),
                  _NicknameStep(controller: _nameController),
                  _PersonalizationStep(settings: settings),
                  _WorkspaceStep(
                    path: settings.activeWorkspacePath,
                    onChoose: _pickWorkspace,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  for (var index = 0; index < 4; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 6),
                      width: index == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(SiqiRadius.pill),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _page == 1 && _nameController.text.trim().isEmpty
                        ? null
                        : _next,
                    icon: SiqiIcon(
                      _page == 3 ? SiqiGlyph.check : SiqiGlyph.chevronRight,
                    ),
                    label: Text(
                      _page == 3
                          ? context.l10n.finish
                          : context.l10n.continueLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 28),
      const Center(child: SiqiBrandMark(size: 76)),
      const SizedBox(height: 24),
      Text(
        context.l10n.onboardingWelcomeTitle,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n.welcomeBody,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 28),
      MaterialSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.licenseTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(context.l10n.licenseBody),
            const Divider(height: 28),
            Text(
              context.l10n.privacyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(context.l10n.privacyBody),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(
        context.l10n.noAffiliation,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _NicknameStep extends StatelessWidget {
  const _NicknameStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 72),
      Center(
        child: SiqiIcon(
          SiqiGlyph.user,
          size: 68,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        context.l10n.nicknameTitle,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(context.l10n.nicknameSubtitle, textAlign: TextAlign.center),
      const SizedBox(height: 28),
      TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: context.l10n.nicknameHint,
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: SiqiIcon(SiqiGlyph.user),
          ),
        ),
      ),
    ],
  );
}

class _PersonalizationStep extends ConsumerWidget {
  const _PersonalizationStep({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          context.l10n.personalizationTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.colorMode,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<AppThemeMode>(
          segments: [
            ButtonSegment(
              value: AppThemeMode.system,
              label: Text(context.l10n.themeSystem),
              icon: const SiqiIcon(SiqiGlyph.theme),
            ),
            ButtonSegment(
              value: AppThemeMode.light,
              label: Text(context.l10n.themeLight),
              icon: const SiqiIcon(SiqiGlyph.sparkles),
            ),
            ButtonSegment(
              value: AppThemeMode.dark,
              label: Text(context.l10n.themeDark),
              icon: const SiqiIcon(SiqiGlyph.palette),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (value) => controller.update(
            (current) => current.copyWith(themeMode: value.first),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceStep extends StatelessWidget {
  const _WorkspaceStep({required this.path, required this.onChoose});
  final String? path;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 48),
      Center(
        child: SiqiIcon(
          SiqiGlyph.workspace,
          size: 68,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        context.l10n.workspaceOnboardingTitle,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(context.l10n.workspaceOnboardingBody, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        context.l10n.preferredProjectsPath(AppConstants.preferredProjectsPath),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 28),
      Card(
        child: ListTile(
          leading: const SiqiIcon(SiqiGlyph.folder),
          title: Text(context.l10n.activeWorkspace),
          subtitle: Text(path ?? context.l10n.noWorkspaceSelected),
          trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
          onTap: onChoose,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.tonalIcon(
        onPressed: onChoose,
        icon: const SiqiIcon(SiqiGlyph.folder),
        label: Text(context.l10n.chooseFolder),
      ),
    ],
  );
}
