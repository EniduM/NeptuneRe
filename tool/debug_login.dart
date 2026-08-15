import 'package:neptune_recyclers/config/app_config.dart';
import 'package:neptune_recyclers/services/api_client.dart';
import 'package:neptune_recyclers/services/auth_api.dart';

Future<void> main() async {
  final client = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenProvider: () async => null,
  );
  final auth = AuthApi(client);

  print('BASE URL: ${AppConfig.apiBaseUrl}');
  try {
    final resp = await auth.login(
      loginId: 'COL001',
      password: 'Collector@12345',
    );
    print('LOGIN OK');
    print('token length: ${resp.accessToken.length}');
    print('user: ${resp.user.loginId} role=${resp.user.role}');
  } catch (e) {
    print('LOGIN FAILED: $e');
  }
}
