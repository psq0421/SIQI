import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/platform_service.dart';
import '../../l10n/l10n.dart';

class CpuPerformancePage extends ConsumerStatefulWidget {
  const CpuPerformancePage({super.key});

  @override
  ConsumerState<CpuPerformancePage> createState() => _CpuPerformancePageState();
}

class _CpuPerformancePageState extends ConsumerState<CpuPerformancePage> {
  DeviceRuntimeInfo? _runtime;
  final _selected = <int>{};
  bool _loading = true;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final runtime = await ref.read(platformServiceProvider).runtimeInfo();
    if (!mounted) return;
    setState(() {
      _runtime = runtime;
      _selected
        ..clear()
        ..addAll(() {
          final saved = ref.read(settingsProvider).selectedCpuCores;
          final available = runtime.cpuCores
              .map((core) => (core['id'] as num).toInt())
              .toSet();
          final selected = saved.where(available.contains).toSet();
          return selected.isEmpty ? available : selected;
        }());
      _loading = false;
    });
  }

  Future<void> _apply() async {
    final runtime = _runtime;
    if (runtime == null || _selected.isEmpty) return;
    setState(() => _applying = true);
    final ok = await ref
        .read(platformServiceProvider)
        .setCpuAffinity(_selected.toList()..sort());
    if (ok) {
      await ref.read(settingsProvider.notifier).update(
            (current) => current.copyWith(
              selectedCpuCores: (_selected.toList()..sort()),
            ),
          );
    }
    if (mounted) {
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? context.l10n.cpuApplied : context.l10n.cpuApplyFailed,
          ),
        ),
      );
    }
  }

  String _frequency(Object? value) {
    final hz = (value as num?)?.toDouble() ?? 0;
    return '${(hz / 1000000000).toStringAsFixed(2)} GHz';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final runtime = _runtime;
    return Scaffold(
      appBar: AppBar(title: Text(l.cpuPerformance)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${l.cpuCoreSelectionDescription}\n\n${l.cpuSmallCoreWarning}',
                    ),
                  ),
                ),
                if (runtime != null)
                  Card(
                    child: ListTile(
                      title: Text(
                        runtime.socModel.isEmpty ? 'SoC' : runtime.socModel,
                      ),
                      subtitle: Text(
                        '${l.npuStatus}: ${runtime.npuOptimizationEligible ? l.npuEligible : l.npuUnavailable}\n'
                        '${runtime.npuOptimizationProfile}',
                      ),
                      trailing: const Icon(Icons.memory_outlined),
                    ),
                  ),
                for (final core
                    in runtime?.cpuCores ?? const <Map<String, Object?>>[])
                  CheckboxListTile(
                    value: _selected.contains((core['id'] as num).toInt()),
                    onChanged: _applying
                        ? null
                        : (value) => setState(() {
                            final id = (core['id'] as num).toInt();
                            if (value == true) {
                              _selected.add(id);
                            } else if (_selected.length > 1) {
                              _selected.remove(id);
                            }
                            final selected = _selected.toList()..sort();
                            ref.read(settingsProvider.notifier).update(
                              (current) => current.copyWith(
                                selectedCpuCores: selected,
                              ),
                            );
                          }),
                    title: Text(
                      '${l.cpuCore} ${(core['id'] as num).toInt()} · ${core['architecture']}',
                    ),
                    subtitle: Text(_frequency(core['maxFrequencyHz'])),
                  ),
                FilledButton.icon(
                  onPressed: _applying || _selected.isEmpty ? null : _apply,
                  icon: const Icon(Icons.tune),
                  label: Text(l.cpuApply),
                ),
              ],
            ),
    );
  }
}
