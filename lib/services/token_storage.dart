import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for the JWT access token (Keychain on iOS, Keystore/EncryptedSharedPreferences on Android).
class TokenStorage {
  static const String _accessTokenKey = 'neptune_access_token';
  static const String _loginIdKey = 'neptune_login_id';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readLoginId() => _storage.read(key: _loginIdKey);

  Future<void> saveSession({
    required String accessToken,
    required String loginId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _loginIdKey, value: loginId);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _loginIdKey);
  }
}
