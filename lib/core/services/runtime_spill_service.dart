import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Application-owned spill space for staging/KV data. It never attempts to
/// modify the system ZRAM device (that would require root); the native layer
/// only reports kernel swap metrics separately.
class RuntimeSpillService {
  Future<Directory> root() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'Runtime', 'spill'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> create(String name, {List<int>? bytes}) async {
    final directory = await root();
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File(p.join(directory.path, '$safe.tmp'));
    if (bytes != null) await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<int> size() async {
    final directory = await root();
    var total = 0;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        try {
          total += await entity.length();
        } on FileSystemException {
          // A concurrent cleanup may have removed the file.
        }
      }
    }
    return total;
  }

  Future<int> clear() async {
    final directory = await root();
    final before = await size();
    if (await directory.exists()) {
      await for (final entity in directory.list(followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } on FileSystemException {
          // Keep files currently used by an active inference task.
        }
      }
    }
    return before;
  }
}
