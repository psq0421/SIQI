import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Optional LAN-only control endpoint. It is disabled by default and exposes
/// read-only health/model endpoints until an authenticated request is made.
class LocalGatewayService {
  LocalGatewayService(this._storage);
  final FlutterSecureStorage _storage;
  HttpServer? _server;
  String? _token;
  static const _tokenKey = 'gateway_token';

  bool get running => _server != null;
  int? get port => _server == null ? null : 1158;

  Future<String> ensureToken() async {
    final existing = await _storage.read(key: _tokenKey);
    if (existing != null && existing.length >= 24) return _token = existing;
    final seed =
        '${DateTime.now().microsecondsSinceEpoch}:${Platform.localHostname}:${String.fromCharCodes(List.generate(24, (i) => 33 + (i * 29) % 90))}';
    final value = sha256.convert(utf8.encode(seed)).toString();
    await _storage.write(key: _tokenKey, value: value);
    return _token = value;
  }

  Future<String> rotateToken() async {
    await _storage.delete(key: _tokenKey);
    _token = null;
    return ensureToken();
  }

  Future<void> start({int port = 1158}) async {
    if (_server != null) return;
    await ensureToken();
    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      port,
      shared: true,
    );
    _server = server;
    unawaited(server.forEach(_handle));
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    final path = request.uri.path;
    if (path == '/' && request.method == 'GET') {
      request.response.headers.contentType = ContentType.html;
      request.response.write(_html());
      await request.response.close();
      return;
    }
    if (path == '/api/health' && request.method == 'GET') {
      request.response.write(
        jsonEncode({'ok': true, 'service': 'siqi', 'port': 1158}),
      );
      await request.response.close();
      return;
    }
    if (!_authorized(request)) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write(jsonEncode({'error': 'unauthorized'}));
      await request.response.close();
      return;
    }
    if (path == '/api/models' && request.method == 'GET') {
      request.response.write(jsonEncode({'models': const <Object>[]}));
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode({'error': 'not-found'}));
    }
    await request.response.close();
  }

  bool _authorized(HttpRequest request) {
    final supplied =
        request.headers.value('x-siqi-token') ??
        request.uri.queryParameters['token'];
    return supplied != null && supplied.isNotEmpty && supplied == _token;
  }

  String _html() =>
      '''<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><title>SIQI LAN</title><style>body{font:16px system-ui;max-width:720px;margin:40px auto;padding:0 18px;color:#172033}input,button{padding:12px;border-radius:12px;border:1px solid #ccd3e0}button{background:#2457d6;color:white}</style><h1>SIQI 工作站</h1><p>局域网控制台（端口 1158）</p><input id="t" placeholder="设备密令"/><button onclick="go()">连接</button><pre id="o"></pre><script>async function go(){let t=document.querySelector('#t').value;let r=await fetch('/api/models',{headers:{'x-siqi-token':t}});document.querySelector('#o').textContent=await r.text()}</script>''';
}
