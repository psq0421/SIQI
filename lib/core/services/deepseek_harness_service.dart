import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../database/local_database.dart';
import '../models/workbench_models.dart';

class DeepSeekHarnessService {
  const DeepSeekHarnessService(this._dio, this._database);

  final Dio _dio;
  final LocalDatabase _database;

  static final _repositoryPattern = RegExp(
    r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$',
  );
  static final _blockedBrand = RegExp(
    String.fromCharCodes(const [99, 111, 100, 101, 120]),
    caseSensitive: false,
  );

  Future<void> syncPluginCatalog(
    void Function(int completedPages, int totalPages, int pluginCount)
    onProgress,
  ) async {
    final first = await _fetchCatalogPage(1);
    await _database.upsertHarnessPlugins(first.plugins);
    var count = first.plugins.length;
    onProgress(1, first.totalPages, count);

    const concurrency = 4;
    for (var start = 2; start <= first.totalPages; start += concurrency) {
      final end = (start + concurrency - 1).clamp(2, first.totalPages);
      final pages = await Future.wait([
        for (var page = start; page <= end; page++) _fetchCatalogPage(page),
      ]);
      final plugins = pages.expand((page) => page.plugins).toList();
      await _database.upsertHarnessPlugins(plugins);
      count += plugins.length;
      onProgress(end, first.totalPages, count);
    }
  }

  Future<({List<HarnessPlugin> plugins, int totalPages})> _fetchCatalogPage(
    int page,
  ) async {
    final response = await _dio.get<String>(
      AppConstants.harnessPluginCatalogUrl,
      queryParameters: {if (page > 1) 'page': page},
      options: Options(responseType: ResponseType.plain),
    );
    final document = html_parser.parse(response.data ?? '');
    final totalPages = document
        .querySelectorAll('.pagination .page-link')
        .map((element) {
          final href = element.attributes['href'];
          if (href == null) return 1;
          return int.tryParse(
                Uri.parse(
                      'https://catalog.local/$href',
                    ).queryParameters['page'] ??
                    '1',
              ) ??
              1;
        })
        .fold<int>(1, (maximum, value) => value > maximum ? value : maximum);
    final syncedAt = DateTime.now();
    final plugins = <HarnessPlugin>[];
    for (final card in document.querySelectorAll('article.project-card')) {
      final link = card.querySelector('.project-card__identity h2 a');
      final href = link?.attributes['href'];
      if (href == null) continue;
      final repositoryId = Uri.parse(
        'https://catalog.local/$href',
      ).queryParameters['id'];
      if (repositoryId == null || !_repositoryPattern.hasMatch(repositoryId)) {
        continue;
      }
      final metrics = card.querySelectorAll('.project-card__metrics > span');
      plugins.add(
        HarnessPlugin(
          repositoryId: repositoryId,
          name: _clean(link?.text ?? repositoryId.split('/').last),
          owner: _clean(
            card.querySelector('.project-card__identity p')?.text ??
                repositoryId.split('/').first,
          ),
          description: _clean(
            card.querySelector('.project-card__description')?.text ?? '',
          ),
          category: _clean(card.querySelector('.mono-label')?.text ?? ''),
          kind: _clean(card.querySelector('.project-card__type')?.text ?? ''),
          repositoryUrl: 'https://github.com/$repositoryId',
          detailUrl:
              'https://dsh.deepseek404.com/detail.php?id=${Uri.encodeQueryComponent(repositoryId)}',
          stars: _clean(metrics.isEmpty ? '' : metrics.first.text),
          updatedLabel: _clean(
            card.querySelector('.project-card__updated')?.text ?? '',
          ),
          syncedAt: syncedAt,
        ),
      );
    }
    return (plugins: plugins, totalPages: totalPages);
  }

