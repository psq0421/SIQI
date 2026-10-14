import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/app_models.dart';
import 'local_inference_service.dart';
import 'model_download_service.dart';
import 'platform_service.dart';

/// Disabled by default. HTTP is NOT encrypted in transit. Use trusted WLAN,
/// ADB forwarding, or a user-controlled TLS tunnel, never naked public HTTP.
class LocalGatewayService {
  LocalGatewayService(
    this._storage,
    this._preferences,
    this._inference,
    this._downloads,
    this._platform,
  );
  final FlutterSecureStorage _storage;
  final SharedPreferences _preferences;
  final LocalInferenceService _inference;
  final ModelDownloadService _downloads;
  final PlatformService _platform;
  HttpServer? _server;
  String? _token;
  bool _reserved = false;
  bool runningRequest = false;
  static const _tokenKey = 'gateway_token';
  bool get running => _server != null;
  int? get port => _server?.port;
  int get configuredPort => _preferences.getInt('gateway_port') ?? 1158;
  bool option(String key, {bool fallback = true}) =>
      _preferences.getBool('gateway_$key') ?? fallback;
  Future<void> setOption(String key, bool value) =>
      _preferences.setBool('gateway_$key', value);
  int get maxConcurrentJobs => 1;
  Future<void> setMaxConcurrentJobs(int value) =>
      _preferences.setInt('gateway_max_jobs', 1);
  int get requestTimeoutSeconds =>
      _preferences.getInt('gateway_timeout') ?? 300;
  Future<void> setRequestTimeoutSeconds(int value) =>
      _preferences.setInt('gateway_timeout', value.clamp(10, 1800));
  Future<void> setPort(int value) async {
    if (value < 1024 || value > 65535) {
      throw const FormatException('invalid-port');
    }
    if (running) throw StateError('stop-gateway-before-port-change');
    await _preferences.setInt('gateway_port', value);
  }

  Future<String> setToken(String value) async {
    if (value.length < 24 ||
        value.length > 256 ||
        value.contains(RegExp(r'\s'))) {
      throw const FormatException(
        'token-requires-24-to-256-non-space-characters',
      );
    }
    await _storage.write(key: _tokenKey, value: value);
    return _token = value;
  }

  Future<String> rotateToken() {
    final random = Random.secure();
    return setToken(
      base64UrlEncode(List.generate(32, (_) => random.nextInt(256))),
    );
  }

  Future<String> ensureToken() async {
    final existing = await _storage.read(key: _tokenKey);
    return existing != null && existing.length >= 24
        ? _token = existing
        : rotateToken();
  }

