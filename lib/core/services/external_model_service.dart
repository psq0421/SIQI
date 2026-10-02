import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/local_database.dart';

class ExternalModelRecord {
  const ExternalModelRecord({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
  });
  final String id;
  final String path;
  final String name;
  final int size;
  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'size': size,
  };
  factory ExternalModelRecord.fromJson(Map<String, dynamic> json) =>
      ExternalModelRecord(
        id: json['id'] as String,
        path: json['path'] as String,
        name: json['name'] as String,
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

class ExternalModelService {
  ExternalModelService(this._preferences, this._database);
  final SharedPreferences _preferences;
  final LocalDatabase _database;
  static const _key = 'external_models';

  List<ExternalModelRecord> list() {
    final raw = _preferences.getStringList(_key) ?? const [];
    return raw
        .map(
          (value) => ExternalModelRecord.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<ExternalModelRecord?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'gguf',
        'ggml',
        'bin',
        'safetensors',
        'mnn',
        'onnx',
        'tflite',
      ],
      allowMultiple: false,
      withData: false,
    );
    final source = result?.files.single.path;
    if (source == null) return null;
    final input = File(source);
    if (!await input.exists()) return null;
    final base = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(base.path, 'models', 'imported'))
      ..createSync(recursive: true);
    final id =
        'imported:${Uri.encodeComponent('${DateTime.now().microsecondsSinceEpoch}:${p.basename(source)}')}';
    final target = File(
      p.join(
        targetDir.path,
        '${DateTime.now().microsecondsSinceEpoch}-${p.basename(source)}',
      ),
    );
    await input.copy(target.path);
    final size = await target.length();
    final checksum = (await sha256.bind(target.openRead()).first).toString();
    await _database.saveDownloadedModel(
      id,
      target.path,
      size,
      checksum: checksum,
    );
    final record = ExternalModelRecord(
      id: id,
      path: target.path,
      name: p.basename(source),
      size: size,
    );
    final values = list()..add(record);
    await _preferences.setStringList(_key, [
      for (final item in values) jsonEncode(item.toJson()),
    ]);
    await _database.addWorkLog(
      category: 'model',
      title: 'import:${record.name}',
      detail: '${record.size} bytes',
      status: 'completed',
    );
    return record;
  }

  Future<void> remove(ExternalModelRecord record) async {
    final file = File(record.path);
    if (await file.exists()) await file.delete();
    await _database.deleteDownloadedModelRecords(record.id);
    final values = list()..removeWhere((item) => item.id == record.id);
    await _preferences.setStringList(_key, [
      for (final item in values) jsonEncode(item.toJson()),
    ]);
  }
}
