import 'dart:convert';

import 'app_models.dart';

enum ScanSeverity { info, warning, error }

enum AgentStepStatus { pending, running, completed, failed, skipped }

enum AgentActionType {
  listFiles,
  readFile,
  writeFile,
  createDirectory,
  runCommand,
}

enum ShellQueueStatus { queued, running, completed, failed, cancelled }

class HarnessPlugin {
  const HarnessPlugin({
    required this.repositoryId,
    required this.name,
    required this.owner,
    required this.description,
    required this.category,
    required this.kind,
    required this.repositoryUrl,
    required this.detailUrl,
    required this.stars,
    required this.updatedLabel,
    required this.syncedAt,
    this.archivePath,
    this.commitSha,
    this.license,
  });

  final String repositoryId;
  final String name;
  final String owner;
  final String description;
  final String category;
  final String kind;
  final String repositoryUrl;
  final String detailUrl;
  final String stars;
  final String updatedLabel;
  final DateTime syncedAt;
  final String? archivePath;
  final String? commitSha;
  final String? license;

  bool get downloaded => archivePath?.isNotEmpty == true;

  Map<String, Object?> toDatabase() => {
    'repository_id': repositoryId,
    'name': name,
    'owner': owner,
    'description': description,
    'category': category,
    'kind': kind,
    'repository_url': repositoryUrl,
    'detail_url': detailUrl,
    'stars': stars,
    'updated_label': updatedLabel,
    'synced_at': syncedAt.millisecondsSinceEpoch,
    'archive_path': archivePath,
    'commit_sha': commitSha,
    'license': license,
  };

  factory HarnessPlugin.fromDatabase(Map<String, Object?> map) => HarnessPlugin(
    repositoryId: map['repository_id']! as String,
    name: map['name']! as String,
    owner: map['owner']! as String,
    description: map['description']! as String,
    category: map['category']! as String,
    kind: map['kind']! as String,
    repositoryUrl: map['repository_url']! as String,
    detailUrl: map['detail_url']! as String,
    stars: map['stars']! as String,
    updatedLabel: map['updated_label']! as String,
    syncedAt: DateTime.fromMillisecondsSinceEpoch(map['synced_at']! as int),
    archivePath: map['archive_path'] as String?,
    commitSha: map['commit_sha'] as String?,
    license: map['license'] as String?,
  );
}

class PluginSyncState {
  const PluginSyncState({
    this.running = false,
    this.completedPages = 0,
    this.totalPages = 0,
    this.totalPlugins = 0,
    this.error,
  });
  final bool running;
  final int completedPages;
  final int totalPages;
  final int totalPlugins;
  final String? error;

  double get progress => totalPages == 0 ? 0 : completedPages / totalPages;
}

class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    required this.rootPath,
    required this.files,
    required this.directories,
    required this.totalBytes,
    required this.languages,
  });
  final String rootPath;
  final List<String> files;
  final List<String> directories;
  final int totalBytes;
  final Map<String, int> languages;

  String get primaryLanguage => languages.entries.isEmpty
      ? 'Unknown'
      : (languages.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
}

class ScanIssue {
  const ScanIssue({
    required this.ruleId,
    required this.severity,
    required this.filePath,
    required this.line,
    required this.messageKey,
    this.evidence,
  });
  final String ruleId;
  final ScanSeverity severity;
  final String filePath;
  final int line;
  final String messageKey;
  final String? evidence;
}

class HarnessReport {
  const HarnessReport({
    required this.generatedAt,
    required this.snapshot,
    required this.issues,
    required this.scannedFiles,
    required this.testDrafts,
  });
  final DateTime generatedAt;
  final WorkspaceSnapshot snapshot;
  final List<ScanIssue> issues;
  final int scannedFiles;
  final Map<String, String> testDrafts;

  int count(ScanSeverity severity) =>
      issues.where((issue) => issue.severity == severity).length;
}

class AgentStep {
  const AgentStep({
    required this.id,
    required this.title,
    required this.description,
    this.status = AgentStepStatus.pending,
    this.detail,
  });
  final String id;
  final String title;
  final String description;
  final AgentStepStatus status;
  final String? detail;

  AgentStep copyWith({AgentStepStatus? status, String? detail}) => AgentStep(
    id: id,
    title: title,
    description: description,
    status: status ?? this.status,
    detail: detail ?? this.detail,
  );
}

class AgentAction {
  const AgentAction({
    required this.id,
    required this.type,
    required this.path,
    this.content,
    this.command,
    this.reason = '',
  });
  final String id;
  final AgentActionType type;
  final String path;
  final String? content;
  final String? command;
  final String reason;

  bool get mutatesWorkspace =>
      type == AgentActionType.writeFile ||
      type == AgentActionType.createDirectory ||
      type == AgentActionType.runCommand;

