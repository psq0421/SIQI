import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../l10n/l10n.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openProject() => launchUrl(
    Uri.parse(AppConstants.projectUrl),
    mode: LaunchMode.externalApplication,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.aboutLegal)),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SizedBox(height: 24),
        const Center(child: SiqiBrandMark(size: 76)),
        const SizedBox(height: 16),
        Text(
          context.l10n.appName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.versionLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const SiqiIcon(SiqiGlyph.github),
                title: Text(context.l10n.projectRepository),
                subtitle: const Text(AppConstants.projectUrl),
                trailing: const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
                onTap: _openProject,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const SiqiIcon(SiqiGlyph.shield),
                title: Text(context.l10n.licenseTitle),
                subtitle: Text(context.l10n.licenseBody),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.noAffiliation),
          ),
        ),
      ],
    ),
  );
}
