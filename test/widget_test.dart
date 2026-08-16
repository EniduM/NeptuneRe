import 'package:flutter/material.dart';
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

/// Fake API layer: only POST /auth/login is stubbed; every other call fails
/// with a 404 so tests stay offline while exercising real session paths.
class FakeNeptuneApi extends ApiClient {
  FakeNeptuneApi(TokenStorage storage)
      : super(
          baseUrl: 'http://fake.invalid',
          tokenProvider: () async => storage.readAccessToken(),
        );

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    if (path == '/auth/login') {
      return {
        'accessToken': 'fake-token',
        'user': {
          'id': 'u1',
          'loginId': 'COLLECTOR001',
          'role': 'COLLECTOR',
          'status': 'ACTIVE',
        },
      };
    }
    throw ApiException(statusCode: 404, message: 'not found');
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    throw ApiException(statusCode: 404, message: 'not found');
  }
}

void main() {
  testWidgets('Neptune Recyclers app launches to the role entry screen',
      (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    final appState = AppState(
      api: ApiService(FakeNeptuneApi(tokenStorage)),
      tokenStorage: tokenStorage,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const NeptuneApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your app role to continue'), findsOneWidget);
  });

  testWidgets('logout returns to the role entry screen, not a blank screen',
      (WidgetTester tester) async {
    // The profile tab is longer than the default 800x600 test surface.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final tokenStorage = InMemoryTokenStorage();
    final appState = AppState(
      api: ApiService(FakeNeptuneApi(tokenStorage)),
      tokenStorage: tokenStorage,
    );
    await appState.login(loginId: 'COLLECTOR001', password: 'Pass1234');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const NeptuneApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Authenticated: the collector shell is showing.
    expect(find.text('My Requests'), findsOneWidget);

    // Open the Profile tab (it is built offstage until selected), then tap
    // Logout through the real UI: profile tile → confirm dialog.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Logout of Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout of Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    // Must land on the role entry screen — never a blank frame.
    expect(find.text('Choose your app role to continue'), findsOneWidget);
    expect(appState.isAuthenticated, isFalse);
  });

  testWidgets('expired JWT (401) returns to the role entry screen',
      (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    final appState = AppState(
      api: ApiService(FakeNeptuneApi(tokenStorage)),
      tokenStorage: tokenStorage,
    );
    await appState.login(loginId: 'COLLECTOR001', password: 'Pass1234');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const NeptuneApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Requests'), findsOneWidget);

    // Simulate the ApiClient firing onUnauthorized after an authenticated 401.
    ApiClient.onUnauthorized?.call();
    await tester.pumpAndSettle();

    expect(find.text('Choose your app role to continue'), findsOneWidget);
    expect(appState.isAuthenticated, isFalse);
    expect(appState.currentUser, isNull);
  });
}