import 'package:flutter/material.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';
import '../../shared/adaptive_top_bar.dart';
import 'about_page.dart';
import 'api_config_page.dart';
import 'appearance_settings_page.dart';
import 'conversation_settings_page.dart';
import 'data_storage_settings_page.dart';
import 'diagnostics_page.dart';
import 'permission_privacy_page.dart';
import 'shell_settings_page.dart';
import 'lan_gateway_page.dart';
import 'performance_lab_page.dart';
import 'cpu_performance_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items =
        <({String title, String subtitle, SiqiGlyph glyph, Widget page})>[
          (
            title: context.l10n.conversationReasoning,
            subtitle: context.l10n.settingsConversationDescription,
            glyph: SiqiGlyph.sparkles,
            page: const ConversationSettingsPage(),
          ),
          (
            title: context.l10n.appearance,
            subtitle: context.l10n.settingsAppearanceDescription,
            glyph: SiqiGlyph.palette,
            page: const AppearanceSettingsPage(),
          ),
          (
            title: context.l10n.apiProjection,
            subtitle: context.l10n.manageProviders,
            glyph: SiqiGlyph.key,
            page: const ApiConfigPage(),
          ),
          (
            title: context.l10n.dataStorage,
            subtitle: context.l10n.settingsDataDescription,
            glyph: SiqiGlyph.storage,
            page: const DataStorageSettingsPage(),
          ),
          (
            title: context.l10n.permissionPrivacy,
            subtitle: context.l10n.permissionPrivacyMenuDescription,
            glyph: SiqiGlyph.shield,
            page: const PermissionPrivacyPage(),
          ),
          (
            title: context.l10n.logsAndCache,
            subtitle: context.l10n.logsAndCacheDescription,
            glyph: SiqiGlyph.history,
            page: const DiagnosticsPage(),
          ),
          (
            title: context.l10n.shellSettings,
            subtitle: context.l10n.settingsShellDescription,
            glyph: SiqiGlyph.terminal,
            page: const ShellSettingsPage(),
          ),
          (
            title: context.l10n.aboutLegal,
            subtitle: context.l10n.aboutDescription,
            glyph: SiqiGlyph.info,
            page: const AboutPage(),
          ),
          (
            title: context.l10n.lanGateway,
            subtitle: context.l10n.gatewaySafety,
            glyph: SiqiGlyph.globe,
            page: const LanGatewayPage(),
          ),
          (
            title: context.l10n.benchmarkTitle,
            subtitle: context.l10n.benchmarkDescription,
            glyph: SiqiGlyph.sparkles,
            page: const PerformanceLabPage(),
          ),
          (
            title: context.l10n.cpuPerformance,
            subtitle: context.l10n.cpuPerformanceDescription,
            glyph: SiqiGlyph.sparkles,
            page: const CpuPerformancePage(),
          ),
        ];
    return Column(
      children: [
        AdaptiveTopBar(
          title: context.l10n.navSettings,
          subtitle: context.l10n.settingsSubtitle,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return SiqiActionTile(
                title: item.title,
                subtitle: item.subtitle,
                glyph: item.glyph,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => item.page)),
              );
            },
          ),
        ),
      ],
    );
  }
}
