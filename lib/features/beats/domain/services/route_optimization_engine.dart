import '../../../../core/location/gps_distance_engine.dart';
import '../../../../core/location/location_coordinates.dart';
import '../entities/beat_stop_entity.dart';

class RouteOptimizationResult {
  final List<BeatStopEntity> optimizedStops;
  final double originalDistanceKm;
  final double optimizedDistanceKm;
  final double savedDistanceKm;
  final double savingsPercentage;

  const RouteOptimizationResult({
    required this.optimizedStops,
    required this.originalDistanceKm,
    required this.optimizedDistanceKm,
    required this.savedDistanceKm,
    required this.savingsPercentage,
  });
}

/// Intelligent PJP Route Optimizer & Compliance Calculation Engine
/// Implements nearest-neighbor TSP heuristic with Haversine distance.
class RouteOptimizationEngine {
  /// Optimizes the visitation sequence of beat stops starting from current location.
  static RouteOptimizationResult optimizeStopSequence({
    required LocationCoordinates startLocation,
    required List<BeatStopEntity> stops,
  }) {
    if (stops.length <= 1) {
      return RouteOptimizationResult(
        optimizedStops: List.from(stops),
        originalDistanceKm: 0.0,
        optimizedDistanceKm: 0.0,
        savedDistanceKm: 0.0,
        savingsPercentage: 0.0,
      );
    }

    // Partition into already visited and remaining unvisited stops
    final visited = stops.where((s) => s.isVisited).toList();
    final unvisited = stops.where((s) => !s.isVisited).toList();

    if (unvisited.length <= 1) {
      return RouteOptimizationResult(
        optimizedStops: List.from(stops),
        originalDistanceKm: 0.0,
        optimizedDistanceKm: 0.0,
        savedDistanceKm: 0.0,
        savingsPercentage: 0.0,
      );
    }

    // 1. Calculate original sequence distance for the remaining unvisited stops
    final originalMeters = _calculateRouteMeters(startLocation, unvisited);

    // 2. Keep visited stops at the front with their sequence intact
    final optimized = <BeatStopEntity>[];
    for (int i = 0; i < visited.length; i++) {
      optimized.add(visited[i].copyWith(sequenceOrder: i + 1));
    }

    var currentLat = startLocation.latitude;
    var currentLon = startLocation.longitude;

    // Nearest Neighbor TSP on remaining unvisited stops
    while (unvisited.isNotEmpty) {
      int closestIdx = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < unvisited.length; i++) {
        final stop = unvisited[i];
        final dist = GpsDistanceEngine.calculateDistanceMeters(
          lat1: currentLat,
          lon1: currentLon,
          lat2: stop.latitude,
          lon2: stop.longitude,
        );

        if (dist < minDistance) {
          minDistance = dist;
          closestIdx = i;
        }
      }

      final nearestStop = unvisited.removeAt(closestIdx);
      optimized.add(nearestStop.copyWith(sequenceOrder: optimized.length + 1));
      currentLat = nearestStop.latitude;
      currentLon = nearestStop.longitude;
    }

    // 3. Calculate optimized sequence distance for reordered unvisited stops
    final newlyOrderedUnvisited = optimized.where((s) => !s.isVisited).toList();
    final optimizedMeters = _calculateRouteMeters(startLocation, newlyOrderedUnvisited);

    final originalKm = (originalMeters / 1000.0 * 10).roundToDouble() / 10.0;
    final optimizedKm = (optimizedMeters / 1000.0 * 10).roundToDouble() / 10.0;
    final savedKm = ((originalMeters - optimizedMeters) / 1000.0).clamp(0.0, double.infinity);
    final savedKmRounded = (savedKm * 10).roundToDouble() / 10.0;

    final savingsPct = originalMeters > 0
        ? (((originalMeters - optimizedMeters) / originalMeters) * 100.0).clamp(0.0, 100.0)
        : 0.0;
    final savingsPctRounded = (savingsPct * 10).roundToDouble() / 10.0;

    return RouteOptimizationResult(
      optimizedStops: optimized,
      originalDistanceKm: originalKm,
      optimizedDistanceKm: optimizedKm,
      savedDistanceKm: savedKmRounded,
      savingsPercentage: savingsPctRounded,
    );
  }

  static double _calculateRouteMeters(
    LocationCoordinates startLocation,
    List<BeatStopEntity> sequence,
  ) {
    if (sequence.isEmpty) return 0.0;

    double total = GpsDistanceEngine.calculateDistanceMeters(
      lat1: startLocation.latitude,
      lon1: startLocation.longitude,
      lat2: sequence.first.latitude,
      lon2: sequence.first.longitude,
    );

    for (int i = 0; i < sequence.length - 1; i++) {
      total += GpsDistanceEngine.calculateDistanceMeters(
        lat1: sequence[i].latitude,
        lon1: sequence[i].longitude,
        lat2: sequence[i + 1].latitude,
        lon2: sequence[i + 1].longitude,
      );
    }

    return total;
  }

  /// Calculates beat execution compliance rate percentage.
  static double calculateBeatCompliance({
    required int plannedStops,
    required int visitedStops,
  }) {
    if (plannedStops <= 0) return 0.0;
    final pct = (visitedStops / plannedStops) * 100.0;
    return (pct.clamp(0.0, 100.0) * 10).roundToDouble() / 10.0;
  }

  /// Calculates beat compliance with visitedStops and totalStops parameters
  static double calculateComplianceRate({
    required int visitedStops,
    required int totalStops,
  }) {
    if (totalStops <= 0) return 100.0;
    final pct = (visitedStops / totalStops) * 100.0;
    return (pct.clamp(0.0, 100.0) * 10).roundToDouble() / 10.0;
  }

  /// Returns textual rating for a compliance percentage.
  static String getComplianceRating(double complianceRate) {
    if (complianceRate >= 90.0) return 'Exceptional';
    if (complianceRate >= 75.0) return 'High Compliance';
    if (complianceRate >= 50.0) return 'Moderate';
    return 'Action Needed';
  }
}
