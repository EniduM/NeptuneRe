/// Models mapping the Neptune API responses (see NEPTUNE_API_HANDOVER.md).
library;

/// Backends have returned numeric fields sometimes as JSON numbers and
/// sometimes as JSON strings (e.g. the rider module serializes latitude
/// and longitude as strings). Parse both so one module cannot break the UI.
double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class AuthUser {
  final String id;
  final String loginId;
  final String role;
  final String status;

  /// Permanent QR token, present only for COLLECTOR users (the surface a
  /// Rider scans for identity verification). Null for RIDER/ADMIN roles
  /// and for sessions that predate backend support.
  final String? qrToken;

  const AuthUser({
    required this.id,
    required this.loginId,
    required this.role,
    required this.status,
    this.qrToken,
  });

  bool get isCollector => role == 'COLLECTOR';
  bool get isRider => role == 'RIDER';
  bool get isAdmin => role == 'ADMIN';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] as String?) ?? '',
    loginId: (json['loginId'] as String?) ?? '',
    role: (json['role'] as String?) ?? '',
    status: (json['status'] as String?) ?? 'ACTIVE',
    qrToken: json['qrToken'] as String?,
  );
}

class LoginResponse {
  final String accessToken;
  final AuthUser user;

  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['accessToken'] as String,
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class CollectorDetails {
  final String id;
  final String fullName;
  final String mobile;
  final String? loginId;

  const CollectorDetails({
    required this.id,
    required this.fullName,
    required this.mobile,
    this.loginId,
  });

  factory CollectorDetails.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return CollectorDetails(
      id: json['id'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      mobile: (json['mobile'] as String?) ?? '',
      loginId: user is Map ? user['loginId'] as String? : null,
    );
  }
}

class RiderDetails {
  final String id;
  final String fullName;
  final String mobile;

  const RiderDetails({
    required this.id,
    required this.fullName,
    required this.mobile,
  });

  factory RiderDetails.fromJson(Map<String, dynamic> json) => RiderDetails(
    id: json['id'] as String,
    fullName: (json['fullName'] as String?) ?? '',
    mobile: (json['mobile'] as String?) ?? '',
  );
}

class DailyAssignment {
  final String id;
  final String assignmentDate;
  final CollectorDetails collector;

  const DailyAssignment({
    required this.id,
    required this.assignmentDate,
    required this.collector,
  });

  factory DailyAssignment.fromJson(Map<String, dynamic> json) =>
      DailyAssignment(
        id: json['id'] as String,
        assignmentDate: json['assignmentDate'] as String,
        collector: CollectorDetails.fromJson(
          json['collector'] as Map<String, dynamic>,
        ),
      );
}

enum RequestStatus { pending, accepted, completed, cancelled }

class CollectionRequest {
  final String id;
  final String? collectorId;
  final String? riderId;
  final double latitude;
  final double longitude;
  final RequestStatus status;
  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final CollectorDetails? collector;
  final RiderDetails? rider;

  const CollectionRequest({
    required this.id,
    this.collectorId,
    this.riderId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.collector,
    this.rider,
  });

  static RequestStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'PENDING':
        return RequestStatus.pending;
      case 'ACCEPTED':
        return RequestStatus.accepted;
      case 'COMPLETED':
        return RequestStatus.completed;
      case 'CANCELLED':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.pending;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String)?.toLocal();
  }

  factory CollectionRequest.fromJson(Map<String, dynamic> json) {
    final collectorRaw = json['collector'];
    final riderRaw = json['rider'];
    return CollectionRequest(
      id: json['id'] as String,
      collectorId: json['collectorId'] as String?,
      riderId: json['riderId'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      status: _statusFrom(json['status'] as String?),
      requestedAt: _parseDate(json['requestedAt']),
      acceptedAt: _parseDate(json['acceptedAt']),
      completedAt: _parseDate(json['completedAt']),
      cancelledAt: _parseDate(json['cancelledAt']),
      collector: collectorRaw is Map
          ? CollectorDetails.fromJson(Map<String, dynamic>.from(collectorRaw))
          : null,
      rider: riderRaw is Map
          ? RiderDetails.fromJson(Map<String, dynamic>.from(riderRaw))
          : null,
    );
  }
}

class Vehicle {
  final String id;
  final String vehicleCode;
  final String vehicleType;
  final String status;

  const Vehicle({
    required this.id,
    required this.vehicleCode,
    required this.vehicleType,
    required this.status,
  });

  bool get isActive => status == 'ACTIVE';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String,
    vehicleCode:
        (json['vehicleCode'] as String?) ?? (json['code'] as String?) ?? '',
    vehicleType:
        (json['vehicleType'] as String?) ?? (json['type'] as String?) ?? '',
    status:
        (json['status'] as String?) ??
        ((json['isActive'] as bool?) == true ? 'ACTIVE' : 'ACTIVE'),
  );
}

class CollectionRecord {
  final String id;
  final String collectionRequestId;
  final String collectorId;
  final String riderId;
  final String? vehicleId;
  final double weightKg;
  final DateTime? collectedAt;
  final Vehicle? vehicle;

  const CollectionRecord({
    required this.id,
    required this.collectionRequestId,
    required this.collectorId,
    required this.riderId,
    this.vehicleId,
    required this.weightKg,
    this.collectedAt,
    this.vehicle,
  });

  factory CollectionRecord.fromJson(Map<String, dynamic> json) {
    final vehicleRaw = json['vehicle'];
    return CollectionRecord(
      id: json['id'] as String,
      collectionRequestId: json['collectionRequestId'] as String,
      collectorId: json['collectorId'] as String,
      riderId: json['riderId'] as String,
      vehicleId: json['vehicleId'] as String?,
      weightKg: _toDouble(json['weightKg']),
      collectedAt: json['collectedAt'] == null
          ? null
          : DateTime.tryParse(json['collectedAt'] as String)?.toLocal(),
      vehicle: vehicleRaw is Map
          ? Vehicle.fromJson(Map<String, dynamic>.from(vehicleRaw))
          : null,
    );
  }
}

class CompleteCollectionResponse {
  final CollectionRequest request;
  final CollectionRecord collection;

  const CompleteCollectionResponse({
    required this.request,
    required this.collection,
  });

  factory CompleteCollectionResponse.fromJson(Map<String, dynamic> json) =>
      CompleteCollectionResponse(
        request: CollectionRequest.fromJson(
          json['request'] as Map<String, dynamic>,
        ),
        collection: CollectionRecord.fromJson(
          json['collection'] as Map<String, dynamic>,
        ),
      );
}

/// One row of the collector leaderboard (ranked by total weight collected).
///
/// Returned by `GET /collector/leaderboard[?period=month]`. The backend
/// calculates `totalWeightKg`, `totalCollections` and `rank`; the app only
/// displays the response.
class LeaderboardEntry {
  final String collectorId;
  final String fullName;
  final double totalWeightKg;
  final int totalCollections;
  final int rank;

  const LeaderboardEntry({
    required this.collectorId,
    required this.fullName,
    required this.totalWeightKg,
    required this.totalCollections,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        collectorId: (json['collectorId'] as String?) ?? '',
        fullName: (json['fullName'] as String?) ?? '',
        totalWeightKg: _toDouble(json['totalWeightKg']),
        totalCollections: (json['totalCollections'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
      );
}
