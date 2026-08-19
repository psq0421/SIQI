import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appearance)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DropdownButtonFormField<AppThemeMode>(
            initialValue: settings.themeMode,
            decoration: InputDecoration(
              labelText: context.l10n.colorMode,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: SiqiIcon(SiqiGlyph.theme),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: AppThemeMode.system,
                child: Text(context.l10n.themeSystem),
              ),
              DropdownMenuItem(
                value: AppThemeMode.light,
                child: Text(context.l10n.themeLight),
              ),
              DropdownMenuItem(
                value: AppThemeMode.dark,
                child: Text(context.l10n.themeDark),
              ),
            ],
            onChanged: (value) => value == null
                ? null
                : update((current) => current.copyWith(themeMode: value)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: settings.localeCode,
            decoration: InputDecoration(
              labelText: context.l10n.language,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: SiqiIcon(SiqiGlyph.globe),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'zh',
                child: Text(context.l10n.languageZhHans),
              ),
              DropdownMenuItem(
                value: 'zh_TW',
                child: Text(context.l10n.languageZhHant),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(context.l10n.languageEnglish),
              ),
              DropdownMenuItem(
                value: 'ja',
                child: Text(context.l10n.languageJapanese),
              ),
            ],
            onChanged: (value) => value == null
                ? null
                : update((current) => current.copyWith(localeCode: value)),
          ),
          _SliderCard(
            label: context.l10n.fontScale,
            value: settings.fontScale,
            min: .8,
            max: 1.5,
            divisions: 7,
            labelFor: (value) => '${value.toStringAsFixed(1)}x',
            onChanged: (value) =>
                update((current) => current.copyWith(fontScale: value)),
          ),
          _SliderCard(
            label: context.l10n.messageSpacing,
            value: settings.messageSpacing,
            min: 2,
            max: 20,
            divisions: 18,
            labelFor: (value) => '${value.round()} px',
            onChanged: (value) =>
                update((current) => current.copyWith(messageSpacing: value)),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<TimestampStyle>(
            initialValue: settings.timestampStyle,
            decoration: InputDecoration(
              labelText: context.l10n.timestampFormat,
            ),
            items: [
              DropdownMenuItem(
                value: TimestampStyle.relative,
                child: Text(context.l10n.timeRelative),
              ),
              DropdownMenuItem(
                value: TimestampStyle.twentyFourHour,
                child: Text(context.l10n.time24),
              ),
              DropdownMenuItem(
                value: TimestampStyle.twelveHour,
                child: Text(context.l10n.time12),
              ),
            ],
            onChanged: (value) => value == null
                ? null
                : update((current) => current.copyWith(timestampStyle: value)),
          ),
        ],
      ),
    );
  }
}

class _SliderCard extends StatefulWidget {
  const _SliderCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelFor,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) labelFor;
  final ValueChanged<double> onChanged;

  @override
  State<_SliderCard> createState() => _SliderCardState();
}

class _SliderCardState extends State<_SliderCard> {
  late double _value = widget.value;

  @override
  void didUpdateWidget(covariant _SliderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label)),
              Text(
                widget.labelFor(_value),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          Slider(
            value: _value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: widget.labelFor(_value),
            onChanged: (value) => setState(() => _value = value),
            onChangeEnd: widget.onChanged,
          ),
        ],
      ),
    ),
  );
}
