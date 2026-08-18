import 'api_client.dart';
import 'auth_api.dart';
import 'collector_api.dart';
import 'rider_api.dart';

/// Bundles the typed API services against the shared [ApiClient].
class ApiService {
  final ApiClient client;
  final AuthApi auth;
  final CollectorApi collector;
  final RiderApi rider;

  ApiService(this.client)
    : auth = AuthApi(client),
      collector = CollectorApi(client),
      rider = RiderApi(client);
}
