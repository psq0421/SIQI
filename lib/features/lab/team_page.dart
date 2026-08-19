import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/icons/siqi_icons.dart';
import '../../core/models/app_models.dart';
import '../../core/models/workbench_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/siqi_design.dart';
import '../../l10n/l10n.dart';

class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage> {
  final _task = TextEditingController();
  List<AiTeam> _teams = const [];
  List<AiTeamMessage> _messages = const [];
  AiTeam? _selected;
  DioException? _dioError;
  Object? _error;
  bool _loading = true;
  bool _running = false;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('page-disposed');
    _task.dispose();
    super.dispose();
  }

  Future<void> _load({String? selectId}) async {
    final teams = await ref.read(localDatabaseProvider).listAiTeams();
    AiTeam? selected;
    final wanted = selectId ?? _selected?.id;
    for (final team in teams) {
      if (team.id == wanted) selected = team;
    }
    selected ??= teams.isEmpty ? null : teams.first;
    final messages = selected == null
        ? const <AiTeamMessage>[]
        : await ref.read(localDatabaseProvider).listAiTeamMessages(selected.id);
    if (!mounted) return;
    setState(() {
      _teams = teams;
      _selected = selected;
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _select(AiTeam team) async {
    final messages = await ref
        .read(localDatabaseProvider)
        .listAiTeamMessages(team.id);
    if (!mounted) return;
    setState(() {
      _selected = team;
      _messages = messages;
      _error = null;
      _dioError = null;
    });
  }

  Future<void> _editTeam(List<ApiProfile> profiles, [AiTeam? team]) async {
    final draft = await showDialog<_TeamDraft>(
      context: context,
      builder: (context) =>
          _TeamEditorDialog(profiles: profiles, initial: team),
    );
    if (draft == null) return;
    final now = DateTime.now();
    final saved = AiTeam(
      id: team?.id ?? const Uuid().v4(),
      name: draft.name,
      memberProfileIds: draft.profileIds.take(8).toList(),
      maxRounds: draft.rounds,
      createdAt: team?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(localDatabaseProvider).saveAiTeam(saved);
    await _load(selectId: saved.id);
  }

  Future<void> _deleteTeam() async {
    final team = _selected;
    if (team == null || _running) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteAiTeam),
        content: Text(context.l10n.deleteAiTeamBody(team.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(localDatabaseProvider).deleteAiTeam(team.id);
    await _load();
  }

  Future<void> _clearMessages() async {
    final team = _selected;
    if (team == null || _running) return;
    await ref.read(localDatabaseProvider).clearAiTeamMessages(team.id);
    if (mounted) setState(() => _messages = const []);
  }

  Future<void> _run(List<ApiProfile> profiles) async {
    final team = _selected;
    final task = _task.text.trim();
    if (team == null || task.isEmpty || _running) return;
    final token = CancelToken();
    setState(() {
      _running = true;
      _cancelToken = token;
      _error = null;
      _dioError = null;
    });
    try {
      await ref
          .read(aiTeamServiceProvider)
          .run(
            team: team,
            availableProfiles: profiles,
            task: task,
            settings: ref.read(settingsProvider),
            cancelToken: token,
            onMessage: (message) {
              if (!mounted) return;
              setState(() => _messages = [..._messages, message]);
            },
          );
      _task.clear();
      ref.invalidate(apiProfilesProvider);
    } on DioException catch (error) {
      if (mounted) setState(() => _dioError = error);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _cancelToken = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesState = ref.watch(apiProfilesProvider);
    final profiles = profilesState.valueOrNull ?? const <ApiProfile>[];
    final tested = profiles
        .where((profile) => profile.lastTestedAt != null)
        .toList(growable: false);
    final profilesById = {for (final profile in profiles) profile.id: profile};
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.aiTeamMode),
        actions: [
          IconButton(
            tooltip: context.l10n.newAiTeam,
            onPressed: tested.isEmpty ? null : () => _editTeam(tested),
            icon: const SiqiIcon(SiqiGlyph.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tested.isEmpty
          ? SiqiEmptyState(
              title: context.l10n.aiTeamNeedsProfiles,
              body: context.l10n.aiTeamNeedsProfilesDescription,
              glyph: SiqiGlyph.key,
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SiqiIcon(SiqiGlyph.queue),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.l10n.aiTeamNotice)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_teams.isEmpty)
                  SiqiEmptyState(
                    title: context.l10n.noAiTeams,
                    body: context.l10n.noAiTeamsDescription,
                    glyph: SiqiGlyph.queue,
                    action: FilledButton.icon(
                      onPressed: () => _editTeam(tested),
                      icon: const SiqiIcon(SiqiGlyph.add),
                      label: Text(context.l10n.newAiTeam),
                    ),
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selected?.id,
                            decoration: InputDecoration(
                              labelText: context.l10n.activeAiTeam,
                            ),
                            items: [
                              for (final team in _teams)
                                DropdownMenuItem(
                                  value: team.id,
                                  child: Text(team.name),
                                ),
                            ],
                            onChanged: _running
                                ? null
                                : (id) {
                                    for (final team in _teams) {
                                      if (team.id == id) _select(team);
                                    }
                                  },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final id
                                  in _selected?.memberProfileIds ??
                                      const <String>[])
                                Chip(
                                  avatar: const SiqiIcon(
                                    SiqiGlyph.agent,
                                    size: 16,
                                  ),
                                  label: Text(profilesById[id]?.name ?? id),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _running
                                    ? null
                                    : () => _editTeam(tested, _selected),
                                child: Text(context.l10n.edit),
                              ),
                              TextButton(
                                onPressed: _running ? null : _deleteTeam,
                                child: Text(context.l10n.delete),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _task,
                    minLines: 3,
                    maxLines: 8,
                    enabled: !_running,
                    decoration: InputDecoration(
                      labelText: context.l10n.aiTeamTask,
                      hintText: context.l10n.aiTeamTaskHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _running
                        ? FilledButton.icon(
                            onPressed: () =>
                                _cancelToken?.cancel('user-cancelled'),
                            icon: const SiqiIcon(SiqiGlyph.stop),
                            label: Text(context.l10n.stop),
                          )
                        : FilledButton.icon(
                            onPressed: _selected == null
                                ? null
                                : () => _run(profiles),
                            icon: const SiqiIcon(SiqiGlyph.play),
                            label: Text(context.l10n.startCollaboration),
                          ),
                  ),
                  if (_error != null || _dioError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      (_error ?? _dioError).toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.teamTranscript,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: _messages.isEmpty || _running
                            ? null
                            : _clearMessages,
                        child: Text(context.l10n.clearHistory),
                      ),
                    ],
                  ),
                  if (_messages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.noTeamMessages,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final message in _messages)
                      _TeamMessageCard(
                        message: message,
                        profileName:
                            profilesById[message.profileId]?.name ??
                            message.profileId,
                      ),
                ],
              ],
            ),
    );
  }
}

class _TeamMessageCard extends StatelessWidget {
  const _TeamMessageCard({required this.message, required this.profileName});

  final AiTeamMessage message;
  final String profileName;

  @override
  Widget build(BuildContext context) => Card(
    color: message.role == 'final'
        ? Theme.of(context).colorScheme.primaryContainer
        : null,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SiqiIcon(
                message.role == 'final' ? SiqiGlyph.check : SiqiGlyph.agent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.role == 'final'
                      ? context.l10n.teamFinalAnswer
                      : context.l10n.teamMemberRound(
                          profileName,
                          message.roundIndex + 1,
                        ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(message.content),
        ],
      ),
    ),
  );
}

