import 'dart:math' as math;
import '../../../../core/location/gps_distance_engine.dart';
import '../../../../core/location/location_coordinates.dart';

class ReconciliationResult {
  final double claimedDistanceKm;
  final double gpsDistanceKm;
  final double discrepancyPercentage;
  final bool isFlaggedForFraud;
  final String? fraudReason;
  final double approvedPayout;

  const ReconciliationResult({
    required this.claimedDistanceKm,
    required this.gpsDistanceKm,
    required this.discrepancyPercentage,
    required this.isFlaggedForFraud,
    this.fraudReason,
    required this.approvedPayout,
  });
}

/// Core Fraud-Proof Conveyance Reconciliation Engine
/// Reconciles claimed odometer mileage against actual GPS waypoint tracks.
class ConveyanceReconciliationEngine {
  /// Default fraud tolerance threshold (15.0% discrepancy)
  static const double defaultFraudThresholdPercentage = 15.0;

  /// Calculates total distance traveled along a series of GPS waypoints in kilometers.
  static double calculateGpsRouteDistanceKm(List<LocationCoordinates> waypoints) {
    if (waypoints.length < 2) return 0.0;

    double totalMeters = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final p1 = waypoints[i];
      final p2 = waypoints[i + 1];
      totalMeters += GpsDistanceEngine.calculateDistanceMeters(
        lat1: p1.latitude,
        lon1: p1.longitude,
        lat2: p2.latitude,
        lon2: p2.longitude,
      );
    }

    return totalMeters / 1000.0;
  }

  /// Calculates the mathematical discrepancy percentage between claimed and GPS distance:
  ///
  /// Discrepancy % = (|Claimed - GPS| / max(Claimed, GPS)) * 100
  static double calculateDiscrepancyPercentage({
    required double claimedKm,
    required double gpsKm,
  }) {
    if (claimedKm <= 0 && gpsKm <= 0) return 0.0;

    final diff = (claimedKm - gpsKm).abs();
    final denominator = math.max(claimedKm, gpsKm);
    if (denominator <= 0.0001) return 0.0;

    final pct = (diff / denominator) * 100.0;
    return (pct * 10).roundToDouble() / 10.0; // Round to 1 decimal place
  }

  /// Evaluates conveyance claim against fraud policy rules.
  static ReconciliationResult evaluateClaim({
    required double startOdometer,
    required double endOdometer,
    required double gpsDistanceKm,
    required double ratePerKm,
    double fraudThresholdPct = defaultFraudThresholdPercentage,
    bool isGpsTrackingAvailable = true,
  }) {
    // 1. Calculate claimed mileage
    final claimedDistanceKm = (endOdometer - startOdometer).clamp(0.0, double.infinity);

    // If GPS was not recorded (e.g. permission denied or indoors), calculate without discrepancy
    if (!isGpsTrackingAvailable || gpsDistanceKm <= 0.0) {
      final payout = (claimedDistanceKm * ratePerKm * 100).roundToDouble() / 100.0;
      return ReconciliationResult(
        claimedDistanceKm: claimedDistanceKm,
        gpsDistanceKm: 0.0,
        discrepancyPercentage: 0.0,
        isFlaggedForFraud: false,
        fraudReason: null,
        approvedPayout: payout,
      );
    }

    // 2. Calculate discrepancy percentage
    final discrepancyPct = calculateDiscrepancyPercentage(
      claimedKm: claimedDistanceKm,
      gpsKm: gpsDistanceKm,
    );

    // 3. Determine fraud flag
    bool isFlagged = false;
    String? reason;

    if (endOdometer < startOdometer) {
      isFlagged = true;
      reason = 'Fraud Alert: End odometer reading is less than start reading ($endOdometer < $startOdometer).';
    } else if (discrepancyPct > fraudThresholdPct) {
      isFlagged = true;
      final diff = (claimedDistanceKm - gpsDistanceKm).abs();
      if (claimedDistanceKm > gpsDistanceKm) {
        reason =
            'Audit Flag: Claimed distance (${claimedDistanceKm.toStringAsFixed(1)} km) exceeds GPS tracking (${gpsDistanceKm.toStringAsFixed(1)} km) by ${discrepancyPct.toStringAsFixed(1)}% (+${diff.toStringAsFixed(1)} km).';
      } else {
        reason =
            'Audit Flag: Claimed distance (${claimedDistanceKm.toStringAsFixed(1)} km) differs from GPS route (${gpsDistanceKm.toStringAsFixed(1)} km) by ${discrepancyPct.toStringAsFixed(1)}%.';
      }
    }

    // 4. Calculate payout: If discrepancy is flagged, conservative payout uses minimum of claimed vs GPS
    final reimbursableDistance = isFlagged
        ? math.min(claimedDistanceKm, gpsDistanceKm)
        : claimedDistanceKm;
    final payout = (reimbursableDistance * ratePerKm * 100).roundToDouble() / 100.0;

    return ReconciliationResult(
      claimedDistanceKm: claimedDistanceKm,
      gpsDistanceKm: (gpsDistanceKm * 10).roundToDouble() / 10.0,
      discrepancyPercentage: discrepancyPct,
      isFlaggedForFraud: isFlagged,
      fraudReason: reason,
      approvedPayout: payout,
    );
  }
}
