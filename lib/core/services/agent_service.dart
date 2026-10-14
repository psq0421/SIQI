import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../database/local_database.dart';
import '../models/app_models.dart';
import '../models/workbench_models.dart';
import 'shell_service.dart';
import 'trace_redactor.dart';
import 'workspace_service.dart';

class AgentService {
  AgentService(this._workspace, this._shell, this._database);
  final WorkspaceService _workspace;
  final ShellService _shell;
  final LocalDatabase _database;
  String? _lastExecutionId;

  String? get lastExecutionId => _lastExecutionId;

  Future<String> beginTask({
    required String workspacePath,
    required String instruction,
    required String modelId,
    required String sessionId,
  }) async {
    final id = const Uuid().v4();
    await _database.startAgentExecution(
      id: id,
      workspacePath: workspacePath,
      summary: 'Agent request',
      inputInstruction: _redact(instruction),
      sessionId: sessionId,
    );
    await _database.appendAgentEvent(
      executionId: id,
      eventType: 'model_requested',
      payload: {'modelId': modelId, 'inputInstruction': _redact(instruction)},
    );
    return id;
  }

  Future<void> recordPlan(String id, AgentEnvelope? envelope) async {
    await _database.appendAgentEvent(
      executionId: id,
      eventType: 'model_completed',
      payload: {
        'summary': envelope == null ? null : _redact(envelope.summary),
        'plan': [
          for (final step in envelope?.steps ?? <AgentStep>[])
            {
              'id': step.id,
              'title': _redact(step.title),
              'description': _redact(step.description),
            },
        ],
        'actions': [
          for (final action in envelope?.actions ?? <AgentAction>[])
            {'id': action.id, ..._actionPayload(action)},
        ],
      },
    );
    if (envelope == null || envelope.actions.isEmpty) {
      await finishTask(id, 'completed', 'no_tool_actions');
    } else {
      await _database.setAgentExecutionStatus(id, 'awaiting_approval');
    }
  }

  Future<void> finishTask(String id, String status, String reason) async {
    await _database.appendAgentEvent(
      executionId: id,
      eventType: 'task_$status',
      payload: {'terminationReason': _redact(reason)},
    );
    await _database.completeAgentExecution(
      id,
      status,
      terminationReason: _redact(reason),
    );
  }

  List<AgentStep> createLocalPlan(String task) {
    final normalized = task.toLowerCase();
    final steps = <AgentStep>[
      const AgentStep(
        id: 'inspect',
        title: 'Inspect workspace',
        description:
            'Index relevant files, languages, and project configuration.',
      ),
      const AgentStep(
        id: 'design',
        title: 'Design bounded change',
        description:
            'Translate the request into explicit file and verification actions.',
      ),
    ];
    if (normalized.contains('bug') ||
        normalized.contains('fix') ||
        normalized.contains('修复')) {
      steps.add(
        const AgentStep(
          id: 'reproduce',
          title: 'Reproduce failure',
          description:
              'Locate the failing path and establish a minimal reproduction.',
        ),
      );
    }
    steps.add(
      const AgentStep(
        id: 'implement',
        title: 'Apply approved actions',
        description:
            'Modify only workspace-contained files after user approval.',
      ),
    );
    steps.add(
      const AgentStep(
        id: 'verify',
        title: 'Verify result',
        description:
            'Run language-appropriate analysis or build commands and summarize evidence.',
      ),
    );
    return steps;
  }

  String protocolInstruction(String rootPath) =>
      '''
The active workspace is $rootPath. When file or command actions are needed, append exactly one machine-readable block:
<siqi_actions>
{"summary":"short summary","plan":[{"id":"step-1","title":"title","description":"detail"}],"actions":[{"id":"action-1","type":"readFile|listFiles|writeFile|createDirectory|runCommand","path":"relative/path","content":"complete content when writing","command":"command when running","reason":"why"}]}
</siqi_actions>
Paths must be relative to the workspace. Never request deletion, privilege escalation, formatting, or commands outside the workspace.
''';

