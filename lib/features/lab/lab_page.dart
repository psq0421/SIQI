import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/siqi_icons.dart';
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
    final settings = ref.watch(settingsProvider);
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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SiqiIconBadge(glyph: SiqiGlyph.harness),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.deepSeekHarnessTitle,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(context.l10n.harnessDescription),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HarnessPage(),
                              ),
                            ),
                            child: Text(context.l10n.harnessDashboard),
                          ),
                        ],
                      ),
                    ),
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
