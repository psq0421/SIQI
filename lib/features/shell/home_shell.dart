import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/siqi_icons.dart';
import '../../l10n/l10n.dart';
import '../chat/chat_page.dart';
import '../lab/lab_page.dart';
import '../settings/settings_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDestination(
        icon: const SiqiIcon(SiqiGlyph.chat),
        selectedIcon: SiqiIcon(
          SiqiGlyph.chat,
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2.4,
        ),
        label: context.l10n.navChat,
      ),
      NavigationDestination(
        icon: const SiqiIcon(SiqiGlyph.lab),
        selectedIcon: SiqiIcon(
          SiqiGlyph.lab,
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2.4,
        ),
        label: context.l10n.navLab,
      ),
      NavigationDestination(
        icon: const SiqiIcon(SiqiGlyph.settings),
        selectedIcon: SiqiIcon(
          SiqiGlyph.settings,
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2.4,
        ),
        label: context.l10n.navSettings,
      ),
    ];
    final pages = const [ChatPage(), LabPage(), SettingsPage()];
    final content = IndexedStack(index: _index, children: pages);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    leading: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: SiqiBrandMark(size: 48),
                    ),
                    destinations: destinations
                        .map(
                          (item) => NavigationRailDestination(
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: SafeArea(left: false, child: content)),
              ],
            ),
          );
        }
        return Scaffold(
          body: SafeArea(bottom: false, child: content),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: destinations,
          ),
        );
      },
    );
  }
}