  Future<List<String>> addresses() async => [
    'http://127.0.0.1:${port ?? configuredPort}',
    if (!option('loopbackOnly', fallback: false))
      for (final interface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      ))
        for (final address in interface.addresses)
          if (_private(address))
            'http://${address.address}:${port ?? configuredPort}',
  ];
  Future<void> start({int? port}) async {
    if (running) return;
    await ensureToken();
    final server = await HttpServer.bind(
      option('loopbackOnly', fallback: false)
          ? InternetAddress.loopbackIPv4
          : InternetAddress.anyIPv4,
      port ?? configuredPort,
      shared: false,
    );
    _server = server;
    server.idleTimeout = const Duration(seconds: 30);
    server.listen(
      (request) => unawaited(_handleSafe(request)),
      onError: (Object _) {},
    );
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (runningRequest) await _inference.cancel();
    await server?.close(force: true);
  }

  Future<void> _json(HttpRequest r, int code, Object body) async {
    r.response.statusCode = code;
    r.response.headers.contentType = ContentType.json;
    r.response.write(jsonEncode(body));
    await r.response.close();
  }

  Future<void> _handleSafe(HttpRequest r) async {
    try {
      await _handle(r);
    } on Object {
      try {
        await r.response.close();
      } on Object {
        /* disconnected */
      }
    }
  }

  Future<void> _handle(HttpRequest r) async {
    var streamed = false;
    try {
      r.response.headers.set('cache-control', 'no-store');
      r.response.headers.set('x-content-type-options', 'nosniff');
      final remote = r.connectionInfo?.remoteAddress;
      if (option('wifiOnly') &&
          remote != null &&
          !remote.isLoopback &&
          (!_private(remote) || !(await _platform.networkStatus()).onWifi)) {
        await _json(r, 403, {'error': 'trusted-wifi-required'});
        return;
      }
      final path = r.uri.path;
      if (path == '/' && r.method == 'GET') {
        r.response.headers.contentType = ContentType.html;
        r.response.write(_html());
        await r.response.close();
        return;
      }
      if (!_authorized(r)) {
        await _json(r, 401, {'error': 'unauthorized'});
        return;
      }
      if (path == '/api/health' && r.method == 'GET') {
        await _json(r, 200, {
          'ok': true,
          'port': port,
          'busy': _inference.busy,
        });
        return;
      }
      if ((path == '/api/models' || path == '/v1/models') &&
          r.method == 'GET' &&
          option('allowModelList')) {
        final models = <Map<String, Object?>>[];
        for (final m in ModelCatalog.models.where(
          (m) =>
              m.family == ModelFamily.local &&
              m.task == ModelTask.chat &&
              m.runnable,
        )) {
          if (await _downloads.isFullyInstalled(m)) {
            models.add({
              'id': m.id,
              'name': m.displayName,
              'object': 'model',
              'owned_by': 'siqi',
            });
          }
        }
        await _json(
          r,
          200,
          path == '/api/models'
              ? {'models': models}
              : {'object': 'list', 'data': models},
        );
        return;
      }
      if ((path != '/api/chat' && path != '/v1/chat/completions') ||
          r.method != 'POST' ||
          !option('allowRemoteChat', fallback: false)) {
        await _json(r, 404, {'error': 'route-disabled-or-not-found'});
        return;
      }
      if (_reserved || _inference.busy) {
        await _json(r, 429, {'error': 'local-inference-busy'});
        return;
      }
      _reserved = true; // acquire before ANY awaited input validation
      try {
        final bytes = <int>[];
        if (r.contentLength > 2 * 1024 * 1024) {
          throw const FormatException('request-too-large');
        }
        await for (final chunk in r.timeout(const Duration(seconds: 15))) {
          if (bytes.length + chunk.length > 2 * 1024 * 1024) {
            throw const FormatException('request-too-large');
          }
          bytes.addAll(chunk);
        }
        final body = jsonDecode(utf8.decode(bytes));
        if (body is! Map<String, dynamic>) {
          throw const FormatException('invalid-json');
        }
        final model = ModelCatalog.models
            .where(
              (m) =>
                  m.id == body['model'] &&
                  m.family == ModelFamily.local &&
                  m.task == ModelTask.chat &&
                  m.runnable,
            )
            .firstOrNull;
        if (model == null) throw const FormatException('unknown-chat-model');
        final input = body['messages'];
        if (input is! List || input.isEmpty || input.length > 256) {
          throw const FormatException('invalid-messages');
        }
        final messages = <ChatMessage>[];
        for (final item in input) {
          if (item is! Map ||
              item['content'] is! String ||
              !['user', 'system', 'assistant'].contains(item['role'])) {
            throw const FormatException('only-text-messages-supported');
          }
          messages.add(
            ChatMessage(
              id: '${messages.length}',
              sessionId: 'lan',
              role: MessageRole.values.byName(item['role'] as String),
              content: item['content'] as String,
              createdAt: DateTime.now(),
            ),
          );
        }
        final artifacts = await _downloads.installedArtifactPaths(model);
        if (!model.installArtifacts
            .where((a) => !a.optional)
            .every((a) => artifacts.containsKey(a.id))) {
          throw const FormatException('model-not-installed');
        }
        // Accept the same product envelope as the in-app settings.  The
        // local resource planner still computes a smaller effective value
        // when the model/device cannot safely reserve the KV cache.
        final maxTokens = _number(body, 'max_tokens', 65536, 1, 262144).toInt();
        final temperature = _number(body, 'temperature', .7, 0, 2).toDouble();
        final topP = _number(body, 'top_p', .9, .01, 1).toDouble();
        streamed = body['stream'] == true;
        if (streamed) {
          r.response.headers.contentType = ContentType(
            'text',
            'event-stream',
            charset: 'utf-8',
          );
        }
        var sent = 0;
        runningRequest = true;
        final pending = _inference.complete(
          model: model,
          artifactPaths: artifacts,
          messages: messages,
          systemPrompt: '',
          contextWindow: _number(
            body,
            'context_window',
            65536,
            2048,
            131072,
          ).toInt(),
          temperature: temperature,
          topP: topP,
          maxTokens: maxTokens,
          onText: streamed
              ? (text) {
                  final delta = text.substring(sent);
                  sent = text.length;
                  r.response.write(
                    'data: ${jsonEncode({
                      'object': 'chat.completion.chunk',
                      'choices': [
                        {
                          'index': 0,
                          'delta': {'content': delta},
                          'finish_reason': null,
                        },
                      ],
                    })}\n\n',
                  );
                  unawaited(
                    r.response.flush().catchError(
                      (Object _) => _inference.cancel(),
                    ),
                  );
                }
              : null,
        );
        unawaited(
          pending
              .then((_) {}, onError: (Object _) {})
              .whenComplete(() => runningRequest = false),
        );
        final result = await pending.timeout(
          Duration(seconds: requestTimeoutSeconds),
          onTimeout: () {
            unawaited(_inference.cancel());
            throw TimeoutException('inference-timeout');
          },
        );
        if (streamed) {
          r.response.write(
            'data: ${jsonEncode({
              'choices': [
                {'index': 0, 'delta': {}, 'finish_reason': 'stop'},
              ],
            })}\n\ndata: [DONE]\n\n',
          );
          await r.response.close();
        } else {
          await _json(
            r,
            200,
            path == '/api/chat'
                ? {'text': result.text}
                : {
                    'id': 'siqi-${DateTime.now().millisecondsSinceEpoch}',
                    'object': 'chat.completion',
                    'model': model.id,
                    'choices': [
                      {
                        'index': 0,
                        'message': {
                          'role': 'assistant',
                          'content': result.text,
                        },
                        'finish_reason': 'stop',
                      },
                    ],
                    'usage': {
                      'prompt_tokens': result.usage.input,
                      'completion_tokens': result.usage.output,
                      'total_tokens': result.usage.input + result.usage.output,
                    },
                  },
          );
        }
      } finally {
        _reserved = false;
      }
    } on Object catch (error) {
      final code = error is TimeoutException
          ? 504
          : error is FormatException
          ? 400
          : 500;
      final message = error is FormatException
          ? error.message
          : error is TimeoutException
          ? 'request-timeout'
          : 'local-inference-failed';
      if (streamed) {
        r.response.write(
          'data: ${jsonEncode({'error': message})}\n\ndata: [DONE]\n\n',
        );
        await r.response.close();
      } else {
        await _json(r, code, {'error': message});
      }
    }
  }

  num _number(
    Map<String, dynamic> body,
    String key,
    num fallback,
    num min,
    num max,
  ) {
    final v = body[key] ?? fallback;
    if (v is! num || !v.isFinite || v < min || v > max) {
      throw FormatException('invalid-$key');
    }
    return v;
  }

  bool _authorized(HttpRequest r) {
    final auth = r.headers.value('authorization');
    final supplied =
        r.headers.value('x-siqi-token') ??
        (auth?.startsWith('Bearer ') == true ? auth!.substring(7) : null);
    if (supplied == null || _token == null) return false;
    final a = sha256.convert(utf8.encode(supplied)).bytes,
        b = sha256.convert(utf8.encode(_token!)).bytes;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  bool _private(InternetAddress address) {
    final b = address.rawAddress;
    return b.length == 4 &&
        (b[0] == 10 ||
            (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
            (b[0] == 192 && b[1] == 168));
  }

  String _html() =>
      '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SIQI</title><style>body{font:16px system-ui;max-width:760px;margin:40px auto;padding:20px;background:#f6f8fc;color:#202a36}input,select,textarea,button{box-sizing:border-box;padding:14px;border-radius:18px;border:1px solid #cdd5e0;margin:6px 0;width:100%;font:inherit}button{background:#3358ce;color:white}pre{white-space:pre-wrap;overflow-wrap:anywhere}</style><h1>司器 · 远程对话</h1><p>密令只保存在本页内存。HTTP 不加密传输，请使用可信 Wi-Fi 或加密隧道。</p><input id="t" type="password" autocomplete="off" placeholder="设备密令"><button id="c">连接并读取模型</button><select id="m"></select><textarea id="q" placeholder="输入消息"></textarea><button id="s">发送</button><pre id="o"></pre><script>const t=document.querySelector('#t'),m=document.querySelector('#m'),q=document.querySelector('#q'),o=document.querySelector('#o');document.querySelector('#c').onclick=async()=>{try{let r=await fetch('/api/models',{headers:{'x-siqi-token':t.value}});let j=await r.json();if(!r.ok)throw Error(j.error);m.replaceChildren(...j.models.map(x=>new Option(x.name,x.id)));o.textContent='已连接';}catch(e){o.textContent=String(e)}};document.querySelector('#s').onclick=async()=>{try{let r=await fetch('/api/chat',{method:'POST',headers:{'content-type':'application/json','x-siqi-token':t.value},body:JSON.stringify({model:m.value,messages:[{role:'user',content:q.value}],max_tokens:512})});let j=await r.json();o.textContent=j.text||j.error;}catch(e){o.textContent=String(e)}};</script></html>''';
}
