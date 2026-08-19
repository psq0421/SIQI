import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppLogService {
  AppLogService._(this._directory, this._activeFile);

  final Directory? _directory;
  final File? _activeFile;

  static Future<AppLogService> open() async {
    try {
      final support = await getApplicationSupportDirectory();
      final directory = Directory(p.join(support.path, 'logs'));
      await directory.create(recursive: true);
      final now = DateTime.now();
      final day =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final file = File(p.join(directory.path, 'siqi-$day.log'));
      final service = AppLogService._(directory, file);
      await service._removeExpiredFiles();
      return service;
    } on Object {
      return AppLogService._(null, null);
    }
  }

  Future<void> info(String event, [String detail = '']) =>
      _write('INFO', event, detail);

  Future<void> warning(String event, [String detail = '']) =>
      _write('WARN', event, detail);

  Future<void> error(String event, Object error, [StackTrace? stackTrace]) =>
      _write('ERROR', event, '$error\n${stackTrace ?? ''}');

  Future<void> _write(String level, String event, String detail) async {
    final file = _activeFile;
    if (file == null) return;
    try {
      final normalized = detail.replaceAll(RegExp(r'[\r\n]+'), ' ↩ ');
      await file.writeAsString(
        '${DateTime.now().toIso8601String()} [$level] $event $normalized\n',
        mode: FileMode.append,
        flush: false,
      );
    } on Object {
      // Logging is diagnostic-only and must never interrupt the app.
    }
  }

  Future<List<File>> files() async {
    final directory = _directory;
    if (directory == null || !await directory.exists()) return const [];
    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<int> totalBytes() async {
    var total = 0;
    for (final file in await files()) {
      total += await file.length();
    }
    return total;
  }

  Future<void> clear() async {
    for (final file in await files()) {
      if (file.path != _activeFile?.path && await file.exists()) {
        await file.delete();
      }
    }
    final active = _activeFile;
    if (active != null) await active.writeAsString('', flush: true);
  }

  Future<void> _removeExpiredFiles() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    for (final file in await files()) {
      final modified = await file.lastModified();
      if (modified.isBefore(cutoff)) await file.delete();
    }
  }
}
