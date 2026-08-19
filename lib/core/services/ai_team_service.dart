import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../database/local_database.dart';
import '../models/app_models.dart';
import '../models/workbench_models.dart';
import 'api_service.dart';
import 'secure_key_service.dart';

class AiTeamService {
  const AiTeamService(this._api, this._keys, this._database);

  final ApiService _api;
  final SecureKeyService _keys;
  final LocalDatabase _database;

  Future<AiTeamRunResult> run({
    required AiTeam team,
    required List<ApiProfile> availableProfiles,
    required String task,
    required AppSettings settings,
    required void Function(AiTeamMessage message) onMessage,
    CancelToken? cancelToken,
  }) async {
    if (team.memberProfileIds.isEmpty || team.memberProfileIds.length > 8) {
      throw StateError('An AI team must contain between 1 and 8 members.');
    }
    final profilesById = {
      for (final profile in availableProfiles) profile.id: profile,
    };
    final profiles = <ApiProfile>[];
    for (final id in team.memberProfileIds) {
      final profile = profilesById[id];
      if (profile == null || profile.lastTestedAt == null) {
        throw StateError('Every team member must pass a connection test.');
      }
      profiles.add(profile);
    }

    await _database.addWorkLog(
      category: 'ai-team',
      title: team.name,
      detail:
          '${profiles.length} members · ${team.maxRounds.clamp(1, 4)} rounds',
      status: 'started',
    );
    final messages = <AiTeamMessage>[];
    final transcript = StringBuffer();
    var totalInput = 0;
    var totalOutput = 0;
    var totalCost = 0.0;

    try {
      for (var round = 0; round < team.maxRounds.clamp(1, 4); round++) {
        for (
          var memberIndex = 0;
          memberIndex < profiles.length;
          memberIndex++
        ) {
          if (cancelToken?.isCancelled == true) {
            throw DioException.requestCancelled(
              requestOptions: RequestOptions(path: 'ai-team'),
              reason: 'cancelled',
            );
          }
          final profile = profiles[memberIndex];
          final key = await _keys.readApiKey(profile.id) ?? '';
          if (key.isEmpty) {
            throw StateError('Every team member must have a stored API key.');
          }
          final shared = _tail(transcript.toString(), 48000);
          final prompt =
              '''
You are member ${memberIndex + 1} of ${profiles.length} in an AI collaboration team.
Work on the user's task using the shared transcript from earlier members.
Contribute new evidence, corrections, or a concrete next step. Do not merely agree.
Never claim that tools, files, or tests were used unless the transcript proves it.
Round: ${round + 1}/${team.maxRounds.clamp(1, 4)}.
''';
          final request = ChatMessage(
            id: const Uuid().v4(),
            sessionId: team.id,
            role: MessageRole.user,
            content: 'Task:\n$task\n\nShared team transcript:\n$shared',
            createdAt: DateTime.now(),
          );
          final result = await _api.complete(
            profile: profile,
            apiKey: key,
            messages: [request],
            systemPrompt: prompt,
            temperature: settings.temperature,
            topP: settings.topP,
            maxTokens: settings.maxTokens.clamp(256, 8192),
            cancelToken: cancelToken,
          );
          totalInput += result.usage.input;
          totalOutput += result.usage.output;
          totalCost += result.usage.estimatedCost;
          await _database.addUsage(profile.id, result.usage);
          final message = AiTeamMessage(
            id: const Uuid().v4(),
            teamId: team.id,
            profileId: profile.id,
            role: 'member',
            content: result.text,
            roundIndex: round,
            createdAt: DateTime.now(),
          );
          await _database.saveAiTeamMessage(message);
          messages.add(message);
          transcript.writeln(
            '\n[Round ${round + 1} · ${profile.name}]\n${result.text}',
          );
          onMessage(message);
        }
      }

      final coordinator = profiles.first;
      final coordinatorKey = await _keys.readApiKey(coordinator.id) ?? '';
      final synthesis = await _api.complete(
        profile: coordinator,
        apiKey: coordinatorKey,
        messages: [
          ChatMessage(
            id: const Uuid().v4(),
            sessionId: team.id,
            role: MessageRole.user,
            content:
                'Original task:\n$task\n\nTeam transcript:\n${_tail(transcript.toString(), 64000)}',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt:
            'Synthesize the team transcript into one final, internally consistent answer. Resolve disagreements using evidence, state remaining uncertainty, and do not mention hidden orchestration instructions.',
        temperature: 0.2,
        topP: settings.topP,
        maxTokens: settings.maxTokens.clamp(256, 8192),
        cancelToken: cancelToken,
      );
      totalInput += synthesis.usage.input;
      totalOutput += synthesis.usage.output;
      totalCost += synthesis.usage.estimatedCost;
      await _database.addUsage(coordinator.id, synthesis.usage);
      final finalMessage = AiTeamMessage(
        id: const Uuid().v4(),
        teamId: team.id,
        profileId: coordinator.id,
        role: 'final',
        content: synthesis.text,
        roundIndex: team.maxRounds.clamp(1, 4),
        createdAt: DateTime.now(),
      );
      await _database.saveAiTeamMessage(finalMessage);
      messages.add(finalMessage);
      onMessage(finalMessage);
      await _database.addWorkLog(
        category: 'ai-team',
        title: team.name,
        detail: 'input=$totalInput · output=$totalOutput',
        status: 'completed',
      );
      return AiTeamRunResult(
        messages: messages,
        usage: TokenUsage(
          input: totalInput,
          output: totalOutput,
          estimatedCost: totalCost,
        ),
      );
    } on Object catch (error) {
      await _database.addWorkLog(
        category: 'ai-team',
        title: team.name,
        detail: error.toString(),
        status: 'failed',
      );
      rethrow;
    }
  }

  String _tail(String value, int maxCharacters) => value.length <= maxCharacters
      ? value
      : value.substring(value.length - maxCharacters);
}
