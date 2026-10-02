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
  bool _allowModelList = true;
  bool _allowRemoteChat = false;
  bool _allowFileUpload = false;
  bool _auditLog = true;
  bool _wifiOnly = true;
  bool _requireToken = true;
  int _maxJobs = 1;
  double _timeout = 120;

  @override
  void initState() {
    super.initState();
    final service = ref.read(localGatewayServiceProvider);
    _running = service.running;
    _allowModelList = service.option('allowModelList');
    _allowRemoteChat = service.option('allowRemoteChat', fallback: false);
    _allowFileUpload = service.option('allowFileUpload', fallback: false);
    _auditLog = service.option('auditLog');
    _wifiOnly = service.option('wifiOnly');
    _requireToken = service.option('requireToken');
    _maxJobs = service.maxConcurrentJobs;
    _timeout = service.requestTimeoutSeconds.toDouble();
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

  Future<void> _setOption(
    String key,
    bool value,
    void Function() update,
  ) async {
    await ref.read(localGatewayServiceProvider).setOption(key, value);
    if (mounted) setState(update);
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
        const Divider(height: 32),
        const Text(
          'Gateway access controls',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SwitchListTile(
          value: _requireToken,
          onChanged: (value) =>
              _setOption('requireToken', value, () => _requireToken = value),
          title: const Text('Require device token'),
          subtitle: const Text('Reject unauthenticated requests.'),
        ),
        SwitchListTile(
          value: _wifiOnly,
          onChanged: (value) =>
              _setOption('wifiOnly', value, () => _wifiOnly = value),
          title: const Text('Prefer Wi‑Fi clients'),
          subtitle: const Text('Keep the gateway intended for local WLAN.'),
        ),
        SwitchListTile(
          value: _allowModelList,
          onChanged: (value) => _setOption(
            'allowModelList',
            value,
            () => _allowModelList = value,
          ),
          title: const Text('Expose model list'),
          subtitle: const Text('Authenticated clients can view models.'),
        ),
        SwitchListTile(
          value: _allowRemoteChat,
          onChanged: (value) => _setOption(
            'allowRemoteChat',
            value,
            () => _allowRemoteChat = value,
          ),
          title: const Text('Allow remote chat'),
          subtitle: const Text('Enable the authenticated chat endpoint.'),
        ),
        SwitchListTile(
          value: _allowFileUpload,
          onChanged: (value) => _setOption(
            'allowFileUpload',
            value,
            () => _allowFileUpload = value,
          ),
          title: const Text('Allow file upload'),
          subtitle: const Text(
            'Keep disabled unless a trusted client needs it.',
          ),
        ),
        SwitchListTile(
          value: _auditLog,
          onChanged: (value) =>
              _setOption('auditLog', value, () => _auditLog = value),
          title: const Text('Write gateway audit log'),
          subtitle: const Text('Keep request metadata locally.'),
        ),
        ListTile(
          title: const Text('Maximum concurrent jobs'),
          subtitle: Slider(
            value: _maxJobs.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '$_maxJobs',
            onChanged: (value) async {
              final jobs = value.round();
              await ref
                  .read(localGatewayServiceProvider)
                  .setMaxConcurrentJobs(jobs);
              if (mounted) setState(() => _maxJobs = jobs);
            },
          ),
        ),
        ListTile(
          title: const Text('Request timeout'),
          subtitle: Slider(
            value: _timeout,
            min: 10,
            max: 1800,
            divisions: 35,
            label: '${_timeout.round()} s',
            onChanged: (value) async {
              await ref
                  .read(localGatewayServiceProvider)
                  .setRequestTimeoutSeconds(value.round());
              if (mounted) setState(() => _timeout = value);
            },
          ),
        ),
      ],
    ),
  );
}
