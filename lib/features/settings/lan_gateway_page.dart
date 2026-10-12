import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/l10n.dart';

class LanGatewayPage extends ConsumerStatefulWidget {
  const LanGatewayPage({super.key});
  @override
  ConsumerState<LanGatewayPage> createState() => _LanGatewayPageState();
}

class _LanGatewayPageState extends ConsumerState<LanGatewayPage> {
  final _port = TextEditingController();
  final _token = TextEditingController();
  List<String> _addresses = [];
  bool _busy = false;
  bool _showToken = false;
  @override
  void initState() {
    super.initState();
    final service = ref.read(localGatewayServiceProvider);
    _port.text = '${service.configuredPort}';
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(localGatewayServiceProvider);
    final token = await service.ensureToken();
    final addresses = await service.addresses();
    if (mounted) {
      setState(() {
        _token.text = token;
        _addresses = addresses;
      });
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.gatewayFailure)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _port.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(localGatewayServiceProvider);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.lanGateway)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.gatewaySafety),
            ),
          ),
          SwitchListTile(
            title: Text(l.lanGatewayEnable),
            value: service.running,
            onChanged: _busy
                ? null
                : (_) => _act(() async {
                    if (service.running) {
                      await service.stop();
                    } else {
                      await service.start();
                    }
                  }),
          ),
          TextField(
            controller: _port,
            enabled: !service.running && !_busy,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.gatewayPort),
          ),
          TextField(
            controller: _token,
            enabled: !_busy,
            obscureText: !_showToken,
            decoration: InputDecoration(
              labelText: l.gatewayToken,
              suffixIcon: IconButton(
                icon: Icon(
                  _showToken ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showToken = !_showToken),
              ),
            ),
          ),
          FilledButton(
            onPressed: _busy || service.running
                ? null
                : () => _act(() async {
                    final port = int.tryParse(_port.text);
                    if (port == null) {
                      throw const FormatException('invalid-port');
                    }
                    await service.setToken(_token.text);
                    await service.setPort(port);
                  }),
            child: Text(l.gatewaySave),
          ),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => _act(() async {
                    await service.rotateToken();
                  }),
            icon: const Icon(Icons.refresh),
            label: Text(l.lanGatewayRotateToken),
          ),
          if (service.running)
            for (final address in _addresses) SelectableText(address),
          if (service.running) Text(l.gatewayStopFirst),
          SwitchListTile(
            title: Text(l.gatewayLoopback),
            value: service.option('loopbackOnly', fallback: false),
            onChanged: service.running || _busy
                ? null
                : (value) => _act(() async {
                    await service.setOption('loopbackOnly', value);
                  }),
          ),
          SwitchListTile(
            title: Text(l.gatewayWifi),
            value: service.option('wifiOnly'),
            onChanged: _busy
                ? null
                : (value) => _act(() async {
                    await service.setOption('wifiOnly', value);
                  }),
          ),
          SwitchListTile(
            title: Text(l.gatewayModels),
            value: service.option('allowModelList'),
            onChanged: _busy
                ? null
                : (value) => _act(() async {
                    await service.setOption('allowModelList', value);
                  }),
          ),
          SwitchListTile(
            title: Text(l.gatewayChat),
            value: service.option('allowRemoteChat', fallback: false),
            onChanged: _busy
                ? null
                : (value) => _act(() async {
                    await service.setOption('allowRemoteChat', value);
                  }),
          ),
          const Divider(),
          Text(l.gatewaySerial),
          ListTile(
            title: Text(l.gatewayTimeout),
            subtitle: Slider(
              value: service.requestTimeoutSeconds.toDouble().clamp(10, 1800),
              min: 10,
              max: 1800,
              divisions: 179,
              label: '${service.requestTimeoutSeconds}',
              onChanged: _busy
                  ? null
                  : (value) async {
                      await service.setRequestTimeoutSeconds(value.round());
                      if (mounted) setState(() {});
                    },
            ),
          ),
        ],
      ),
    );
  }
}
