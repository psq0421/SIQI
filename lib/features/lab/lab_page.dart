import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';
import '../../shared/adaptive_top_bar.dart';
import 'github_import_page.dart';
import 'harness_page.dart';
import 'mcp_page.dart';
import 'mcp_store_page.dart';
import 'model_market_page.dart';
import 'multimodal_page.dart';
import 'shell_page.dart';
import 'team_page.dart';

class LabPage extends ConsumerWidget {
  const LabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final servers = ref.watch(mcpServersProvider);
    final localModels = ModelCatalog.models
        .where(
          (model) => model.family == ModelFamily.local && model.downloadable,
        )
        .length;
    final totalTokens = chat.profiles.fold<int>(
      0,
      (sum, item) => sum + item.inputTokens + item.outputTokens,
    );
    final items = <_LabItem>[
      _LabItem(
        context.l10n.modelMarket,
        context.l10n.modelMarketDescription,
        SiqiGlyph.market,
        const ModelMarketPage(),
      ),
      _LabItem(
        context.l10n.multimodalZone,
        context.l10n.multimodalZoneDescription,
        SiqiGlyph.audio,
        const MultimodalPage(),
      ),
      _LabItem(
        context.l10n.mcpConfiguration,
        context.l10n.mcpDescription,
        SiqiGlyph.mcp,
        const McpPage(),
      ),
      _LabItem(
        context.l10n.mcpStore,
        context.l10n.mcpStoreDescription,
        SiqiGlyph.market,
        const McpStorePage(),
      ),
      _LabItem(
        context.l10n.aiTeamMode,
        context.l10n.aiTeamDescription,
        SiqiGlyph.queue,
        const TeamPage(),
      ),
      _LabItem(
        context.l10n.harnessDashboard,
        context.l10n.harnessDescription,
        SiqiGlyph.harness,
        const HarnessPage(),
      ),
      if (settings.developerMode)
        _LabItem(
          context.l10n.agentToolbox,
          context.l10n.agentToolboxDescription,
          SiqiGlyph.terminal,
          const ShellPage(),
        ),
      _LabItem(
        context.l10n.codeReview,
        context.l10n.codeReviewDescription,
        SiqiGlyph.review,
        const HarnessPage(),
      ),
      _LabItem(
        context.l10n.githubImport,
        context.l10n.githubImportDescription,
        SiqiGlyph.github,
        const GithubImportPage(),
      ),
    ];
    return Column(
      children: [
        AdaptiveTopBar(
          title: context.l10n.navLab,
          subtitle: context.l10n.labSubtitle,
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SiqiSectionHeader(
                        title: context.l10n.labOverview,
                        subtitle:
                            settings.activeWorkspacePath ??
                            context.l10n.noWorkspaceSelected,
                        icon: SiqiGlyph.workspace,
                        trailing: settings.activeWorkspacePath == null
                            ? SiqiStatusPill(
                                label: context.l10n.notConfigured,
                                glyph: SiqiGlyph.warning,
                                compact: true,
                                color: Theme.of(context).colorScheme.error,
                              )
                            : SiqiStatusPill(
                                label: context.l10n.localReady,
                                glyph: SiqiGlyph.check,
                                compact: true,
                              ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth >= 760
                              ? (constraints.maxWidth - 30) / 4
                              : (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: width,
                                child: SiqiMetricCard(
                                  label: context.l10n.conversations,
                                  value: '${chat.sessions.length}',
                                  glyph: SiqiGlyph.chat,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: SiqiMetricCard(
                                  label: context.l10n.apiProfiles,
                                  value: '${chat.profiles.length}',
                                  caption: context.l10n.tokensUsed(totalTokens),
                                  glyph: SiqiGlyph.key,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: SiqiMetricCard(
                                  label: context.l10n.mcpServersMetric,
                                  value: servers.when(
                                    data: (value) => '${value.length}',
                                    loading: () => '…',
                                    error: (_, __) => '—',
                                  ),
                                  glyph: SiqiGlyph.mcp,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: SiqiMetricCard(
                                  label: context.l10n.localModelsMetric,
                                  value: '$localModels',
                                  caption: context.l10n.availableToDownload,
                                  glyph: SiqiGlyph.chip,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SiqiSectionHeader(
                        title: context.l10n.workbenchTools,
                        subtitle: context.l10n.workbenchToolsDescription,
                        icon: SiqiGlyph.tools,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 1100
                        ? 3
                        : constraints.crossAxisExtent >= 620
                        ? 2
                        : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 116,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return SiqiActionTile(
                          title: item.title,
                          subtitle: item.subtitle,
                          glyph: item.glyph,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => item.page),
                          ),
                        );
                      }, childCount: items.length),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabItem {
  const _LabItem(this.title, this.subtitle, this.glyph, this.page);
  final String title;
  final String subtitle;
  final SiqiGlyph glyph;
  final Widget page;
}