  Future<List<AgentActionResult>> execute({
    required String workspacePath,
    required List<AgentAction> actions,
    required ShellEnvironment shellEnvironment,
    required bool allowMutations,
    String inputInstruction = '',
    String? traceId,
  }) async {
    final results = <AgentActionResult>[];
    final executionId = traceId ?? const Uuid().v4();
    _lastExecutionId = executionId;
    final snapshottedPaths = <String>{};
    if (traceId != null) {
      final trace = await _database.agentExecution(traceId);
      if (trace == null || trace['workspace_path'] != workspacePath) {
        await finishTask(
          executionId,
          'failed',
          'workspace_changed_before_approval',
        );
        throw StateError('Agent workspace changed before approval');
      }
    }
    if (traceId == null) {
      await _database.startAgentExecution(
        id: executionId,
        workspacePath: workspacePath,
        summary: '${actions.length} approved actions',
        inputInstruction: _redact(inputInstruction),
      );
    }
    await _database.setAgentExecutionStatus(executionId, 'running');
    await _database.appendAgentEvent(
      executionId: executionId,
      eventType: 'task_started',
      payload: {
        'inputInstruction': _redact(inputInstruction),
        'actionCount': actions.length,
        'allowMutations': allowMutations,
      },
    );
    Object? executionError;
    try {
      for (final action in actions) {
        await _database.appendAgentEvent(
          executionId: executionId,
          eventType: 'action_started',
          actionId: action.id,
          payload: _actionPayload(action),
        );
        if (action.mutatesWorkspace && !allowMutations) {
          const output = 'Mutation approval required';
          results.add(
            AgentActionResult(action: action, success: false, output: output),
          );
          await _database.appendAgentEvent(
            executionId: executionId,
            eventType: 'action_failed',
            actionId: action.id,
            payload: {'error': output, 'reason': 'approval_required'},
          );
          continue;
        }
        try {
          if ((action.type == AgentActionType.writeFile ||
                  action.type == AgentActionType.createDirectory) &&
              snapshottedPaths.add(action.path)) {
            await _snapshotPath(
              executionId: executionId,
              workspacePath: workspacePath,
              relativePath: action.path,
            );
          }
          switch (action.type) {
            case AgentActionType.listFiles:
              final snapshot = await _workspace.snapshot(workspacePath);
              results.add(
                AgentActionResult(
                  action: action,
                  success: true,
                  output: jsonEncode({
                    'files': snapshot.files,
                    'directories': snapshot.directories,
                    'languages': snapshot.languages,
                  }),
                ),
              );
            case AgentActionType.readFile:
              results.add(
                AgentActionResult(
                  action: action,
                  success: true,
                  output: await _workspace.readText(workspacePath, action.path),
                ),
              );
            case AgentActionType.writeFile:
              await _workspace.writeText(
                workspacePath,
                action.path,
                action.content ?? '',
              );
              results.add(
                AgentActionResult(
                  action: action,
                  success: true,
                  output: action.path,
                ),
              );
            case AgentActionType.createDirectory:
              await _workspace.createDirectory(workspacePath, action.path);
              results.add(
                AgentActionResult(
                  action: action,
                  success: true,
                  output: action.path,
                ),
              );
            case AgentActionType.runCommand:
              final command = action.command?.trim() ?? '';
              if (!_shell.isWorkspaceCommandAllowed(command)) {
                throw StateError('Workspace command policy rejected this task');
              }
              final shellResult = await _shell.run(
                command,
                shellEnvironment,
                workingDirectory: workspacePath,
              );
              results.add(
                AgentActionResult(
                  action: action,
                  success: shellResult.exitCode == 0,
                  output: '${shellResult.stdout}${shellResult.stderr}',
                  exitCode: shellResult.exitCode,
                ),
              );
          }
          final result = results.last;
          await _database.appendAgentEvent(
            executionId: executionId,
            eventType: result.success ? 'action_completed' : 'action_failed',
            actionId: action.id,
            payload: {
              'success': result.success,
              'exitCode': result.exitCode,
              'output': _redact(_bounded(result.output)),
            },
          );
        } on Object catch (error) {
          final detail = _redact(error.toString());
          results.add(
            AgentActionResult(action: action, success: false, output: detail),
          );
          await _database.appendAgentEvent(
            executionId: executionId,
            eventType: 'action_failed',
            actionId: action.id,
            payload: {'error': detail},
          );
        }
      }
    } on Object catch (error) {
      executionError = error;
      rethrow;
    } finally {
      final success =
          executionError == null &&
          results.length == actions.length &&
          results.every((result) => result.success);
      final reason = results.isEmpty
          ? 'no_actions'
          : success
          ? 'completed'
          : executionError == null
          ? 'action_failed'
          : 'execution_error';
      await _database.appendAgentEvent(
        executionId: executionId,
        eventType: success ? 'task_completed' : 'task_failed',
        payload: {
          'terminationReason': reason,
          'successfulActions': results.where((result) => result.success).length,
          'failedActions': results.where((result) => !result.success).length,
          if (executionError != null)
            'error': _redact(executionError.toString()),
        },
      );
      await _database.completeAgentExecution(
        executionId,
        success ? 'completed' : 'failed',
        terminationReason: reason,
      );
    }
    return results;
  }

