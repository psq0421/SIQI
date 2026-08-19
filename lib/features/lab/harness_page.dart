import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/workbench_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';
import '../settings/api_config_page.dart';
import 'harness_plugins_page.dart';

class HarnessPage extends ConsumerStatefulWidget {
  const HarnessPage({super.key});

  @override
  ConsumerState<HarnessPage> createState() => _HarnessPageState();
}

class _HarnessPageState extends ConsumerState<HarnessPage> {
  HarnessReport? _report;
  ScanSeverity? _filter;
  bool _running = false;
  String? _error;
  bool _runtimeDownloading = false;
  bool _runtimeAvailable = false;
  double? _runtimeProgress;

  @override
  void initState() {
    super.initState();
    _loadRuntimeState();
  }

  Future<void> _loadRuntimeState() async {
    final archive = await ref
        .read(deepSeekHarnessServiceProvider)
        .runtimeArchive();
    if (mounted) setState(() => _runtimeAvailable = archive != null);
  }

  Future<void> _downloadRuntime() async {
    setState(() {
      _runtimeDownloading = true;
      _runtimeProgress = null;
    });
    try {
      await ref
          .read(deepSeekHarnessServiceProvider)
          .downloadRuntime(
            onProgress: (received, total) {
              if (!mounted) return;
              setState(
                () => _runtimeProgress = total <= 0 ? null : received / total,
              );
            },
          );
      if (mounted) setState(() => _runtimeAvailable = true);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.downloadFailedReason(error.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _runtimeDownloading = false);
    }
  }

