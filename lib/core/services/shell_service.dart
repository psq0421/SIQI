import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../database/local_database.dart';
import '../models/app_models.dart';

class ShellResult {
  const ShellResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
  final int exitCode;
  final String stdout;
  final String stderr;
}

class ShellPolicyException implements Exception {
  const ShellPolicyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ShellService {
  const ShellService(this._database);
  final LocalDatabase _database;
  static const _workspaceExecutables = <String>{
    'bun',
    'cargo',
    'clang',
    'clang++',
    'cmake',
    'ctest',
    'dart',
    'flutter',
    'g++',
    'gcc',
    'git',
    'go',
    'gradle',
    'gradlew',
    'java',
    'javac',
    'kotlinc',
    'make',
    'ninja',
    'npm',
    'pnpm',
    'pytest',
    'python',
    'python3',
    'rustc',
    'swift',
    'yarn',
  };
  static const _readOnlyGitSubcommands = <String>{
    'blame',
    'describe',
    'diff',
    'grep',
    'log',
    'ls-files',
    'rev-parse',
    'show',
    'status',
  };
  static final _dangerousPatterns = <RegExp>[
    RegExp(r'(^|\s)rm\s+(-[^\s]*r[^\s]*f|-[^\s]*f[^\s]*r)\s'),
    RegExp(r'(^|\s)(mkfs|format|fdisk|dd)\b'),
    RegExp(r'>\s*/dev/(sd|nvme|mmcblk)'),
    RegExp(r'(^|\s)reboot\b'),
  ];
  static final _rootPatterns = <RegExp>[
    RegExp(r'(^|[;&|]\s*)(su|sudo)\b'),
    RegExp(r'(^|\s)(setenforce|magisk|resetprop)\b'),
    RegExp(r'(^|\s)(mount|umount)\s+[^\n]*(/system|/vendor|/product)\b'),
    RegExp(r'(^|\s)(pm\s+grant|appops\s+set)\b'),
  ];
  static const _maxCapturedBytes = 1024 * 1024;

  bool isDangerous(String command) => _dangerousPatterns.any(
    (pattern) => pattern.hasMatch(command.toLowerCase()),
  );

  bool isForbidden(String command) =>
      _rootPatterns.any((pattern) => pattern.hasMatch(command.toLowerCase()));

  /// Agent-generated commands use a deliberately smaller policy than the
  /// developer Shell. The Android application sandbox remains the primary OS
  /// boundary; this policy additionally rejects shell composition and paths
  /// that explicitly leave the user-selected workspace.
  bool isWorkspaceCommandAllowed(String command) {
    final normalized = command.trim();
    if (normalized.isEmpty ||
        isDangerous(normalized) ||
        isForbidden(normalized)) {
      return false;
    }
    if (RegExp(r'[\r\n;&|`<>$]').hasMatch(normalized) ||
        RegExp(r'(^|[\s="\x27])~(?:[/\\]|$)').hasMatch(normalized) ||
        RegExp(r'(^|[\s="\x27])\.\.(?:[/\\]|$)').hasMatch(normalized) ||
        RegExp(r'(^|[\s="\x27=])/(?!/)').hasMatch(normalized) ||
        RegExp(r'(^|[\s="\x27=])[A-Za-z]:[\\/]').hasMatch(normalized)) {
      return false;
    }

    final words = normalized.split(RegExp(r'\s+'));
    final executable = words.first
        .replaceFirst(RegExp(r'^\./'), '')
        .replaceAll(RegExp(r'''^["']|["']$'''), '');
    if (!_workspaceExecutables.contains(executable)) return false;

    if (executable == 'git') {
      final subcommand = words
          .skip(1)
          .firstWhere((word) => !word.startsWith('-'), orElse: () => '');
      return _readOnlyGitSubcommands.contains(subcommand);
    }
    return true;
  }

  Future<ShellResult> run(
    String command,
    ShellEnvironment environment, {
    String? workingDirectory,
  }) async {
    if (isForbidden(command)) {
      throw const ShellPolicyException(
        'Root, privilege escalation, and protected-partition changes are not available.',
      );
    }
    final executable = switch (environment) {
      ShellEnvironment.system => 'sh',
      ShellEnvironment.termux => '/data/data/com.termux/files/usr/bin/sh',
      ShellEnvironment.shizuku => 'sh',
    };
    await _database.addWorkLog(
      category: 'shell',
      title: 'shell task',
      detail: command,
      status: 'started',
    );
    final process = await Process.start(
      executable,
      ['-c', command],
      runInShell: false,
      workingDirectory: workingDirectory,
      environment: {
        'LANG': 'C.UTF-8',
        'LC_ALL': 'C.UTF-8',
        'PATH':
            Platform.environment['PATH'] ??
            '/system/bin:/system/xbin:/vendor/bin:/product/bin',
      },
      includeParentEnvironment: true,
    );
    final stdout = StringBuffer();
    final stderr = StringBuffer();
    var stdoutBytes = 0;
    var stderrBytes = 0;
    var timedOut = false;

    Future<void> capture(
      Stream<List<int>> stream,
      StringBuffer target,
      bool isStandardOutput,
    ) async {
      await for (final chunk in stream) {
        final used = isStandardOutput ? stdoutBytes : stderrBytes;
        final remaining = _maxCapturedBytes - used;
        if (remaining <= 0) continue;
        final accepted = chunk.length <= remaining
            ? chunk
            : chunk.sublist(0, remaining);
        target.write(utf8.decode(accepted, allowMalformed: true));
        if (isStandardOutput) {
          stdoutBytes += accepted.length;
        } else {
          stderrBytes += accepted.length;
        }
      }
    }

    final stdoutTask = capture(process.stdout, stdout, true);
    final stderrTask = capture(process.stderr, stderr, false);
    final timer = Timer(const Duration(minutes: 2), () {
      timedOut = true;
      process.kill(ProcessSignal.sigkill);
    });
    final exitCode = await process.exitCode;
    timer.cancel();
    await Future.wait([stdoutTask, stderrTask]);
    if (stdoutBytes >= _maxCapturedBytes) {
      stdout.write('\n[output truncated at 1 MiB]');
    }
    if (stderrBytes >= _maxCapturedBytes) {
      stderr.write('\n[error output truncated at 1 MiB]');
    }
    if (timedOut) stderr.write('\n[task stopped after 2 minutes]');
    final resolvedExitCode = timedOut ? 124 : exitCode;
    await _database.saveShellCommand(command, resolvedExitCode);
    await _database.addWorkLog(
      category: 'shell',
      title: 'shell task',
      detail:
          'exit=$resolvedExitCode · stdout=$stdoutBytes B · stderr=$stderrBytes B',
      status: resolvedExitCode == 0 ? 'completed' : 'failed',
    );
    return ShellResult(
      exitCode: resolvedExitCode,
      stdout: stdout.toString(),
      stderr: stderr.toString(),
    );
  }
}
