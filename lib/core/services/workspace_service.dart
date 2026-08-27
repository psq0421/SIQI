import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/workbench_models.dart';

class WorkspaceService {
  static const ignoredDirectories = <String>{
    '.git',
    '.dart_tool',
    'build',
    '.gradle',
    '.idea',
    'node_modules',
    '.vscode',
  };
  static const maximumFiles = 5000;
  static const maximumTextBytes = 2 * 1024 * 1024;

  static Future<
    ({
      String root,
      String projects,
      String models,
      String exports,
      String logs,
      String cache,
    })
  >
  ensureAppDirectories() async {
    final external = await getExternalStorageDirectory();
    final root = external ?? await getApplicationSupportDirectory();
    final projects = Directory(p.join(root.path, 'Projects'));
    final models = Directory(p.join(root.path, 'Models'));
    final exports = Directory(p.join(root.path, 'Exports'));
    final logs = Directory(p.join(root.path, 'Logs'));
    final cache = Directory(p.join(root.path, 'Cache'));
    for (final directory in [projects, models, exports, logs, cache]) {
      await directory.create(recursive: true);
    }
    return (
      root: root.path,
      projects: projects.path,
      models: models.path,
      exports: exports.path,
      logs: logs.path,
      cache: cache.path,
    );
  }

  Future<bool> verifyWritableDirectory(String path) async {
    File? probe;
    try {
      final directory = Directory(p.normalize(p.absolute(path)));
      if (!await directory.exists()) await directory.create(recursive: true);
      probe = File(
        p.join(
          directory.path,
          '.siqi-write-probe-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await probe.writeAsString('SIQI', flush: true);
      return await probe.length() == 4;
    } on Object {
      return false;
    } finally {
      try {
        if (probe != null && await probe.exists()) await probe.delete();
      } on Object {
        // The probe result already captures whether the directory is usable.
      }
    }
  }

  Future<WorkspaceSnapshot> snapshot(String rootPath) async {
    final root = Directory(p.normalize(p.absolute(rootPath)));
    if (!await root.exists()) {
      throw FileSystemException('Workspace does not exist', root.path);
    }
    final files = <String>[];
    final directories = <String>[];
    final languages = <String, int>{};
    var totalBytes = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      final relative = p.relative(entity.path, from: root.path);
      final segments = p.split(relative);
      if (segments.any(ignoredDirectories.contains)) continue;
      if (entity is Directory) {
        directories.add(relative);
      } else if (entity is File) {
        if (files.length >= maximumFiles) break;
        files.add(relative);
        final length = await entity.length();
        totalBytes += length;
        final language = languageForPath(relative);
        if (language != null) {
          languages.update(language, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    files.sort();
    directories.sort();
    return WorkspaceSnapshot(
      rootPath: root.path,
      files: files,
      directories: directories,
      totalBytes: totalBytes,
      languages: languages,
    );
  }

  String resolveSafe(String rootPath, String relativePath) {
    final root = p.normalize(p.absolute(rootPath));
    final resolved = p.normalize(p.absolute(p.join(root, relativePath)));
    if (resolved != root && !p.isWithin(root, resolved)) {
      throw const FileSystemException('Path escapes workspace');
    }
    return resolved;
  }

  Future<String> readText(String rootPath, String relativePath) async {
    final path = resolveSafe(rootPath, relativePath);
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', path);
    }
    final length = await file.length();
    if (length > maximumTextBytes) {
      throw FileSystemException('File is too large for direct editing', path);
    }
    return file.readAsString();
  }

  Future<void> writeText(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    final path = resolveSafe(rootPath, relativePath);
    final file = File(path);
    await file.parent.create(recursive: true);
    final temporary = File('$path.siqi_tmp');
    final backup = File('$path.siqi_bak');
    if (await temporary.exists()) await temporary.delete();
    if (await backup.exists()) await backup.delete();
    await temporary.writeAsString(content, encoding: utf8, flush: true);
    final existed = await file.exists();
    if (existed) await file.rename(backup.path);
    try {
      await temporary.rename(path);
      if (await backup.exists()) await backup.delete();
    } on Object {
      if (await temporary.exists()) await temporary.delete();
      if (existed && await backup.exists() && !await file.exists()) {
        await backup.rename(path);
      }
      rethrow;
    }
  }

  Future<void> createDirectory(String rootPath, String relativePath) =>
      Directory(resolveSafe(rootPath, relativePath)).create(recursive: true);

  Future<bool> exists(String rootPath, String relativePath) =>
      FileSystemEntity.type(
        resolveSafe(rootPath, relativePath),
        followLinks: false,
      ).then((type) => type != FileSystemEntityType.notFound);

  Future<void> deleteFile(String rootPath, String relativePath) async {
    final file = File(resolveSafe(rootPath, relativePath));
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteDirectoryIfEmpty(
    String rootPath,
    String relativePath,
  ) async {
    final directory = Directory(resolveSafe(rootPath, relativePath));
    if (!await directory.exists()) return;
    if (!await directory.list(followLinks: false).isEmpty) return;
    await directory.delete();
  }

  Stream<List<int>> streamFile(String rootPath, String relativePath) =>
      File(resolveSafe(rootPath, relativePath)).openRead();

  String? languageForPath(String path) =>
      switch (p.extension(path).toLowerCase()) {
        '.dart' => 'Dart',
        '.kt' || '.kts' => 'Kotlin',
        '.java' => 'Java',
        '.py' => 'Python',
        '.js' || '.mjs' || '.cjs' => 'JavaScript',
        '.ts' || '.tsx' => 'TypeScript',
        '.go' => 'Go',
        '.rs' => 'Rust',
        '.c' => 'C',
        '.cc' || '.cpp' || '.cxx' || '.h' || '.hpp' => 'C/C++',
        '.swift' => 'Swift',
        '.sh' || '.bash' => 'Shell',
        '.yaml' || '.yml' => 'YAML',
        '.json' => 'JSON',
        '.md' => 'Markdown',
        '.html' => 'HTML',
        '.css' => 'CSS',
        _ => null,
      };
}
