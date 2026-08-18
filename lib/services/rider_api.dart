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
  /// POST /rider/collection-requests/:id/verify-qr-token — the backend
  /// matches the token against the request's collector and sets
  /// qrVerified: true. A mismatch throws ApiException(409); the backend also
  /// refuses to complete a request whose QR was not verified first.
  Future<void> verifyQrToken({
    required String requestId,
    required String qrToken,
  }) async {
    await _client.post(
      '/rider/collection-requests/$requestId/verify-qr-token',
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
    return CompleteCollectionResponse.fromJson(json as Map<String, dynamic>);
  }

  /// GET /rider/vehicles
  ///
  /// Vehicles are created by the ADMIN and their `id` is a backend UUID —
  /// the completion endpoint rejects anything that is not a real vehicle id
  /// ("Vehicle must be a UUID"), so the picker MUST use this list and never
  /// locally fabricated ids.
  Future<List<Vehicle>> vehicles() async {
    final json = await _client.get('/rider/vehicles');
    return (json as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
