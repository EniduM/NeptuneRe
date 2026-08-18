import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neptune_recyclers/models/api_models.dart';
import 'package:neptune_recyclers/providers/app_state.dart';
import 'package:neptune_recyclers/screens/collector/collector_dashboard_screen.dart';
import 'package:neptune_recyclers/screens/collector/collector_profile_screen.dart';
import 'package:neptune_recyclers/screens/collector/collector_request_detail_screen.dart';
import 'package:neptune_recyclers/screens/collector/collector_requests_screen.dart';
import 'package:neptune_recyclers/screens/collector/collector_rider_track_screen.dart';
import 'package:neptune_recyclers/screens/collector/create_request_screen.dart';
import 'package:neptune_recyclers/screens/collector/leaderboard_screen.dart';
import 'package:neptune_recyclers/screens/rider/rider_dashboard_screen.dart';
import 'package:neptune_recyclers/screens/rider/rider_jobs_screen.dart';
import 'package:neptune_recyclers/screens/rider/rider_profile_screen.dart';
import 'package:neptune_recyclers/screens/rider/rider_qr_scan_screen.dart';
import 'package:neptune_recyclers/screens/rider/rider_request_workflow_screen.dart';
import 'package:neptune_recyclers/screens/rider/rider_weight_entry_screen.dart';
import 'package:neptune_recyclers/screens/splash_screen.dart';
import 'package:neptune_recyclers/services/api_client.dart';
import 'package:neptune_recyclers/services/api_service.dart';
import 'package:neptune_recyclers/services/token_storage.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Runs on the `chrome` platform so every screen is exercised inside a real
/// browser engine. Each screen must render its expected content (or its
/// graceful unavailable state for camera/geolocation/Firebase-dependent
/// screens) without crashing.

class InMemoryTokenStorage extends TokenStorage {
  String? _token;
  String? _loginId;

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

const _collectorUser = {
  'id': 'u1',
  'loginId': 'COL001',
  'role': 'COLLECTOR',
  'status': 'ACTIVE',
  'qrToken': 'QR-COL-TEST-001',
};

const _riderUser = {
  'id': 'u2',
  'loginId': 'RID001',
  'role': 'RIDER',
  'status': 'ACTIVE',
};

Map<String, dynamic> _request(String id, String status, {String? riderId}) => {
  'id': id,
  'collectorId': 'c1',
  'riderId': riderId,
  'latitude': 6.9271,
  'longitude': 79.8612,
  'status': status,
  'requestedAt': '2026-08-17T10:00:00.000Z',
  'acceptedAt': status == 'ACCEPTED' || status == 'COMPLETED'
      ? '2026-08-17T10:05:00.000Z'
      : null,
  'completedAt': status == 'COMPLETED' ? '2026-08-17T10:30:00.000Z' : null,
  'cancelledAt': null,
  'collector': {
    'id': 'c1',
    'fullName': 'Dilshan Maluddeniya',
    'mobile': '+94771234567',
    'user': {'loginId': 'COL001'},
  },
  'rider': riderId == null
      ? null
      : {'id': 'r1', 'fullName': 'Kasun Perera', 'mobile': '+94772345678'},
};

/// Keeps the splash screen visible long enough to assert on while the
/// session restore is still in flight.
class SlowTokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async {
    await Future<void>.delayed(const Duration(seconds: 10));
    return null;
  }
}

