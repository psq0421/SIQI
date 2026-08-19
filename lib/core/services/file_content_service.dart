import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../constants/app_constants.dart';
import '../models/app_models.dart';

class FileContentService {
  static const _largeFileThreshold = 5 * 1024 * 1024;
  static const _maximumExtractedCharacters = 180000;

  Future<List<AppAttachment>> pick({required bool multimodal}) async {
    final allowed = <String>{
      ...AppConstants.supportedTextExtensions,
      ...AppConstants.richDocumentExtensions,
      if (multimodal) ...[
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
        'wav',
        'mp3',
        'm4a',
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

  Future<AppAttachment> read(String path, {required bool multimodal}) async {
    final file = File(path);
    final size = await file.length();
    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    final mime = lookupMimeType(path) ?? 'application/octet-stream';
    if (mime.startsWith('image/') || mime.startsWith('audio/')) {
      if (!multimodal) throw UnsupportedError('multimodal-disabled');
      final data = await file.readAsBytes();
      return AppAttachment(
        name: p.basename(path),
        path: path,
        mimeType: mime,
        base64Data: base64Encode(data),
        size: size,
      );
    }
    final text = switch (extension) {
      'pdf' => await _readPdf(file),
      'docx' => await _readOpenXml(file, const ['word/document.xml']),
      'pptx' => await _readOpenXml(file, null),
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
