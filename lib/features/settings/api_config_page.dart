import 'dart:convert';

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
  late final TextEditingController _model;
  late final TextEditingController _apiKey;
  late final TextEditingController _headers;
  late String _templateId;
  late ApiFormat _format;
  late bool _multimodal;
  bool _testing = false;
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
    _model = TextEditingController(text: profile?.modelId ?? '');
    _apiKey = TextEditingController();
    _headers = TextEditingController(
      text: const JsonEncoder.withIndent(
        '  ',
      ).convert(profile?.headers ?? const <String, String>{}),
    );
    _templateId = profile?.providerId ?? initialTemplate.id;
    _format = profile?.format ?? initialTemplate.format;
    _multimodal = profile?.isMultimodal ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    _headers.dispose();
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

  Map<String, String>? _parseHeaders() {
    try {
      final value = jsonDecode(
        _headers.text.trim().isEmpty ? '{}' : _headers.text,
      );
      if (value is! Map ||
          value.keys.any((key) => key is! String) ||
          value.values.any((item) => item is! String)) {
        return null;
      }
      return value.map(
        (key, value) => MapEntry(key as String, value as String),
      );
    } on Object {
      return null;
    }
  }

  ApiProfile? _build({DateTime? testedAt}) {
    final headers = _parseHeaders();
    if (headers == null) {
      setState(() => _error = context.l10n.invalidJson);
      return null;
    }
    if (_name.text.trim().isEmpty ||
        _baseUrl.text.trim().isEmpty ||
        _model.text.trim().isEmpty) {
      setState(() => _error = context.l10n.requiredField);
      return null;
    }
    final existing = widget.profile;
    return ApiProfile(
      id: existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      providerId: _templateId,
      baseUrl: _baseUrl.text.trim(),
      modelId: _model.text.trim(),
      format: _format,
      isMultimodal: _multimodal,
      headers: headers,
      lastTestedAt: testedAt ?? existing?.lastTestedAt,
      inputTokens: existing?.inputTokens ?? 0,
      outputTokens: existing?.outputTokens ?? 0,
      estimatedCost: existing?.estimatedCost ?? 0,
    );
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
        headers: profile.headers,
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
                controller: _baseUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: context.l10n.baseUrl),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _model,
                decoration: InputDecoration(labelText: context.l10n.modelId),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _multimodal,
                onChanged: (value) => setState(() => _multimodal = value),
                title: Text(context.l10n.multimodal),
              ),
              TextField(
                controller: _headers,
                minLines: 3,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: context.l10n.customHeaders,
                  hintText: context.l10n.headersHint,
                ),
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
