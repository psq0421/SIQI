import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/app_models.dart';
import '../models/workbench_models.dart';
import 'shell_service.dart';
import 'workspace_service.dart';

class AgentService {
  const AgentService(this._workspace, this._shell);
  final WorkspaceService _workspace;
  final ShellService _shell;

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
  }) async {
    final results = <AgentActionResult>[];
    for (final action in actions) {
      if (action.mutatesWorkspace && !allowMutations) {
        results.add(
          AgentActionResult(
            action: action,
            success: false,
            output: 'Mutation approval required',
          ),
        );
        continue;
      }
      try {
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
      } on Object catch (error) {
        results.add(
          AgentActionResult(
            action: action,
            success: false,
            output: error.toString(),
          ),
        );
      }
    }
    return results;
  }

  AgentAction makeReadAction(String path) => AgentAction(
    id: const Uuid().v4(),
    type: AgentActionType.readFile,
    path: path,
  );
}