  Map<String, Object?> _actionPayload(AgentAction action) => {
    'type': action.type.name,
    'path': _redact(action.path),
    'command': action.command == null ? null : _redact(action.command!),
    'reason': _redact(action.reason),
    'contentSha256': action.content == null
        ? null
        : sha256.convert(utf8.encode(action.content!)).toString(),
    'contentBytes': action.content == null
        ? 0
        : utf8.encode(action.content!).length,
  };

  String _bounded(String value) => value.length <= 12000
      ? value
      : '${value.substring(0, 12000)}\n...[truncated]';

  String _redact(String value) => TraceRedactor.sanitize(value);

  Future<void> _snapshotPath({
    required String executionId,
    required String workspacePath,
    required String relativePath,
  }) async {
    final resolved = _workspace.resolveSafe(workspacePath, relativePath);
    final type = await FileSystemEntity.type(resolved, followLinks: false);
    String? content;
    String? checksum;
    if (type == FileSystemEntityType.file) {
      content = await _workspace.readText(workspacePath, relativePath);
      checksum = sha256.convert(utf8.encode(content)).toString();
    }
    await _database.saveWorkspaceSnapshot(
      id: const Uuid().v4(),
      executionId: executionId,
      relativePath: relativePath,
      content: content,
      checksum: checksum,
      existed: type != FileSystemEntityType.notFound,
    );
  }

  Future<void> rollback({
    required String executionId,
    required String workspacePath,
  }) async {
    final snapshots = await _database.workspaceSnapshots(executionId);
    await _database.addWorkLog(
      category: 'agent',
      title: 'rollback:$executionId',
      detail: '${snapshots.length} workspace snapshots',
      status: 'started',
    );
    for (final snapshot in snapshots) {
      final path = snapshot['relative_path']! as String;
      final existed = snapshot['existed'] == 1;
      final content = snapshot['content'] as String?;
      if (existed && content != null) {
        await _workspace.writeText(workspacePath, path, content);
      } else if (!existed) {
        final resolved = _workspace.resolveSafe(workspacePath, path);
        final type = await FileSystemEntity.type(resolved, followLinks: false);
        if (type == FileSystemEntityType.file) {
          await _workspace.deleteFile(workspacePath, path);
        } else if (type == FileSystemEntityType.directory) {
          await _workspace.deleteDirectoryIfEmpty(workspacePath, path);
        }
      }
    }
    await _database.completeAgentExecution(executionId, 'rolledBack');
    await _database.addWorkLog(
      category: 'agent',
      title: 'rollback:$executionId',
      detail: '${snapshots.length} workspace snapshots restored',
      status: 'completed',
    );
  }

  AgentAction makeReadAction(String path) => AgentAction(
    id: const Uuid().v4(),
    type: AgentActionType.readFile,
    path: path,
  );
}