  String _clean(String value) => value
      .replaceAll(_blockedBrand, 'AI coding tool')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<HarnessPlugin> downloadPlugin(
    HarnessPlugin plugin, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (!_repositoryPattern.hasMatch(plugin.repositoryId)) {
      throw const FormatException('Invalid GitHub repository identifier.');
    }
    final apiHeaders = {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };
    final repository = await _dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/${plugin.repositoryId}',
      options: Options(headers: apiHeaders),
    );
    final data = repository.data;
    if (data == null || data['archived'] == true || data['disabled'] == true) {
      throw StateError('The repository is unavailable or archived.');
    }
    final branch = data['default_branch'] as String?;
    if (branch == null || branch.isEmpty) {
      throw StateError('The repository has no default branch.');
    }
    final commit = await _dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/${plugin.repositoryId}/commits/${Uri.encodeComponent(branch)}',
      options: Options(headers: apiHeaders),
    );
    final sha = commit.data?['sha'] as String?;
    if (sha == null || !RegExp(r'^[a-f0-9]{40}$').hasMatch(sha)) {
      throw const FormatException('GitHub did not return a valid commit hash.');
    }
    final licenseData = data['license'];
    final license = licenseData is Map
        ? licenseData['spdx_id'] as String? ?? 'NOASSERTION'
        : 'NOASSERTION';
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'harness', 'plugins'));
    await directory.create(recursive: true);
    final safeName = plugin.repositoryId.replaceAll('/', '--');
    final target = File(
      p.join(directory.path, '$safeName-${sha.substring(0, 12)}.zip'),
    );
    final partial = '${target.path}.part';
    await _dio.download(
      'https://api.github.com/repos/${plugin.repositoryId}/zipball/$sha',
      partial,
      options: Options(headers: apiHeaders),
      onReceiveProgress: onProgress,
    );
    final partialFile = File(partial);
    if (await target.exists()) await target.delete();
    await partialFile.rename(target.path);
    await _database.saveHarnessPluginArchive(
      plugin.repositoryId,
      archivePath: target.path,
      commitSha: sha,
      license: license,
    );
    return HarnessPlugin.fromDatabase({
      ...plugin.toDatabase(),
      'archive_path': target.path,
      'commit_sha': sha,
      'license': license,
    });
  }

  Future<void> uninstallPlugin(HarnessPlugin plugin) async {
    final path = plugin.archivePath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await _database.clearHarnessPluginArchive(plugin.repositoryId);
  }

  String installCommand(HarnessPlugin plugin) {
    final revision = plugin.commitSha;
    if (revision == null || revision.isEmpty) return '';
    return 'npx @deepseek-ai/dsh@${AppConstants.harnessVersion} plugin --profile siqi add github:${plugin.repositoryId}#$revision';
  }

  Future<File> downloadRuntime({
    void Function(int received, int total)? onProgress,
  }) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'harness', 'runtime'));
    await directory.create(recursive: true);
    final target = File(
      p.join(directory.path, 'dsh-${AppConstants.harnessVersion}.tgz'),
    );
    final partial = '${target.path}.part';
    await _dio.download(
      AppConstants.harnessNpmTarballUrl,
      partial,
      onReceiveProgress: onProgress,
    );
    final partialFile = File(partial);
    if (await target.exists()) await target.delete();
    await partialFile.rename(target.path);
    final integrity = base64Encode(
      (await sha512.bind(target.openRead()).first).bytes,
    );
    if (integrity != AppConstants.harnessNpmSha512) {
      await target.delete();
      throw const FormatException('Official runtime integrity check failed.');
    }
    final digest = await sha256.bind(target.openRead()).first;
    final checksum = File('${target.path}.sha256');
    await checksum.writeAsString(digest.toString(), flush: true);
    return target;
  }

  Future<File?> runtimeArchive() async {
    final support = await getApplicationSupportDirectory();
    final file = File(
      p.join(
        support.path,
        'harness',
        'runtime',
        'dsh-${AppConstants.harnessVersion}.tgz',
      ),
    );
    return await file.exists() ? file : null;
  }
}
