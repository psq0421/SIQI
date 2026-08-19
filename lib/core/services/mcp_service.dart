import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../database/local_database.dart';
import '../models/workbench_models.dart';

class McpService {
  const McpService(this._dio, this._database);
  final Dio _dio;
  final LocalDatabase _database;

  static const catalogUrl = 'https://modelscope.cn/mcp';
  static const _catalogEndpoint =
      'https://modelscope.cn/api/v1/dolphin/mcpServers';

  Future<int> syncCatalog() async {
    final collected = <Map<String, Object?>>[];
    var page = 1;
    var total = 0;
    do {
      final response = await _dio.put<dynamic>(
        _catalogEndpoint,
        data: {
          'PageSize': 100,
          'PageNumber': page,
          'Query': '',
          'Criterion': const [],
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Referer': catalogUrl,
            'x-modelscope-accept-language': 'zh_CN',
            'X-Modelscope-Visit-From': 'pc',
          },
        ),
      );
      final payload = response.data;
      if (payload is! Map) {
        throw const FormatException('modelscope-catalog-protected');
      }
      final root = Map<String, dynamic>.from(payload);
      if (root['Success'] != true || root['Code'] != 200) {
        throw FormatException(
          (root['Message'] ?? 'modelscope-catalog-unavailable').toString(),
        );
      }
      final data = Map<String, dynamic>.from(root['Data'] as Map? ?? const {});
      final server = Map<String, dynamic>.from(
        data['McpServer'] as Map? ?? const {},
      );
      total = (server['TotalCount'] as num?)?.toInt() ?? 0;
      final entries = (server['McpServers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item));
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in entries) {
        final normalized = _catalogRecord(entry, now);
        if (normalized != null) collected.add(normalized);
      }
      if (entries.isEmpty) break;
      page++;
    } while (collected.length < total && page <= 50);

    if (collected.isEmpty && total > 0) {
      throw const FormatException('modelscope-catalog-empty');
    }
    await _database.replaceMcpCatalog(collected);
    await _database.addWorkLog(
      category: 'mcp',
      title: 'catalog-sync',
      detail: '$catalogUrl | ${collected.length} entries',
      status: 'completed',
    );
    return collected.length;
  }

  Future<bool> importCatalogEntry(Map<String, Object?> record) async {
    final raw = jsonDecode(record['install_json']! as String);
    if (raw is! Map) return false;
    final endpoint = _findEndpoint(raw);
    if (endpoint == null) return false;
    final id = record['id']! as String;
    await _database.saveMcpServer({
      'id': 'catalog:$id',
      'name': record['name']! as String,
      'transport': endpoint.contains('/sse') ? 'sse' : 'http',
      'command_or_url': endpoint,
      'config_json': jsonEncode({
        'source': record['homepage'],
        'catalogId': id,
      }),
      'enabled': 1,
    });
    await _database.addWorkLog(
      category: 'mcp',
      title: 'catalog-import:$id',
      detail: endpoint,
      status: 'completed',
    );
    return true;
  }

  Map<String, Object?>? _catalogRecord(
    Map<String, dynamic> item,
    int syncedAt,
  ) {
    final name = _firstString(item, const ['Name', 'name']);
    if (name.isEmpty) return null;
    final path = _firstString(item, const [
      'Path',
      'path',
      'FromSitePath',
      'fromSitePath',
      'namespace',
    ]);
    final chineseName = _firstString(item, const [
      'ChineseName',
      'chineseName',
    ]);
    final description = _firstString(item, const [
      'Abstract',
      'abstract',
      'Description',
      'description',
      'Readme',
    ]);
    final author = path.isEmpty ? 'ModelScope' : path;
    final scope = path.isEmpty ? '@ModelScope' : path;
    final tags = <String>{};
    for (final key in const [
      'Tags',
      'tags',
      'Category',
      'category',
      'License',
    ]) {
      final value = item[key];
      if (value is List) {
        tags.addAll(
          value.map((tag) => tag.toString()).where((tag) => tag.isNotEmpty),
        );
      } else if (value != null && value.toString().isNotEmpty) {
        tags.add(value.toString());
      }
    }
    return {
      'id': '$scope/$name',
      'name': chineseName.isEmpty ? name : chineseName,
      'description': description,
      'author': author,
      'homepage':
          '$catalogUrl/servers/${Uri.encodeComponent(scope)}/${Uri.encodeComponent(name)}',
      'install_json': jsonEncode(item),
      'tags_json': jsonEncode(tags.toList()),
      'synced_at': syncedAt,
    };
  }

