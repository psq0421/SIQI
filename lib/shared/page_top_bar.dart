import 'package:flutter/material.dart';

import '../core/theme/siqi_design.dart';

/// Light-reflecting, large-radius controls without blur or extra animations.
/// Keeps the native back tooltip, semantics, tap target and keyboard behavior.
class SiqiTopControl extends StatelessWidget {
  const SiqiTopControl({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SiqiRadius.surface),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surfaceContainerLowest,
              colors.surfaceContainerHighest,
            ],
          ),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: colors.onSurface,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SiqiRadius.surface),
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SiqiPageBar extends StatelessWidget implements PreferredSizeWidget {
  const SiqiPageBar({required this.title, this.actions = const [], super.key});

  final Widget title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 64,
    leadingWidth: 64,
    title: title,
    leading: Navigator.of(context).canPop()
        ? const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SiqiTopControl(child: BackButton()),
          )
        : null,
    actions: [
      for (final action in actions) SiqiTopControl(child: action),
      if (actions.isNotEmpty) const SizedBox(width: 8),
    ],
  );
}
