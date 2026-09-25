import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/features/beats/domain/entities/beat_stop_entity.dart';
import 'package:field_ops/features/beats/domain/services/route_optimization_engine.dart';

void main() {
  group('RouteOptimizationEngine TSP & Distance Optimization', () {
    const startCoord = LocationCoordinates(
      latitude: 37.7749,
      longitude: -122.4194,
    );

    const stopA = BeatStopEntity(
      id: 'stop-a',
      beatPlanId: 'beat-01',
      sequenceOrder: 1,
      customerId: 'cust-a',
      customerName: 'Customer A (Nearby)',
      locationId: 'loc-a',
      locationAddress: 'Market St',
      latitude: 37.7752,
      longitude: -122.4180,
    );

    const stopB = BeatStopEntity(
      id: 'stop-b',
      beatPlanId: 'beat-01',
      sequenceOrder: 2,
      customerId: 'cust-b',
      customerName: 'Customer B (Far away)',
      locationId: 'loc-b',
      locationAddress: 'Mission Bay',
      latitude: 37.7650,
      longitude: -122.3850,
    );

    const stopC = BeatStopEntity(
      id: 'stop-c',
      beatPlanId: 'beat-01',
      sequenceOrder: 3,
      customerId: 'cust-c',
      customerName: 'Customer C (Medium)',
      locationId: 'loc-c',
      locationAddress: 'Civic Center',
      latitude: 37.7790,
      longitude: -122.4150,
    );

    test('reorders unvisited stops by nearest neighbor sequence', () {
      // In reverse order (B far, then C medium, then A nearby)
      final unorderedStops = [stopB, stopC, stopA];

      final result = RouteOptimizationEngine.optimizeStopSequence(
        startLocation: startCoord,
        stops: unorderedStops,
      );

      expect(result.optimizedStops.length, equals(3));
      // First visited should be Stop A (closest to start point)
      expect(result.optimizedStops.first.id, equals('stop-a'));
      expect(result.optimizedStops.first.sequenceOrder, equals(1));
      // Sequence numbers must be contiguous 1..N
      expect(result.optimizedStops.map((s) => s.sequenceOrder).toList(), equals([1, 2, 3]));
      expect(result.savedDistanceKm, greaterThanOrEqualTo(0.0));
      expect(result.savingsPercentage, greaterThanOrEqualTo(0.0));
    });

    test('preserves already visited stops in front', () {
      final visitedStop = stopB.copyWith(isVisited: true, sequenceOrder: 1);
      final remaining = [stopC, stopA];

      final result = RouteOptimizationEngine.optimizeStopSequence(
        startLocation: startCoord,
        stops: [visitedStop, ...remaining],
      );

      expect(result.optimizedStops.first.id, equals('stop-b'));
      expect(result.optimizedStops.first.isVisited, isTrue);
      expect(result.optimizedStops.length, equals(3));
    });

    test('returns original stops when 1 or fewer unvisited stops', () {
      const single = [stopA];
      final result = RouteOptimizationEngine.optimizeStopSequence(
        startLocation: startCoord,
        stops: single,
      );

      expect(result.optimizedStops.length, equals(1));
      expect(result.savedDistanceKm, equals(0.0));
      expect(result.savingsPercentage, equals(0.0));
    });
  });

  group('RouteOptimizationEngine Compliance Calculations', () {
    test('calculates accurate compliance percentages', () {
      expect(RouteOptimizationEngine.calculateComplianceRate(visitedStops: 4, totalStops: 4), equals(100.0));
      expect(RouteOptimizationEngine.calculateComplianceRate(visitedStops: 3, totalStops: 4), equals(75.0));
      expect(RouteOptimizationEngine.calculateComplianceRate(visitedStops: 1, totalStops: 3), closeTo(33.33, 0.05));
      expect(RouteOptimizationEngine.calculateComplianceRate(visitedStops: 0, totalStops: 5), equals(0.0));
      expect(RouteOptimizationEngine.calculateComplianceRate(visitedStops: 0, totalStops: 0), equals(100.0));
    });

    test('returns correct compliance tier badges', () {
      expect(RouteOptimizationEngine.getComplianceRating(95.0), equals('Exceptional'));
      expect(RouteOptimizationEngine.getComplianceRating(90.0), equals('Exceptional'));
      expect(RouteOptimizationEngine.getComplianceRating(80.0), equals('High Compliance'));
      expect(RouteOptimizationEngine.getComplianceRating(75.0), equals('High Compliance'));
      expect(RouteOptimizationEngine.getComplianceRating(65.0), equals('Moderate'));
      expect(RouteOptimizationEngine.getComplianceRating(50.0), equals('Moderate'));
      expect(RouteOptimizationEngine.getComplianceRating(40.0), equals('Action Needed'));
      expect(RouteOptimizationEngine.getComplianceRating(10.0), equals('Action Needed'));
    });
  });
}
