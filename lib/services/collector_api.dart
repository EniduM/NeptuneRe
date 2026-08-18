import '../models/api_models.dart';
import 'api_client.dart';

class CollectorApi {
  final ApiClient _client;
  const CollectorApi(this._client);

  /// GET /collector/assignments/today
  ///
  /// Throws ApiException(404) when the collector has no assignment today.
  Future<DailyAssignment> todayAssignment() async {
    final json = await _client.get('/collector/assignments/today');
    return DailyAssignment.fromJson(json as Map<String, dynamic>);
  }

  /// POST /collector/collection-requests
  Future<CollectionRequest> createRequest({
    required double latitude,
    required double longitude,
  }) async {
    final json = await _client.post(
      '/collector/collection-requests',
      body: {'latitude': latitude, 'longitude': longitude},
    );
    return CollectionRequest.fromJson(json as Map<String, dynamic>);
  }

  /// GET /collector/collection-requests
  Future<List<CollectionRequest>> myRequests() async {
    final json = await _client.get('/collector/collection-requests');
    return (json as List)
        .map((e) => CollectionRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /collector/collection-requests/:id
  Future<CollectionRequest> getRequest(String id) async {
    final json = await _client.get('/collector/collection-requests/$id');
    return CollectionRequest.fromJson(json as Map<String, dynamic>);
  }

  /// PATCH /collector/collection-requests/:id/cancel
  Future<CollectionRequest> cancelRequest(String id) async {
    // Backend contract: this endpoint accepts an empty body.
    final json = await _client.patch(
      '/collector/collection-requests/$id/cancel',
    );
    return CollectionRequest.fromJson(json as Map<String, dynamic>);
  }

  /// GET /collector/leaderboard[?period=month]
  ///
  /// Real leaderboard data ranked by the backend. [period] of `'month'`
  /// limits the totals to the current calendar month; omit for all time.
  Future<List<LeaderboardEntry>> leaderboard({String? period}) async {
    final json = await _client.get(
      '/collector/leaderboard',
      query: period == null ? null : {'period': period},
    );
    return (json as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
