import 'package:shared_preferences/shared_preferences.dart';

/// Persisted storage for the JWT access token.
///
/// Uses shared_preferences so the session survives app restarts on every
/// platform (Android SharedPreferences XML, web localStorage). The JWT only
/// lives 24h server-side, so the slight downgrade from Keychain/Keystore is
/// an acceptable trade-off for reliable "stay logged in" behavior.
class TokenStorage {
  static const String _accessTokenKey = 'neptune_access_token';
  static const String _loginIdKey = 'neptune_login_id';

  const TokenStorage();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> readLoginId() async {
    final prefs = await _prefs;
    return prefs.getString(_loginIdKey);
  }

  Future<void> saveSession({
    required String accessToken,
    required String loginId,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_loginIdKey, loginId);
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_loginIdKey);
  }
}
