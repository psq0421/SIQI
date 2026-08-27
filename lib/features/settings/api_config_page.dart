import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';

class ApiConfigPage extends ConsumerWidget {
  const ApiConfigPage({this.initialProviderId, super.key});
  final String? initialProviderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(apiProfilesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.apiProfiles),
        actions: [
          IconButton(
            tooltip: context.l10n.addProfile,
            onPressed: () =>
                _edit(context, ref, initialProviderId: initialProviderId),
            icon: const SiqiIcon(SiqiGlyph.add),
          ),
        ],
      ),
      body: profiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(context.l10n.error)),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SiqiIcon(SiqiGlyph.key, size: 52),
                    const SizedBox(height: 12),
                    Text(context.l10n.noProfiles),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _edit(
                        context,
                        ref,
                        initialProviderId: initialProviderId,
                      ),
                      icon: const SiqiIcon(SiqiGlyph.add),
                      label: Text(context.l10n.addProfile),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final profile = items[index];
                  return Card(
                    child: ListTile(
                      onTap: () => _edit(context, ref, profile: profile),
                      leading: SiqiIcon(
                        profile.isMultimodal ? SiqiGlyph.image : SiqiGlyph.key,
                      ),
                      title: Text(profile.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.modelId),
                          Text(
                            context.l10n.configuredModelCount(
                              profile.selectableModels.length,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.lastTestedAt == null
                                ? context.l10n.neverTested
                                : context.l10n.lastTested(
                                    DateFormat.yMd(
                                      Localizations.localeOf(
                                        context,
                                      ).toLanguageTag(),
                                    ).add_Hm().format(profile.lastTestedAt!),
                                  ),
                          ),
                          Text(
                            '${context.l10n.inputTokens}: ${profile.inputTokens} · ${context.l10n.outputTokens}: ${profile.outputTokens} · ${context.l10n.estimatedCost}: ${profile.estimatedCost.toStringAsFixed(4)}',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: const SiqiIcon(
                        SiqiGlyph.chevronRight,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _edit(context, ref, initialProviderId: initialProviderId),
        icon: const SiqiIcon(SiqiGlyph.add),
        label: Text(context.l10n.addProfile),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    ApiProfile? profile,
    String? initialProviderId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ApiProfileEditor(
        profile: profile,
        initialProviderId: initialProviderId,
      ),
    );
    ref.invalidate(apiProfilesProvider);
    await ref.read(chatProvider.notifier).refreshProfiles();
  }
}

class _ApiProfileEditor extends ConsumerStatefulWidget {
  const _ApiProfileEditor({required this.profile, this.initialProviderId});
  final ApiProfile? profile;
  final String? initialProviderId;
  @override
  ConsumerState<_ApiProfileEditor> createState() => _ApiProfileEditorState();
}

class _ApiProfileEditorState extends ConsumerState<_ApiProfileEditor> {
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _notes;
  late final TextEditingController _currency;
  late final TextEditingController _inputPrice;
  late final TextEditingController _outputPrice;
  late String _templateId;
  late ApiFormat _format;
  late bool _multimodal;
  bool _testing = false;
  bool _fetchingModels = false;
  late List<String> _availableModels;
  late Set<String> _selectedModels;
  late Set<String> _reasoningModels;
  String? _fallbackModel;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile?.name ?? '');
    final initialTemplate = ProviderTemplates.values.firstWhere(
      (item) => item.id == widget.initialProviderId,
      orElse: () => ProviderTemplates.values.first,
    );
    _baseUrl = TextEditingController(
      text: profile?.baseUrl ?? initialTemplate.baseUrl,
    );
    _apiKey = TextEditingController();
    _notes = TextEditingController(text: profile?.notes ?? '');
    _availableModels = profile?.selectableModels.values.toSet().toList() ?? [];
    _selectedModels = {..._availableModels};
    _reasoningModels = {...?profile?.reasoningModelIds};
    _fallbackModel = profile?.defaultModelId;
    _currency = TextEditingController(text: profile?.billingCurrency ?? '');
    _inputPrice = TextEditingController(
      text: profile?.inputPricePerMillion?.toString() ?? '',
    );
    _outputPrice = TextEditingController(
      text: profile?.outputPricePerMillion?.toString() ?? '',
    );
    _templateId = profile?.providerId ?? initialTemplate.id;
    _format = profile?.format ?? initialTemplate.format;
    _multimodal = profile?.isMultimodal ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _notes.dispose();
    _currency.dispose();
    _inputPrice.dispose();
    _outputPrice.dispose();
    super.dispose();
  }

  void _applyTemplate(String id) {
    final template = ProviderTemplates.values.firstWhere(
      (item) => item.id == id,
    );
    setState(() {
      _templateId = id;
      _format = template.format;
      if (template.baseUrl.isNotEmpty) _baseUrl.text = template.baseUrl;
      if (_name.text.trim().isEmpty) _name.text = template.name;
    });
  }

  double? _optionalPrice(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : double.tryParse(value);
  }

  ApiProfile? _build({DateTime? testedAt}) {
    final fallback = _fallbackModel;
    final inputPrice = _optionalPrice(_inputPrice);
    final outputPrice = _optionalPrice(_outputPrice);
    if ((_inputPrice.text.trim().isNotEmpty && inputPrice == null) ||
        (_outputPrice.text.trim().isNotEmpty && outputPrice == null)) {
      setState(() => _error = context.l10n.requiredField);
      return null;
    }
    if (_name.text.trim().isEmpty ||
        _baseUrl.text.trim().isEmpty ||
        fallback == null ||
        _selectedModels.isEmpty) {
      setState(() => _error = context.l10n.requiredField);
      return null;
    }
    final existing = widget.profile;
    return ApiProfile(
      id: existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      providerId: _templateId,
      baseUrl: _baseUrl.text.trim(),
      modelId: fallback,
      format: _format,
      isMultimodal: _multimodal,
      notes: _notes.text.trim(),
      modelMappings: {for (final model in _selectedModels) model: model},
      reasoningModelIds: _reasoningModels.intersection(_selectedModels),
      fallbackModelId: fallback,
      billingCurrency: _currency.text.trim(),
      inputPricePerMillion: inputPrice,
      outputPricePerMillion: outputPrice,
      lastTestedAt: testedAt ?? existing?.lastTestedAt,
      inputTokens: existing?.inputTokens ?? 0,
      outputTokens: existing?.outputTokens ?? 0,
      estimatedCost: existing?.estimatedCost ?? 0,
    );
  }

  Future<String> _apiKeyForRequest() async {
    if (_apiKey.text.trim().isNotEmpty) return _apiKey.text.trim();
    final existing = widget.profile;
    if (existing == null) return '';
    return await ref.read(secureKeyServiceProvider).readApiKey(existing.id) ??
        '';
  }

  Future<void> _fetchModels() async {
    if (_baseUrl.text.trim().isEmpty) {
      setState(() => _error = context.l10n.requiredField);
      return;
    }
    setState(() {
      _fetchingModels = true;
      _error = null;
    });
    try {
      final models = await ref
          .read(apiServiceProvider)
          .fetchModels(
            baseUrl: _baseUrl.text.trim(),
            format: _format,
            apiKey: await _apiKeyForRequest(),
          );
      if (!mounted) return;
      setState(() {
        _availableModels = models;
        _selectedModels = {...models};
        _reasoningModels = models.where(_looksLikeReasoningModel).toSet();
        _fallbackModel = models.contains(_fallbackModel)
            ? _fallbackModel
            : models.first;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.modelsFetched(models.length))),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = context.l10n.testFailed(error.toString()));
      }
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  Future<void> _save() async {
    final profile = _build();
    if (profile == null) return;
    await ref.read(localDatabaseProvider).saveApiProfile(profile);
    if (_apiKey.text.trim().isNotEmpty) {
      await ref
          .read(secureKeyServiceProvider)
          .writeApiKey(profile.id, _apiKey.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _test() async {
    var profile = _build();
    if (profile == null) return;
    setState(() {
      _testing = true;
      _error = null;
    });
    try {
      final existingKey = widget.profile == null
          ? null
          : await ref
                .read(secureKeyServiceProvider)
                .readApiKey(widget.profile!.id);
      final key = _apiKey.text.trim().isEmpty
          ? existingKey ?? ''
          : _apiKey.text.trim();
      await ref.read(apiServiceProvider).testProfile(profile, key);
      profile = ApiProfile(
        id: profile.id,
        name: profile.name,
        providerId: profile.providerId,
        baseUrl: profile.baseUrl,
        modelId: profile.modelId,
        format: profile.format,
        isMultimodal: profile.isMultimodal,
        notes: profile.notes,
        modelMappings: profile.modelMappings,
        reasoningModelIds: profile.reasoningModelIds,
        fallbackModelId: profile.fallbackModelId,
        billingCurrency: profile.billingCurrency,
        inputPricePerMillion: profile.inputPricePerMillion,
        outputPricePerMillion: profile.outputPricePerMillion,
        lastTestedAt: DateTime.now(),
        inputTokens: profile.inputTokens,
        outputTokens: profile.outputTokens,
        estimatedCost: profile.estimatedCost,
      );
      await ref.read(localDatabaseProvider).saveApiProfile(profile);
      if (_apiKey.text.trim().isNotEmpty) {
        await ref
            .read(secureKeyServiceProvider)
            .writeApiKey(profile.id, _apiKey.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.testSuccess)));
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = context.l10n.testFailed(error.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _delete() async {
    final profile = widget.profile;
    if (profile == null) return;
    await ref.read(localDatabaseProvider).deleteApiProfile(profile.id);
    await ref.read(secureKeyServiceProvider).deleteApiKey(profile.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(SiqiRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.profile == null
                    ? context.l10n.addProfile
                    : widget.profile!.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _templateId,
                decoration: InputDecoration(
                  labelText: context.l10n.providerTemplate,
                ),
                items: ProviderTemplates.values
                    .map(
                      (template) => DropdownMenuItem(
                        value: template.id,
                        child: Text(template.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    value == null ? null : _applyTemplate(value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: context.l10n.customName),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                decoration: InputDecoration(
                  labelText: context.l10n.providerNotes,
                  hintText: context.l10n.providerNotesHint,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _baseUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: context.l10n.baseUrl),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apiKey,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.l10n.apiKey,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: SiqiIcon(SiqiGlyph.key),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<ApiFormat>(
                segments: [
                  ButtonSegment(
                    value: ApiFormat.openAi,
                    label: Text(context.l10n.protocolOpenAi),
                  ),
                  ButtonSegment(
                    value: ApiFormat.anthropic,
                    label: Text(context.l10n.protocolAnthropic),
                  ),
                ],
                selected: {_format},
                onSelectionChanged: (value) =>
                    setState(() => _format = value.first),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _fetchingModels ? null : _fetchModels,
                icon: _fetchingModels
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SiqiIcon(SiqiGlyph.refresh),
                label: Text(
                  _fetchingModels
                      ? context.l10n.fetchingModels
                      : context.l10n.fetchModels,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.modelListFromBaseUrl,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_availableModels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  context.l10n.selectModels,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final model in _availableModels)
                      FilterChip(
                        label: Text(model),
                        selected: _selectedModels.contains(model),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedModels.add(model);
                            _fallbackModel ??= model;
                          } else if (_selectedModels.length > 1) {
                            _selectedModels.remove(model);
                            if (_fallbackModel == model) {
                              _fallbackModel = _selectedModels.first;
                            }
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.reasoningCapableModels,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final model in _selectedModels)
                      FilterChip(
                        label: Text(model),
                        selected: _reasoningModels.contains(model),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _reasoningModels.add(model);
                          } else {
                            _reasoningModels.remove(model);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(_fallbackModel),
                  initialValue: _selectedModels.contains(_fallbackModel)
                      ? _fallbackModel
                      : null,
                  decoration: InputDecoration(
                    labelText: context.l10n.fallbackModel,
                  ),
                  items: _selectedModels
                      .map(
                        (model) => DropdownMenuItem(
                          value: model,
                          child: Text(model, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _fallbackModel = value),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _multimodal,
                onChanged: (value) => setState(() => _multimodal = value),
                title: Text(context.l10n.multimodal),
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(context.l10n.billingConfiguration),
                children: [
                  TextField(
                    controller: _currency,
                    decoration: InputDecoration(
                      labelText: context.l10n.billingCurrency,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.l10n.inputPricePerMillion,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _outputPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.l10n.outputPricePerMillion,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SiqiIcon(SiqiGlyph.refresh),
                      label: Text(
                        _testing
                            ? context.l10n.testing
                            : context.l10n.testConnection,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const SiqiIcon(SiqiGlyph.check),
                      label: Text(context.l10n.save),
                    ),
                  ),
                ],
              ),
              if (widget.profile != null)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const SiqiIcon(SiqiGlyph.close),
                  label: Text(context.l10n.deleteProfile),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _looksLikeReasoningModel(String modelId) {
  final id = modelId.toLowerCase();
  return id.contains('reason') ||
      id.contains('thinking') ||
      id.contains('deepseek-r1') ||
      id.contains('deepseek-reasoner') ||
      id.contains('qwq') ||
      RegExp(r'(^|[-_/])o[134]([-.]|$)').hasMatch(id);
}
