import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CacheService {
  const CacheService();

  Future<int> size() async {
    final root = await getTemporaryDirectory();
    if (!await root.exists()) return 0;
    var bytes = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          bytes += await entity.length();
        } on FileSystemException {
          // A concurrent cleanup may have already removed the file.
        }
      }
    }
    return bytes;
  }

  Future<int> clear() async {
    final root = await getTemporaryDirectory();
    if (!await root.exists()) return 0;
    final before = await size();
    await for (final entity in root.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } on FileSystemException {
        // Keep files currently owned by an active platform operation.
      }
    }
    return before;
  }
}
