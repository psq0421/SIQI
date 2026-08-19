import 'package:flutter/material.dart';

import '../icons/siqi_icons.dart';

abstract final class SiqiSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class SiqiRadius {
  static const surface = 12.0;
  static const pill = 999.0;
}

class SiqiIconBadge extends StatelessWidget {
  const SiqiIconBadge({
    required this.glyph,
    this.color,
    this.size = 40,
    super.key,
  });
  final SiqiGlyph glyph;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(SiqiRadius.surface),
        border: Border.all(color: resolved.withValues(alpha: .17)),
      ),
      alignment: Alignment.center,
      child: SiqiIcon(glyph, size: size * .52, color: resolved),
    );
  }
}

class SiqiSectionHeader extends StatelessWidget {
  const SiqiSectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    super.key,
  });
  final String title;
  final String? subtitle;
  final SiqiGlyph? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        SiqiIconBadge(glyph: icon!),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

class SiqiStatusPill extends StatelessWidget {
  const SiqiStatusPill({
    required this.label,
    required this.glyph,
    this.color,
    this.compact = false,
    super.key,
  });
  final String label;
  final SiqiGlyph glyph;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(SiqiRadius.pill),
        border: Border.all(color: resolved.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SiqiIcon(glyph, size: compact ? 13 : 15, color: resolved),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: resolved,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SiqiMetricCard extends StatelessWidget {
  const SiqiMetricCard({
    required this.label,
    required this.value,
    required this.glyph,
    this.color,
    this.caption,
    super.key,
  });
  final String label;
  final String value;
  final String? caption;
  final SiqiGlyph glyph;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SiqiIconBadge(glyph: glyph, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class SiqiEmptyState extends StatelessWidget {
  const SiqiEmptyState({
    required this.title,
    required this.body,
    required this.glyph,
    this.action,
    super.key,
  });
  final String title;
  final String body;
  final SiqiGlyph glyph;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SiqiIconBadge(glyph: glyph, size: 64),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    ),
  );
}

class SiqiActionTile extends StatelessWidget {
  const SiqiActionTile({
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.onTap,
    this.badge,
    this.color,
    super.key,
  });
  final String title;
  final String subtitle;
  final SiqiGlyph glyph;
  final VoidCallback onTap;
  final Widget? badge;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            SiqiIconBadge(glyph: glyph, color: color, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (badge != null) badge!,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SiqiIcon(SiqiGlyph.chevronRight, size: 18),
          ],
        ),
      ),
    ),
  );
}

class SiqiProgressRing extends StatelessWidget {
  const SiqiProgressRing({
    required this.value,
    this.size = 42,
    this.color,
    this.child,
    super.key,
  });
  final double value;
  final double size;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          strokeWidth: 3.5,
          color: color,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
        if (child != null) child!,
      ],
    ),
  );
}
