import 'package:flutter/material.dart';

class AdaptiveTopBar extends StatelessWidget {
  const AdaptiveTopBar({
    required this.title,
    this.subtitle,
    this.actions = const [],
    super.key,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final islandInset = media.padding.top > 24 ? 40.0 : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16 + islandInset, 12, 16 + islandInset, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
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
          ...actions,
        ],
      ),
    );
  }
}
