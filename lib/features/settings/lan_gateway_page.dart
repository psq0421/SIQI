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
    appBar: AppBar(title: const Text('局域网网关')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('可选的加密局域网控制台，端口 1158。默认关闭，仅建议在可信 Wi‑Fi 内使用。'),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _running,
          onChanged: (_) => _toggle(),
          title: const Text('启用局域网网关'),
          subtitle: Text(_running ? '监听地址：0.0.0.0:1158' : '已关闭'),
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
            label: const Text('更换设备密令'),
          ),
        ],
        const Divider(height: 32),
        const Text('网关访问控制', style: TextStyle(fontWeight: FontWeight.w700)),
        SwitchListTile(
          value: _requireToken,
          onChanged: (value) =>
              _setOption('requireToken', value, () => _requireToken = value),
          title: const Text('必须验证设备密令'),
          subtitle: const Text('拒绝未通过身份验证的请求。'),
        ),
        SwitchListTile(
          value: _wifiOnly,
          onChanged: (value) =>
              _setOption('wifiOnly', value, () => _wifiOnly = value),
          title: const Text('仅允许 Wi‑Fi 客户端'),
          subtitle: const Text('限制为本地 WLAN 内的设备访问。'),
        ),
        SwitchListTile(
          value: _allowModelList,
          onChanged: (value) => _setOption(
            'allowModelList',
            value,
            () => _allowModelList = value,
          ),
          title: const Text('允许查看模型列表'),
          subtitle: const Text('通过验证的客户端可以查看本机模型。'),
        ),
        SwitchListTile(
          value: _allowRemoteChat,
          onChanged: (value) => _setOption(
            'allowRemoteChat',
            value,
            () => _allowRemoteChat = value,
          ),
          title: const Text('允许远程对话'),
          subtitle: const Text('开放需要密令验证的对话接口。'),
        ),
        SwitchListTile(
          value: _allowFileUpload,
          onChanged: (value) => _setOption(
            'allowFileUpload',
            value,
            () => _allowFileUpload = value,
          ),
          title: const Text('允许上传文件'),
          subtitle: const Text('除非明确需要，否则建议保持关闭。'),
        ),
        SwitchListTile(
          value: _auditLog,
          onChanged: (value) =>
              _setOption('auditLog', value, () => _auditLog = value),
          title: const Text('记录网关审计日志'),
          subtitle: const Text('仅在本地保存请求元数据。'),
        ),
        ListTile(
          title: const Text('最大并发任务数'),
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
          title: const Text('请求超时时间'),
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