  String _firstString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String? _findEndpoint(Object? value) {
    if (value is Map) {
      for (final key in const [
        'Endpoint',
        'endpoint',
        'ServerUrl',
        'serverUrl',
        'SseUrl',
        'SSEUrl',
        'HttpUrl',
        'URL',
        'Url',
        'url',
      ]) {
        final candidate = value[key];
        if (candidate is String &&
            (candidate.startsWith('https://') ||
                candidate.startsWith('http://'))) {
          return candidate;
        }
      }
      for (final nested in value.values) {
        final result = _findEndpoint(nested);
        if (result != null) return result;
      }
    } else if (value is List) {
      for (final nested in value) {
        final result = _findEndpoint(nested);
        if (result != null) return result;
      }
    }
    return null;
  }

  Future<McpConnectionResult> test(Map<String, Object?> server) async {
    final watch = Stopwatch()..start();
    try {
      final transport = server['transport'] as String? ?? 'http';
      final tools = transport == 'stdio'
          ? await _testStdio(server)
          : await _testHttp(server);
      watch.stop();
      return McpConnectionResult(
        success: true,
        serverName: server['name'] as String? ?? '',
        tools: tools,
        latency: watch.elapsed,
      );
    } on Object catch (error) {
      watch.stop();
      return McpConnectionResult(
        success: false,
        serverName: server['name'] as String? ?? '',
        tools: const [],
        latency: watch.elapsed,
        error: error.toString(),
      );
    }
  }

  Future<List<McpToolDefinition>> _testHttp(Map<String, Object?> server) async {
    final url = server['command_or_url']! as String;
    final custom =
        jsonDecode(server['config_json'] as String? ?? '{}')
            as Map<String, dynamic>;
    final headers = Map<String, String>.from(
      custom['headers'] as Map? ?? const {},
    );
    final initialize = await _dio.post<Map<String, dynamic>>(
      url,
      data: _request(1, 'initialize', {
        'protocolVersion': '2025-03-26',
        'capabilities': const {},
        'clientInfo': {'name': 'SIQI', 'version': '1.0.0'},
      }),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/event-stream',
          ...headers,
        },
      ),
    );
    final sessionId = initialize.headers.value('mcp-session-id');
    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: _request(2, 'tools/list', const {}),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/event-stream',
          if (sessionId != null) 'Mcp-Session-Id': sessionId,
          ...headers,
        },
      ),
    );
    return _parseTools(response.data);
  }

  Future<List<McpToolDefinition>> _testStdio(
    Map<String, Object?> server,
  ) async {
    final command = server['command_or_url']! as String;
    final process = await Process.start('sh', [
      '-c',
      command,
    ], runInShell: false);
    final responses = <int, Map<String, dynamic>>{};
    final subscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          try {
            final data = jsonDecode(line) as Map<String, dynamic>;
            final id = data['id'];
            if (id is int) responses[id] = data;
          } on Object {
            return;
          }
        });
    try {
      process.stdin.writeln(
        jsonEncode(
          _request(1, 'initialize', {
            'protocolVersion': '2025-03-26',
            'capabilities': const {},
            'clientInfo': {'name': 'SIQI', 'version': '1.0.0'},
          }),
        ),
      );
      await process.stdin.flush();
      await _waitFor(responses, 1);
      process.stdin.writeln(
        jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'}),
      );
      process.stdin.writeln(jsonEncode(_request(2, 'tools/list', const {})));
      await process.stdin.flush();
      final response = await _waitFor(responses, 2);
      return _parseTools(response);
    } finally {
      await subscription.cancel();
      process.kill();
    }
  }

  Future<Map<String, dynamic>> _waitFor(
    Map<int, Map<String, dynamic>> responses,
    int id,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(deadline)) {
      final value = responses[id];
      if (value != null) return value;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    throw TimeoutException('MCP response timed out');
  }

  List<McpToolDefinition> _parseTools(Map<String, dynamic>? payload) {
    final result = payload?['result'] as Map<String, dynamic>? ?? const {};
    final tools = result['tools'] as List? ?? const [];
    return tools.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return McpToolDefinition(
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        inputSchema: Map<String, dynamic>.from(
          map['inputSchema'] as Map? ?? const {},
        ),
      );
    }).toList();
  }

  Map<String, dynamic> _request(
    int id,
    String method,
    Map<String, dynamic> params,
  ) => {'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params};
}
