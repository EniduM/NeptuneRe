import '../models/api_models.dart';
import 'api_client.dart';

class RiderApi {
  final ApiClient _client;
  const RiderApi(this._client);

  /// GET /rider/collection-requests (PENDING only, oldest first)
  Future<List<CollectionRequest>> pendingRequests() async {
    final json = await _client.get('/rider/collection-requests');
    return (json as List)
        .map((e) => CollectionRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /rider/collection-requests/my
  Future<List<CollectionRequest>> myRequests() async {
    final json = await _client.get('/rider/collection-requests/my');
    return (json as List)
        .map((e) => CollectionRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /rider/collection-requests/:id
  Future<CollectionRequest> getRequest(String id) async {
    final json = await _client.get('/rider/collection-requests/$id');
    return CollectionRequest.fromJson(json as Map<String, dynamic>);
  }

  /// PATCH /rider/collection-requests/:id/accept
  Future<CollectionRequest> acceptRequest(String id) async {
    final json = await _client.patch('/rider/collection-requests/$id/accept');
    return CollectionRequest.fromJson(json as Map<String, dynamic>);
  }

  /// POST /rider/collection-requests/:id/verify-qr
  Future<void> verifyQr({
    required String requestId,
    required String qrToken,
  }) async {
    await _client.post(
      '/rider/collection-requests/$requestId/verify-qr',
      body: {'qrToken': qrToken},
    );
  }

  /// POST /rider/collection-requests/:id/complete
  Future<CompleteCollectionResponse> complete({
    required String requestId,
    required String vehicleId,
    required double weightKg,
  }) async {
    final json = await _client.post(
      '/rider/collection-requests/$requestId/complete',
      body: {'vehicleId': vehicleId, 'weightKg': weightKg},
    );
    return CompleteCollectionResponse.fromJson(
      json as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------
  // NOT in NEPTUNE_API_HANDOVER.md: the backend currently exposes vehicle
  // management only to ADMIN. The Rider completion payload requires a
  // vehicleId, so a rider-facing vehicle list endpoint is required.
  // Wire-up target: GET /rider/vehicles (returns ACTIVE vehicles).
  // Until the backend team adds it, callers receive an ApiException and the
  // UI shows an "API unavailable" state instead of fabricated data.
  // ---------------------------------------------------------------------
  Future<List<Vehicle>> vehicles() async {
    final json = await _client.get('/rider/vehicles');
    return (json as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}