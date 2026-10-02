import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';

class LanGatewayPage extends ConsumerStatefulWidget {
  const LanGatewayPage({super.key});
  @override
  ConsumerState<LanGatewayPage> createState() => _LanGatewayPageState();
}

class _LanGatewayPageState extends ConsumerState<LanGatewayPage> {
  bool _running = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _running = ref.read(localGatewayServiceProvider).running;
  }

  Future<void> _toggle() async {
    final service = ref.read(localGatewayServiceProvider);
    if (_running) {
      await service.stop();
    } else {
      await service.start();
      _token = await service.ensureToken();
    }
    if (mounted) setState(() => _running = service.running);
  }

  Future<void> _rotate() async {
    final token = await ref.read(localGatewayServiceProvider).rotateToken();
    if (mounted) setState(() => _token = token);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('LAN gateway')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Optional encrypted local-network control panel on port 1158. It is disabled by default.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _running,
          onChanged: (_) => _toggle(),
          title: const Text('Enable LAN gateway'),
          subtitle: Text(_running ? '0.0.0.0:1158' : 'Disabled'),
        ),
        if (_token != null) ...[
          const SizedBox(height: 12),
          SelectableText(
            _token!,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          TextButton.icon(
            onPressed: _rotate,
            icon: const Icon(Icons.refresh),
            label: const Text('Rotate device token'),
          ),
        ],
      ],
    ),
  );
}
