import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class GithubService {
  const GithubService(this._dio);
  final Dio _dio;

  Future<GithubDeviceCode> requestDeviceCode(String clientId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'https://github.com/login/device/code',
      data: {'client_id': clientId, 'scope': 'repo read:user'},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Accept': 'application/json'},
      ),
    );
    final data = response.data ?? const {};
    return GithubDeviceCode(
      deviceCode: data['device_code']! as String,
      userCode: data['user_code']! as String,
      verificationUri: Uri.parse(data['verification_uri']! as String),
      expiresIn: data['expires_in'] as int? ?? 900,
      interval: data['interval'] as int? ?? 5,
    );
  }

  Future<String?> pollDeviceToken({
    required String clientId,
    required GithubDeviceCode deviceCode,
  }) async {
    final deadline = DateTime.now().add(
      Duration(seconds: deviceCode.expiresIn),
    );
    while (DateTime.now().isBefore(deadline)) {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://github.com/login/oauth/access_token',
        data: {
          'client_id': clientId,
          'device_code': deviceCode.deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
        ),
      );
      final data = response.data ?? const {};
      final token = data['access_token'] as String?;
      if (token != null && token.isNotEmpty) return token;
      final error = data['error'] as String?;
      if (error != 'authorization_pending' && error != 'slow_down') return null;
      final extra = error == 'slow_down' ? 5 : 0;
      await Future<void>.delayed(
        Duration(seconds: deviceCode.interval + extra),
      );
    }
    return null;
  }

  Future<void> importRepository({
    required String owner,
    required String repository,
    required String destination,
    String? token,
  }) async {
    final response = await _dio.get<List<int>>(
      'https://api.github.com/repos/$owner/$repository/zipball',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
        },
      ),
    );
    final archive = ZipDecoder().decodeBytes(
      response.data ?? const [],
      verify: true,
    );
    final root = Directory(destination)..createSync(recursive: true);
    final rootPath = p.normalize(p.absolute(root.path));
    for (final entry in archive.files) {
      final segments = p.split(entry.name);
      if (segments.length < 2) continue;
      final relative = p.joinAll(segments.skip(1));
      final outputPath = p.normalize(p.absolute(p.join(rootPath, relative)));
      if (!p.isWithin(rootPath, outputPath)) {
        throw const FormatException('Unsafe archive entry');
      }
      if (entry.isFile) {
        final file = File(outputPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content as List<int>);
      } else {
        await Directory(outputPath).create(recursive: true);
      }
    }
  }
}

class GithubDeviceCode {
  const GithubDeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });
  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final int expiresIn;
  final int interval;
}
