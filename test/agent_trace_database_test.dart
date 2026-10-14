import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:siqi/core/database/local_database.dart';
import 'package:siqi/core/models/app_models.dart';
import 'package:siqi/core/models/workbench_models.dart';
import 'package:siqi/core/services/agent_service.dart';
import 'package:siqi/core/services/shell_service.dart';
import 'package:siqi/core/services/workspace_service.dart';

void main() {
  sqfliteFfiInit();
  late Directory root;
  late LocalDatabase db;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('siqi-agent-test-');
    db = await LocalDatabase.open(
      path: p.join(root.path, 'test.db'),
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  test('parallel event appends have unique monotonic sequences', () async {
    await db.startAgentExecution(
      id: 'parallel',
      workspacePath: root.path,
      summary: 'test',
    );
    await Future.wait([
      for (var i = 0; i < 25; i++)
        db.appendAgentEvent(
          executionId: 'parallel',
          eventType: 'sample',
          payload: {'i': i},
        ),
    ]);
    expect(
      (await db.listAgentEvents(
        'parallel',
      )).map((event) => event['sequence_no']),
      List<int>.generate(25, (i) => i),
    );
  });

  test('failure filtering precedes export limit', () async {
    await db.startAgentExecution(
      id: 'failure',
      workspacePath: root.path,
      summary: 'old failure',
    );
    await db.completeAgentExecution(
      'failure',
      'failed',
      terminationReason: 'test',
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.startAgentExecution(
      id: 'success',
      workspacePath: root.path,
      summary: 'new success',
    );
    await db.completeAgentExecution('success', 'completed');
    final failures = await db.exportAgentExecutions(limit: 1, failedOnly: true);
    expect(failures.single['executionId'], 'failure');
  });

  test(
    'action ordering, command failure, input and termination survive export',
    () async {
      final agent = AgentService(WorkspaceService(), ShellService(db), db);
      final results = await agent.execute(
        workspacePath: root.path,
        shellEnvironment: ShellEnvironment.system,
        allowMutations: true,
        inputInstruction: '修复代码 api_key=secretvalue',
        actions: [
          const AgentAction(
            id: 'write',
            type: AgentActionType.writeFile,
            path: 'out.txt',
            content: 'hello',
          ),
          const AgentAction(
            id: 'escape',
            type: AgentActionType.readFile,
            path: '../outside.txt',
          ),
        ],
      );
      expect(results.map((result) => result.success), [true, false]);
      final exported = (await db.exportAgentExecution(agent.lastExecutionId!))!;
      expect(exported['status'], 'failed');
      expect(exported['terminationReason'], 'action_failed');
      expect(exported['inputInstruction'], isNot(contains('secretvalue')));
      final events = exported['events'] as List;
      expect(events.map((event) => event['type']), [
        'task_started',
        'action_started',
        'action_completed',
        'action_started',
        'action_failed',
        'task_failed',
      ]);
      expect(events.map((event) => event['sequence']), [0, 1, 2, 3, 4, 5]);
      expect(await File(p.join(root.path, 'out.txt')).readAsString(), 'hello');
    },
  );
  test('refused write is recorded and never mutates workspace', () async {
    final agent = AgentService(WorkspaceService(), ShellService(db), db);
    await agent.execute(
      workspacePath: root.path,
      shellEnvironment: ShellEnvironment.system,
      allowMutations: false,
      actions: [
        const AgentAction(
          id: 'write',
          type: AgentActionType.writeFile,
          path: 'blocked.txt',
          content: 'do not write',
        ),
      ],
    );
    expect(await File(p.join(root.path, 'blocked.txt')).exists(), isFalse);
    expect((await db.exportAgentExecutions(failedOnly: true)).length, 1);
  });
  test('model failure is exported even when no tools ran', () async {
    final now = DateTime.now();
    await db.saveSession(
      ChatSession(id: 'session', title: 'test', createdAt: now, updatedAt: now),
    );
    final agent = AgentService(WorkspaceService(), ShellService(db), db);
    final id = await agent.beginTask(
      workspacePath: root.path,
      instruction: 'inspect project',
      modelId: 'minicpm-test',
      sessionId: 'session',
    );
    await agent.finishTask(id, 'failed', 'guard:localNotDownloaded');
    final trace = (await db.exportAgentExecution(id))!;
    expect((trace['events'] as List).first['type'], 'model_requested');
    expect(trace['terminationReason'], 'guard:localNotDownloaded');
  });
  test('restart marks unfinished tasks interrupted', () async {
    await db.startAgentExecution(
      id: 'unfinished',
      workspacePath: root.path,
      summary: 'task',
    );
    await db.close();
    db = await LocalDatabase.open(
      path: p.join(root.path, 'test.db'),
      factory: databaseFactoryFfi,
    );
    final trace = (await db.exportAgentExecution('unfinished'))!;
    expect(trace['status'], 'interrupted');
    expect(trace['terminationReason'], 'app_restart');
    expect((await db.exportAgentExecutions(failedOnly: true)).length, 1);
  });
  test(
    'snapshot round trip preserves parent-first trace relationships',
    () async {
      await db.startAgentExecution(
        id: 'trace',
        workspacePath: root.path,
        summary: 'task',
      );
      await db.appendAgentEvent(
        executionId: 'trace',
        eventType: 'task_failed',
        payload: {'reason': 'test'},
      );
      await db.completeAgentExecution(
        'trace',
        'failed',
        terminationReason: 'test',
      );
      final snapshot = await db.exportSnapshot();
      await db.deleteAgentExecution('trace');
      expect(await db.listAgentEvents('trace'), isEmpty);
      await db.importSnapshot(snapshot);
      expect((await db.listAgentEvents('trace')).length, 1);
      expect((await db.agentExecution('trace'))!['termination_reason'], 'test');
    },
  );
  test(
    'version 6 migrates trace schema without deleting historical tasks',
    () async {
      await db.startAgentExecution(
        id: 'old',
        workspacePath: root.path,
        summary: 'historical',
      );
      await db.completeAgentExecution('old', 'completed');
      await db.close();
      final raw = await databaseFactoryFfi.openDatabase(
        p.join(root.path, 'test.db'),
      );
      await raw.execute('DROP TABLE agent_execution_events');
      await raw.execute(
        'ALTER TABLE agent_executions DROP COLUMN input_instruction',
      );
      await raw.execute(
        'ALTER TABLE agent_executions DROP COLUMN termination_reason',
      );
      await raw.execute('PRAGMA user_version = 6');
      await raw.close();
      db = await LocalDatabase.open(
        path: p.join(root.path, 'test.db'),
        factory: databaseFactoryFfi,
      );
      expect((await db.agentExecution('old'))!['summary'], 'historical');
      await db.appendAgentEvent(
        executionId: 'old',
        eventType: 'migration_verified',
        payload: {},
      );
      expect((await db.listAgentEvents('old')).length, 1);
    },
  );
}
