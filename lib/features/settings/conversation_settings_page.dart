import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class ConversationSettingsPage extends ConsumerStatefulWidget {
  const ConversationSettingsPage({super.key});

  @override
  ConsumerState<ConversationSettingsPage> createState() =>
      _ConversationSettingsPageState();
}

class _ConversationSettingsPageState
    extends ConsumerState<ConversationSettingsPage> {
  late final TextEditingController _systemPrompt;
  Timer? _saveTimer;

  static const _contextOptions = <int>[
    2048,
    4096,
    8192,
    16384,
    32768,
    65536,
    131072,
    262144,
  ];
  static const _outputOptions = <int>[
    256,
    512,
    1024,
    2048,
    4096,
    8192,
    16384,
    32768,
    65536,
    131072,
    262144,
  ];

  @override
  void initState() {
    super.initState();
    _systemPrompt = TextEditingController(
      text: ref.read(settingsProvider).systemPrompt,
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _systemPrompt.dispose();
    super.dispose();
  }

  void _schedulePromptSave(String value) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), () {
      ref
          .read(settingsProvider.notifier)
          .update((current) => current.copyWith(systemPrompt: value));
    });
  }

  String _tokensLabel(int value) =>
      value >= 1024 ? '${value ~/ 1024}K' : value.toString();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.conversationReasoning)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _contextOptions.contains(settings.contextWindow)
                ? settings.contextWindow
                : 32768,
            decoration: InputDecoration(
              labelText: context.l10n.contextWindow,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: SiqiIcon(SiqiGlyph.memory),
              ),
            ),
            items: _contextOptions
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_tokensLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => value == null
                ? null
                : update((current) => current.copyWith(contextWindow: value)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _outputOptions.contains(settings.maxTokens)
                ? settings.maxTokens
                : 4096,
            decoration: InputDecoration(
              labelText: context.l10n.maxTokens,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: SiqiIcon(SiqiGlyph.tokens),
              ),
            ),
            items: _outputOptions
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_tokensLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => value == null
                ? null
                : update((current) => current.copyWith(maxTokens: value)),
          ),
          const SizedBox(height: 12),
          _DeferredSlider(
            label: context.l10n.temperature,
            value: settings.temperature,
            min: 0,
            max: 2,
            divisions: 20,
            valueLabel: (value) => value.toStringAsFixed(1),
            onCommit: (value) =>
                update((current) => current.copyWith(temperature: value)),
          ),
          _DeferredSlider(
            label: context.l10n.topP,
            value: settings.topP,
            min: .1,
            max: 1,
            divisions: 9,
            valueLabel: (value) => value.toStringAsFixed(1),
            onCommit: (value) =>
                update((current) => current.copyWith(topP: value)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _systemPrompt,
            minLines: 4,
            maxLines: 10,
            onChanged: _schedulePromptSave,
            decoration: InputDecoration(
              labelText: context.l10n.systemPrompt,
              helperText: context.l10n.variablesHint,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.streamResponses,
                  onChanged: (value) => update(
                    (current) => current.copyWith(streamResponses: value),
                  ),
                  secondary: const SiqiIcon(SiqiGlyph.tokens),
                  title: Text(context.l10n.streamResponses),
                  subtitle: Text(context.l10n.streamResponsesDescription),
                ),
                SwitchListTile(
                  value: settings.showTokenCounter,
                  onChanged: (value) => update(
                    (current) => current.copyWith(showTokenCounter: value),
                  ),
                  secondary: const SiqiIcon(SiqiGlyph.cost),
                  title: Text(context.l10n.showTokenCounter),
                ),
                SwitchListTile(
                  value: settings.autoTitleSessions,
                  onChanged: (value) => update(
                    (current) => current.copyWith(autoTitleSessions: value),
                  ),
                  secondary: const SiqiIcon(SiqiGlyph.chat),
                  title: Text(context.l10n.autoTitleSessions),
                ),
                SwitchListTile(
                  value: settings.confirmAgentWrites,
                  onChanged: (value) => update(
                    (current) => current.copyWith(confirmAgentWrites: value),
                  ),
                  secondary: const SiqiIcon(SiqiGlyph.shield),
                  title: Text(context.l10n.confirmAgentWrites),
                  subtitle: Text(context.l10n.confirmAgentWritesDescription),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeferredSlider extends StatefulWidget {
  const _DeferredSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onCommit,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) valueLabel;
  final ValueChanged<double> onCommit;

  @override
  State<_DeferredSlider> createState() => _DeferredSliderState();
}

class _DeferredSliderState extends State<_DeferredSlider> {
  late double _value = widget.value;

  @override
  void didUpdateWidget(covariant _DeferredSlider oldWidget) {
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
                widget.valueLabel(_value),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          Slider(
            value: _value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: widget.valueLabel(_value),
            onChanged: (value) => setState(() => _value = value),
            onChangeEnd: widget.onCommit,
          ),
        ],
      ),
    ),
  );
}
