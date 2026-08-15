import 'package:flutter/foundation.dart';

import '../models/api_models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

/// Central application state.
///
/// Authentication is JWT-based against the Neptune API. The access token is
/// persisted in secure storage and restored at startup. Identity (role,
/// user id) is derived from the JWT server-side — the client never sends
/// collectorId/riderId.
class AppState extends ChangeNotifier {
  final ApiService api;
  final TokenStorage _tokenStorage;

  AuthUser? _currentUser;
  String? _accessToken;

  bool _isRestoring = true;

  AppState({
    required this.api,
    required TokenStorage tokenStorage,
  })  : _tokenStorage = tokenStorage {
    _restoreSession();
  }

  AuthUser? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;
  bool get isRestoringSession => _isRestoring;
  bool get isCollector => _currentUser?.isCollector ?? false;
  bool get isRider => _currentUser?.isRider ?? false;

  Future<void> _restoreSession() async {
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        try {
          _currentUser = await api.auth.me();
        } on ApiException {
          // Token invalid or expired — require a fresh login.
          await _tokenStorage.clearSession();
          _accessToken = null;
          _currentUser = null;
        }
      }
    } catch (_) {
      _accessToken = null;
      _currentUser = null;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Authenticates with the Neptune JWT API and persists the session.
  /// Throws [ApiException] on failure (401 for wrong credentials, etc.).
  Future<void> login({
    required String loginId,
    required String password,
  }) async {
    final response = await api.auth.login(
      loginId: loginId,
      password: password,
    );
    _accessToken = response.accessToken;
    _currentUser = response.user;
    await _tokenStorage.saveSession(
      accessToken: response.accessToken,
      loginId: response.user.loginId,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    _currentUser = null;
    await _tokenStorage.clearSession();
    notifyListeners();
  }
}