class WebFakeApi extends ApiClient {
  WebFakeApi(TokenStorage storage)
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
      final loginId = (body as Map)['loginId'] as String;
      return {
        'accessToken': 'fake-token',
        'user': loginId == 'RID001' ? _riderUser : _collectorUser,
      };
    }
    if (path == '/collector/collection-requests') {
      return _request('REQ-NEW', 'PENDING');
    }
    if (path.endsWith('/cancel')) {
      return _request('REQ1', 'CANCELLED');
    }
    if (path.endsWith('/verify-qr-token')) {
      return _request('REQ1', 'ACCEPTED', riderId: 'r1');
    }
    if (path.endsWith('/accept')) {
      return _request('REQ1', 'ACCEPTED', riderId: 'r1');
    }
    if (path.endsWith('/complete')) {
      return {
        'request': _request('REQ1', 'COMPLETED', riderId: 'r1'),
        'collection': {
          'id': 'rec1',
          'collectionRequestId': 'REQ1',
          'collectorId': 'c1',
          'riderId': 'r1',
          'vehicleId': 'v1',
          'weightKg': 12.5,
          'collectedAt': '2026-08-17T10:30:00.000Z',
        },
      };
    }
    throw ApiException(statusCode: 404, message: 'not found');
  }

  @override
  Future<dynamic> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    if (path.endsWith('/accept')) {
      return _request('REQ1', 'ACCEPTED', riderId: 'r1');
    }
    throw ApiException(statusCode: 404, message: 'not found');
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    if (path == '/auth/me') {
      return _collectorUser;
    }
    if (path == '/collector/assignments/today') {
      return {
        'id': 'a1',
        'assignmentDate': '2026-08-17',
        'collector': {
          'id': 'c1',
          'fullName': 'Dilshan Maluddeniya',
          'mobile': '+94771234567',
          'user': {'loginId': 'COL001'},
        },
      };
    }
    if (path == '/collector/leaderboard') {
      return [
        {
          'collectorId': 'c1',
          'fullName': 'Dilshan Maluddeniya',
          'totalWeightKg': 341.8,
          'totalCollections': 61,
          'rank': 1,
        },
        {
          'collectorId': 'c2',
          'fullName': 'Kasun Perera',
          'totalWeightKg': 198.2,
          'totalCollections': 45,
          'rank': 2,
        },
        {
          'collectorId': 'c3',
          'fullName': 'Nimali Fernando',
          'totalWeightKg': 150.4,
          'totalCollections': 38,
          'rank': 3,
        },
      ];
    }
    if (path == '/collector/collection-requests') {
      return [
        _request('REQ1', 'ACCEPTED', riderId: 'r1'),
        _request('REQ2', 'COMPLETED', riderId: 'r1'),
        _request('REQ3', 'PENDING'),
      ];
    }
    if (path.startsWith('/collector/collection-requests/')) {
      return _request('REQ1', 'ACCEPTED', riderId: 'r1');
    }
    if (path == '/rider/collection-requests') {
      return [_request('REQ1', 'PENDING'), _request('REQ2', 'PENDING')];
    }
    if (path == '/rider/collection-requests/my') {
      return [
        _request('REQ1', 'ACCEPTED', riderId: 'r1'),
        _request('REQ2', 'COMPLETED', riderId: 'r1'),
      ];
    }
    if (path.startsWith('/rider/collection-requests/')) {
      return _request('REQ1', 'ACCEPTED', riderId: 'r1');
    }
    if (path == '/rider/vehicles') {
      return [
        {
          'id': '9c3c9314-790f-4d76-9a1b-32f2ba3f7d01',
          'vehicleCode': 'NP-TRK-01',
          'vehicleType': 'Truck',
          'status': 'ACTIVE',
        },
      ];
    }
    throw ApiException(statusCode: 404, message: 'not found');
  }
}

