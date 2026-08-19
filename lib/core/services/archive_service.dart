import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../database/local_database.dart';
import '../models/app_models.dart';

class ArchiveService {
  const ArchiveService(this._database);
  final LocalDatabase _database;

  Future<File> exportAll(AppSettings settings) async {
    final snapshot = await _database.exportSnapshot();
    final payload = jsonEncode({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'database': snapshot,
    });
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'session.json',
          utf8.encode(payload).length,
          utf8.encode(payload),
        ),
      );
    final attachments = (snapshot['messages'] as List)
        .cast<Map<String, Object?>>();
    final seen = <String>{};
    for (final row in attachments) {
      final raw = row['attachments_json'] as String? ?? '[]';
      for (final item in (jsonDecode(raw) as List).cast<Map>()) {
        final path = item['path'] as String?;
        if (path == null || !seen.add(path)) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final data = await file.readAsBytes();
        archive.addFile(
          ArchiveFile('files/${p.basename(path)}', data.length, data),
        );
      }
    }
    final encoded = ZipEncoder().encode(archive);
    final directory = await getTemporaryDirectory();
    final file = File(
      p.join(
        directory.path,
        'siqi_${DateTime.now().millisecondsSinceEpoch}.${AppConstants.exportExtension}',
      ),
    );
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }

  Future<AppSettings> importAll(String path) async {
    final archive = ZipDecoder().decodeBytes(
      await File(path).readAsBytes(),
      verify: true,
    );
    final entry = archive.files
        .where((file) => file.name == 'session.json' && file.isFile)
        .firstOrNull;
    if (entry == null) throw const FormatException('session.json is missing');
    final data =
        jsonDecode(utf8.decode(entry.content as List<int>))
            as Map<String, dynamic>;
    if (data['schemaVersion'] != 1) {
      throw const FormatException('Unsupported archive schema');
    }
    await _database.importSnapshot(data['database'] as Map<String, dynamic>);
    return AppSettings.fromJson(data['settings'] as Map<String, dynamic>);
  }

  Future<File> exportConfiguration(
    AppSettings settings,
    List<ApiProfile> profiles,
  ) async {
    final body = jsonEncode({
      'schemaVersion': 1,
      'settings': settings.toJson(),
      'apiProfiles': profiles.map((profile) => profile.toDatabase()).toList(),
      'apiKeys': 'redacted',
    });
    final directory = await getTemporaryDirectory();
    final file = File(
      p.join(
        directory.path,
        'siqi_config_${DateTime.now().millisecondsSinceEpoch}.${AppConstants.configExtension}',
      ),
    );
    await file.writeAsString(body, flush: true);
    return file;
  }

  Future<({AppSettings settings, List<ApiProfile> profiles})>
  importConfiguration(String path) async {
    final data =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    if (data['schemaVersion'] != 1) {
      throw const FormatException('Unsupported configuration schema');
    }
    final settings = AppSettings.fromJson(
      data['settings'] as Map<String, dynamic>,
    );
    final profiles = (data['apiProfiles'] as List? ?? const [])
        .cast<Map>()
        .map((row) => ApiProfile.fromDatabase(Map<String, Object?>.from(row)))
        .toList();
    for (final profile in profiles) {
      await _database.saveApiProfile(profile);
    }
    return (settings: settings, profiles: profiles);
  }
}