class _TeamDraft {
  const _TeamDraft(this.name, this.profileIds, this.rounds);

  final String name;
  final List<String> profileIds;
  final int rounds;
}

class _TeamEditorDialog extends StatefulWidget {
  const _TeamEditorDialog({required this.profiles, this.initial});

  final List<ApiProfile> profiles;
  final AiTeam? initial;

  @override
  State<_TeamEditorDialog> createState() => _TeamEditorDialogState();
}

class _TeamEditorDialogState extends State<_TeamEditorDialog> {
  late final TextEditingController _name;
  late final Set<String> _selected;
  late int _rounds;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _selected = {...?widget.initial?.memberProfileIds};
    _rounds = widget.initial?.maxRounds ?? 2;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initial == null ? context.l10n.newAiTeam : context.l10n.editAiTeam,
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: context.l10n.aiTeamName),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.aiTeamMembers(_selected.length)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final profile in widget.profiles)
                  FilterChip(
                    label: Text(profile.name),
                    selected: _selected.contains(profile.id),
                    onSelected: (selected) {
                      if (selected && _selected.length >= 8) return;
                      setState(() {
                        selected
                            ? _selected.add(profile.id)
                            : _selected.remove(profile.id);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.l10n.collaborationRounds(_rounds)),
            Slider(
              value: _rounds.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              label: '$_rounds',
              onChanged: (value) => setState(() => _rounds = value.round()),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: _name.text.trim().isEmpty || _selected.isEmpty
            ? null
            : () => Navigator.pop(
                context,
                _TeamDraft(
                  _name.text.trim(),
                  _selected.take(8).toList(),
                  _rounds,
                ),
              ),
        child: Text(context.l10n.save),
      ),
    ],
  );
}