void main() {
  void size(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<AppState> collectorState() async {
    final storage = InMemoryTokenStorage();
    final state = AppState(
      api: ApiService(WebFakeApi(storage)),
      tokenStorage: storage,
    );
    await state.login(loginId: 'COL001', password: 'Pass1234');
    return state;
  }

  Future<AppState> riderState() async {
    final storage = InMemoryTokenStorage();
    final state = AppState(
      api: ApiService(WebFakeApi(storage)),
      tokenStorage: storage,
    );
    await state.login(loginId: 'RID001', password: 'Pass1234');
    return state;
  }

  Widget wrap(AppState state, Widget child) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(home: child),
    );
  }

  Future<void> pump(WidgetTester tester, Widget child, AppState state) async {
    await tester.pumpWidget(wrap(state, child));
    // Fixed pumps instead of pumpAndSettle: map loaders / spinners animate
    // forever and would never settle.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('collector dashboard renders in Chrome', (tester) async {
    size(tester);
    final state = await collectorState();
    await pump(tester, const CollectorDashboardScreen(), state);
    expect(find.text("Today's Assignment"), findsOneWidget);
    // Real leaderboard segment renders with backend-shaped data.
    expect(find.text('Collector Leaderboard'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Dilshan Maluddeniya'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Recent Requests'), 200);
    expect(find.text('Recent Requests'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collector requests list renders in Chrome', (tester) async {
    size(tester);
    final state = await collectorState();
    await pump(tester, const CollectorRequestsScreen(), state);
    expect(find.text('My Requests'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collector request detail renders in Chrome', (tester) async {
    size(tester);
    final state = await collectorState();
    await pump(
      tester,
      const CollectorRequestDetailScreen(requestId: 'REQ1'),
      state,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('create request renders in Chrome (fallback when no GPS)', (
    tester,
  ) async {
    size(tester);
    final state = await collectorState();
    await pump(tester, const CreateRequestScreen(), state);
    expect(find.text('Create Collection Request'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live rider track renders in Chrome', (tester) async {
    size(tester);
    final state = await collectorState();
    final request = CollectionRequest.fromJson(
      _request('REQ1', 'ACCEPTED', riderId: 'r1'),
    );
    await pump(tester, CollectorRiderTrackScreen(request: request), state);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaderboard renders in Chrome', (tester) async {
    size(tester);
    final state = await collectorState();
    await pump(tester, const LeaderboardScreen(), state);
    expect(find.text('Leaderboard'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collector profile renders in Chrome', (tester) async {
    size(tester);
    final state = await collectorState();
    await pump(tester, const CollectorProfileScreen(), state);
    expect(find.text('Collector Profile'), findsOneWidget);
    // Real QR renders from the /auth/me qrToken (no fabrication).
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rider dashboard renders in Chrome', (tester) async {
    size(tester);
    final state = await riderState();
    await pump(tester, const RiderDashboardScreen(), state);
    expect(find.text('Available Requests'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rider jobs renders in Chrome', (tester) async {
    size(tester);
    final state = await riderState();
    await pump(tester, const RiderJobsScreen(), state);
    expect(find.text('My Jobs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rider request workflow renders in Chrome', (tester) async {
    size(tester);
    final state = await riderState();
    final request = CollectionRequest.fromJson(
      _request('REQ1', 'ACCEPTED', riderId: 'r1'),
    );
    await pump(
      tester,
      RiderRequestWorkflowScreen(initialRequest: request),
      state,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rider QR scan renders in Chrome (camera-denied state)', (
    tester,
  ) async {
    size(tester);
    final state = await riderState();
    final request = CollectionRequest.fromJson(
      _request('REQ1', 'ACCEPTED', riderId: 'r1'),
    );
    await pump(tester, RiderQrScanScreen(request: request), state);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rider weight entry renders in Chrome', (tester) async {
    size(tester);
    final state = await riderState();
    size(tester);
    final request = CollectionRequest.fromJson(
      _request('REQ1', 'ACCEPTED', riderId: 'r1'),
    );
    await pump(
      tester,
      RiderWeightEntryScreen(request: request, qrVerified: true),
      state,
    );
    // Vehicle list comes from GET /rider/vehicles — load completes.
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Vehicle>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NP-TRK-01 — Truck'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '12.5');
    await tester.tap(find.text('Complete Collection'));
    await tester.pumpAndSettle();
    expect(find.text('Collection Completed!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rider profile renders in Chrome', (tester) async {
    size(tester);
    final state = await riderState();
    await pump(tester, const RiderProfileScreen(), state);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash screen renders brand logo in Chrome', (tester) async {
    size(tester);
    final storage = SlowTokenStorage();
    final state = AppState(
      api: ApiService(WebFakeApi(storage)),
      tokenStorage: storage,
    );
    await pump(tester, const SplashScreen(), state);
    expect(find.text('NEPTUNE RECYCLERS'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    // Flush the pending restore timer so the test teardown sees no timers.
    await tester.pump(const Duration(seconds: 11));
  });
}
