import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LesCancelledException implements Exception {
  const LesCancelledException();
}

/// A small opaque ABI for the separately linked MiniCPM LES runtime. Native
/// preparation, prefill and decode run on its worker, never the Flutter thread.
/// No llama/ggml structs from this revision cross the old llamadart ABI.
class MiniCpmLesBackend {
  static const bundled = bool.fromEnvironment('SIQI_LES_RUNTIME');
  late final DynamicLibrary _library = DynamicLibrary.open('libsiqi_les.so');
  late final _create = _library
      .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
        'siqi_les_create',
      );
  late final _start = _library
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Utf8>),
        int Function(Pointer<Void>, Pointer<Utf8>)
      >('siqi_les_start');
  late final _next = _library
      .lookupFunction<
        Pointer<Utf8> Function(Pointer<Void>),
        Pointer<Utf8> Function(Pointer<Void>)
      >('siqi_les_next_event');
  late final _free = _library
      .lookupFunction<
        Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)
      >('siqi_les_string_free');
  late final _cancel = _library
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('siqi_les_cancel');
  late final _active = _library
      .lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('siqi_les_active');
  Pointer<Void> _handle = nullptr;
  bool _running = false;

  static Future<Directory> cacheDirectory(String modelId) async {
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(modelId) ||
        modelId == '..' ||
        modelId == '.') {
      throw ArgumentError('invalid-model-cache-id');
    }
    final root = await getApplicationSupportDirectory();
    return Directory(p.join(root.path, 'les-model-cache', modelId));
  }

  /// Explicit model removal also removes ONLY its app-owned derivative cache.
  static Future<int> removeModelCache(String modelId) async {
    final directory = await cacheDirectory(modelId);
    if (!await directory.exists()) return 0;
    var bytes = 0;
    await for (final item in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (item is File) bytes += await item.length();
    }
    await directory.delete(recursive: true);
    return bytes;
  }

  static Future<int> cacheSize() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'les-model-cache'));
    if (!await directory.exists()) return 0;
    var size = 0;
    await for (final file in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (file is File) size += await file.length();
    }
    return size;
  }

  /// The caller must unload the runtime first. Keep original model directories,
  /// sessions, preferences and unrelated caches outside this explicit target.
  static Future<void> clearCaches() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'les-model-cache'));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<Map<String, dynamic>> generate({
    required Map<String, Object?> request,
    void Function(String text)? onText,
    void Function(Map<String, dynamic> event)? onProgress,
  }) async {
    if (!bundled || !Platform.isAndroid) {
      throw StateError('les-runtime-not-bundled');
    }
    if (_running) throw StateError('les-runtime-busy');
    final abi = _library.lookupFunction<Int32 Function(), int Function()>(
      'siqi_les_abi_version',
    )();
    final supported = _library.lookupFunction<Int32 Function(), int Function()>(
      'siqi_les_supported_cpu',
    )();
    if (abi != 1 || supported == 0) {
      throw UnsupportedError('les-runtime-cpu-or-abi-unsupported');
    }
    if (_handle == nullptr) _handle = _create();
    if (_handle == nullptr) throw StateError('les-runtime-already-owned');
    final encoded = jsonEncode(request).toNativeUtf8();
    try {
      if (_start(_handle, encoded) == 0) {
        throw StateError('les-runtime-start-failed');
      }
    } finally {
      calloc.free(encoded);
    }
    _running = true;
    try {
      var lastActivity = DateTime.now();
      while (true) {
        var delivered = false;
        for (var count = 0; count < 64; count++) {
          final pointer = _next(_handle);
          if (pointer == nullptr) break;
          late final Map<String, dynamic> event;
          try {
            event = jsonDecode(pointer.toDartString()) as Map<String, dynamic>;
          } finally {
            _free(pointer);
          }
          delivered = true;
          lastActivity = DateTime.now();
          switch (event['event']) {
            case 'text':
              onText?.call(event['text'] as String);
            case 'completed':
              // A terminal event is published just before the worker clears
              // its active flag. Keep the Dart owner busy until that ack so a
              // fast follow-up cannot race native start/destroy.
              await _waitForWorkerStop();
              return event;
            case 'failed':
              await _waitForWorkerStop();
              if (event['cancelled'] == true) {
                throw const LesCancelledException();
              }
              throw StateError('les-${event['reason']}');
            default:
              onProgress?.call(event);
          }
        }
        if (!delivered && _active(_handle) == 0) {
          throw StateError('les-worker-ended-without-result');
        }
        if (DateTime.now().difference(lastActivity) >
            const Duration(minutes: 5)) {
          cancel();
          throw TimeoutException('les-worker-idle-timeout');
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    } on Object {
      // Client callbacks and event decoding can fail before a terminal event.
      // Never leave the native decoder running after its consumer has exited.
      cancel();
      await _waitForWorkerStop();
      rethrow;
    } finally {
      _running = false;
    }
  }

  void cancel() {
    if (_handle != nullptr) _cancel(_handle);
  }

  Future<void> _waitForWorkerStop() async {
    while (_handle != nullptr && _active(_handle) != 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> close() async {
    if (_handle == nullptr) return;
    cancel();
    while (_active(_handle) != 0) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    final address = _handle.address;
    _handle = nullptr;
    // Destruction unmaps thousands of file-backed expert pages off the UI.
    await Isolate.run(() {
      final library = DynamicLibrary.open('libsiqi_les.so');
      final destroy = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('siqi_les_destroy');
      destroy(Pointer<Void>.fromAddress(address));
    });
  }
}