  Future<void> _pickWorkspace() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await ref
        .read(settingsProvider.notifier)
        .update((current) => current.copyWith(activeWorkspacePath: path));
    setState(() {
      _report = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final path = ref.read(settingsProvider).activeWorkspacePath;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectWorkspaceFirst)),
      );
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final report = await ref
          .read(harnessServiceProvider)
          .analyzeWorkspace(path);
      if (mounted) setState(() => _report = report);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(settingsProvider).activeWorkspacePath;
    final settings = ref.watch(settingsProvider);
    final deepSeekProfiles = ref
        .watch(chatProvider)
        .profiles
        .where((profile) => profile.providerId == 'deepseek')
        .toList();
    final report = _report;
    final issues =
        report?.issues
            .where((issue) => _filter == null || issue.severity == _filter)
            .toList() ??
        const <ScanIssue>[];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.harnessDashboard)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SiqiSectionHeader(
                    title: context.l10n.deepSeekHarnessTitle,
                    subtitle: context.l10n.deepSeekHarnessVersion(
                      AppConstants.harnessVersion,
                    ),
                    icon: SiqiGlyph.harness,
                    trailing: SiqiStatusPill(
                      label: context.l10n.developerPreview,
                      glyph: SiqiGlyph.warning,
                      compact: true,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SiqiIcon(SiqiGlyph.info),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(context.l10n.harnessRuntimeNotice),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (deepSeekProfiles.isEmpty)
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ApiConfigPage(
                                    initialProviderId: 'deepseek',
                                  ),
                                ),
                              ),
                              icon: const SiqiIcon(SiqiGlyph.key),
                              label: Text(context.l10n.addDeepSeekProfile),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue:
                                  deepSeekProfiles.any(
                                    (profile) =>
                                        profile.id ==
                                        settings.harnessApiProfileId,
                                  )
                                  ? settings.harnessApiProfileId
                                  : null,
                              decoration: InputDecoration(
                                labelText: context.l10n.harnessDeepSeekProfile,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SiqiIcon(SiqiGlyph.key),
                                ),
                              ),
                              items: deepSeekProfiles
                                  .map(
                                    (profile) => DropdownMenuItem(
                                      value: profile.id,
                                      child: Text(
                                        '${profile.name} · ${profile.modelId}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => ref
                                  .read(settingsProvider.notifier)
                                  .update(
                                    (current) => current.copyWith(
                                      harnessApiProfileId: value,
                                      clearHarnessApiProfileId: value == null,
                                    ),
                                  ),
                            ),
                          if (_runtimeDownloading) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: _runtimeProgress),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: _runtimeDownloading
                                    ? null
                                    : _downloadRuntime,
                                icon: const SiqiIcon(SiqiGlyph.download),
                                label: Text(
                                  _runtimeAvailable
                                      ? context.l10n.runtimeDownloaded
                                      : context.l10n.downloadOfficialRuntime,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const HarnessPluginsPage(),
                                  ),
                                ),
                                icon: const SiqiIcon(SiqiGlyph.market),
                                label: Text(context.l10n.harnessPluginCatalog),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.parse(
                                    AppConstants.harnessDocumentationUrl,
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                                icon: const SiqiIcon(SiqiGlyph.link),
                                label: Text(context.l10n.developmentDocs),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.parse(AppConstants.harnessRepositoryUrl),
                                  mode: LaunchMode.externalApplication,
                                ),
                                icon: const SiqiIcon(SiqiGlyph.github),
                                label: Text(context.l10n.repository),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.parse('http://127.0.0.1:3080'),
                                  mode: LaunchMode.externalApplication,
                                ),
                                icon: const SiqiIcon(SiqiGlyph.play),
                                label: Text(context.l10n.openLocalHarness),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SiqiSectionHeader(
                    title: context.l10n.localPreflight,
                    subtitle: workspace ?? context.l10n.noWorkspaceSelected,
                    icon: SiqiGlyph.review,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _running ? null : _pickWorkspace,
                        icon: const SiqiIcon(SiqiGlyph.folder, size: 18),
                        label: Text(context.l10n.chooseFolder),
                      ),
                      FilledButton.icon(
                        onPressed: _running ? null : _analyze,
                        icon: _running
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const SiqiIcon(SiqiGlyph.search, size: 18),
                        label: Text(
                          _running
                              ? context.l10n.scanning
                              : context.l10n.analyzeWorkspace,
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        context.l10n.scanFailed(_error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (report != null) ...[
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth >= 720
                            ? (constraints.maxWidth - 30) / 4
                            : (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: width,
                              child: SiqiMetricCard(
                                label: context.l10n.scannedFiles,
                                value: '${report.scannedFiles}',
                                caption: report.snapshot.primaryLanguage,
                                glyph: SiqiGlyph.code,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: SiqiMetricCard(
                                label: context.l10n.errorSeverity,
                                value: '${report.count(ScanSeverity.error)}',
                                glyph: SiqiGlyph.warning,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: SiqiMetricCard(
                                label: context.l10n.warningSeverity,
                                value: '${report.count(ScanSeverity.warning)}',
                                glyph: SiqiGlyph.shield,
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: SiqiMetricCard(
                                label: context.l10n.testDrafts,
                                value: '${report.testDrafts.length}',
                                glyph: SiqiGlyph.review,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    SiqiSectionHeader(
                      title: context.l10n.reviewResult,
                      subtitle: context.l10n.issueCount(report.issues.length),
                      icon: SiqiGlyph.review,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text(context.l10n.allSeverities),
                            selected: _filter == null,
                            onSelected: (_) => setState(() => _filter = null),
                          ),
                          const SizedBox(width: 7),
                          ChoiceChip(
                            label: Text(context.l10n.errorSeverity),
                            selected: _filter == ScanSeverity.error,
                            onSelected: (_) =>
                                setState(() => _filter = ScanSeverity.error),
                          ),
                          const SizedBox(width: 7),
                          ChoiceChip(
                            label: Text(context.l10n.warningSeverity),
                            selected: _filter == ScanSeverity.warning,
                            onSelected: (_) =>
                                setState(() => _filter = ScanSeverity.warning),
                          ),
                          const SizedBox(width: 7),
                          ChoiceChip(
                            label: Text(context.l10n.infoSeverity),
                            selected: _filter == ScanSeverity.info,
                            onSelected: (_) =>
                                setState(() => _filter = ScanSeverity.info),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (report != null && issues.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SiqiEmptyState(
                title: context.l10n.noIssuesTitle,
                body: context.l10n.noIssues,
                glyph: SiqiGlyph.check,
              ),
            )
          else if (report != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              sliver: SliverList.builder(
                itemCount: issues.length,
                itemBuilder: (context, index) =>
                    _IssueCard(issue: issues[index]),
              ),
            ),
          if (report != null && report.testDrafts.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
              sliver: SliverToBoxAdapter(
                child: _TestDraftPanel(drafts: report.testDrafts),
              ),
            ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});
  final ScanIssue issue;
  @override
  Widget build(BuildContext context) {
    final color = switch (issue.severity) {
      ScanSeverity.error => Theme.of(context).colorScheme.error,
      ScanSeverity.warning => Colors.orange,
      ScanSeverity.info => Theme.of(context).colorScheme.primary,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SiqiIconBadge(
              glyph: issue.severity == ScanSeverity.error
                  ? SiqiGlyph.warning
                  : SiqiGlyph.info,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _issueMessage(context, issue.messageKey),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      SiqiStatusPill(
                        label: _severityName(context, issue.severity),
                        glyph: issue.severity == ScanSeverity.error
                            ? SiqiGlyph.warning
                            : SiqiGlyph.info,
                        compact: true,
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    '${issue.filePath}:${issue.line}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  if (issue.evidence != null && issue.evidence!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: SelectableText(
                        issue.evidence!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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

class _TestDraftPanel extends StatelessWidget {
  const _TestDraftPanel({required this.drafts});
  final Map<String, String> drafts;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SiqiSectionHeader(
            title: context.l10n.generatedTestIdeas,
            subtitle: context.l10n.testDraftDescription,
            icon: SiqiGlyph.review,
          ),
          const SizedBox(height: 10),
          for (final entry in drafts.entries.take(20))
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                entry.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const SiqiIcon(SiqiGlyph.code, size: 20),
              trailing: IconButton(
                tooltip: context.l10n.copy,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: entry.value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.copied)),
                    );
                  }
                },
                icon: const SiqiIcon(SiqiGlyph.copy, size: 19),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(SiqiRadius.surface),
                  ),
                  child: SelectableText(
                    entry.value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

String _severityName(BuildContext context, ScanSeverity severity) =>
    switch (severity) {
      ScanSeverity.error => context.l10n.errorSeverity,
      ScanSeverity.warning => context.l10n.warningSeverity,
      ScanSeverity.info => context.l10n.infoSeverity,
    };

String _issueMessage(BuildContext context, String key) => switch (key) {
  'longLine' => context.l10n.issueLongLine,
  'todoMarker' => context.l10n.issueTodo,
  'hardcodedSecret' => context.l10n.issueHardcodedSecret,
  'dynamicExecution' => context.l10n.issueDynamicExecution,
  'shellInjection' => context.l10n.issueShellInjection,
  'sqlInterpolation' => context.l10n.issueSqlInterpolation,
  'emptyCatch' => context.l10n.issueEmptyCatch,
  'debugOutput' => context.l10n.issueDebugOutput,
  'cleartextUrl' => context.l10n.issueCleartextUrl,
  'destructiveCommand' => context.l10n.issueDestructiveCommand,
  'missingDispose' => context.l10n.issueMissingDispose,
  'innerHtml' => context.l10n.issueInnerHtml,
  _ => key,
};
