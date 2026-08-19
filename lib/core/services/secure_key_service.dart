import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyService {
  const SecureKeyService(this._storage);
  final FlutterSecureStorage _storage;
  static const _prefix = 'api_key_';
  static const _githubKey = 'github_access_token';

  Future<void> writeApiKey(String profileId, String apiKey) =>
      _storage.write(key: '$_prefix$profileId', value: apiKey);
  Future<String?> readApiKey(String profileId) =>
      _storage.read(key: '$_prefix$profileId');
  Future<void> deleteApiKey(String profileId) =>
      _storage.delete(key: '$_prefix$profileId');
  Future<void> writeGithubToken(String token) =>
      _storage.write(key: _githubKey, value: token);
  Future<String?> readGithubToken() => _storage.read(key: _githubKey);
  Future<void> deleteGithubToken() => _storage.delete(key: _githubKey);
}
