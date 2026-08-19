import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/workbench_models.dart';
import 'workspace_service.dart';

class HarnessService {
  const HarnessService(this._workspace);
  final WorkspaceService _workspace;

  Future<HarnessReport> analyzeWorkspace(String rootPath) async {
    final snapshot = await _workspace.snapshot(rootPath);
    final issues = <ScanIssue>[];
    final drafts = <String, String>{};
    var scanned = 0;
    for (final relativePath in snapshot.files) {
      final language = _workspace.languageForPath(relativePath);
      if (language == null) continue;
      final file = File(
        _workspace.resolveSafe(snapshot.rootPath, relativePath),
      );
      if (await file.length() > WorkspaceService.maximumTextBytes) continue;
      String content;
      try {
        content = await file.readAsString();
      } on Object {
        continue;
      }
      scanned++;
      issues.addAll(_scan(relativePath, content, language));
      if (_isTestCandidate(relativePath, language)) {
        drafts[relativePath] = generateTestDraft(
          relativePath,
          content,
          language,
        );
      }
    }
    issues.sort((a, b) {
      final severity = b.severity.index.compareTo(a.severity.index);
      return severity != 0 ? severity : a.filePath.compareTo(b.filePath);
    });
    return HarnessReport(
      generatedAt: DateTime.now(),
      snapshot: snapshot,
      issues: issues,
      scannedFiles: scanned,
      testDrafts: drafts,
    );
  }

  List<ScanIssue> _scan(String path, String content, String language) {
    final issues = <ScanIssue>[];
    final lines = content.split('\n');
    void add(
      String rule,
      ScanSeverity severity,
      int line,
      String key, [
      String? evidence,
    ]) => issues.add(
      ScanIssue(
        ruleId: rule,
        severity: severity,
        filePath: path,
        line: line + 1,
        messageKey: key,
        evidence: evidence,
      ),
    );
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trim();
      if (line.length > 140) {
        add(
          'style.long-line',
          ScanSeverity.info,
          index,
          'longLine',
          line.substring(0, 100),
        );
      }
      if (RegExp(r'\b(TODO|FIXME|HACK)\b').hasMatch(line)) {
        add(
          'maintainability.todo',
          ScanSeverity.info,
          index,
          'todoMarker',
          trimmed,
        );
      }
      if (RegExp(
        r'(api[_-]?key|secret|password|token)\s*[:=]\s*[\x27\x22][^\x27\x22]{8,}',
        caseSensitive: false,
      ).hasMatch(line)) {
        add(
          'security.hardcoded-secret',
          ScanSeverity.error,
          index,
          'hardcodedSecret',
        );
      }
      if (RegExp(r'\b(eval|exec)\s*\(').hasMatch(line) &&
          language == 'Python') {
        add(
          'security.dynamic-execution',
          ScanSeverity.error,
          index,
          'dynamicExecution',
          trimmed,
        );
      }
      if (RegExp(
        r'Process\.run\([^\n]*-c|Runtime\.getRuntime\(\)\.exec|subprocess\..*shell\s*=\s*True',
      ).hasMatch(line)) {
        add(
          'security.shell-injection',
          ScanSeverity.warning,
          index,
          'shellInjection',
          trimmed,
        );
      }
      if (RegExp(
        r'(SELECT|INSERT|UPDATE|DELETE).*(\$\{|\+\s*\w+)',
        caseSensitive: false,
      ).hasMatch(line)) {
        add(
          'security.sql-interpolation',
          ScanSeverity.warning,
          index,
          'sqlInterpolation',
          trimmed,
        );
      }
      if (RegExp(r'catch\s*\([^)]*\)\s*\{?\s*\}?$').hasMatch(trimmed)) {
        add(
          'correctness.empty-catch',
          ScanSeverity.warning,
          index,
          'emptyCatch',
        );
      }
      if (RegExp(r'\b(print|console\.log|System\.out\.print)').hasMatch(line) &&
          !path.toLowerCase().contains('test')) {
        add(
          'maintainability.debug-output',
          ScanSeverity.info,
          index,
          'debugOutput',
          trimmed,
        );
      }
      if (RegExp(r'http://').hasMatch(line) &&
          !RegExp(r'(localhost|127\.0\.0\.1)').hasMatch(line)) {
        add(
          'security.cleartext-url',
          ScanSeverity.warning,
          index,
          'cleartextUrl',
          trimmed,
        );
      }
      if (RegExp(
        r'\brm\s+-[^\n]*r[^\n]*f|\bformat\b|\bmkfs\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        add(
          'security.destructive-command',
          ScanSeverity.error,
          index,
          'destructiveCommand',
          trimmed,
        );
      }
    }
    if (language == 'Dart' &&
        content.contains('TextEditingController(') &&
        !content.contains('dispose()')) {
      add(
        'lifecycle.missing-dispose',
        ScanSeverity.warning,
        0,
        'missingDispose',
      );
    }
    if ((language == 'JavaScript' || language == 'TypeScript') &&
        content.contains('innerHTML =')) {
      add('security.inner-html', ScanSeverity.warning, 0, 'innerHtml');
    }
    return issues;
  }

  bool _isTestCandidate(String path, String language) {
    final normalized = path.toLowerCase();
    if (normalized.contains('/test/') ||
        normalized.contains('\\test\\') ||
        normalized.endsWith('_test.dart')) {
      return false;
    }
    return const {
      'Dart',
      'Kotlin',
      'Java',
      'Python',
      'JavaScript',
      'TypeScript',
      'Go',
      'Rust',
    }.contains(language);
  }

  String generateTestDraft(String path, String content, String language) {
    final base = p.basenameWithoutExtension(path);
    return switch (language) {
      'Dart' =>
        "import 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  group('$base', () {\n    test('handles normal and boundary input', () {\n      // Arrange\n      // Act\n      // Assert\n    });\n  });\n}\n",
      'Kotlin' =>
        "import kotlin.test.Test\nimport kotlin.test.assertTrue\n\nclass ${_pascal(base)}Test {\n    @Test fun handlesNormalAndBoundaryInput() {\n        assertTrue(true)\n    }\n}\n",
      'Java' =>
        "import org.junit.jupiter.api.Test;\nimport static org.junit.jupiter.api.Assertions.assertTrue;\n\nclass ${_pascal(base)}Test {\n    @Test void handlesNormalAndBoundaryInput() {\n        assertTrue(true);\n    }\n}\n",
      'Python' =>
        "def test_${_snake(base)}_handles_normal_and_boundary_input():\n    # Arrange / Act / Assert\n    assert True\n",
      'JavaScript' || 'TypeScript' =>
        "describe('$base', () => {\n  it('handles normal and boundary input', () => {\n    expect(true).toBe(true);\n  });\n});\n",
      'Go' =>
        "package ${_snake(base)}\n\nimport \"testing\"\n\nfunc Test${_pascal(base)}(t *testing.T) {\n    // Arrange / Act / Assert\n}\n",
      'Rust' =>
        "#[cfg(test)]\nmod tests {\n    #[test]\n    fn handles_normal_and_boundary_input() {\n        assert!(true);\n    }\n}\n",
      _ => '',
    };
  }

  String _pascal(String value) => value
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();
  String _snake(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
}
