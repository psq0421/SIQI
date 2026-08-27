import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../models/app_models.dart';
import '../models/privacy_models.dart';
import '../models/workbench_models.dart';

class LocalDatabase {
  LocalDatabase._(this._database);
  final Database _database;

  static Future<LocalDatabase> open() async {
    final root = await getDatabasesPath();
    final database = await openDatabase(
      p.join(root, AppConstants.databaseName),
      version: AppConstants.databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createHarnessPluginTable(db);
        if (oldVersion < 3) await _createOperationalTables(db);
        if (oldVersion < 4) await _createAlpha2Tables(db);
        if (oldVersion < 5) await _upgradeApiProfilesForAlpha3(db);
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            model_id TEXT,
            attachments_json TEXT NOT NULL DEFAULT '[]',
            FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_messages_session ON messages(session_id, created_at)',
        );
        await db.execute('''
          CREATE TABLE api_profiles(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            provider_id TEXT NOT NULL,
            base_url TEXT NOT NULL,
            model_id TEXT NOT NULL,
            format TEXT NOT NULL,
            is_multimodal INTEGER NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            model_mappings_json TEXT NOT NULL DEFAULT '{}',
            fallback_model_id TEXT NOT NULL DEFAULT '',
            billing_currency TEXT NOT NULL DEFAULT '',
            input_price_per_million REAL,
            output_price_per_million REAL,
            headers_json TEXT NOT NULL DEFAULT '{}',
            last_tested_at INTEGER,
            input_tokens INTEGER NOT NULL DEFAULT 0,
            output_tokens INTEGER NOT NULL DEFAULT 0,
            estimated_cost REAL NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE model_downloads(
            model_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            checksum TEXT,
            completed_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE mcp_servers(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            transport TEXT NOT NULL,
            command_or_url TEXT NOT NULL,
            config_json TEXT NOT NULL DEFAULT '{}',
            enabled INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE shell_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            command TEXT NOT NULL,
            exit_code INTEGER,
            created_at INTEGER NOT NULL
          )
        ''');
        await _createHarnessPluginTable(db);
        await _createOperationalTables(db);
        await _createAlpha2Tables(db);
      },
    );
    return LocalDatabase._(database);
  }

  static Future<void> _createHarnessPluginTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS harness_plugins(
      repository_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      owner TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL,
      kind TEXT NOT NULL,
      repository_url TEXT NOT NULL,
      detail_url TEXT NOT NULL,
      stars TEXT NOT NULL,
      updated_label TEXT NOT NULL,
      synced_at INTEGER NOT NULL,
      archive_path TEXT,
      commit_sha TEXT,
      license TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_harness_plugins_name ON harness_plugins(name COLLATE NOCASE)',
    );
  }

  static Future<void> _upgradeApiProfilesForAlpha3(Database db) async {
    await db.execute(
      "ALTER TABLE api_profiles ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE api_profiles ADD COLUMN model_mappings_json TEXT NOT NULL DEFAULT '{}'",
    );
    await db.execute(
      "ALTER TABLE api_profiles ADD COLUMN fallback_model_id TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE api_profiles ADD COLUMN billing_currency TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      'ALTER TABLE api_profiles ADD COLUMN input_price_per_million REAL',
    );
    await db.execute(
      'ALTER TABLE api_profiles ADD COLUMN output_price_per_million REAL',
    );
  }

  static Future<void> _createOperationalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS permission_audit(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        permission TEXT NOT NULL,
        purpose TEXT NOT NULL,
        decision TEXT NOT NULL,
        requested_at INTEGER NOT NULL,
        detail TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_permission_audit_time ON permission_audit(requested_at DESC)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        detail TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_work_logs_time ON work_logs(created_at DESC)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mcp_catalog(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        author TEXT NOT NULL,
        homepage TEXT NOT NULL,
        install_json TEXT NOT NULL DEFAULT '{}',
        tags_json TEXT NOT NULL DEFAULT '[]',
        synced_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_teams(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        member_profile_ids_json TEXT NOT NULL,
        max_rounds INTEGER NOT NULL DEFAULT 3,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_team_messages(
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        profile_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        round_index INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(team_id) REFERENCES ai_teams(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createAlpha2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS model_artifacts(
        model_id TEXT NOT NULL,
        artifact_id TEXT NOT NULL,
        role TEXT NOT NULL,
        format TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        source_url TEXT NOT NULL,
        etag TEXT,
        last_modified TEXT,
        state TEXT NOT NULL DEFAULT 'completed',
        completed_at INTEGER NOT NULL,
        verified_at INTEGER,
        PRIMARY KEY(model_id, artifact_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS harness_sessions(
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL,
        profile_id TEXT,
        workspace_path TEXT NOT NULL,
        status TEXT NOT NULL,
        capabilities_json TEXT NOT NULL DEFAULT '{}',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS harness_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(session_id) REFERENCES harness_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_harness_events_session ON harness_events(session_id, created_at)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tool_approvals(
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        action_id TEXT NOT NULL,
        decision TEXT NOT NULL,
        reason TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY(session_id) REFERENCES harness_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agent_executions(
        id TEXT PRIMARY KEY,
        session_id TEXT,
        workspace_path TEXT NOT NULL,
        summary TEXT NOT NULL,
        status TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workspace_snapshots(
        id TEXT PRIMARY KEY,
        execution_id TEXT NOT NULL,
        relative_path TEXT NOT NULL,
        content TEXT,
        checksum TEXT,
        existed INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(execution_id) REFERENCES agent_executions(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<ChatSession>> listSessions({String query = ''}) async {
    final normalized = query.trim();
    final rows = normalized.isEmpty
        ? await _database.query('sessions', orderBy: 'updated_at DESC')
        : await _database.rawQuery(
            '''
              SELECT DISTINCT sessions.*
              FROM sessions
              LEFT JOIN messages ON messages.session_id = sessions.id
              WHERE sessions.title LIKE ? OR messages.content LIKE ?
              ORDER BY sessions.updated_at DESC
            ''',
            ['%$normalized%', '%$normalized%'],
          );
    return rows.map(ChatSession.fromDatabase).toList();
  }

  Future<void> saveSession(ChatSession session) => _database.insert(
    'sessions',
    session.toDatabase(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> deleteSession(String id) =>
      _database.delete('sessions', where: 'id = ?', whereArgs: [id]);

  Future<List<ChatMessage>> listMessages(String sessionId) async {
    final rows = await _database.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ChatMessage.fromDatabase).toList();
  }

  Future<void> saveMessage(ChatMessage message) async {
    await _database.transaction((transaction) async {
      await transaction.insert(
        'messages',
        message.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.update(
        'sessions',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [message.sessionId],
      );
    });
  }

  Future<List<ApiProfile>> listApiProfiles() async {
    final rows = await _database.query(
      'api_profiles',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(ApiProfile.fromDatabase).toList();
  }

  Future<void> saveApiProfile(ApiProfile profile) => _database.insert(
    'api_profiles',
    profile.toDatabase(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> deleteApiProfile(String id) =>
      _database.delete('api_profiles', where: 'id = ?', whereArgs: [id]);

  Future<void> addUsage(String profileId, TokenUsage usage) async {
    await _database.rawUpdate(
      'UPDATE api_profiles SET input_tokens = input_tokens + ?, output_tokens = output_tokens + ?, estimated_cost = estimated_cost + ? WHERE id = ?',
      [usage.input, usage.output, usage.estimatedCost, profileId],
    );
  }

  Future<void> markProfileTested(String id) => _database.update(
    'api_profiles',
    {'last_tested_at': DateTime.now().millisecondsSinceEpoch},
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<void> saveDownloadedModel(
    String modelId,
    String path,
    int size, {
    String? checksum,
  }) => _database.insert('model_downloads', {
    'model_id': modelId,
    'file_path': path,
    'file_size': size,
    'checksum': checksum,
    'completed_at': DateTime.now().millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Map<String, Object?>?> downloadedModel(String modelId) async {
    final rows = await _database.query(
      'model_downloads',
      where: 'model_id = ?',
      whereArgs: [modelId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveModelArtifact({
    required String modelId,
    required ModelArtifact artifact,
    required String path,
    required int size,
    required String checksum,
    required String? etag,
    required String? lastModified,
  }) => _database.insert('model_artifacts', {
    'model_id': modelId,
    'artifact_id': artifact.id,
    'role': artifact.role.name,
    'format': artifact.format.name,
    'file_path': path,
    'file_size': size,
    'checksum': checksum,
    'source_url': artifact.downloadUrl,
    'etag': etag,
    'last_modified': lastModified,
    'state': 'completed',
    'completed_at': DateTime.now().millisecondsSinceEpoch,
    'verified_at': DateTime.now().millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Map<String, Object?>?> downloadedModelArtifact(
    String modelId,
    String artifactId,
  ) async {
    final rows = await _database.query(
      'model_artifacts',
      where: 'model_id = ? AND artifact_id = ?',
      whereArgs: [modelId, artifactId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> listDownloadedModelArtifacts(
    String modelId,
  ) => _database.query(
    'model_artifacts',
    where: 'model_id = ?',
    whereArgs: [modelId],
    orderBy: "CASE role WHEN 'model' THEN 0 WHEN 'projector' THEN 1 ELSE 2 END",
  );

  Future<void> markModelArtifactVerified(String modelId, String artifactId) =>
      _database.update(
        'model_artifacts',
        {'verified_at': DateTime.now().millisecondsSinceEpoch},
        where: 'model_id = ? AND artifact_id = ?',
        whereArgs: [modelId, artifactId],
      );

  Future<void> deleteDownloadedModelRecords(String modelId) async {
    await _database.transaction((transaction) async {
      await transaction.delete(
        'model_artifacts',
        where: 'model_id = ?',
        whereArgs: [modelId],
      );
      await transaction.delete(
        'model_downloads',
        where: 'model_id = ?',
        whereArgs: [modelId],
      );
    });
  }

  Future<void> startAgentExecution({
    required String id,
    required String workspacePath,
    required String summary,
  }) => _database.insert('agent_executions', {
    'id': id,
    'session_id': null,
    'workspace_path': workspacePath,
    'summary': summary,
    'status': 'running',
    'started_at': DateTime.now().millisecondsSinceEpoch,
    'completed_at': null,
  });

  Future<void> saveWorkspaceSnapshot({
    required String id,
    required String executionId,
    required String relativePath,
    required String? content,
    required String? checksum,
    required bool existed,
  }) => _database.insert('workspace_snapshots', {
    'id': id,
    'execution_id': executionId,
    'relative_path': relativePath,
    'content': content,
    'checksum': checksum,
    'existed': existed ? 1 : 0,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> completeAgentExecution(String id, String status) =>
      _database.update(
        'agent_executions',
        {
          'status': status,
          'completed_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<Map<String, Object?>>> workspaceSnapshots(String executionId) =>
      _database.query(
        'workspace_snapshots',
        where: 'execution_id = ?',
        whereArgs: [executionId],
        orderBy: 'created_at DESC',
      );

  Future<void> recordToolApproval({
    required String id,
    required String sessionId,
    required String actionId,
    required String decision,
    String reason = '',
  }) => _database.insert('tool_approvals', {
    'id': id,
    'session_id': sessionId,
    'action_id': actionId,
    'decision': decision,
    'reason': reason,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  });

  Future<List<Map<String, Object?>>> listMcpServers() =>
      _database.query('mcp_servers', orderBy: 'name COLLATE NOCASE');

  Future<void> saveMcpServer(Map<String, Object?> server) => _database.insert(
    'mcp_servers',
    server,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> deleteMcpServer(String id) =>
      _database.delete('mcp_servers', where: 'id = ?', whereArgs: [id]);

  Future<void> saveShellCommand(String command, int exitCode) =>
      _database.insert('shell_history', {
        'command': command,
        'exit_code': exitCode,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

  Future<List<Map<String, Object?>>> shellHistory(int limit) => _database.query(
    'shell_history',
    orderBy: 'created_at DESC',
    limit: limit,
  );

  Future<void> addPermissionAudit({
    required AppPermissionKind permission,
    required PermissionPurpose purpose,
    required PermissionDecision decision,
    String? detail,
  }) => _database.insert('permission_audit', {
    'permission': permission.name,
    'purpose': purpose.name,
    'decision': decision.name,
    'requested_at': DateTime.now().millisecondsSinceEpoch,
    'detail': detail,
  });

  Future<List<PermissionAuditEntry>> listPermissionAudit() async {
    final rows = await _database.query(
      'permission_audit',
      orderBy: 'requested_at DESC',
    );
    return rows.map(PermissionAuditEntry.fromDatabase).toList();
  }

  Future<void> deletePermissionAudit(int id) =>
      _database.delete('permission_audit', where: 'id = ?', whereArgs: [id]);

  Future<void> clearPermissionAudit() => _database.delete('permission_audit');

  Future<void> addWorkLog({
    required String category,
    required String title,
    required String detail,
    required String status,
  }) => _database.insert('work_logs', {
    'category': category,
    'title': title,
    'detail': detail,
    'status': status,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  });

  Future<List<WorkLogEntry>> listWorkLogs({int limit = 500}) async {
    final rows = await _database.query(
      'work_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(WorkLogEntry.fromDatabase).toList();
  }

  Future<void> clearWorkLogs() => _database.delete('work_logs');

  Future<int> mcpCatalogCount() async {
    final rows = await _database.rawQuery('SELECT COUNT(*) FROM mcp_catalog');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> replaceMcpCatalog(List<Map<String, Object?>> items) async {
    await _database.transaction((transaction) async {
      await transaction.delete('mcp_catalog');
      final batch = transaction.batch();
      for (final item in items) {
        batch.insert(
          'mcp_catalog',
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, Object?>>> listMcpCatalog({
    String query = '',
    int limit = 200,
    int offset = 0,
  }) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return _database.query(
        'mcp_catalog',
        orderBy: 'name COLLATE NOCASE',
        limit: limit,
        offset: offset,
      );
    }
    return _database.query(
      'mcp_catalog',
      where: 'name LIKE ? OR description LIKE ? OR author LIKE ?',
      whereArgs: List.filled(3, '%$normalized%'),
      orderBy: 'name COLLATE NOCASE',
      limit: limit,
      offset: offset,
    );
  }

  Future<int> harnessPluginCount() async {
    final rows = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM harness_plugins',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<List<HarnessPlugin>> listHarnessPlugins({
    String query = '',
    int limit = 200,
    int offset = 0,
  }) async {
    final normalized = query.trim();
    final rows = normalized.isEmpty
        ? await _database.query(
            'harness_plugins',
            orderBy: 'archive_path IS NOT NULL DESC, name COLLATE NOCASE',
            limit: limit,
            offset: offset,
          )
        : await _database.query(
            'harness_plugins',
            where:
                'name LIKE ? OR owner LIKE ? OR description LIKE ? OR category LIKE ?',
            whereArgs: List.filled(4, '%$normalized%'),
            orderBy: 'archive_path IS NOT NULL DESC, name COLLATE NOCASE',
            limit: limit,
            offset: offset,
          );
    return rows.map(HarnessPlugin.fromDatabase).toList();
  }

  Future<void> upsertHarnessPlugins(List<HarnessPlugin> plugins) async {
    await _database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final plugin in plugins) {
        batch.rawInsert(
          '''
          INSERT OR IGNORE INTO harness_plugins(
            repository_id, name, owner, description, category, kind,
            repository_url, detail_url, stars, updated_label, synced_at
          ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            plugin.repositoryId,
            plugin.name,
            plugin.owner,
            plugin.description,
            plugin.category,
            plugin.kind,
            plugin.repositoryUrl,
            plugin.detailUrl,
            plugin.stars,
            plugin.updatedLabel,
            plugin.syncedAt.millisecondsSinceEpoch,
          ],
        );
        batch.rawUpdate(
          '''
          UPDATE harness_plugins SET
            name = ?, owner = ?, description = ?, category = ?, kind = ?,
            repository_url = ?, detail_url = ?, stars = ?,
            updated_label = ?, synced_at = ?
          WHERE repository_id = ?
          ''',
          [
            plugin.name,
            plugin.owner,
            plugin.description,
            plugin.category,
            plugin.kind,
            plugin.repositoryUrl,
            plugin.detailUrl,
            plugin.stars,
            plugin.updatedLabel,
            plugin.syncedAt.millisecondsSinceEpoch,
            plugin.repositoryId,
          ],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> saveHarnessPluginArchive(
    String repositoryId, {
    required String archivePath,
    required String commitSha,
    required String license,
  }) => _database.update(
    'harness_plugins',
    {'archive_path': archivePath, 'commit_sha': commitSha, 'license': license},
    where: 'repository_id = ?',
    whereArgs: [repositoryId],
  );

  Future<void> clearHarnessPluginArchive(String repositoryId) =>
      _database.update(
        'harness_plugins',
        {'archive_path': null, 'commit_sha': null, 'license': null},
        where: 'repository_id = ?',
        whereArgs: [repositoryId],
      );

  Future<List<AiTeam>> listAiTeams() async {
    final rows = await _database.query('ai_teams', orderBy: 'updated_at DESC');
    return rows.map(AiTeam.fromDatabase).toList();
  }

  Future<void> saveAiTeam(AiTeam team) => _database.insert(
    'ai_teams',
    team.toDatabase(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> deleteAiTeam(String id) =>
      _database.delete('ai_teams', where: 'id = ?', whereArgs: [id]);

  Future<List<AiTeamMessage>> listAiTeamMessages(String teamId) async {
    final rows = await _database.query(
      'ai_team_messages',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'created_at ASC',
    );
    return rows.map(AiTeamMessage.fromDatabase).toList();
  }

  Future<void> saveAiTeamMessage(AiTeamMessage message) async {
    await _database.transaction((transaction) async {
      await transaction.insert(
        'ai_team_messages',
        message.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.update(
        'ai_teams',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [message.teamId],
      );
    });
  }

  Future<void> clearAiTeamMessages(String teamId) => _database.delete(
    'ai_team_messages',
    where: 'team_id = ?',
    whereArgs: [teamId],
  );

  Future<Map<String, Object?>> exportSnapshot() async => {
    'sessions': await _database.query('sessions'),
    'messages': await _database.query('messages'),
    'api_profiles': await _database.query('api_profiles'),
    'model_downloads': await _database.query('model_downloads'),
    'model_artifacts': await _database.query('model_artifacts'),
    'mcp_servers': await _database.query('mcp_servers'),
    'harness_plugins': await _database.query('harness_plugins'),
    'permission_audit': await _database.query('permission_audit'),
    'work_logs': await _database.query('work_logs'),
    'mcp_catalog': await _database.query('mcp_catalog'),
    'ai_teams': await _database.query('ai_teams'),
    'ai_team_messages': await _database.query('ai_team_messages'),
    'harness_sessions': await _database.query('harness_sessions'),
    'harness_events': await _database.query('harness_events'),
    'tool_approvals': await _database.query('tool_approvals'),
    'agent_executions': await _database.query('agent_executions'),
    'workspace_snapshots': await _database.query('workspace_snapshots'),
  };

  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    await _database.transaction((transaction) async {
      for (final table in [
        'sessions',
        'messages',
        'api_profiles',
        'model_downloads',
        'model_artifacts',
        'mcp_servers',
        'harness_plugins',
        'permission_audit',
        'work_logs',
        'mcp_catalog',
        'ai_teams',
        'ai_team_messages',
        'harness_sessions',
        'harness_events',
        'tool_approvals',
        'agent_executions',
        'workspace_snapshots',
      ]) {
        final rows = (snapshot[table] as List? ?? const []).cast<Map>();
        for (final row in rows) {
          await transaction.insert(
            table,
            Map<String, Object?>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> close() => _database.close();
}
