import 'dart:convert';
import 'dart:io';

/// All benchmark pages use the UI isolate. Serialize whole JSON records by
/// absolute file path: multiple buffered IOSinks can otherwise interleave.
/// This is not a cross-process journal; native workers must use separate files.
class BenchmarkJournal {
  BenchmarkJournal(File file) : _file = file.absolute;

  final File _file;
  static final Map<String, Future<void>> _pending = {};

  Future<void> append(Map<String, Object?> record) async {
    // Snapshot/encode now, before callers can mutate the record while queued.
    final line = '${jsonEncode(record)}\n';
    final previous = _pending[_file.path] ?? Future<void>.value();
    final write = previous.catchError((Object _) {}).then((_) async {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(line, mode: FileMode.append, flush: true);
    });
    _pending[_file.path] = write;
    try {
      await write;
    } finally {
      if (identical(_pending[_file.path], write)) {
        _pending.remove(_file.path);
      }
    }
  }
}

/// A service-scoped reservation remains held if its originating page closes.
class BenchmarkRunGate {
  Object? _owner;
  bool get running => _owner != null;

  bool acquire(Object owner) {
    if (running) return false;
    _owner = owner;
    return true;
  }

  void release(Object owner) {
    if (identical(_owner, owner)) _owner = null;
  }
}