  factory AgentAction.fromJson(Map<String, dynamic> json) => AgentAction(
    id:
        json['id'] as String? ??
        DateTime.now().microsecondsSinceEpoch.toString(),
    type: AgentActionType.values.byName(json['type'] as String),
    path: json['path'] as String? ?? '.',
    content: json['content'] as String?,
    command: json['command'] as String?,
    reason: json['reason'] as String? ?? '',
  );
}

class AgentEnvelope {
  const AgentEnvelope({
    required this.summary,
    required this.steps,
    required this.actions,
  });
  final String summary;
  final List<AgentStep> steps;
  final List<AgentAction> actions;

  static AgentEnvelope? tryParse(String response) {
    final match = RegExp(
      r'<siqi_actions>([\s\S]*?)</siqi_actions>',
    ).firstMatch(response);
    if (match == null) return null;
    try {
      final value = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      final steps = (value['plan'] as List? ?? const []).asMap().entries.map((
        entry,
      ) {
        final item = entry.value;
        if (item is String) {
          return AgentStep(
            id: 'step-${entry.key}',
            title: item,
            description: item,
          );
        }
        final map = Map<String, dynamic>.from(item as Map);
        return AgentStep(
          id: map['id'] as String? ?? 'step-${entry.key}',
          title: map['title'] as String? ?? '',
          description: map['description'] as String? ?? '',
        );
      }).toList();
      final actions = (value['actions'] as List? ?? const [])
          .map(
            (item) =>
                AgentAction.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      return AgentEnvelope(
        summary: value['summary'] as String? ?? '',
        steps: steps,
        actions: actions,
      );
    } on Object {
      return null;
    }
  }
}

class AgentActionResult {
  const AgentActionResult({
    required this.action,
    required this.success,
    required this.output,
    this.exitCode,
  });
  final AgentAction action;
  final bool success;
  final String output;
  final int? exitCode;
}

class McpToolDefinition {
  const McpToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
}

class McpConnectionResult {
  const McpConnectionResult({
    required this.success,
    required this.serverName,
    required this.tools,
    required this.latency,
    this.error,
  });
  final bool success;
  final String serverName;
  final List<McpToolDefinition> tools;
  final Duration latency;
  final String? error;
}

class ShellQueueItem {
  const ShellQueueItem({
    required this.id,
    required this.command,
    required this.createdAt,
    this.status = ShellQueueStatus.queued,
    this.stdout = '',
    this.stderr = '',
    this.exitCode,
  });
  final String id;
  final String command;
  final DateTime createdAt;
  final ShellQueueStatus status;
  final String stdout;
  final String stderr;
  final int? exitCode;

  ShellQueueItem copyWith({
    ShellQueueStatus? status,
    String? stdout,
    String? stderr,
    int? exitCode,
  }) => ShellQueueItem(
    id: id,
    command: command,
    createdAt: createdAt,
    status: status ?? this.status,
    stdout: stdout ?? this.stdout,
    stderr: stderr ?? this.stderr,
    exitCode: exitCode ?? this.exitCode,
  );
}

class AiTeam {
  const AiTeam({
    required this.id,
    required this.name,
    required this.memberProfileIds,
    required this.maxRounds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> memberProfileIds;
  final int maxRounds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toDatabase() => {
    'id': id,
    'name': name,
    'member_profile_ids_json': jsonEncode(memberProfileIds),
    'max_rounds': maxRounds.clamp(1, 4),
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory AiTeam.fromDatabase(Map<String, Object?> map) => AiTeam(
    id: map['id']! as String,
    name: map['name']! as String,
    memberProfileIds:
        (jsonDecode(map['member_profile_ids_json']! as String) as List)
            .cast<String>(),
    maxRounds: map['max_rounds'] as int? ?? 2,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
  );
}

class AiTeamMessage {
  const AiTeamMessage({
    required this.id,
    required this.teamId,
    required this.profileId,
    required this.role,
    required this.content,
    required this.roundIndex,
    required this.createdAt,
  });

  final String id;
  final String teamId;
  final String profileId;
  final String role;
  final String content;
  final int roundIndex;
  final DateTime createdAt;

  Map<String, Object?> toDatabase() => {
    'id': id,
    'team_id': teamId,
    'profile_id': profileId,
    'role': role,
    'content': content,
    'round_index': roundIndex,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory AiTeamMessage.fromDatabase(Map<String, Object?> map) => AiTeamMessage(
    id: map['id']! as String,
    teamId: map['team_id']! as String,
    profileId: map['profile_id']! as String,
    role: map['role']! as String,
    content: map['content']! as String,
    roundIndex: map['round_index']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
  );
}

class AiTeamRunResult {
  const AiTeamRunResult({required this.messages, required this.usage});

  final List<AiTeamMessage> messages;
  final TokenUsage usage;
}
