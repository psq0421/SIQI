import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../constants/app_constants.dart';
import '../models/app_models.dart';

class FileContentService {
  static const _platformChannel = MethodChannel('com.psq.siqi/platform');
  static const _largeFileThreshold = 5 * 1024 * 1024;
  static const _maximumExtractedCharacters = 180000;
  static const _maximumImageInputBytes = 32 * 1024 * 1024;
  static const _maximumImageLongEdge = 1024;

  Future<List<AppAttachment>> pick({required bool multimodal}) async {
    final allowed = <String>{
      ...AppConstants.supportedTextExtensions,
      ...AppConstants.richDocumentExtensions,
      if (multimodal) ...[
        ...AppConstants.imageExtensions,
        ...AppConstants.audioExtensions,
      ],
    }.toList();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowed,
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return const [];
    final attachments = <AppAttachment>[];
    for (final selected in result.files) {
      final path = selected.path;
      if (path == null) continue;
      attachments.add(await read(path, multimodal: multimodal));
    }
    return attachments;
  }

  Future<String?> pickImageForOcr() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.imageExtensions.toList(),
      allowMultiple: false,
      withData: false,
    );
    return result == null || result.files.isEmpty
        ? null
        : result.files.first.path;
  }

  Future<String?> pickAudioForAsr() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.audioExtensions.toList(),
      allowMultiple: false,
      withData: false,
    );
    return result == null || result.files.isEmpty
        ? null
        : result.files.first.path;
  }

  Future<AppAttachment> read(String path, {required bool multimodal}) async {
    final file = File(path);
    final size = await file.length();
    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    final mime = lookupMimeType(path) ?? 'application/octet-stream';
    if (mime.startsWith('image/') ||
        AppConstants.imageExtensions.contains(extension)) {
      if (!multimodal) throw UnsupportedError('multimodal-disabled');
      if (size > _maximumImageInputBytes) {
        throw UnsupportedError('image-too-large');
      }
      final normalizedPath = await normalizeImageForInference(path);
      final normalized = File(normalizedPath);
      final data = await normalized.readAsBytes();
      return AppAttachment(
        name: p.basename(path),
        path: normalizedPath,
        mimeType: normalizedPath == path ? mime : 'image/png',
        base64Data: base64Encode(data),
        size: data.length,
      );
    }
    if (mime.startsWith('audio/') ||
        AppConstants.audioExtensions.contains(extension)) {
      if (!multimodal) throw UnsupportedError('multimodal-disabled');
      // Large audio remains path-backed. Reading a multi-hour recording into
      // one base64 string would duplicate it several times and can kill the
      // Android process; ASR consumes the path in bounded PCM chunks.
      final data = size <= _largeFileThreshold
          ? await file.readAsBytes()
          : null;
      return AppAttachment(
        name: p.basename(path),
        path: path,
        mimeType: mime,
        base64Data: data == null ? null : base64Encode(data),
        size: size,
      );
    }
    final text = switch (extension) {
      'pdf' => await _readPdf(file),
      'docx' => await _readOpenXml(file, const ['word/document.xml']),
      'pptx' => await _readOpenXml(file, null),
      'xlsx' => await _readSpreadsheet(file),
      'odt' ||
      'ods' ||
      'odp' => await _readOpenXml(file, const ['content.xml']),
      'epub' => await _readEpub(file),
      'rtf' => await _readRtf(file),
      _ =>
        size > _largeFileThreshold
            ? await _readTextStreamed(file)
            : await file.readAsString(),
    };
    return AppAttachment(
      name: p.basename(path),
      path: path,
      mimeType: mime,
      extractedText: text,
      size: size,
    );
  }

  /// Converts an image to one bounded PNG in the app cache. This keeps visual
  /// prompt encoding predictable on mobile hardware and also repairs older
  /// sessions whose attachments predate image normalization.
  static Future<String> normalizeImageForInference(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;
    final length = await source.length();
    if (length > _maximumImageInputBytes) {
      throw UnsupportedError('image-too-large');
    }
    final modified = await source.lastModified();
    final fingerprint = sha256
        .convert(
          utf8.encode(
            '${source.absolute.path}|$length|${modified.millisecondsSinceEpoch}',
          ),
        )
        .toString();
    final cache = Directory(
      p.join((await getTemporaryDirectory()).path, 'vision_inputs'),
    );
    await cache.create(recursive: true);
    final target = File(p.join(cache.path, '$fingerprint.png'));
    if (await target.exists() && await target.length() > 0) return target.path;
    final result = await Isolate.run(
      () => _normalizeImageJob(source.path, target.path, _maximumImageLongEdge),
    );
    if (result != null) return result;
    // Android's ImageDecoder handles HEIF/HEIC and several vendor screenshot
    // formats that the pure-Dart decoder intentionally does not bundle.
    try {
      final converted = await _platformChannel
          .invokeMethod<String>('normalizeImage', {
            'source': source.path,
            'target': target.path,
            'maxEdge': _maximumImageLongEdge,
          });
      if (converted != null && await File(converted).exists()) return converted;
    } on PlatformException {
      // Preserve the original path so the caller receives a precise runtime
      // error instead of losing access to the selected source file.
    }
    return sourcePath;
  }

  Future<String> _readTextStreamed(File file) async {
    final sink = StringBuffer();
    await for (final text in file.openRead().transform(utf8.decoder)) {
      if (sink.length >= _maximumExtractedCharacters) break;
      sink.write(text);
    }
    final text = sink.toString();
    return text.length > _maximumExtractedCharacters
        ? text.substring(0, _maximumExtractedCharacters)
        : text;
  }

  Future<String> _readOpenXml(File file, List<String>? exactNames) async {
    final input = InputFileStream(file.path);
    try {
      // Decode the ZIP directory from disk so large Office documents are not
      // copied into one in-memory byte array. Entry data is inflated lazily.
      final archive = ZipDecoder().decodeStream(input);
      final names =
          exactNames ??
                archive.files
                    .where(
                      (entry) => RegExp(
                        r'^ppt/slides/slide\d+\.xml$',
                      ).hasMatch(entry.name),
                    )
                    .map((entry) => entry.name)
                    .toList()
            ..sort();
      final buffer = StringBuffer();
      for (final name in names) {
        final entries = archive.files.where(
          (entry) => entry.name == name && entry.isFile,
        );
        if (entries.isEmpty) continue;
        final bytes = entries.first.content as List<int>;
        final document = XmlDocument.parse(utf8.decode(bytes));
        final nodes = document.descendants
            .whereType<XmlElement>()
            .where((node) => node.name.local == 't')
            .map((node) => node.innerText.trim())
            .where((text) => text.isNotEmpty);
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeAll(nodes, '\n');
        if (buffer.length >= _maximumExtractedCharacters) break;
      }
      final text = buffer.toString();
      return text.length > _maximumExtractedCharacters
          ? text.substring(0, _maximumExtractedCharacters)
          : text;
    } finally {
      await input.close();
    }
  }

  Future<String> _readSpreadsheet(File file) async {
    final input = InputFileStream(file.path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final names =
          archive.files
              .where(
                (entry) =>
                    entry.isFile &&
                    (entry.name == 'xl/sharedStrings.xml' ||
                        RegExp(
                          r'^xl/worksheets/sheet\d+\.xml$',
                        ).hasMatch(entry.name)),
              )
              .map((entry) => entry.name)
              .toList()
            ..sort();
      return _extractXmlEntries(archive, names, const {'t', 'v'});
    } finally {
      await input.close();
    }
  }

  Future<String> _readEpub(File file) async {
    final input = InputFileStream(file.path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final names =
          archive.files
              .where(
                (entry) =>
                    entry.isFile &&
                    RegExp(
                      r'\.(xhtml|html|htm)$',
                      caseSensitive: false,
                    ).hasMatch(entry.name),
              )
              .map((entry) => entry.name)
              .toList()
            ..sort();
      return _extractXmlEntries(archive, names, const {
        'p',
        'h1',
        'h2',
        'h3',
        'h4',
        'li',
      }, useInnerText: true);
    } finally {
      await input.close();
    }
  }

  String _extractXmlEntries(
    Archive archive,
    List<String> names,
    Set<String> nodeNames, {
    bool useInnerText = false,
  }) {
    final buffer = StringBuffer();
    for (final name in names) {
      final entries = archive.files.where(
        (entry) => entry.name == name && entry.isFile,
      );
      if (entries.isEmpty) continue;
      try {
        final document = XmlDocument.parse(
          utf8.decode(entries.first.content as List<int>, allowMalformed: true),
        );
        final values = document.descendants
            .whereType<XmlElement>()
            .where((node) => nodeNames.contains(node.name.local))
            .map(
              (node) => useInnerText ? node.innerText : node.innerText.trim(),
            )
            .where((text) => text.trim().isNotEmpty);
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeAll(values, '\n');
      } on XmlParserException {
        continue;
      }
      if (buffer.length >= _maximumExtractedCharacters) break;
    }
    final text = buffer.toString();
    return text.length > _maximumExtractedCharacters
        ? text.substring(0, _maximumExtractedCharacters)
        : text;
  }

  Future<String> _readRtf(File file) async {
    final source = await _readTextStreamed(file);
    return source
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), '')
        .replaceAll(RegExp(r"\\'[0-9a-fA-F]{2}"), '')
        .replaceAll(RegExp(r'[{}]'), '')
        .trim();
  }

  Future<String> _readPdf(File file) async {
    final bytes = await file.readAsBytes();
    final latin = latin1.decode(bytes, allowInvalid: true);
    final output = StringBuffer();
    for (final match in RegExp(
      r'stream\r?\n([\s\S]*?)\r?\nendstream',
    ).allMatches(latin)) {
      Uint8List stream = Uint8List.fromList(latin1.encode(match.group(1)!));
      final prefix = latin.substring(
        (match.start - 220).clamp(0, match.start).toInt(),
        match.start,
      );
      if (prefix.contains('/FlateDecode')) {
        try {
          stream = Uint8List.fromList(zlib.decode(stream));
        } on Object {
          continue;
        }
      }
      final decoded = latin1.decode(stream, allowInvalid: true);
      for (final textMatch in RegExp(
        r'\((.*?)(?<!\\)\)\s*Tj',
        dotAll: true,
      ).allMatches(decoded)) {
        output.writeln(_unescapePdf(textMatch.group(1)!));
        if (output.length >= _maximumExtractedCharacters) break;
      }
      if (output.length >= _maximumExtractedCharacters) break;
    }
    return output.toString();
  }

  String _unescapePdf(String value) => value
      .replaceAll(r'\(', '(')
      .replaceAll(r'\)', ')')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\r', '\n')
      .replaceAll(r'\\', String.fromCharCode(92));
}

String? _normalizeImageJob(String sourcePath, String targetPath, int maxEdge) {
  final decoded = image.decodeImage(File(sourcePath).readAsBytesSync());
  if (decoded == null) return null;
  final longest = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final normalized = longest <= maxEdge
      ? decoded
      : image.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxEdge : null,
          height: decoded.height > decoded.width ? maxEdge : null,
          interpolation: image.Interpolation.linear,
        );
  File(targetPath).writeAsBytesSync(image.encodePng(normalized, level: 6));
  return targetPath;
}
