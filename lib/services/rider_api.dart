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

  /// Verify the Collector's permanent QR before completing a collection.
  ///
  // PENDING BACKEND: there is no backend verification endpoint for this step
  // (NEPTUNE_API_HANDOVER.md does not define one, and the NestJS backend has
  // no /verify-qr route). This stub currently returns success so the flow can
  // continue; replace the body with the real call once the backend team
  // exposes an endpoint.
  Future<void> verifyQrToken({
    required String requestId,
    required String qrToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return;
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
  // Vehicle picker for the completion step.
  //
  // Per NEPTUNE_API_HANDOVER.md the completion payload requires a vehicleId
  // and there is no rider-specific vehicle API: the Rider selects an ACTIVE
  // vehicle from the admin vehicle list (GET /admin/vehicles) at completion
  // time and passes vehicleId in the complete call. Active vehicles are
  // filtered client-side via Vehicle.isActive.
  //
  // NOTE: the current NestJS backend guards /admin/vehicles with the ADMIN
  // role (riders receive 403). Until the backend team opens vehicle listing
  // to RIDER, the picker surfaces that error instead of fabricated data.
  // ---------------------------------------------------------------------
  Future<List<Vehicle>> vehicles() async {
    final json = await _client.get('/admin/vehicles');
    return (json as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}