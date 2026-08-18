import '../models/api_models.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  const AuthApi(this._client);

  /// POST /auth/login
  Future<LoginResponse> login({
    required String loginId,
    required String password,
  }) async {
    final json = await _client.post(
      '/auth/login',
      body: {'loginId': loginId, 'password': password},
      authenticated: false,
    );
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  /// GET /auth/me
  Future<AuthUser> me() async {
    final json = await _client.get('/auth/me');
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }
}
