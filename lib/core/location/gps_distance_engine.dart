import 'dart:math' as math;

class GpsRadiusCheckResult {
  final bool isWithinRadius;
  final double distanceMeters;
  final int allowedRadiusMeters;
  final double deltaMeters;

  const GpsRadiusCheckResult({
    required this.isWithinRadius,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    required this.deltaMeters,
  });

  @override
  String toString() =>
      'GpsRadiusCheckResult(isWithin: $isWithinRadius, dist: ${distanceMeters.toStringAsFixed(1)}m, allowed: ${allowedRadiusMeters}m)';
}

class GpsDistanceEngine {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates the spherical distance in meters between two lat/lon coordinates
  /// using the Haversine formula.
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    if (lat1 == lat2 && lon1 == lon2) {
      return 0.0;
    }

    final phi1 = lat1 * (math.pi / 180.0);
    final phi2 = lat2 * (math.pi / 180.0);
    final deltaPhi = (lat2 - lat1) * (math.pi / 180.0);
    final deltaLambda = (lon2 - lon1) * (math.pi / 180.0);

    final sinHalfDeltaPhi = math.sin(deltaPhi / 2.0);
    final sinHalfDeltaLambda = math.sin(deltaLambda / 2.0);

    final a = (sinHalfDeltaPhi * sinHalfDeltaPhi) +
        (math.cos(phi1) * math.cos(phi2) * sinHalfDeltaLambda * sinHalfDeltaLambda);

    // Clamp value to [0.0, 1.0] to avoid rounding/NaN issues with sqrt
    final clampedA = a.clamp(0.0, 1.0);
    final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));

    return earthRadiusMeters * c;
  }

  /// Verifies whether the current user position is within the target location's geofence radius.
  static GpsRadiusCheckResult checkRadius({
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required int radiusMeters,
  }) {
    final distance = calculateDistanceMeters(
      lat1: currentLatitude,
      lon1: currentLongitude,
      lat2: targetLatitude,
      lon2: targetLongitude,
    );

    final delta = distance - radiusMeters;
    final isWithin = distance <= radiusMeters;

    return GpsRadiusCheckResult(
      isWithinRadius: isWithin,
      distanceMeters: distance,
      allowedRadiusMeters: radiusMeters,
      deltaMeters: delta,
    );
  }

  /// Friendly human-readable distance formatter
  static String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      final km = distanceMeters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
