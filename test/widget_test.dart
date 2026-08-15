import 'package:flutter_test/flutter_test.dart';
import 'package:neptune_recyclers/main.dart';
import 'package:neptune_recyclers/providers/app_state.dart';
import 'package:neptune_recyclers/services/api_client.dart';
import 'package:neptune_recyclers/services/api_service.dart';
import 'package:neptune_recyclers/services/token_storage.dart';
import 'package:provider/provider.dart';

/// In-memory token storage so tests avoid platform channels.
class InMemoryTokenStorage extends TokenStorage {
  String? _token;
  String? _loginId;

  InMemoryTokenStorage();

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<String?> readLoginId() async => _loginId;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String loginId,
  }) async {
    _token = accessToken;
    _loginId = loginId;
  }

  @override
  Future<void> clearSession() async {
    _token = null;
    _loginId = null;
  }
}

void main() {
  testWidgets('Neptune Recyclers app launches to the login screen',
      (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    ApiClient.initialize(tokenProvider: tokenStorage.readAccessToken);
    final appState = AppState(
      api: ApiService(ApiClient.instance),
      tokenStorage: tokenStorage,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const NeptuneApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Development mode'), findsOneWidget);
  });
}