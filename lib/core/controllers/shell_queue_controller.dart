import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';
import '../models/workbench_models.dart';
import '../services/shell_service.dart';

class ShellQueueController extends StateNotifier<List<ShellQueueItem>> {
  ShellQueueController(this._shell, this._settings) : super(const []);
  final ShellService _shell;
  final AppSettings Function() _settings;
  bool _draining = false;

  void enqueue(String command) {
    final normalized = command.trim();
    if (normalized.isEmpty) return;
    state = [
      ...state,
      ShellQueueItem(
        id: const Uuid().v4(),
        command: normalized,
        createdAt: DateTime.now(),
      ),
    ];
    unawaited(_drain());
  }

  void cancelQueued(String id) {
    state = [
      for (final item in state)
        if (item.id == id && item.status == ShellQueueStatus.queued)
          item.copyWith(status: ShellQueueStatus.cancelled)
        else
          item,
    ];
  }

  void clearCompleted() {
    state = state
        .where(
          (item) =>
              item.status == ShellQueueStatus.queued ||
              item.status == ShellQueueStatus.running,
        )
        .toList();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (mounted) {
        final index = state.indexWhere(
          (item) => item.status == ShellQueueStatus.queued,
        );
        if (index < 0) break;
        final item = state[index];
        _replace(item.copyWith(status: ShellQueueStatus.running));
        try {
          final settings = _settings();
          final result = await _shell.run(
            item.command,
            settings.shellEnvironment,
            workingDirectory: settings.activeWorkspacePath,
          );
          _replace(
            item.copyWith(
              status: result.exitCode == 0
                  ? ShellQueueStatus.completed
                  : ShellQueueStatus.failed,
              stdout: result.stdout,
              stderr: result.stderr,
              exitCode: result.exitCode,
            ),
          );
        } on Object catch (error) {
          _replace(
            item.copyWith(
              status: ShellQueueStatus.failed,
              stderr: error.toString(),
              exitCode: -1,
            ),
          );
        }
      }
    } finally {
      _draining = false;
    }
  }

  void _replace(ShellQueueItem updated) {
    if (!mounted) return;
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
  }
}
