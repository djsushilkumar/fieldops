import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/features/conveyance/domain/services/conveyance_reconciliation_engine.dart';

void main() {
  group('ConveyanceReconciliationEngine Unit Tests', () {
    test('calculateDiscrepancyPercentage returns 0.0 for identical distances', () {
      final pct = ConveyanceReconciliationEngine.calculateDiscrepancyPercentage(
        claimedKm: 50.0,
        gpsKm: 50.0,
      );
      expect(pct, 0.0);
    });

    test('calculateDiscrepancyPercentage accurately computes difference relative to max', () {
      // Claimed = 50km, GPS = 40km -> diff = 10km, max = 50km -> 10/50 * 100 = 20.0%
      final pct = ConveyanceReconciliationEngine.calculateDiscrepancyPercentage(
        claimedKm: 50.0,
        gpsKm: 40.0,
      );
      expect(pct, 20.0);
    });

    test('evaluates claim within 15% tolerance without fraud flag', () {
      // Start 1000, End 1045 -> claimed 45km. GPS tracked 42km -> diff 3km / 45km = 6.7% discrepancy
      final eval = ConveyanceReconciliationEngine.evaluateClaim(
        startOdometer: 1000.0,
        endOdometer: 1045.0,
        gpsDistanceKm: 42.0,
        ratePerKm: 3.50, // bike
      );

      expect(eval.claimedDistanceKm, 45.0);
      expect(eval.gpsDistanceKm, 42.0);
      expect(eval.discrepancyPercentage, 6.7);
      expect(eval.isFlaggedForFraud, isFalse);
      expect(eval.fraudReason, isNull);
      expect(eval.approvedPayout, 45.0 * 3.50); // 157.50
    });

    test('flags claim for fraud when discrepancy exceeds 15.0%', () {
      // Start 1000, End 1100 -> claimed 100km. GPS tracked 60km -> diff 40km / 100km = 40.0% discrepancy!
      final eval = ConveyanceReconciliationEngine.evaluateClaim(
        startOdometer: 1000.0,
        endOdometer: 1100.0,
        gpsDistanceKm: 60.0,
        ratePerKm: 8.00, // car
      );

      expect(eval.claimedDistanceKm, 100.0);
      expect(eval.gpsDistanceKm, 60.0);
      expect(eval.discrepancyPercentage, 40.0);
      expect(eval.isFlaggedForFraud, isTrue);
      expect(eval.fraudReason, contains('exceeds GPS tracking'));
      // Conservative payout limits to GPS distance (60 * 8.0 = 480.0)
      expect(eval.approvedPayout, 480.0);
    });

    test('flags fraud immediately when end odometer is less than start', () {
      final eval = ConveyanceReconciliationEngine.evaluateClaim(
        startOdometer: 15000.0,
        endOdometer: 14800.0,
        gpsDistanceKm: 25.0,
        ratePerKm: 3.50,
      );

      expect(eval.isFlaggedForFraud, isTrue);
      expect(eval.fraudReason, contains('End odometer reading is less than start reading'));
    });

    test('calculateGpsRouteDistanceKm computes path distance between coordinates', () {
      // Point 1: SF downtown, Point 2: Fisherman's Wharf (~2.5km)
      final waypoints = [
        const LocationCoordinates(latitude: 37.7749, longitude: -122.4194),
        const LocationCoordinates(latitude: 37.8080, longitude: -122.4177),
      ];

      final distanceKm = ConveyanceReconciliationEngine.calculateGpsRouteDistanceKm(waypoints);
      expect(distanceKm, greaterThan(3.0));
      expect(distanceKm, lessThan(4.0));
    });
  });
}
